# Pendientes institucionales (no se inventó ninguno)

Valores o reglas que la documentación no define; el esquema los deja vacíos o abiertos.

| Pendiente | Dónde se refleja |
|---|---|
| Umbral de exportación del MTD (UQQ-004) | `prog_umbral_exportacion_mtd` queda nulo; `concepto_aptitud` se emite como `no_emitido` mientras no exista |
| Tamaño de celda de la retícula (UQQ-005) | `reti_resolucion_m` es parámetro por predio |
| Proveedor de imagen satelital (UQQ-007) | `prog_proveedor_imagen` |
| Definición de lote y de ciclo de cultivo (UQQ-001) | `lote`, `prog_ciclo_inicio/fin` |
| Proveedor de identidad (RI-008) | `usua_proveedor`, `usua_sujeto_externo`; `restablecimiento_clave` solo aplica a cuentas locales |
| Fuente de polígonos de predios | `pred_geom` nulo hasta cargarlos |
| Códigos DANE de departamentos y municipios, y cajas de `rango_departamento` | tablas vacías: se cargan desde la fuente DANE |
| Valores de `fenologia`, `fenologia_regla`, `variedad_cultivo`, `producto_fitosanitario`, `plaga_enfermedad`, `severidad`, `criterio_bpa`, `condicion_trampa`, `escenario_trampeo`, `norma`, `permiso` | catálogos sin valores oficiales: los define la institución / el Administrador |
| Vocabulario de `cose_metodo_registro` y `esti_metodo` | texto libre hasta definirlo |
| Unidades admitidas para dosis (RN-017) | `unidad_medida` solo trae kg, ha y mL/L |
| Límites de tamaño de archivo (8 MB imágenes, 10 MB documentos) | `arch_tamano_bytes`; reglas del frontend por confirmar |
| Unidad del área de predio y lote (ha) | `pred_area`, `lote_area`: por confirmar con datos reales |
| Valores de `d_estado_revision` | `pendiente`, `en_revision`, `aceptado` (origen: frontend), por confirmar como regla institucional |
