# SIGAT v6 · Base de datos completa — paquete para revisión

> Todo se instaló y probó en una base desechable (PostgreSQL 16.15 + PostGIS 3.4). **Nada se ha ejecutado en su base real.**

## Qué cambió respecto a v5
- **Prefijo de 4 letras:** cada columna empieza con las primeras 4 letras de su tabla (`lote_`, `pred_`, `usua_`…). Las llaves foráneas llevan el prefijo de la tabla a la que apuntan. Colisiones y excepciones: `docs/07_prefijos.md`.
- **Sin ICA:** sin menciones en notas y comentarios, y sin el sufijo `_ica` en columnas (`espm_codigo`, `feno_codigo`, `loca_codigo`, `vigi_codigo`, `tecn_codigo`, `tram_codigo`, `prof_registro`).
- Se corrigieron notas copiadas por error en las columnas `*_tecnico_registro_id` y `ruta_admin_registro_id`.

## Qué contiene
| Carpeta / archivo | Contenido |
|---|---|
| `sql/00_instalar_todo.sql` | Instala todo en una orden (`-v demo=SI` agrega la demostración). Alternativa sin `\ir`: `sql/sigat_bd_completa.sql` |
| `sql/01_esquema_completo.sql` | 74 tablas, 164 llaves foráneas, 182 reglas CHECK, 5 restricciones de no-solapamiento, 4 dominios, 299 índices, funciones base, disparadores y comentarios en todas las tablas y columnas |
| `sql/02_catalogos_basicos.sql` | Solo valores que la documentación define (4 roles, estados, Jackson/McPhail, atrayentes, especies de mosca, durazno, tipos de manejo, categorías de aviso, unidades) |
| `sql/03_vistas.sql` | **21 vistas** (`v_*_vigente`, `v_*_app`, informes de validación) |
| `sql/04_funciones.sql` | **22 funciones y 13 disparadores de validación**: quién ve qué (`fn_lotes_visibles`, `fn_*_app`), cálculos (`fn_etapa_derivada`, `fn_lote_que_contiene`, `fn_mtd_lectura_valida`) y reglas de planificación, lectura, ubicación, periodo, programa, concepto, geometría, retícula, archivos y avisos |
| `sql/05_datos_demo.sql` · `05b_borrar_datos_demo.sql` | Datos ficticios para capacitación y pruebas, y el script que los borra dejando solo los catálogos |
| `sql/06_validacion.sql` | 8 consultas de validación (deben dar 0 filas) |
| `sql/07_pruebas_restricciones.sql` | 31 pruebas automáticas en una transacción con ROLLBACK (**base sin datos**: no usar con la demo cargada) |
| `migracion/` | **Migración v5 → v6** (M1–M5, reversión y `migrar_todo.sh`) — ver `migracion/LEEME_migracion.md` |
| `pruebas_escritorio/` | **49 escenarios** paso a paso (`PE_escenarios.md`), su versión ejecutable (`PE_ejecutable.sql`) y la prueba de escritorio de la migración (`PE_migracion.md`) |
| `diagramas/` | `sigat.dbml` (para https://dbdiagram.io/d), DBML por área (9) y diagramas ER (`.dot`, `.svg`, `.png`) |
| `docs/` | Diccionario de datos, matriz de relaciones, matriz de índices, prefijos, pendientes institucionales |
| `herramientas/` | Scripts y fuentes para regenerar todo el paquete |

La explicación narrativa de cada tabla está en el documento «SIGAT v6 · Explicación de cada tabla» (Docs): https://claude.ai/artifact/LmPzd4KzyQ8kKD2PZh7Xvq

## Cómo instalar (base NUEVA o de pruebas)
Requisitos: PostgreSQL 16, PostGIS ≥ 3.3 y `btree_gist`; un rol que pueda hacer `CREATE EXTENSION`.
```bash
cd sql
psql -X -v ON_ERROR_STOP=1 -f 00_instalar_todo.sql               # sin datos
psql -X -v ON_ERROR_STOP=1 -v demo=SI -f 00_instalar_todo.sql    # con demostración
```
Para correr las pruebas: `sql/07_pruebas_restricciones.sql` (en una base **sin** datos) y `pruebas_escritorio/ejecutar_pruebas_escritorio.sh "<conexión>"` (instala la demo y corre los 49 escenarios; use una base de prueba).

## Resultados de verificación (en la base desechable)
- Instalación limpia sin errores: 74 tablas, 21 vistas, 30 funciones, 84 disparadores, 299 índices.
- `06_validacion.sql`: 0 filas en todas las consultas.
- `07_pruebas_restricciones.sql`: 31/31 OK (base sin datos).
- `pruebas_escritorio/PE_ejecutable.sql`: **52/52 OK** (49 escenarios; 3 tienen dos pasos).
- Demo + borrado: se carga sin errores; `05b` deja solo los catálogos y reactiva los disparadores.
- Migración v5→v6: ver `migracion/LEEME_migracion.md` (probada sobre una **réplica** de v5, no sobre una base v5 real).

## Límites que conviene conocer
- Las **vistas y funciones se reescribieron** a partir de la descripción del documento v5 (no del SQL original de v5, que no se tenía). Las reglas están probadas con los escenarios de arriba, pero conviene revisarlas contra lo que usted espera de cada una.
- `fn_planificacion_valida` exige que el actor de la sesión sea el destinatario: la capa de aplicación debe fijar `SET LOCAL sigat.usuario_actual = '<usua_id>'` en cada transacción.
- Las llaves foráneas usan la acción predeterminada (NO ACTION); las acciones `ON DELETE/ON UPDATE` de v5 no se trasladaron.
- Tres reglas CHECK largas del documento v5 venían cortadas y se escribieron a partir de las notas (`lote_fechas_validas`, `archivo_adjunto_estado_coherente`, `archivo_adjunto_mime_valido`); otras cuatro se reconstruyeron desde el paquete anterior. Conviene revisarlas.
- No incluye el modelo local SQLite, el informe de normalización ni la importación del MF_UBI del paquete anterior.
- Sigue pendiente lo que la institución debe definir (umbral oficial, normas, catálogos sin valores oficiales): `docs/09_pendientes_institucionales.md`.
