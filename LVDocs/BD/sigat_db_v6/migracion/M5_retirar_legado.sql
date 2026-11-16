-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 5 · RETIRAR EL ESQUEMA VIEJO  (IRREVERSIBLE)
-- Solo después de M4 sin diferencias y de aceptar las pruebas de escritorio. Borra sigat_v5 y sigat_migracion
-- (un resumen de la migración queda como comentario del esquema sigat).
-- Haga una copia de seguridad (pg_dump) ANTES.   Ejecutar:  psql -v confirmo=SI -f M5_retirar_legado.sql
-- =====================================================================
\set ON_ERROR_STOP on
\if :{?confirmo}
\else
  \echo 'Falta la confirmación: psql -v confirmo=SI -f M5_retirar_legado.sql'
  \quit
\endif
SELECT :'confirmo' = 'SI' AS ok \gset
\if :ok
BEGIN;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM sigat_migracion.registro WHERE paso = 'M4' AND detalle LIKE 'Verificación completa%') THEN
    RAISE EXCEPTION 'M4 no terminó sin diferencias: no se retira el esquema viejo';
  END IF;
END $$;
DO $$
BEGIN
  EXECUTE format('COMMENT ON SCHEMA sigat IS %L',
    format('SIGAT v6. Migrado desde v5 el %s; esquema viejo retirado el %s.',
           (SELECT min(en)::date FROM sigat_migracion.registro WHERE paso = 'M1'), now()::date));
END $$;
SET LOCAL client_min_messages = warning;
DROP SCHEMA sigat_v5 CASCADE;
DROP SCHEMA sigat_migracion CASCADE;
COMMIT;
\echo 'Esquema viejo retirado. La base queda solo con SIGAT v6.'
\else
  \echo 'Confirmación distinta de SI: no se borró nada.'
\endif
