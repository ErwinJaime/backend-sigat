-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 2 · RENOMBRAR EL ESQUEMA VIEJO E INSTALAR v6 VACÍO
-- Una sola transacción: si algo falla, todo vuelve a como estaba.
-- Instala 01 (tablas, restricciones, índices, triggers base), 03 (vistas) y 04 (funciones y validaciones).
-- NO instala 02 (catálogos básicos): los catálogos se copian de v5 en el paso 3, para conservar sus identificadores.
-- Ejecutar DESDE la carpeta migracion/:   psql -v ON_ERROR_STOP=1 -f M2_instalar_v6.sql
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
ALTER SCHEMA sigat RENAME TO sigat_v5;
\ir ../sql/01_esquema_completo.sql
\ir ../sql/03_vistas.sql
\ir ../sql/04_funciones.sql
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M2', 'sigat renombrado a sigat_v5; esquema v6 instalado vacío');
COMMIT;
\echo 'M2 listo. Siguiente: M3_copiar_datos.sql'
