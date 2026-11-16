-- =====================================================================
-- REVERSIÓN · volver a v5 (mientras sigat_v5 todavía exista, es decir, antes de M5)
-- Descarta el esquema v6 y vuelve a poner el v5 con su nombre original. Todo lo que se haya escrito en v6
-- DESPUÉS de la migración se pierde (v5 no lo conoce). Por eso pide confirmación explícita.
-- Una sola transacción.   Ejecutar:  psql -v confirmo=SI -f M_revertir_a_v5.sql
-- =====================================================================
\set ON_ERROR_STOP on
\if :{?confirmo}
\else
  \echo 'Falta la confirmación: psql -v confirmo=SI -f M_revertir_a_v5.sql'
  \quit
\endif
SELECT :'confirmo' = 'SI' AS ok \gset
\if :ok
BEGIN;
DO $$
BEGIN
  IF to_regnamespace('sigat_v5') IS NULL THEN RAISE EXCEPTION 'No existe sigat_v5 (¿ya se ejecutó M5?). No hay a qué volver: restaure la copia de seguridad'; END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='sigat_v5' AND table_name='administrador' AND column_name='adm_id') THEN
    RAISE EXCEPTION 'sigat_v5 no tiene la forma v5';
  END IF;
END $$;
SET LOCAL client_min_messages = warning;
DROP SCHEMA IF EXISTS sigat CASCADE;
ALTER SCHEMA sigat_v5 RENAME TO sigat;
DROP SCHEMA IF EXISTS sigat_migracion CASCADE;
COMMIT;
\echo 'Revertido: la base vuelve a ser v5 con sus datos originales.'
\else
  \echo 'Confirmación distinta de SI: no se revirtió nada.'
\endif
