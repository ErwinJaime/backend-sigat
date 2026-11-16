"""Reglas del módulo planificacion (los disparadores fn_planificacion_* las refuerzan en la BD)."""

from datetime import date
from typing import Any
from uuid import UUID

import pytest
from pydantic import ValidationError

from sigat_api.compartido.errores import Prohibido, ReglaNegocio
from sigat_api.compartido.tipos import Actor, Cliente, RolCodigo
from sigat_api.modules.planificacion import esquemas as e
from sigat_api.modules.planificacion.servicio import ServicioPlanificacion

PENDIENTE = pytest.mark.skip(reason="Por implementar")

AGRONOMO = Actor(usua_id=2, rol=RolCodigo.AGRONOMO_SUPERVISOR, disp_id=None, cliente=Cliente.WEB)
ORIGEN = UUID(int=1)


class _Repo:
    """Destinatario del ``tipo`` dado, lotes 1 y 2 asignables y un origen en ``estado_origen``."""

    def __init__(self, tipo: str, estado_origen: str = "aceptada") -> None:
        self.tipo = tipo
        self.estado_origen = estado_origen
        self.insertadas: list[dict[str, Any]] = []

    async def destinatarios(
        self, tipo: str | None, agronomo: int, usua_id: int | None = None
    ) -> list[dict[str, Any]]:
        return [{"usua_id": usua_id, "nombre": "X", "subtitulo": "X", "tipo": self.tipo}]

    async def lotes_asignables(self, agronomo: int, destinatario: int | None) -> list[dict[str, Any]]:
        return [{"lote_id": 1}, {"lote_id": 2}]

    async def obtener(self, plan_id: UUID) -> dict[str, Any] | None:
        return {
            "plan_id": ORIGEN,
            "tipo": "productor",
            "plan_estado": self.estado_origen,
            "plan_fecha_inicio": date(2026, 11, 1),
            "plan_fecha_fin": None,
            "lote_ids": [1, 2],
            "usua_id_creador": AGRONOMO.usua_id,
            "usua_id_destinatario": 4,
        }

    async def insertar(self, fila: dict[str, Any], lote_ids: list[int]) -> UUID:
        self.insertadas.append(fila)
        raise _Insertada


class _Insertada(Exception):
    """Corta el flujo tras insertar: estas reglas no dependen de la respuesta."""


def _nueva(destinatario: int, **cambios: Any) -> e.NuevaPlanificacion:
    return e.NuevaPlanificacion(
        usua_id_destinatario=destinatario,
        plan_actividad="Actividad",
        plan_fecha_inicio=date(2026, 11, 20),
        **cambios,
    )


async def _crear(repo: _Repo, actor: Actor, s: e.NuevaPlanificacion) -> None:
    with pytest.raises(_Insertada):
        await ServicioPlanificacion(repo).crear(actor, s)  # type: ignore[arg-type]


@pytest.mark.regla
async def test_planificacion_01() -> None:
    """solo el agrónomo crea (C01: creador = actor)."""
    for rol in (RolCodigo.TECNICO, RolCodigo.PRODUCTOR, RolCodigo.ADMINISTRADOR):
        otro = Actor(usua_id=9, rol=rol, disp_id=None, cliente=Cliente.WEB)
        svc = ServicioPlanificacion(_Repo("productor"))  # type: ignore[arg-type]
        with pytest.raises(Prohibido):
            await svc.crear(otro, _nueva(4, plan_observaciones="Observación válida"))

    repo = _Repo("productor")
    await _crear(repo, AGRONOMO, _nueva(4, plan_observaciones="Observación válida"))
    assert repo.insertadas[0]["usua_id_creador"] == AGRONOMO.usua_id


@pytest.mark.regla
async def test_planificacion_02() -> None:
    """planificación a productor exige documento u observación >= 10."""
    svc = ServicioPlanificacion(_Repo("productor"))  # type: ignore[arg-type]
    with pytest.raises(ReglaNegocio) as error:
        await svc.crear(AGRONOMO, _nueva(4, plan_observaciones="123456789"))
    assert error.value.codigo == "DOCUMENTO_U_OBSERVACION_REQUERIDO"

    await _crear(_Repo("productor"), AGRONOMO, _nueva(4, plan_observaciones="1234567890"))
    await _crear(_Repo("productor"), AGRONOMO, _nueva(4, arch_id_documento=UUID(int=7)))


@pytest.mark.regla
async def test_planificacion_03() -> None:
    """actividad de técnico exige plan_id_origen ACEPTADA y al menos un lote."""
    casos = [
        (_Repo("tecnico"), _nueva(3, plan_id_origen=ORIGEN), "LOTES_REQUERIDOS"),
        (_Repo("tecnico"), _nueva(3, lote_ids=[1]), "ORIGEN_REQUERIDO"),
        (_Repo("tecnico", "pendiente"), _nueva(3, plan_id_origen=ORIGEN, lote_ids=[1]), "ORIGEN_NO_ACEPTADO"),
    ]
    for repo, s, codigo in casos:
        with pytest.raises(ReglaNegocio) as error:
            await ServicioPlanificacion(repo).crear(AGRONOMO, s)  # type: ignore[arg-type]
        assert error.value.codigo == codigo

    await _crear(_Repo("tecnico"), AGRONOMO, _nueva(3, plan_id_origen=ORIGEN, lote_ids=[1]))


@pytest.mark.regla
@PENDIENTE
def test_planificacion_04() -> None:
    """solo el productor destinatario responde y solo si pendiente."""


@pytest.mark.regla
def test_planificacion_05() -> None:
    """rechazo exige motivo >= 10 (punto de aplicación hoy en Python: ``esquemas.Rechazo``)."""
    with pytest.raises(ValidationError) as error:
        e.Rechazo(motivo="corto")

    fallos = error.value.errors()
    assert len(fallos) == 1
    assert fallos[0]["loc"] == ("motivo",)
    assert fallos[0]["type"] == "string_too_short"

    # El límite es 10: nueve se rechazan, diez se aceptan.
    with pytest.raises(ValidationError) as error_nueve:
        e.Rechazo(motivo="123456789")
    assert error_nueve.value.errors()[0]["loc"] == ("motivo",)

    justo = e.Rechazo(motivo="1234567890")
    assert justo.motivo == "1234567890"


@pytest.mark.regla
@PENDIENTE
def test_planificacion_06() -> None:
    """no_ejecutada exige justificación; un lote se resuelve una vez."""


@pytest.mark.regla
@PENDIENTE
def test_planificacion_07() -> None:
    """al resolver todos los lotes la actividad pasa a completada."""
