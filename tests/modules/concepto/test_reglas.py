"""Reglas del módulo concepto (RNF-017).

El servicio de concepto es íntegramente esqueleto en este backend: ``reemitir``,
``concepto_a_fecha`` y todos los demás métodos de ``ServicioConcepto`` (y los del
repositorio) lanzan ``NoImplementado``. No hay cálculo puro en dominio.py (el módulo
ni siquiera lo tiene). Las tres reglas viven en ese código que aún no existe, así que
se dejan con skip y motivo; NO se inventa la lógica.
"""

import pytest


@pytest.mark.regla
@pytest.mark.skip(
    reason="ServicioConcepto.reemitir lanza NoImplementado: ningún código Python asigna hoy "
    "conc_fecha_efecto = t_observacion del registro disparador (la regla está solo en el docstring)."
)
def test_concepto_01() -> None:
    """reemisión usa fecha de efecto = t_observacion del registro disparador."""


@pytest.mark.regla
@pytest.mark.skip(
    reason="ServicioConcepto.concepto_a_fecha y RepositorioConcepto.concepto_a_fecha lanzan NoImplementado "
    "(la consulta SQL «vigente a esa fecha» ni siquiera está escrita). No hay nada Python que respondería "
    "con el concepto que regía ese día (RF-024)."
)
def test_concepto_02() -> None:
    """concepto a una fecha devuelve el que regía ese día (RF-024)."""


@pytest.mark.regla
@pytest.mark.skip(
    reason="La derivación «sin umbral -> no_emitido» vive en reemitir(), hoy NoImplementado. Solo existen "
    "los vocabularios ResultadoContraste.SIN_UMBRAL / ResultadoConcepto.NO_EMITIDO; probarlos no probaría "
    "la regla."
)
def test_concepto_03() -> None:
    """sin umbral el concepto es no_emitido."""
