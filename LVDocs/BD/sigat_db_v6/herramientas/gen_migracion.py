#!/usr/bin/env python3
"""Genera migracion/*.sql (v5 -> v6) a partir de meta.json.  Uso: gen_migracion.py meta.json outdir"""
import json, sys, os, collections
meta = json.load(open(sys.argv[1])); OUT = sys.argv[2]
T = meta['tables']; colmap = meta['colmap']
def w(path, text):
    p = os.path.join(OUT, path); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w', encoding='utf-8').write(text)
# orden topológico (padres primero) y autorreferencias
dep = collections.defaultdict(set); auto = {}
for a, _, b in meta['refs']:
    ta, tb = a.split('.')[0], b.split('.')[0]
    if ta == tb: auto[ta] = a.split('.')[1].strip('()').strip()
    else: dep[ta].add(tb)
order, seen = [], set()
def visit(t):
    if t in seen: return
    seen.add(t)
    for d in sorted(dep[t]): visit(d)
    order.append(t)
for t in sorted(T): visit(t)
q = lambda s: "'" + s.replace("'", "''") + "'"
vals_cols = ",\n".join(f"  ({q(t)}, {q(o)}, {q(n)})" for t in sorted(colmap) for o, n in colmap[t].items())
vals_ord = ",\n".join(f"  ({i+1}, {q(t)}, {q(auto[t]) if t in auto else 'NULL'})" for i, t in enumerate(order))
n_cols = sum(len(v) for v in colmap.values())

w('migracion/M1_preparar.sql', f"""-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 1 · PREPARAR (no toca los datos)
-- v5 = esquema «sigat» con prefijos de 3 letras e identificadores «ica».  v6 = prefijos de 4 letras, sin «ica».
-- Estrategia (la misma de la migración anterior): el esquema actual se RENOMBRA a sigat_v5 (queda intacto como
-- respaldo), se instala el esquema v6 vacío y se copian los datos tabla por tabla con el mapa de columnas.
-- Este paso: revisa que la base sea v5, crea el esquema auxiliar sigat_migracion y carga el mapa
-- ({n_cols} columnas de {len(order)} tablas) y el orden de copia (padres antes que hijos).
-- Ejecutar con:  psql -v ON_ERROR_STOP=1 -f M1_preparar.sql
-- =====================================================================
\\set ON_ERROR_STOP on
BEGIN;
DO $$
BEGIN
  IF to_regnamespace('sigat') IS NULL THEN RAISE EXCEPTION 'No existe el esquema sigat: no hay nada que migrar'; END IF;
  IF to_regnamespace('sigat_v5') IS NOT NULL THEN RAISE EXCEPTION 'Ya existe sigat_v5: la migración ya se ejecutó (o quedó a medias). Revise antes de seguir'; END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='sigat' AND table_name='administrador' AND column_name='adm_id') THEN
    RAISE EXCEPTION 'El esquema sigat no tiene la forma v5 (falta administrador.adm_id). ¿Ya es v6?';
  END IF;
END $$;
DROP SCHEMA IF EXISTS sigat_migracion CASCADE;
CREATE SCHEMA sigat_migracion;
COMMENT ON SCHEMA sigat_migracion IS 'Auxiliar de la migración v5->v6. Se puede borrar cuando la migración esté aceptada (M5_retirar_legado.sql).';
CREATE TABLE sigat_migracion.mapa_columnas (tabla text NOT NULL, col_v5 text NOT NULL, col_v6 text NOT NULL, PRIMARY KEY (tabla, col_v5));
CREATE TABLE sigat_migracion.orden_tablas  (orden int PRIMARY KEY, tabla text NOT NULL UNIQUE, col_autorreferencia text);
CREATE TABLE sigat_migracion.registro (n serial PRIMARY KEY, paso text NOT NULL, tabla text, filas_v5 bigint, filas_v6 bigint, detalle text, en timestamptz NOT NULL DEFAULT now());
INSERT INTO sigat_migracion.mapa_columnas VALUES
{vals_cols};
INSERT INTO sigat_migracion.orden_tablas VALUES
{vals_ord};
-- Control: el mapa cubre TODAS las columnas de v5 (si falta alguna, se detiene aquí y no después de copiar)
DO $$
DECLARE falt text;
BEGIN
  SELECT string_agg(c.table_name || '.' || c.column_name, ', ') INTO falt
    FROM information_schema.columns c
   WHERE c.table_schema = 'sigat'
     AND c.table_name IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'sigat' AND table_type = 'BASE TABLE')
     AND NOT EXISTS (SELECT 1 FROM sigat_migracion.mapa_columnas m WHERE m.tabla = c.table_name AND m.col_v5 = c.column_name);
  IF falt IS NOT NULL THEN RAISE EXCEPTION 'Columnas de la base que el mapa no conoce (no se migrarían): %', falt; END IF;
END $$;
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M1', 'Preparado: mapa y orden cargados');
COMMIT;
\\echo 'M1 listo. Siguiente: M2_instalar_v6.sql'
""")

w('migracion/M2_instalar_v6.sql', """-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 2 · RENOMBRAR EL ESQUEMA VIEJO E INSTALAR v6 VACÍO
-- Una sola transacción: si algo falla, todo vuelve a como estaba.
-- Instala 01 (tablas, restricciones, índices, triggers base), 03 (vistas) y 04 (funciones y validaciones).
-- NO instala 02 (catálogos básicos): los catálogos se copian de v5 en el paso 3, para conservar sus identificadores.
-- Ejecutar DESDE la carpeta migracion/:   psql -v ON_ERROR_STOP=1 -f M2_instalar_v6.sql
-- =====================================================================
\\set ON_ERROR_STOP on
BEGIN;
ALTER SCHEMA sigat RENAME TO sigat_v5;
\\ir ../sql/01_esquema_completo.sql
\\ir ../sql/03_vistas.sql
\\ir ../sql/04_funciones.sql
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M2', 'sigat renombrado a sigat_v5; esquema v6 instalado vacío');
COMMIT;
\\echo 'M2 listo. Siguiente: M3_copiar_datos.sql'
""")

w('migracion/M3_copiar_datos.sql', """-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 3 · COPIAR LOS DATOS (tabla por tabla, padres primero)
-- Una sola transacción. Para conservar el histórico tal cual (t_sincronizacion, versiones, bitácora) se
-- desactivan SOLO los triggers de usuario de las tablas durante la copia y se reactivan al final;
-- las llaves foráneas, CHECK y EXCLUDE siguen activos: si un dato viejo no cumple una regla v6, la copia
-- se detiene y dice cuál (no se «arregla» ni se descarta nada en silencio).
-- Las columnas generadas (MTD, geometría de ubicación, área del lote, número de trampa) se recalculan solas.
-- Los identificadores se copian tal cual y los contadores se reajustan al máximo.
-- =====================================================================
\\set ON_ERROR_STOP on
BEGIN;
DO $copia$
DECLARE
  t record; ident record; cols_v6 text; cols_v5 text; n5 bigint; n6 bigint;
BEGIN
  FOR t IN SELECT tabla FROM sigat_migracion.orden_tablas LOOP
    EXECUTE format('ALTER TABLE sigat.%I DISABLE TRIGGER USER', t.tabla);
  END LOOP;

  FOR t IN SELECT * FROM sigat_migracion.orden_tablas ORDER BY orden LOOP
    SELECT string_agg(format('%I', m.col_v6), ', ' ORDER BY c.ordinal_position),
           string_agg(format('o.%I', m.col_v5), ', ' ORDER BY c.ordinal_position)
      INTO cols_v6, cols_v5
      FROM sigat_migracion.mapa_columnas m
      JOIN information_schema.columns c
        ON c.table_schema = 'sigat' AND c.table_name = m.tabla AND c.column_name = m.col_v6 AND c.is_generated = 'NEVER'
     WHERE m.tabla = t.tabla
       AND (t.col_autorreferencia IS NULL OR m.col_v6 <> t.col_autorreferencia);
    -- (en una tabla autorreferenciada la columna de referencia se rellena al final, ver más abajo)
    EXECUTE format('INSERT INTO sigat.%I (%s) OVERRIDING SYSTEM VALUE SELECT %s FROM sigat_v5.%I o', t.tabla, cols_v6, cols_v5, t.tabla);
    EXECUTE format('SELECT count(*) FROM sigat_v5.%I', t.tabla) INTO n5;
    EXECUTE format('SELECT count(*) FROM sigat.%I', t.tabla) INTO n6;
    INSERT INTO sigat_migracion.registro (paso, tabla, filas_v5, filas_v6) VALUES ('M3', t.tabla, n5, n6);
    IF n5 <> n6 THEN RAISE EXCEPTION 'Tabla %: v5 tiene % filas y v6 quedó con %', t.tabla, n5, n6; END IF;
  END LOOP;

  -- referencias de las tablas autorreferenciadas (se rellenan después de copiar todas las filas)
  FOR t IN SELECT * FROM sigat_migracion.orden_tablas WHERE col_autorreferencia IS NOT NULL LOOP
    DECLARE pk6 text; ref6 text; pk5 text; ref5 text;
    BEGIN
      ref6 := t.col_autorreferencia;
      SELECT col_v5 INTO ref5 FROM sigat_migracion.mapa_columnas WHERE tabla = t.tabla AND col_v6 = ref6;
      SELECT a.attname INTO pk6 FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[0]
       WHERE i.indrelid = format('sigat.%I', t.tabla)::regclass AND i.indisprimary;
      SELECT col_v5 INTO pk5 FROM sigat_migracion.mapa_columnas WHERE tabla = t.tabla AND col_v6 = pk6;
      EXECUTE format('UPDATE sigat.%1$I n SET %2$I = o.%3$I FROM sigat_v5.%1$I o WHERE o.%4$I = n.%5$I AND o.%3$I IS NOT NULL',
                     t.tabla, ref6, ref5, pk5, pk6);
    END;
  END LOOP;

  -- contadores de las columnas identity
  FOR ident IN SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = 'sigat' AND is_identity = 'YES' LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(%L, %L), GREATEST(coalesce(max(%I), 0), 1), coalesce(max(%I), 0) > 0) FROM sigat.%I',
                   'sigat.' || ident.table_name, ident.column_name, ident.column_name, ident.column_name, ident.table_name);
  END LOOP;

  FOR t IN SELECT tabla FROM sigat_migracion.orden_tablas LOOP
    EXECUTE format('ALTER TABLE sigat.%I ENABLE TRIGGER USER', t.tabla);
  END LOOP;
END $copia$;
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M3', 'Datos copiados y contadores reajustados');
COMMIT;
\\echo 'M3 listo. Siguiente: M4_verificar.sql'
""")

w('migracion/M4_verificar.sql', """-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 4 · VERIFICAR (solo lectura)
-- Para cada tabla compara v5 contra v6 columna por columna (con el mapa): mismas filas y mismos valores.
--   a) conteo igual   b) filas de v5 que NO están en v6 = 0   c) filas de v6 que NO están en v5 = 0
-- Si algo difiere se detiene con el nombre de la tabla. Termina con un resumen por tabla.
-- =====================================================================
\\set ON_ERROR_STOP on
SET search_path = sigat, public;
DO $ver$
DECLARE t record; lst5 text; lst6 text; n5 bigint; n6 bigint; a bigint; b bigint; mal int := 0;
BEGIN
  FOR t IN SELECT * FROM sigat_migracion.orden_tablas ORDER BY orden LOOP
    SELECT string_agg(format('o.%I', m.col_v5), ', ' ORDER BY m.col_v6), string_agg(format('n.%I', m.col_v6), ', ' ORDER BY m.col_v6)
      INTO lst5, lst6 FROM sigat_migracion.mapa_columnas m WHERE m.tabla = t.tabla;
    EXECUTE format('SELECT count(*) FROM sigat_v5.%I', t.tabla) INTO n5;
    EXECUTE format('SELECT count(*) FROM sigat.%I', t.tabla) INTO n6;
    EXECUTE format('SELECT count(*) FROM (SELECT %s FROM sigat_v5.%I o EXCEPT SELECT %s FROM sigat.%I n) x', lst5, t.tabla, lst6, t.tabla) INTO a;
    EXECUTE format('SELECT count(*) FROM (SELECT %s FROM sigat.%I n EXCEPT SELECT %s FROM sigat_v5.%I o) x', lst6, t.tabla, lst5, t.tabla) INTO b;
    INSERT INTO sigat_migracion.registro (paso, tabla, filas_v5, filas_v6, detalle)
      VALUES ('M4', t.tabla, n5, n6, format('solo_en_v5=%s solo_en_v6=%s', a, b));
    IF n5 <> n6 OR a <> 0 OR b <> 0 THEN
      mal := mal + 1;
      RAISE WARNING 'DIFERENCIA en %: filas v5=% v6=% ; solo en v5=% ; solo en v6=%', t.tabla, n5, n6, a, b;
    END IF;
  END LOOP;
  IF mal > 0 THEN RAISE EXCEPTION 'La verificación encontró diferencias en % tabla(s). NO retire sigat_v5.', mal; END IF;
END $ver$;
\\echo '== Resumen por tabla (v5 / v6 / diferencias)'
SELECT tabla, filas_v5, filas_v6, detalle FROM sigat_migracion.registro WHERE paso = 'M4' AND filas_v5 > 0 ORDER BY filas_v5 DESC, tabla;
\\echo '== Reglas de integridad del esquema nuevo (deben salir 0 filas)'
\\ir ../sql/06_validacion.sql
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M4', 'Verificación completa: 0 diferencias');
\\echo 'M4 listo: v5 y v6 contienen exactamente los mismos datos. Siguiente: pruebas de escritorio y, cuando acepte, M5_retirar_legado.sql'
""")

w('migracion/M5_retirar_legado.sql', """-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 5 · RETIRAR EL ESQUEMA VIEJO  (IRREVERSIBLE)
-- Solo después de M4 sin diferencias y de aceptar las pruebas de escritorio. Borra sigat_v5 y sigat_migracion
-- (un resumen de la migración queda como comentario del esquema sigat).
-- Haga una copia de seguridad (pg_dump) ANTES.   Ejecutar:  psql -v confirmo=SI -f M5_retirar_legado.sql
-- =====================================================================
\\set ON_ERROR_STOP on
\\if :{?confirmo}
\\else
  \\echo 'Falta la confirmación: psql -v confirmo=SI -f M5_retirar_legado.sql'
  \\quit
\\endif
SELECT :'confirmo' = 'SI' AS ok \\gset
\\if :ok
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
\\echo 'Esquema viejo retirado. La base queda solo con SIGAT v6.'
\\else
  \\echo 'Confirmación distinta de SI: no se borró nada.'
\\endif
""")

w('migracion/M_revertir_a_v5.sql', """-- =====================================================================
-- REVERSIÓN · volver a v5 (mientras sigat_v5 todavía exista, es decir, antes de M5)
-- Descarta el esquema v6 y vuelve a poner el v5 con su nombre original. Todo lo que se haya escrito en v6
-- DESPUÉS de la migración se pierde (v5 no lo conoce). Por eso pide confirmación explícita.
-- Una sola transacción.   Ejecutar:  psql -v confirmo=SI -f M_revertir_a_v5.sql
-- =====================================================================
\\set ON_ERROR_STOP on
\\if :{?confirmo}
\\else
  \\echo 'Falta la confirmación: psql -v confirmo=SI -f M_revertir_a_v5.sql'
  \\quit
\\endif
SELECT :'confirmo' = 'SI' AS ok \\gset
\\if :ok
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
\\echo 'Revertido: la base vuelve a ser v5 con sus datos originales.'
\\else
  \\echo 'Confirmación distinta de SI: no se revirtió nada.'
\\endif
""")

w('migracion/migrar_todo.sh', """#!/bin/bash
# Ejecuta M1..M4 en orden sobre la base indicada (NO ejecuta M5, que es irreversible).
# Uso:  ./migrar_todo.sh "host=... dbname=... user=..."     (cadena de conexión de psql)
# Haga ANTES una copia:  pg_dump -Fc -f respaldo_v5.dump <base>
set -e
cd "$(dirname "$0")"
CONN="${1:?Indique la cadena de conexión de psql}"
for f in M1_preparar.sql M2_instalar_v6.sql M3_copiar_datos.sql M4_verificar.sql; do
  echo "=== $f"; psql "$CONN" -X -v ON_ERROR_STOP=1 -f "$f"
done
echo "Migración lista y verificada. Revise las pruebas de escritorio; cuando acepte: psql \\"$CONN\\" -v confirmo=SI -f M5_retirar_legado.sql"
""")
os.chmod(os.path.join(OUT, 'migracion/migrar_todo.sh'), 0o755)
print('migración generada:', len(order), 'tablas;', n_cols, 'columnas;', 'autorreferencias:', auto)
