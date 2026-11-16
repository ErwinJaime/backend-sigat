-- =====================================================================
-- MIGRACIÓN v5 -> v6 · PASO 3 · COPIAR LOS DATOS (tabla por tabla, padres primero)
-- Una sola transacción. Para conservar el histórico tal cual (t_sincronizacion, versiones, bitácora) se
-- desactivan SOLO los triggers de usuario de las tablas durante la copia y se reactivan al final;
-- las llaves foráneas, CHECK y EXCLUDE siguen activos: si un dato viejo no cumple una regla v6, la copia
-- se detiene y dice cuál (no se «arregla» ni se descarta nada en silencio).
-- Las columnas generadas (MTD, geometría de ubicación, área del lote, número de trampa) se recalculan solas.
-- Los identificadores se copian tal cual y los contadores se reajustan al máximo.
-- =====================================================================
\set ON_ERROR_STOP on
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
\echo 'M3 listo. Siguiente: M4_verificar.sql'
