"""Reglas del módulo sincronizacion.

Estado real del módulo: la capa Python es un esqueleto. ``ServicioSincronizacion.recibir`` /
``.resolver`` / ``.pendientes``, ``RegistradorOperacionesEnLinea`` y ``ProcesadorReproceso``
lanzan ``NoImplementado``; las garantías con las que el diseño cubre estas reglas viven en la BD
(clave única ``operacion_sync (disp_id, oper_cliente_id)``, ``recepcion_sync`` append-only, CHECK
``oper_hash_contenido``/``oper_motivo_requerido``; bd/sql/01_esquema_completo.sql) y el ordenado
del encolado del reproceso está solo en los docstrings del servicio/procesador.

No hay forma honesta de testearlas unitariamente hoy: una prueba con dobles de repo, puertos, cola
o reloj no llegaría más allá del ``NoImplementado`` (la excepción se lanza antes de tocar ninguno)
y no demostraría nada sobre la regla. Los siete stubs conservan ``@PENDIENTE`` hasta que exista la
implementación Python (ver informe del trabajo).
"""

import pytest

PENDIENTE = pytest.mark.skip(reason="Por implementar")


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_01() -> None:
    """R-T4 mismo cliente_id y mismo hash es idempotente_repetida sin duplicar."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_02() -> None:
    """mismo cliente_id con hash distinto es conflicto_contenido."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_03() -> None:
    """lote parcialmente aceptado responde por operación."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_04() -> None:
    """revisar/rechazada tienen reintentable=false."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_05() -> None:
    """R-T6 deriva de reloj sin confirmación queda en revisar."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_06() -> None:
    """disp_id distinto al del token rechaza el lote con 403."""


@pytest.mark.regla
@PENDIENTE
def test_sincronizacion_07() -> None:
    """alta retroactiva encola reproceso con clave única por periodo."""
