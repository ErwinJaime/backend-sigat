-- =====================================================================
-- SIGAT v6 - VALIDACIÓN DEL ESQUEMA
-- Cada consulta debe devolver 0 filas (la primera, 74 en "tablas").
-- Ejecutar después de 01_esquema_completo.sql: psql -f 06_validacion.sql
-- =====================================================================
SET search_path = sigat, public;

\echo '== 0. Número de tablas del esquema (esperado: 74)'
SELECT count(*) AS tablas FROM pg_tables WHERE schemaname = 'sigat';

\echo '== 1. Tablas sin clave primaria (esperado: 0 filas)'
SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'sigat' AND c.relkind = 'r'
  AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'p');

\echo '== 2. Llaves foráneas sin índice que las respalde (esperado: 0 filas)'
SELECT k.conrelid::regclass AS tabla, k.conname
FROM pg_constraint k
WHERE k.contype = 'f' AND k.connamespace = 'sigat'::regnamespace
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = k.conrelid
      AND (i.indkey::int2[])[0:cardinality(k.conkey) - 1] = k.conkey);

\echo '== 3. Tablas sin comentario (esperado: 0 filas)'
SELECT c.relname FROM pg_class c
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND obj_description(c.oid, 'pg_class') IS NULL;

\echo '== 4. Columnas sin comentario (esperado: 0 filas)'
SELECT c.relname, a.attname FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
  AND col_description(c.oid, a.attnum) IS NULL;

\echo '== 5. Regla del prefijo de 4 letras: columnas cuyo prefijo no es el de ninguna tabla (esperado: 0 filas)'
SELECT c.relname, a.attname
FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
  AND split_part(a.attname, '_', 1) <> ALL (ARRAY[__PREFIJOS__]);

\echo '== 6. Rastros de ICA en nombres de columnas o comentarios (esperado: 0 filas)'
SELECT c.relname, a.attname FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND a.attnum > 0
  AND (a.attname ~* '(^|_)ica(_|$)' OR col_description(c.oid, a.attnum) ~ '\mICA\M')
UNION ALL
SELECT c.relname, '(tabla)' FROM pg_class c
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND obj_description(c.oid, 'pg_class') ~ '\mICA\M';

\echo '== 7. Tablas de solo inserción sin disparador de bloqueo (esperado: 0 filas)'
SELECT t FROM unnest(ARRAY['aplicacion_fitosanitaria','bitacora_auditoria','bpa_verificacion','concepto_aptitud','cosecha',
  'estimacion_produccion','etapa_declarada','evidencia','hallazgo','indice_mtd_lectura','indice_mtd','lectura_trampa',
  'manejo_agronomico','operacion_sync','recepcion_sync','visita_lote']) AS t
WHERE NOT EXISTS (SELECT 1 FROM pg_trigger g WHERE g.tgrelid = ('sigat.' || t)::regclass AND g.tgname = 'trg_' || t || '_ro');

\echo '== 8. Geometrías con índice espacial (esperado: 0 filas sin índice)'
SELECT c.relname, a.attname FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid
WHERE c.relnamespace = 'sigat'::regnamespace AND c.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
  AND format_type(a.atttypid, a.atttypmod) LIKE 'geometry%'
  AND NOT EXISTS (SELECT 1 FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid JOIN pg_am am ON am.oid = ic.relam
                  WHERE i.indrelid = c.oid AND am.amname = 'gist' AND a.attnum = ANY (i.indkey::int2[]));
