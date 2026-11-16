# Cambios del backend (API SIGAT Durazno)

Registro de cambios del código del backend. **La base de datos tiene su propio registro:**
`bd/CAMBIOS.md` (una entrada por revisión, como exige la convención del equipo).

Los comentarios inline del código solo documentan el *por qué* inmediato de una línea
(SQLSTATE, regla de BD, decisión de seguridad). La rationale de nivel sprint y los
pendientes viven aquí, no en el código.

## Pendientes técnicos

Extraídos del código en el cierre del Sprint 2 backend (seguían siendo comentarios
«PENDIENTE» en el fuente; aquí siguen siendo visibles sin ensuciar el código):

1. **Worker de la cola (procrastinate)** — `src/sigat_api/worker.py` lanza
   `NotImplementedError`. Tareas previstas: `reprocesar_periodo` →
   `sincronizacion.procesador.ProcesadorReproceso`; `generar_paquete_campo` →
   `configuracion.servicio.ServicioPaqueteCampo.generar`; `verificar_archivo` →
   `imagenes.servicio.ServicioArchivos`; `enviar_correo` → `infra.correo.enviar`.
   Arranque: `app.run_worker_async(concurrency=cfg.cola_concurrencia)`.
2. **Bloques nulos del inicio** — `api/v1/rutas/yo.py`: los bloques `tecnico` /
   `productor` / `agronomo` de `InicioResumen` van en `null` (nunca valores inventados)
   hasta que sus módulos estén implementados.
3. **Indicadores de lote sin fuente en la BD** — `configuracion.servicio`: no existe
   vista ni función en la BD que calcule los campos obligatorios de `IndicadoresLote`;
   el bloque va en `null` (lo admite el esquema). Depende de la BD (ver `bd/CAMBIOS.md`).
4. **Foto de perfil** — `identidad.servicio`: `foto_url=None` hasta que el módulo de
   imágenes implemente la URL firmada.

## Reglas sin implementación (backlog de pruebas)

Auditoría regla por regla de `tests/modules/*/test_reglas.py`: los stubs cuya regla **no
tiene código que probar** se conservan con skip y motivo documentado (nunca asserts vacíos).
Corresponden a Sprints 3–5 del cronograma, no al Sprint 2:

- **planificación** (Sprint 5): 01 C01 creador=actor, 03 plan ACEPTADA + ≥1 lote, 04 solo
  destinatario y solo pendiente → triggers SQL (`fn_planificacion_*`); 02 documento u
  observación ≥ 10 → solo docstring; 06 justificación/no_ejecutada → CHECK SQL; 07 completar
  al resolver lotes → ausente.
- **sincronización** (Sprint 5): 01 idempotencia R-T4, 02 conflicto_contenido, 03 respuesta
  por operación, 04 reintentable=false, 05 R-T6 revisar, 06 disp_id 403, 07 reproceso →
  `ServicioSincronizacion`/`ProcesadorReproceso` son `NoImplementado`; la idempotencia vive
  en BD (`UNIQUE (disp_id, oper_cliente_id)`, `recepcion_sync` append-only).
- **catálogo**: 01 mayúsculas, 02 retiro lógico, 03 invalida paquetes → `reemplazar()` es
  `NoImplementado` (efecto en BD/cola).
- **concepto**: 01 reemisión, 02 a una fecha (RF-024), 03 sin umbral → `ServicioConcepto`
  completo `NoImplementado`.
- **imágenes**: 01 hash, 02 MIME por contenido, 03 foto ajena → `ServicioArchivos`,
  `AlmacenS3` y `ServicioPerfil.poner_foto` `NoImplementado`.
- **configuración 02** (ADR-05): pipeline de versiones de programa `NoImplementado`.
- **escenarios MVP** (`tests/integracion/test_escenarios_mvp.py`): requieren el pipeline de
  sincronización completo; el job `integracion` del CI los ejecutará cuando existan.

Para llevar cada skip a test real hay que **implementar el feature** (el test ya está
diseñado: docstring con la regla y el camino a ejercer). Probar el esqueleto equivaldría a
afirmar «el código es un stub», no la regla.

## Cierre del Sprint 2 (backend)

- **Contrato OpenAPI regenerado** (`contracts/openapi.json`): la frase del código 422
  pasó de «Unprocessable Entity» a «Unprocessable Content» en starlette >= 1.x; el
  contrato comitado quedó obsoleto y tumbaba la puerta «Contrato OpenAPI sincronizado»
  del CI. Regenerado con el toolchain actual del CI.
- **`pyproject.toml`**: se eliminó `readme = "README.md"` (el documento vive fuera del
  repo por decisión de equipo); sin esto, `pip install -e .` fallaba y con él el job de
  calidad del CI.
- **Puerta de cobertura restablecida** (RNF-017 / ADR-17): el CI deja de correr
  `pytest` con `--no-cov` y vuelve a medir sobre las reglas de negocio. Por decisión
  del equipo el `fail_under` arranca bajo (60 %) y se sube sprint a sprint hasta el
  80 % exigido para fusionar. Resultado en este cierre: **198 pruebas pasan (antes
  173), 23 skip justificados, 0 fallos; cobertura 72.8 %** (antes 70.5 %).
- **Pruebas de reglas revisadas una a una**: los stubs con `@pytest.mark.skip("Por
  implementar")` se auditaron contra el código real. Los que tienen implementación
  testeable ya son **pruebas reales** (registro_01/03/04/11, auditoría_01/02,
  notificaciones_01/02/03, planificación_05, configuración_03/06). Los de registro
  sin implementación (02, 05–10) son **tripwires**: asserts sobre el 501
  `NoImplementado` + los tokens de contrato de cada regla; fallan en cuanto alguien
  programe la regla. Los que **no tienen implementación** — el módulo es esqueleto
  (`NoImplementado` en servicio y repositorio) o la regla vive solo en
  triggers/CHECKs de PostgreSQL o en docstrings (Sprints 3–5) — se conservan como
  skip **con motivo documentado**, nunca con asserts vacíos. Ver la sección
  «Reglas sin implementación (backlog de pruebas)» de arriba.
- **Limpieza de comentarios** (solo Python; `bd/` intacto por convención): se eliminaron
  los marcadores «PENDIENTE» del código (están en «Pendientes técnicos» de arriba) y la
  referencia colgante a `docs/07_prefijos.md`. Se conservaron deliberadamente los
  comentarios que explican el *por qué* junto al código (mapeo de SQLSTATE, P-04,
  RFC 8785, argon2id, seguridad de listas blancas…): sacarlos a un md obligaría a
  saltar entre archivos para entender una línea. Los 387 comentarios de `bd/sql/` y los
  docstrings de las migraciones tampoco se tocaron: son la documentación por revisión
  que exige `bd/CAMBIOS.md` y que `scripts/revisar_migraciones.py` usa.
