-- =====================================================================
-- SIGAT v6 - PRUEBAS DE RESTRICCIONES Y REGLAS AUTOMÁTICAS
-- Necesita: 01_esquema_completo.sql y 02_catalogos_basicos.sql.
-- Todo se ejecuta en una transacción que termina en ROLLBACK (no deja datos).
-- Cada prueba imprime OK o FALLA. Ejecutar: psql -f 07_pruebas_restricciones.sql
-- =====================================================================
\set QUIET on
SET search_path = sigat, public;
BEGIN;
\o /dev/null

-- Datos mínimos para las pruebas ------------------------------------------------
INSERT INTO region (regi_descripcion) VALUES ('Región de prueba');
INSERT INTO departamento (depa_descripcion, regi_id, depa_codigo) SELECT 'Dpto prueba', regi_id, '99' FROM region;
INSERT INTO municipio (muni_descripcion, depa_id, muni_codigo) SELECT 'Muni prueba', depa_id, '001' FROM departamento;
INSERT INTO centro_acopio (cent_descripcion, depa_id) SELECT 'Centro prueba', depa_id FROM departamento;
INSERT INTO persona (pers_cc, pers_nombre, pers_apellido) VALUES (1001, 'Ana', 'Admin'), (1002, 'Tito', 'Tecnico'), (1003, 'Pedro', 'Productor'), (1004, 'Sara', 'Supervisora');
INSERT INTO administrador (pers_cc, cent_id) SELECT 1001, cent_id FROM centro_acopio;
INSERT INTO tecnico (pers_cc, cent_id, admi_id, tecn_fecha_registro, esta_id)
  SELECT 1002, cent_id, (SELECT admi_id FROM administrador), current_date, (SELECT esta_id FROM estado_registro WHERE esta_descripcion = 'activo') FROM centro_acopio;
INSERT INTO productor (pers_cc, prod_fecha_registro, prod_tecnico_registro_id, muni_id)
  SELECT 1003, current_date, (SELECT tecn_id FROM tecnico), muni_id FROM municipio;
INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id)
  SELECT 1002, 'tito', '$argon2id$v=19$m=65536,t=3,p=4$c2FsdHNhbHQ$aGFzaGhhc2g', (SELECT rol_id FROM rol WHERE rol_codigo = 'TECNICO'), (SELECT esta_id FROM estado_registro WHERE esta_descripcion = 'activo');
INSERT INTO predio (pred_codigo, pred_nombre, muni_id, pred_area, pers_cc, pred_fecha_registro, pred_tecnico_registro_id)
  SELECT 'P-001', 'Finca prueba', muni_id, 10, 1003, current_date, (SELECT tecn_id FROM tecnico) FROM municipio;
INSERT INTO lote (lote_codigo, lote_descripcion, lote_area, pred_id, espc_id, lote_fecha_registro, lote_tecnico_registro_id)
  SELECT 'A', 'Lote A', 2, pred_id, (SELECT espc_id FROM especie_cultivo), current_date, (SELECT tecn_id FROM tecnico) FROM predio;
INSERT INTO dispositivo (disp_plataforma) VALUES ('android');
INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
  SELECT disp_id, gen_random_uuid(), (SELECT usua_id FROM usuario), 'cosecha', 'crear', gen_random_uuid(), repeat('a', 64), 'alta_nueva', now() FROM dispositivo;

CREATE TEMP TABLE resultado (n int, prueba text, ok boolean);
GRANT ALL ON resultado TO PUBLIC;

-- Función auxiliar: espera que la sentencia FALLE
CREATE FUNCTION pg_temp.debe_fallar(n int, prueba text, sentencia text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE sentencia;
    INSERT INTO resultado VALUES (n, prueba, false);
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado VALUES (n, prueba, true);
  END;
END $$;
CREATE FUNCTION pg_temp.debe_pasar(n int, prueba text, sentencia text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE sentencia;
    INSERT INTO resultado VALUES (n, prueba, true);
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado VALUES (n, prueba || ' [' || SQLERRM || ']', false);
  END;
END $$;

-- 1-4: restricciones CHECK y llaves ----------------------------------------------
SELECT pg_temp.debe_fallar(1, 'rol: ámbito inválido', $$INSERT INTO rol (rol_descripcion, rol_codigo, rol_ambito) VALUES ('X','XX','otro')$$);
SELECT pg_temp.debe_fallar(2, 'departamento: código DANE debe ser de 2 dígitos', $$INSERT INTO departamento (depa_descripcion, regi_id, depa_codigo) SELECT 'Z', regi_id, 'ABC' FROM region$$);
SELECT pg_temp.debe_fallar(3, 'municipio: no repite código dentro del departamento', $$INSERT INTO municipio (muni_descripcion, depa_id, muni_codigo) SELECT 'Otro', depa_id, '001' FROM departamento WHERE depa_codigo = '99'$$);
SELECT pg_temp.debe_fallar(4, 'persona: la cédula no se repite', $$INSERT INTO persona (pers_cc, pers_nombre, pers_apellido) VALUES (1001, 'X', 'Y')$$);
SELECT pg_temp.debe_fallar(5, 'lote: (predio, código) único', $$INSERT INTO lote (lote_codigo, lote_descripcion, lote_area, pred_id, lote_fecha_registro, lote_tecnico_registro_id) SELECT 'A','otro',1,pred_id,current_date,(SELECT tecn_id FROM tecnico) FROM predio$$);
SELECT pg_temp.debe_fallar(6, 'llave foránea: municipio inexistente en predio', $$INSERT INTO predio (pred_nombre, muni_id, pred_area, pers_cc, pred_fecha_registro, pred_tecnico_registro_id) VALUES ('X', 999999, 1, 1003, current_date, (SELECT tecn_id FROM tecnico))$$);

-- 7-12: registros versionados (cosecha) ------------------------------------------
CREATE TEMP TABLE ctx AS SELECT gen_random_uuid() AS reg, (SELECT lote_id FROM lote) AS lote_id, (SELECT usua_id FROM usuario) AS usua_id,
  (SELECT disp_id FROM dispositivo) AS disp_id, (SELECT unid_id FROM unidad_medida WHERE unid_simbolo = 'kg') AS unid_id;
CREATE FUNCTION pg_temp.cosecha(ver int, tobs timestamptz) RETURNS text LANGUAGE sql AS $$
  SELECT format($f$INSERT INTO cosecha (cose_registro_id, cose_version, lote_id, cose_fecha_esperada, cose_volumen_esperado, cose_volumen_uni_id,
        usua_id, disp_id, oper_id, cose_t_observacion, cose_t_captura)
     SELECT reg, %s, lote_id, current_date, 100, unid_id, usua_id, disp_id,
        (SELECT oper_id FROM operacion_sync WHERE oper_id NOT IN (SELECT oper_id FROM cosecha) ORDER BY oper_id LIMIT 1), %L, now() FROM ctx$f$, ver, tobs)
$$;
INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
  SELECT disp_id, gen_random_uuid(), usua_id, 'cosecha', 'corregir', reg, repeat('b', 64), 'correccion', now() FROM ctx;
INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
  SELECT disp_id, gen_random_uuid(), usua_id, 'cosecha', 'corregir', reg, repeat('c', 64), 'correccion', now() FROM ctx;
SELECT pg_temp.debe_fallar(7, 'cosecha: la primera versión debe ser 1', pg_temp.cosecha(2, '2026-01-01 08:00+00'));
SELECT pg_temp.debe_pasar (8, 'cosecha: versión 1 se inserta', pg_temp.cosecha(1, '2026-01-01 08:00+00'));
SELECT pg_temp.debe_pasar (9, 'cosecha: versión 2 (corrección) se inserta', pg_temp.cosecha(2, '2026-01-01 08:00+00'));
SELECT pg_temp.debe_fallar(10, 'cosecha: t_observacion no puede cambiar entre versiones', pg_temp.cosecha(3, '2026-02-02 08:00+00'));
SELECT pg_temp.debe_fallar(11, 'cosecha: solo inserción (UPDATE bloqueado)', $$UPDATE cosecha SET cose_observaciones = 'x'$$);
SELECT pg_temp.debe_fallar(12, 'cosecha: solo inserción (DELETE bloqueado)', $$DELETE FROM cosecha$$);
SELECT pg_temp.debe_fallar(13, 'cosecha: solo inserción (TRUNCATE bloqueado)', $$TRUNCATE cosecha$$);
INSERT INTO resultado
  SELECT 14, 't_sincronizacion la fija el servidor (no el cliente)', bool_and(cose_t_sincronizacion >= now() - interval '1 minute') FROM cosecha;

-- 15-17: auditoría ------------------------------------------------------------------
INSERT INTO resultado SELECT 15, 'auditoría: el alta de persona queda en la bitácora', count(*) >= 4 FROM bitacora_auditoria WHERE bita_tabla = 'persona' AND bita_accion = 'INSERT';
INSERT INTO resultado SELECT 16, 'auditoría: nunca guarda la contraseña', count(*) = 0 FROM bitacora_auditoria WHERE bita_detalle::text LIKE '%c2FsdHNhbHQ%';
SELECT pg_temp.debe_fallar(17, 'bitácora: no se modifica', $$UPDATE bitacora_auditoria SET bita_tabla = 'x'$$);

-- 18-20: columnas generadas y no solapamiento ------------------------------------
SELECT pg_temp.debe_fallar(19, 'lote_geometria: dos versiones vigentes a la vez se rechazan', $$
  INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde)
  SELECT lote_id, 1, ST_Multi(ST_GeomFromText('POLYGON((-72 7,-72 7.01,-71.99 7.01,-71.99 7,-72 7))', 4326)), '2026-01-01' FROM lote;
  INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde)
  SELECT lote_id, 2, ST_Multi(ST_GeomFromText('POLYGON((-72 7,-72 7.01,-71.99 7.01,-71.99 7,-72 7))', 4326)), '2026-02-01' FROM lote$$);
INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde, lotg_vigente_hasta)
  SELECT lote_id, 1, ST_Multi(ST_GeomFromText('POLYGON((-72 7,-72 7.01,-71.99 7.01,-71.99 7,-72 7))', 4326)), '2026-01-01', '2026-02-01' FROM lote;
INSERT INTO resultado SELECT 20, 'lote_geometria: el área en m² se calcula sola', lotg_area_m2 > 1000000 FROM lote_geometria;

-- 21-24: trampas y ubicaciones ---------------------------------------------------------
INSERT INTO trampa (tram_codigo, tipt_id, atra_id, esta_id, tram_fecha_registro, tram_tecnico_registro_id)
  SELECT '54125-602-1', (SELECT tipt_id FROM tipo_trampa WHERE tipt_descripcion = 'Jackson'), (SELECT atra_id FROM atrayente WHERE atra_descripcion = 'Plug'),
         (SELECT esta_id FROM estado_registro WHERE esta_descripcion = 'activo'), current_date, (SELECT tecn_id FROM tecnico);
INSERT INTO vigilancia (vigi_descripcion) VALUES ('Vigilancia de prueba');
INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, ubic_fecha_fin, tecn_id, vigi_id, ubic_long, ubic_lat)
  SELECT tram_id, (SELECT pred_id FROM predio), (SELECT lote_id FROM lote), '2026-01-01', '2026-03-01', (SELECT tecn_id FROM tecnico), (SELECT vigi_id FROM vigilancia), -71.995, 7.005 FROM trampa;
INSERT INTO resultado SELECT 21, 'ubicacion_trampa: el punto se calcula de long/lat', ST_X(ubic_geom)::numeric = ubic_long FROM ubicacion_trampa;
SELECT pg_temp.debe_fallar(22, 'ubicacion_trampa: una trampa no puede estar en dos sitios a la vez', $$
  INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ubic_long, ubic_lat)
  SELECT tram_id, (SELECT pred_id FROM predio), (SELECT lote_id FROM lote), '2026-02-01', (SELECT tecn_id FROM tecnico), (SELECT vigi_id FROM vigilancia), -71.995, 7.005 FROM trampa$$);
SELECT pg_temp.debe_fallar(23, 'ubicacion_trampa: el lote debe ser del predio indicado', $$
  INSERT INTO predio (pred_codigo, pred_nombre, muni_id, pred_area, pers_cc, pred_fecha_registro, pred_tecnico_registro_id)
  SELECT 'P-002','Otra',muni_id,1,1003,current_date,(SELECT tecn_id FROM tecnico) FROM municipio;
  INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ubic_long, ubic_lat)
  SELECT tram_id, (SELECT pred_id FROM predio WHERE pred_codigo = 'P-002'), (SELECT lote_id FROM lote), '2026-04-01', (SELECT tecn_id FROM tecnico), (SELECT vigi_id FROM vigilancia), -71.995, 7.005 FROM trampa$$);

SELECT pg_temp.debe_fallar(31, 'trampa: Jackson con número par se rechaza (RN-005)', $$INSERT INTO trampa (tram_codigo, tipt_id, atra_id, esta_id, tram_fecha_registro, tram_tecnico_registro_id)
  SELECT '54125-602-2', (SELECT tipt_id FROM tipo_trampa WHERE tipt_descripcion = 'Jackson'), (SELECT atra_id FROM atrayente LIMIT 1), (SELECT esta_id FROM estado_registro LIMIT 1), current_date, (SELECT tecn_id FROM tecnico)$$);
INSERT INTO resultado SELECT 32, 'trampa: el número se extrae del código', tram_numero = 1 FROM trampa;
-- 24-26: visita y lectura --------------------------------------------------------------------
INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
  SELECT disp_id, gen_random_uuid(), usua_id, 'visita', 'crear', gen_random_uuid(), repeat('d', 64), 'alta_nueva', now() FROM ctx;
INSERT INTO visita (disp_id, oper_id, usua_id, pred_id, visi_t_inicio_obs, visi_t_fin_obs, visi_t_captura)
  SELECT disp_id, (SELECT max(oper_id) FROM operacion_sync), usua_id, (SELECT pred_id FROM predio WHERE pred_codigo = 'P-001'), now() - interval '1 hour', now(), now() FROM ctx;
INSERT INTO resultado SELECT 24, 'visita: nace pendiente de revisión', visi_estado_revision = 'pendiente' FROM visita;
SELECT pg_temp.debe_pasar (25, 'visita: el supervisor puede cambiar la revisión', $$UPDATE visita SET visi_estado_revision = 'en_revision', visi_revisada_por = (SELECT usua_id FROM usuario), visi_revisada_en = now()$$);
SELECT pg_temp.debe_fallar(26, 'visita: no se puede cambiar el predio', $$UPDATE visita SET pred_id = pred_id + 1$$);
SELECT pg_temp.debe_fallar(27, 'visita: no se borra', $$DELETE FROM visita$$);

-- 28-30: MTD y estado de datos ------------------------------------------------------------------
INSERT INTO resultado SELECT 28, 'catálogo de roles: 4 roles', count(*) = 4 FROM rol;
INSERT INTO resultado SELECT 29, 'especie_mosca: sin columnas ICA', count(*) = 0 FROM information_schema.columns WHERE table_schema = 'sigat' AND column_name LIKE '%\_ica';
SELECT pg_temp.debe_fallar(30, 'lectura_trampa: sin ubicación/condición no se inserta (condición obligatoria)', $$INSERT INTO lectura_trampa (visi_id, tram_id, lect_leida) SELECT visi_id, (SELECT tram_id FROM trampa), true FROM visita$$);

\o
\echo '== RESULTADO DE LAS PRUEBAS'
SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALLA' END AS estado, prueba FROM resultado ORDER BY n;
SELECT count(*) FILTER (WHERE ok) AS ok, count(*) FILTER (WHERE NOT ok) AS fallas FROM resultado;
ROLLBACK;
