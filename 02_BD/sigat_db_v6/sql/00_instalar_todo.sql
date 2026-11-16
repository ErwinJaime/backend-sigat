-- =====================================================================
-- SIGAT v6 - INSTALACIÓN COMPLETA EN UNA SOLA ORDEN (base nueva o de pruebas)
--   psql -X -v ON_ERROR_STOP=1 -f 00_instalar_todo.sql                 # esquema + catálogos + vistas + funciones + validación
--   psql -X -v ON_ERROR_STOP=1 -v demo=SI -f 00_instalar_todo.sql      # lo anterior + datos de demostración
-- Ejecutar DESDE la carpeta sql/ (usa \ir). Para borrar la demo: 05b_borrar_datos_demo.sql.
-- Alternativa sin \ir: sigat_bd_completa.sql (los mismos 4 archivos en uno solo).
-- =====================================================================
\set ON_ERROR_STOP on
\ir 01_esquema_completo.sql
\ir 02_catalogos_basicos.sql
\ir 03_vistas.sql
\ir 04_funciones.sql
\ir 06_validacion.sql
\if :{?demo}
SELECT (:'demo' = 'SI') AS cargar_demo \gset
\else
SELECT false AS cargar_demo \gset
\endif
\if :cargar_demo
\ir 05_datos_demo.sql
\echo 'Datos de demostración cargados.'
\endif
\echo 'SIGAT v6 instalado.'
