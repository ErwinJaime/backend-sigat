-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 4 · VERIFICAR (solo lectura)
-- Para cada tabla compara v5 contra v6 columna por columna (con el mapa): mismas filas y mismos valores.
--   a) conteo igual   b) filas de v5 que NO están en v6 = 0   c) filas de v6 que NO están en v5 = 0
-- Si algo difiere se detiene con el nombre de la tabla. Termina con un resumen por tabla.
-- =====================================================================
\set ON_ERROR_STOP on
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
\echo '== Resumen por tabla (v5 / v6 / diferencias)'
SELECT tabla, filas_v5, filas_v6, detalle FROM sigat_migracion.registro WHERE paso = 'M4' AND filas_v5 > 0 ORDER BY filas_v5 DESC, tabla;
\echo '== Reglas de integridad del esquema nuevo (deben salir 0 filas)'
\ir ../sql/06_validacion.sql
INSERT INTO sigat_migracion.registro (paso, detalle) VALUES ('M4', 'Verificación completa: 0 diferencias');
\echo 'M4 listo: v5 y v6 contienen exactamente los mismos datos. Siguiente: pruebas de escritorio y, cuando acepte, M5_retirar_legado.sql'
