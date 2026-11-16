-- =====================================================================
-- SIGAT v6 - BORRAR LOS DATOS DE DEMOSTRACIÓN (y cualquier otro dato cargado)
-- Deja intactos los catálogos básicos de 02_catalogos_basicos.sql
-- (estado_registro, rol, tipo_trampa, atrayente, especie_mosca, especie_cultivo, tipo_manejo,
--  categoria_notificacion, unidad_medida) y reinicia los contadores.
-- Las tablas de solo inserción impiden DELETE/TRUNCATE a propósito; este script desactiva
-- esos triggers SOLO dentro de esta transacción y los vuelve a activar antes de terminar.
-- Debe ejecutarlo el dueño del esquema. NUNCA en producción: borra todo el historial.
-- Pide confirmación:  psql -v confirmo=SI -f 05b_borrar_datos_demo.sql
-- =====================================================================
\if :{?confirmo}
\else
  \echo 'Falta la confirmación. Ejecute: psql -v confirmo=SI -f 05b_borrar_datos_demo.sql'
  \quit
\endif
SELECT :'confirmo' = 'SI' AS confirmado \gset
\if :confirmado
BEGIN;
DO $borrar$
DECLARE t text;
  conservar text[] := ARRAY['estado_registro','rol','tipo_trampa','atrayente','especie_mosca','especie_cultivo',
                            'tipo_manejo','categoria_notificacion','unidad_medida'];
BEGIN
  FOR t IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'sigat' AND c.relkind = 'r' AND NOT (c.relname = ANY (conservar)) LOOP
    EXECUTE format('ALTER TABLE sigat.%I DISABLE TRIGGER USER', t);
  END LOOP;
  FOR t IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'sigat' AND c.relkind = 'r' AND NOT (c.relname = ANY (conservar)) LOOP
    EXECUTE format('TRUNCATE sigat.%I RESTART IDENTITY CASCADE', t);
  END LOOP;
  FOR t IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'sigat' AND c.relkind = 'r' AND NOT (c.relname = ANY (conservar)) LOOP
    EXECUTE format('ALTER TABLE sigat.%I ENABLE TRIGGER USER', t);
  END LOOP;
END $borrar$;
COMMIT;
\echo 'Datos borrados; catálogos básicos conservados.'
\else
  \echo 'Confirmación distinta de SI: no se borró nada.'
\endif
