"""Reglas de negocio del módulo registro: cada una cuenta para RNF-017.

Patrón (igual que ``tests/modules/configuracion/test_reglas.py``): dobles que implementan
el protocolo del repositorio + el servicio/dominio REAL, sin PostgreSQL.

Honestidad: el motor temporal (``dominio.clasificar``), el validador de invariantes y el
MTD son hoy un esqueleto ``NoImplementado`` en Python (las reglas viven en la BD:
``fn_registro_version_valida``, CHECKs y vistas, o aún faltan). Esos tests son
"tripwires": afirman el 501 actual y el token de contrato que la regla debe producir, y
FALLAN en cuanto alguien programe la regla, obligando a reescribirlos con asserts reales.
"""

from copy import deepcopy
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import Any
from uuid import UUID

import pytest

from sigat_api.compartido.contratos import OperacionCampo, PertenenciaTrampa
from sigat_api.compartido.errores import Conflicto, NoImplementado
from sigat_api.compartido.tipos import (
    AccionSync,
    Actor,
    ClasificacionOperacion,
    Cliente,
    EntidadSync,
    Linaje,
    ResultadoContraste,
    RolCodigo,
)
from sigat_api.modules.registro import esquemas as e
from sigat_api.modules.registro.dominio import EstadoPrevio, MotivoRechazo, clasificar, orden_canonico
from sigat_api.modules.registro.mtd import EntradaMtd, calcular
from sigat_api.modules.registro.servicio import ServicioConsultaRegistro, ServicioRegistro, ServicioRevision
from sigat_api.modules.registro.validador import ValidadorInvariantes

AGRONOMO = Actor(usua_id=3, rol=RolCodigo.AGRONOMO_SUPERVISOR, disp_id=None, cliente=Cliente.WEB)
AHORA = datetime(2026, 11, 12, 15, 0, tzinfo=UTC)
T_OBS = datetime(2026, 11, 10, 8, 10, tzinfo=UTC)
VISI = UUID("0190f0d0-0000-7000-8000-000000000001")
REGISTRO = UUID("0190f0d0-0000-7000-8000-0000000000aa")
CLIENTE_ID = UUID("0190f0d0-0000-7000-8000-0000000000c1")
DISP_ID = UUID("0190f0d0-0000-7000-8000-0000000000d2")


def _el(dia: int, hora: int, minuto: int = 0) -> datetime:
    return datetime(2026, 11, dia, hora, minuto, tzinfo=UTC)


VERSIONES: list[dict[str, Any]] = [
    {
        "version": 1,
        "anulada": False,
        "motivo": None,
        "autor": "Técnico Prueba",
        "usua_id": 2,
        "t_sincronizacion": _el(10, 12),
        "t_observacion": T_OBS,
        "valores": {"lect_especimenes": 9},
    },
    {
        "version": 2,
        "anulada": False,
        "motivo": "Se contaron dos veces los mismos especímenes",
        "autor": "Agrónomo Prueba",
        "usua_id": 3,
        "t_sincronizacion": _el(11, 10),
        "t_observacion": T_OBS,
        "valores": {"lect_especimenes": 7},
    },
]

VISITA_ACEPTADA: dict[str, Any] = {
    "visi_id": VISI,
    "usua_id": 2,
    "tecnico": "Técnico Prueba",
    "pred_id": 1,
    "pred_nombre": "Finca de demostración",
    "ruta_id": None,
    "t_inicio_obs": _el(10, 8),
    "t_fin_obs": _el(10, 9),
    "t_captura": _el(10, 9, 5),
    "t_sincronizacion": _el(10, 12),
    "deriva_reloj_seg": 4,
    "estado_revision": "aceptado",
    "motivo_revision": "Duplicada con la visita del martes",
    "revisada_por": 3,
    "revisada_en": AHORA,
    "lote_ids": [1],
    "lotes": ["01"],
    "trampas_leidas": 1,
    "lote_sin_asignacion": False,
    "trampa_fuera_del_lote": False,
}


class _RepoVersiones:
    """Solo lo que ``versiones_lectura`` necesita: visibilidad + versiones append-only."""

    def __init__(self, versiones: list[dict[str, Any]]) -> None:
        self.filas = deepcopy(versiones)
        self.consultadas: list[tuple[str, UUID]] = []

    async def lectura_visible(self, usua_id: int, solo_propias: bool, registro_id: UUID) -> bool:
        return registro_id == REGISTRO

    async def versiones(self, entidad: str, registro_id: UUID) -> list[dict[str, Any]]:
        self.consultadas.append((entidad, registro_id))
        return deepcopy(self.filas)


class _RepoRevision:
    """Una visita ya aceptada: ``aceptar`` debe dar 409 sin escribir."""

    def __init__(self) -> None:
        self.fila = deepcopy(VISITA_ACEPTADA)
        self.llamadas: list[tuple[Any, ...]] = []

    async def registro_revision(self, usua_id: int, visi_id: UUID, bloquear: bool = False):
        self.llamadas.append(("registro_revision", visi_id, bloquear))
        return deepcopy(self.fila) if visi_id == VISI else None

    async def actualizar_revision_visita(
        self, visi_id: UUID, estado: str, motivo: str | None, usua_id: int, en: datetime
    ) -> None:
        self.llamadas.append(("actualizar", visi_id, estado))

    async def lecturas_de_visita(self, visi_id: UUID):
        return []

    async def versiones(self, entidad: str, registro_id: UUID):
        return []


class _ConfigFalsa:
    """Puerto de configuración: registra si el validador llegó a consultarlo."""

    def __init__(self, pertenencia: PertenenciaTrampa | None) -> None:
        self.pertenencia = pertenencia
        self.llamadas: list[tuple[int, datetime]] = []

    async def pertenencia_trampa(self, tram_id: int, instante: datetime) -> PertenenciaTrampa | None:
        self.llamadas.append((tram_id, instante))
        return self.pertenencia

    async def lote_activo_en(self, lote_id: int, instante: datetime) -> bool:
        return True


class _RelojFijo:
    def ahora(self) -> datetime:
        return AHORA


class _RepoFalso:
    def __init__(self) -> None:
        self.llamadas: list[tuple[Any, ...]] = []

    async def estado_previo(self, *args: Any) -> Any:
        self.llamadas.append(args)
        return None


def _lectura(t_observacion: datetime, datos: dict[str, Any]) -> OperacionCampo:
    return OperacionCampo(
        oper_id=1,
        cliente_id=CLIENTE_ID,
        disp_id=DISP_ID,
        entidad=EntidadSync.LECTURA_TRAMPA,
        accion=AccionSync.CREAR,
        registro_id=REGISTRO,
        version=1,
        linaje=Linaje.INSPECCION_OFICIAL,
        t_observacion=t_observacion,
        t_captura=t_observacion + timedelta(minutes=1),
        deriva_reloj_seg=0,
        datos=datos,
    )


# ------------------------------------------------------------------ R-T1: orden canónico
@pytest.mark.regla
def test_registro_01() -> None:
    """R-T1: orden canónico por t_observacion; desempate (t_captura, id); la llegada no participa."""
    lecturas = [
        {"reg": "0003", "obs": _el(10, 8, 10), "cap": _el(10, 8, 11), "llego": _el(10, 12, 0)},
        {"reg": "0001", "obs": _el(10, 8, 5), "cap": _el(10, 8, 31), "llego": _el(10, 11, 0)},
        {"reg": "0002", "obs": _el(10, 8, 10), "cap": _el(10, 8, 0), "llego": _el(10, 13, 0)},
        {"reg": "0000", "obs": _el(10, 8, 10), "cap": _el(10, 8, 0), "llego": _el(10, 10, 0)},
    ]
    claves = [orden_canonico(f["obs"], f["cap"], f["reg"]) for f in lecturas]
    orden = [f["reg"] for _, f in sorted(zip(claves, lecturas, strict=True))]

    assert orden == ["0001", "0000", "0002", "0003"]  # observación, luego captura, luego id
    assert claves[2] < claves[0]  # "0002" llegó después que "0003" pero va antes: la llegada no ordena
    assert orden_canonico(_el(10, 8, 5), _el(10, 8, 31), "0001") == (_el(10, 8, 5), _el(10, 8, 31), "0001")


# ------------------------------------------------------------------ R-T2: alta retroactiva
@pytest.mark.regla
def test_registro_02() -> None:
    """R-T2: crear con t_observacion anterior a la última de la serie = alta_retroactiva.

    El motor temporal aún es esqueleto en Python (dominio.clasificar): tripwire.
    """
    previo = EstadoPrevio(
        version_vigente=None,
        t_observacion_original=None,
        ultima_t_observacion_serie=_el(10, 8, 0),
        hay_solapamiento=False,
    )

    with pytest.raises(NoImplementado) as exc:
        clasificar(AccionSync.CREAR, 1, _el(9, 10), previo)  # observada el día 9, antes que la última

    assert exc.value.estado_http == 501
    assert exc.value.codigo == "NO_IMPLEMENTADO"
    assert "Clasificación de la operación" in exc.value.detalle
    # token que la regla debe guardar en oper_clasificacion (CHECK de BD, d_clasificacion_operacion)
    assert ClasificacionOperacion.ALTA_RETROACTIVA.value == "alta_retroactiva"


# ------------------------------------------------------------------ R-T3: versión n+1
@pytest.mark.regla
async def test_registro_03() -> None:
    """R-T3: la corrección deja versión n+1 y conserva la anterior (append-only, nada se sobrescribe)."""
    repo = _RepoVersiones(VERSIONES)
    historial = await ServicioConsultaRegistro(repo).versiones_lectura(AGRONOMO, REGISTRO)  # type: ignore[arg-type]

    assert historial.entidad == "lectura_trampa"
    assert historial.registro_id == REGISTRO
    assert [v.version for v in historial.versiones] == [1, 2]
    assert historial.t_observacion == T_OBS  # misma ventana para ambas versiones
    assert historial.versiones[0].accion == AccionSync.CREAR  # la 1 es el alta
    assert historial.versiones[0].valores == {"lect_especimenes": 9}  # la original se conserva
    assert historial.versiones[1].accion == AccionSync.CORREGIR
    assert historial.versiones[1].motivo == "Se contaron dos veces los mismos especímenes"
    assert repo.consultadas == [("lectura_trampa", REGISTRO)]

    # Camino de escritura (crear la n+1): el servicio aún es esqueleto en Python.
    with pytest.raises(NoImplementado) as exc:
        await ServicioRegistro(None, None, None, None).corregir_lectura(  # type: ignore[arg-type]
            AGRONOMO,
            REGISTRO,
            e.CorreccionLectura(lect_especimenes=7, motivo="Se contaron dos veces los mismos especímenes"),
        )
    assert "Corregir lectura" in exc.value.detalle


# ------------------------------------------------------------------ ADR-02: t_observacion inmutable
@pytest.mark.regla
async def test_registro_04() -> None:
    """ADR-02: la corrección no puede cambiar t_observacion (anular y crear nueva, no corregir la fecha)."""
    # 1) El contrato web de corrección ni siquiera admite otra fecha de observación.
    assert "t_observacion" not in e.CorreccionLectura.model_fields
    # 2) El historial reporta la fecha de la versión 1 aunque una versión posterior traiga otra:
    #    la fecha vive en el registro, no en la versión del cambio.
    versiones = deepcopy(VERSIONES)
    versiones[1]["t_observacion"] = T_OBS + timedelta(hours=3)
    historial = await ServicioConsultaRegistro(_RepoVersiones(versiones)).versiones_lectura(  # type: ignore[arg-type]
        AGRONOMO, REGISTRO
    )
    assert historial.t_observacion == T_OBS
    # 3) La decisión de dominio (rechazar si difiere de la original) aún es esqueleto: tripwire.
    previo = EstadoPrevio(
        version_vigente=1,
        t_observacion_original=T_OBS,
        ultima_t_observacion_serie=T_OBS,
        hay_solapamiento=False,
    )
    with pytest.raises(NoImplementado) as exc:
        clasificar(AccionSync.CORREGIR, 2, T_OBS + timedelta(hours=1), previo)
    assert "Clasificación de la operación" in exc.value.detalle
    assert MotivoRechazo.T_OBSERVACION_CAMBIADA.value == "T_OBSERVACION_CAMBIADA"


# ------------------------------------------------------------------ R-T5: solapamiento
@pytest.mark.regla
def test_registro_05() -> None:
    """R-T5: solapamiento deja la operación en 'revisar' y no elige ganador.

    La bandera existe en EstadoPrevio; la decisión del motor temporal aún es esqueleto: tripwire.
    """
    previo = EstadoPrevio(
        version_vigente=1,
        t_observacion_original=T_OBS,
        ultima_t_observacion_serie=T_OBS,
        hay_solapamiento=True,  # otra medición del mismo tipo cubre esa ventana
    )
    assert previo.hay_solapamiento is True

    with pytest.raises(NoImplementado) as exc:
        clasificar(AccionSync.CREAR, 1, T_OBS, previo)
    assert "Clasificación de la operación" in exc.value.detalle
    # token que la regla debe producir (d_clasificacion_operacion): quedarse en revisar.
    assert ClasificacionOperacion.REVISAR.value == "revisar"


# ------------------------------------------------------------------ validaciones del invariante
@pytest.mark.regla
async def test_registro_06() -> None:
    """fecha de observación futura se rechaza (MotivoRechazo.FECHA_FUTURA).

    El validador de invariantes aún es esqueleto en Python: tripwire.
    """
    futura = AHORA + timedelta(days=1)
    assert futura > AHORA  # la fixture sí es futura
    config = _ConfigFalsa(None)

    with pytest.raises(NoImplementado) as exc:
        await ValidadorInvariantes(config, _RepoFalso()).validar(_lectura(futura, {}), AHORA)

    assert exc.value.estado_http == 501
    assert exc.value.codigo == "NO_IMPLEMENTADO"
    assert "Validación de invariantes" in exc.value.detalle
    assert config.llamadas == []  # el esqueleto ni siquiera consultó el puerto
    assert MotivoRechazo.FECHA_FUTURA.value == "FECHA_FUTURA"


@pytest.mark.regla
async def test_registro_07() -> None:
    """trampa que no pertenecía al lote en t_observacion se rechaza (TRAMPA_NO_PERTENECE_AL_LOTE).

    El validador aún es esqueleto: la pertenencia la debe preguntar PuertoConfiguracion en el
    instante de la observación (no hoy). Tripwire.
    """
    config = _ConfigFalsa(
        PertenenciaTrampa(tram_id=1, ubic_id=1, lote_id=2, pred_id=1, lote_activo=True)  # lote 2 ≠ lote 1
    )
    op = _lectura(T_OBS, {"lote_id": 1, "tram_id": 1})

    with pytest.raises(NoImplementado) as exc:
        await ValidadorInvariantes(config, _RepoFalso()).validar(op, AHORA)

    assert exc.value.codigo == "NO_IMPLEMENTADO"
    assert "Validación de invariantes" in exc.value.detalle
    assert config.llamadas == []  # no consultó la ubicación vigente al observar
    assert MotivoRechazo.TRAMPA_NO_PERTENECE_AL_LOTE.value == "TRAMPA_NO_PERTENECE_AL_LOTE"


@pytest.mark.regla
async def test_registro_08() -> None:
    """lectura no leída exige justificación y especímenes nulos (MotivoRechazo.VALOR_NO_VALIDO).

    Hoy lo exige la CHECK ``lectura_trampa_conteo_coherente`` (bd/sql/01_esquema_completo.sql);
    el validador Python aún es esqueleto: tripwire.
    """
    op = _lectura(
        T_OBS,
        {"lect_leida": False, "lect_especimenes": 3, "lect_justificacion": None},  # inválido
    )
    assert op.datos["lect_especimenes"] is not None
    assert op.datos["lect_justificacion"] is None

    with pytest.raises(NoImplementado) as exc:
        await ValidadorInvariantes(_ConfigFalsa(None), _RepoFalso()).validar(op, AHORA)

    assert exc.value.estado_http == 501
    assert "Validación de invariantes" in exc.value.detalle
    assert MotivoRechazo.VALOR_NO_VALIDO.value == "VALOR_NO_VALIDO"


# ------------------------------------------------------------------ MTD
@pytest.mark.regla
def test_registro_09() -> None:
    """MTD = M/(T×D) y T×D=0 da nulo.

    La fórmula no está programada en ``mtd.calcular`` (esqueleto): tripwire. Cuando se
    implemente, este test debe afirmar 12/(3×4)=1.0 y valor None con T×D=0.
    """
    entrada = EntradaMtd(moscas=12, trampas=3, dias_exposicion=Decimal("4"), umbral=Decimal("2.5"))

    with pytest.raises(NoImplementado) as exc:
        calcular(entrada)

    assert exc.value.estado_http == 501
    assert exc.value.codigo == "NO_IMPLEMENTADO"
    assert "Cálculo del MTD" in exc.value.detalle


@pytest.mark.regla
def test_registro_10() -> None:
    """sin umbral vigente a la fecha del periodo, el contraste es sin_umbral (concepto no_emitido).

    El cálculo vive en ``mtd.calcular`` (esqueleto): tripwire + tokens del contrato de contraste.
    """
    sin_umbral = EntradaMtd(moscas=12, trampas=3, dias_exposicion=Decimal("4"), umbral=None)

    with pytest.raises(NoImplementado) as exc:
        calcular(sin_umbral)

    assert "Cálculo del MTD" in exc.value.detalle
    # tokens que la regla debe devolver (d_resultado_contraste, RF-024)
    assert ResultadoContraste.SIN_UMBRAL.value == "sin_umbral"
    assert ResultadoContraste.IGUAL_O_SUPERIOR_UMBRAL.value == "igual_o_superior_umbral"


# ------------------------------------------------------------------ revisión
@pytest.mark.regla
async def test_registro_11() -> None:
    """aceptar una revisión ya aceptada da 409 REVISION_YA_RESUELTA y no vuelve a escribir."""
    repo = _RepoRevision()

    with pytest.raises(Conflicto) as exc:
        await ServicioRevision(repo, _RelojFijo()).aceptar(AGRONOMO, VISI)  # type: ignore[arg-type]

    assert exc.value.estado_http == 409
    assert exc.value.codigo == "REVISION_YA_RESUELTA"
    assert "ya fue aceptada" in exc.value.detalle
    assert ("registro_revision", VISI, True) in repo.llamadas  # bloqueó la fila antes de decidir
    assert not [c for c in repo.llamadas if c[0] == "actualizar"]  # no sobrescribió la decisión
