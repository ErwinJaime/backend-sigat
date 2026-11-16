-- =====================================================================
-- SIGAT v6 - PRUEBAS DE ESCRITORIO EJECUTABLES (49 escenarios)
-- Necesita: 01, 02, 03, 04 y 05_datos_demo.sql ya cargados. Todo corre en una transacción que termina en ROLLBACK.
-- Cada escenario dice qué se espera y qué se obtuvo; el documento PE_escenarios.md explica cada uno paso a paso.
-- Ejecutar:  psql -X -f PE_ejecutable.sql      (o ./ejecutar_pruebas_escritorio.sh)
-- =====================================================================
\set QUIET on
SET search_path = sigat, public;
BEGIN;
\o /dev/null
CREATE TEMP TABLE pe_resultado (n serial, id text, titulo text, esperado text, obtenido text, ok boolean);

CREATE FUNCTION pg_temp.pe_actor(a text) RETURNS void LANGUAGE sql AS
$$ SELECT set_config('sigat.usuario_actual', COALESCE((SELECT usua_id::text FROM sigat.usuario WHERE usua_usuario = a), ''), true) $$;

-- Escenario que debe FALLAR (con un SQLSTATE o un fragmento del mensaje)
CREATE FUNCTION pg_temp.pe_falla(i text, t text, actor text, sentencia text, esperado text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.pe_actor(actor);
  EXECUTE sentencia;
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok) VALUES (i, t, 'falla: ' || esperado, 'NO falló', false);
EXCEPTION WHEN OTHERS THEN
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok)
  VALUES (i, t, 'falla: ' || esperado, SQLSTATE || ' ' || left(SQLERRM, 110),
          CASE WHEN esperado LIKE 'SQLSTATE:%' THEN SQLSTATE = substr(esperado, 10) ELSE SQLERRM ILIKE '%' || esperado || '%' END);
END $$;

-- Escenario que debe PASAR
CREATE FUNCTION pg_temp.pe_pasa(i text, t text, actor text, sentencia text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.pe_actor(actor);
  EXECUTE sentencia;
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok) VALUES (i, t, 'se acepta', 'se aceptó', true);
EXCEPTION WHEN OTHERS THEN
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok) VALUES (i, t, 'se acepta', 'ERROR ' || left(SQLERRM, 110), false);
END $$;

-- Escenario cuyo resultado es un valor
CREATE FUNCTION pg_temp.pe_valor(i text, t text, consulta text, esperado text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v text;
BEGIN
  EXECUTE consulta INTO v;
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok) VALUES (i, t, esperado, COALESCE(v, '(nulo)'), v IS NOT DISTINCT FROM esperado);
EXCEPTION WHEN OTHERS THEN
  INSERT INTO pe_resultado (id, titulo, esperado, obtenido, ok) VALUES (i, t, esperado, 'ERROR ' || left(SQLERRM, 110), false);
END $$;

-- Genera el SQL de una nueva versión de la lectura de la trampa 3 (copia de la versión 2 con cambios)
CREATE FUNCTION pg_temp.sql_lectura(ver int, tobs timestamptz, tram int, ubic bigint) RETURNS text LANGUAGE sql AS $body$
SELECT format($f$DO $x$ DECLARE r lectura_trampa; op bigint; BEGIN
  SELECT * INTO r FROM lectura_trampa WHERE lect_version = 2;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (r.disp_id, gen_random_uuid(), r.usua_id, 'lectura_trampa', 'corregir', r.lect_registro_id, md5(random()::text) || md5(random()::text), 'correccion', now()) RETURNING oper_id INTO op;
  r.lect_id := gen_random_uuid(); r.lect_version := %s; r.oper_id := op;
  IF %L::timestamptz IS NOT NULL THEN r.lect_t_observacion := %L::timestamptz; END IF;
  IF %L::int IS NOT NULL THEN r.tram_id := %L::int; END IF;
  IF %L::bigint IS NOT NULL THEN r.ubic_id := %L::bigint; END IF;
  INSERT INTO lectura_trampa SELECT r.*; END $x$$f$, ver, tobs, tobs, tram, tram, ubic, ubic)
$body$;


SELECT pg_temp.pe_valor('PE-01', $q$El técnico Andrés ve solo los lotes que le asignaron$q$, $q$(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')) v JOIN lote l USING (lote_id))$q$, $q${A,C}$q$);
SELECT pg_temp.pe_valor('PE-02', $q$El técnico Juan ve solo B y D (no ve los lotes de Andrés)$q$, $q$(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'juan.tec')) v JOIN lote l USING (lote_id))$q$, $q${B,D}$q$);
SELECT pg_temp.pe_valor('PE-03', $q$El productor Pedro ve los lotes de su predio (A,B,C,D) pero no el E de Marta$q$, $q$(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'pedro.prod')) v JOIN lote l USING (lote_id))$q$, $q${A,B,C,D}$q$);
SELECT pg_temp.pe_valor('PE-04', $q$La productora Marta ve solo su lote E$q$, $q$(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'marta.prod')) v JOIN lote l USING (lote_id))$q$, $q${E}$q$);
SELECT pg_temp.pe_valor('PE-05', $q$El administrador ve todos los lotes$q$, $q$(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'ana.admin')) v JOIN lote l USING (lote_id))$q$, $q${A,B,C,D,E}$q$);
SELECT pg_temp.pe_valor('PE-06', $q$Andrés recibe en su teléfono las 3 trampas del lote A; Juan no recibe ninguna$q$, $q$SELECT (SELECT count(*) FROM fn_trampa_app((SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')))::text || '-' || (SELECT count(*) FROM fn_trampa_app((SELECT usua_id FROM usuario WHERE usua_usuario = 'juan.tec')))::text$q$, $q$3-0$q$);
SELECT pg_temp.pe_falla('PE-07', $q$Un técnico no puede crear planificaciones$q$, 'andres.tec', $q$INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio) VALUES ((SELECT usua_id FROM usuario WHERE usua_usuario = 'juan.tec'), (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec'), 'Actividad de prueba', '2026-10-01')$q$, $q$Solo un Agrónomo/Supervisor crea$q$);
SELECT pg_temp.pe_falla('PE-08', $q$El destinatario no puede ser Administrador$q$, 'sara.super', $q$INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio) VALUES ((SELECT usua_id FROM usuario WHERE usua_usuario = 'ana.admin'), (SELECT usua_id FROM usuario WHERE usua_usuario = 'sara.super'), 'Actividad de prueba', '2026-10-01')$q$, $q$destinatario debe ser$q$);
SELECT pg_temp.pe_falla('PE-09', $q$No se pueden asignar lotes de un predio al que el destinatario no tiene acceso$q$, 'sara.super', $q$DO $x$ DECLARE p uuid; BEGIN INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio) VALUES ((SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec'), (SELECT usua_id FROM usuario WHERE usua_usuario = 'sara.super'), 'Actividad de prueba', '2026-10-01') RETURNING plan_id INTO p; INSERT INTO planificacion_lote VALUES (p, (SELECT lote_id FROM lote WHERE lote_codigo = 'E' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-2'))); END $x$$q$, $q$no tiene acceso al predio$q$);
SELECT pg_temp.pe_falla('PE-10', $q$El técnico no puede rechazar (solo completar)$q$, 'andres.tec', $q$UPDATE planificacion SET plan_estado = 'rechazada', plan_motivo_rechazo = 'No puedo' WHERE usua_id_destinatario = (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')$q$, $q$no permitida para el rol$q$);
SELECT pg_temp.pe_falla('PE-11', $q$Solo el destinatario responde: Sara no puede completar la planificación de Juan$q$, 'sara.super', $q$UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = (SELECT usua_id FROM usuario WHERE usua_usuario = 'juan.tec')$q$, $q$Solo el destinatario responde$q$);
SELECT pg_temp.pe_pasa('PE-12', $q$Andrés completa su planificación$q$, 'andres.tec', $q$UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')$q$);
SELECT pg_temp.pe_valor('PE-13', $q$Al completarse, los lotes dejan de estar vigentes para el técnico (queda el historial)$q$, $q$SELECT COALESCE((SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles((SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')) v JOIN lote l USING (lote_id)), '{}')$q$, $q${}$q$);
SELECT pg_temp.pe_pasa('PE-14', $q$Pedro (productor) completa la planificación que ya había aceptado$q$, 'pedro.prod', $q$UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = (SELECT usua_id FROM usuario WHERE usua_usuario = 'pedro.prod')$q$);
SELECT pg_temp.pe_falla('PE-15', $q$Una planificación completada no admite más lotes$q$, 'sara.super', $q$INSERT INTO planificacion_lote SELECT plan_id, (SELECT lote_id FROM lote WHERE lote_codigo = 'C' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')) FROM planificacion WHERE usua_id_destinatario = (SELECT usua_id FROM usuario WHERE usua_usuario = 'pedro.prod')$q$, $q$congelados$q$);
SELECT pg_temp.pe_valor('PE-16', $q$La corrección de una lectura reemplaza a la original (vigente = versión 2)$q$, $q$SELECT string_agg(lect_especimenes::text, ',' ORDER BY tram_id) FROM v_lectura_vigente$q$, $q$2,0,5$q$);
DO $do$ BEGIN PERFORM pg_temp.pe_falla('PE-17', $q$No se puede saltar una versión (de la 2 a la 4)$q$, 'andres.tec', (SELECT * FROM (SELECT pg_temp.sql_lectura(4, NULL, NULL, NULL)) z), $q$inválida$q$); END $do$;
DO $do$ BEGIN PERFORM pg_temp.pe_falla('PE-18', $q$La hora observada no puede cambiar entre versiones$q$, 'andres.tec', (SELECT * FROM (SELECT pg_temp.sql_lectura(3, '2026-09-09 08:00-05'::timestamptz, NULL, NULL)) z), $q$inmutable$q$); END $do$;
DO $do$ BEGIN PERFORM pg_temp.pe_falla('PE-19', $q$Una corrección no puede mover la lectura a otra trampa/ubicación$q$, 'andres.tec', (SELECT * FROM (SELECT pg_temp.sql_lectura(3, NULL, (SELECT tram_id FROM trampa WHERE tram_codigo = '54518-602-2'), NULL)) z), $q$no es de la trampa$q$); END $do$;
SELECT pg_temp.pe_falla('PE-20', $q$Las lecturas no se modifican (solo inserción)$q$, 'andres.tec', $q$UPDATE lectura_trampa SET lect_especimenes = 99$q$, $q$solo inserción$q$);
SELECT pg_temp.pe_falla('PE-21', $q$No se puede leer una trampa en una fecha en que la ubicación aún no existía$q$, 'andres.tec', $q$DO $x$ DECLARE r lectura_trampa; op bigint; vid uuid; BEGIN
  SELECT * INTO r FROM lectura_trampa WHERE lect_version = 1 AND tram_id = (SELECT tram_id FROM trampa WHERE tram_codigo = '54518-602-1');
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (r.disp_id, gen_random_uuid(), r.usua_id, 'visita', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  INSERT INTO visita (disp_id, oper_id, usua_id, pred_id, ruta_id, visi_t_inicio_obs, visi_t_fin_obs, visi_t_captura)
    SELECT r.disp_id, op, r.usua_id, pred_id, ruta_id, '2026-01-15 08:00-05', '2026-01-15 09:00-05', '2026-01-15 20:00-05' FROM visita WHERE visi_id = r.visi_id RETURNING visi_id INTO vid;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (r.disp_id, gen_random_uuid(), r.usua_id, 'lectura_trampa', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  r.lect_id := gen_random_uuid(); r.lect_registro_id := gen_random_uuid(); r.lect_version := 1; r.visi_id := vid; r.oper_id := op;
  r.lect_t_observacion := '2026-01-15 08:30-05'; r.lect_t_captura := '2026-01-15 20:00-05';
  INSERT INTO lectura_trampa SELECT r.*; END $x$$q$, $q$no estaba vigente$q$);
SELECT pg_temp.pe_valor('PE-22', $q$MTD calculado a mano = moscas / (trampas × días)$q$, $q$SELECT round(indi_valor, 4)::text FROM indice_mtd$q$, $q$0.3333$q$);
SELECT pg_temp.pe_valor('PE-23', $q$Solo las lecturas oficiales, leídas y vigentes del lote y del periodo alimentan el MTD$q$, $q$SELECT count(*)::text FROM fn_mtd_lectura_valida((SELECT peri_id FROM periodo_trampeo))$q$, $q$3$q$);
SELECT pg_temp.pe_valor('PE-24', $q$Sin umbral oficial el concepto queda «no_emitido»$q$, $q$SELECT conc_resultado FROM v_concepto_vigente$q$, $q$no_emitido$q$);
SELECT pg_temp.pe_falla('PE-25', $q$No se puede emitir «apto» sin umbral configurado$q$, 'sara.super', $q$DO $x$ DECLARE n int; BEGIN INSERT INTO norma (norm_codigo, norm_titulo, norm_emisor) VALUES ('N-DEMO', 'Norma de prueba', 'Institución') RETURNING norm_id INTO n; INSERT INTO concepto_aptitud (lote_id, peri_id, indi_id, conc_version, conc_resultado, conc_fecha_efecto, norm_id, conc_motivo) SELECT lote_id, peri_id, indi_id, 2, 'apto', '2026-09-20', n, 'prueba' FROM concepto_aptitud LIMIT 1; END $x$$q$, $q$sin umbral$q$);
SELECT pg_temp.pe_valor('PE-26', $q$La etapa fenológica se deriva de la fecha de plantación y la regla vigente$q$, $q$SELECT feno_descripcion FROM fenologia WHERE feno_id = fn_etapa_derivada((SELECT lote_id FROM lote WHERE lote_codigo = 'A' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')), '2026-09-10')$q$, $q$Cuajado$q$);
SELECT pg_temp.pe_valor('PE-27', $q$Se detecta la discrepancia entre lo que declara el productor y lo que observa el técnico$q$, $q$SELECT count(*)::text || ' ' || (SELECT feno_descripcion FROM fenologia WHERE feno_id = d.feno_declarada) || ' vs ' || (SELECT feno_descripcion FROM fenologia WHERE feno_id = d.feno_observada) FROM v_etapa_discrepancia d GROUP BY d.feno_declarada, d.feno_observada$q$, $q$1 Cuajado vs Floración$q$);
SELECT pg_temp.pe_falla('PE-28', $q$La paridad del número de trampa depende del tipo (Jackson impar)$q$, 'andres.tec', $q$INSERT INTO trampa (tram_codigo, tipt_id, atra_id, esta_id, tram_fecha_registro, tram_tecnico_registro_id) SELECT '54518-602-4', (SELECT tipt_id FROM tipo_trampa WHERE tipt_descripcion = 'Jackson'), (SELECT atra_id FROM atrayente LIMIT 1), (SELECT esta_id FROM estado_registro LIMIT 1), current_date, (SELECT tecn_id FROM tecnico LIMIT 1)$q$, $q$paridad$q$);
SELECT pg_temp.pe_falla('PE-29', $q$Las coordenadas deben caer dentro del rango del departamento$q$, 'andres.tec', $q$INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ubic_long, ubic_lat) SELECT (SELECT tram_id FROM trampa WHERE tram_codigo = '54518-602-1'), (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1'), (SELECT lote_id FROM lote WHERE lote_codigo = 'A' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')), '2026-03-01', (SELECT tecn_id FROM tecnico LIMIT 1), (SELECT vigi_id FROM vigilancia LIMIT 1), -80.0, 7.37$q$, $q$fuera del rango$q$);
SELECT pg_temp.pe_falla('PE-30', $q$Una trampa no puede estar en dos puestos a la vez (vigencias que se solapan)$q$, 'andres.tec', $q$INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ubic_long, ubic_lat) SELECT (SELECT tram_id FROM trampa WHERE tram_codigo = '54518-602-1'), (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1'), (SELECT lote_id FROM lote WHERE lote_codigo = 'A' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')), '2026-03-01', (SELECT tecn_id FROM tecnico LIMIT 1), (SELECT vigi_id FROM vigilancia LIMIT 1), -72.6495, 7.3705$q$, $q$SQLSTATE:23P01$q$);
SELECT pg_temp.pe_valor('PE-31', $q$Un punto GPS se asigna al lote que lo contiene$q$, $q$SELECT l.lote_codigo FROM lote l WHERE l.lote_id IN (SELECT fn_lote_que_contiene(ST_SetSRID(ST_MakePoint(-72.6425, 7.3725), 4326)))$q$, $q$B$q$);
SELECT pg_temp.pe_valor('PE-32', $q$Las 3 trampas caen dentro de la geometría del lote A$q$, $q$SELECT count(*)::text FROM v_trampa_lote_vigente WHERE dentro_del_lote$q$, $q$3$q$);
SELECT pg_temp.pe_valor('PE-33', $q$El código de ruta de 9 dígitos se compone del Divipola + registro de ruta$q$, $q$SELECT ruta_codigo_9 FROM v_ruta_codigo_ica$q$, $q$545180602$q$);
SELECT pg_temp.pe_falla('PE-34', $q$La geometría de un lote no puede salirse del predio$q$, 'sara.super', $q$INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde) VALUES ((SELECT lote_id FROM lote WHERE lote_codigo = 'B' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')), 2, ST_GeomFromText('POLYGON((-72.5 7.3,-72.49 7.3,-72.49 7.31,-72.5 7.31,-72.5 7.3))', 4326), now())$q$, $q$fuera del límite$q$);
SELECT pg_temp.pe_falla('PE-35', $q$La resolución de la retícula debe ser múltiplo de la distancia mínima entre trampas$q$, 'sara.super', $q$DO $x$ DECLARE r int; BEGIN INSERT INTO reticula (pred_id, reti_resolucion_m) VALUES ((SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1'), 90) RETURNING reti_id INTO r; INSERT INTO programa_inspeccion (pred_id, prog_version, prog_vigente_desde, prog_periodo_lectura_dias, prog_distancia_min_trampas_m, reti_id) VALUES ((SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1'), 2, '2026-10-01', 7, 40, r); END $x$$q$, $q$múltiplo$q$);
SELECT pg_temp.pe_falla('PE-36', $q$Una retícula no cambia de resolución (se crea otra)$q$, 'sara.super', $q$UPDATE reticula SET reti_resolucion_m = 100$q$, $q$no se modifican$q$);
SELECT pg_temp.pe_valor('PE-37', $q$Se detecta la visita a un lote no asignado, sin bloquear el registro$q$, $q$SELECT count(*)::text || ' ' || string_agg(u.usua_usuario, ',') FROM v_visita_lote_sin_asignacion v JOIN usuario u USING (usua_id)$q$, $q$1 juan.tec$q$);
SELECT pg_temp.pe_falla('PE-38', $q$De una visita solo cambian las columnas de revisión$q$, 'sara.super', $q$UPDATE visita SET visi_t_captura = visi_t_captura + interval '1 hour'$q$, $q$solo se pueden modificar$q$);
SELECT pg_temp.pe_pasa('PE-39', $q$La supervisora puede poner una visita en revisión$q$, 'sara.super', $q$UPDATE visita SET visi_estado_revision = 'en_revision', visi_revisada_por = (SELECT usua_id FROM usuario WHERE usua_usuario = 'sara.super'), visi_revisada_en = now() WHERE visi_estado_revision = 'pendiente'$q$);
SELECT pg_temp.pe_falla('PE-40', $q$La misma operación del celular enviada dos veces no se duplica (idempotencia)$q$, 'andres.tec', $q$INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura) SELECT disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura FROM operacion_sync LIMIT 1$q$, $q$SQLSTATE:23505$q$);
SELECT pg_temp.pe_pasa('PE-41.a', $q$El reloj de sincronización lo pone el servidor, no el celular (paso 1)$q$, 'andres.tec', $q$DO $x$ DECLARE op bigint; d uuid; BEGIN
  SELECT disp_id INTO d FROM dispositivo LIMIT 1;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (d, gen_random_uuid(), (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec'), 'cosecha', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  INSERT INTO cosecha (cose_registro_id, lote_id, cose_fecha_esperada, cose_volumen_esperado, cose_volumen_uni_id, cose_linaje, usua_id, disp_id, oper_id, cose_t_observacion, cose_t_captura, cose_t_sincronizacion)
    VALUES (gen_random_uuid(), (SELECT lote_id FROM lote WHERE lote_codigo = 'C' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')), '2026-12-20', 100, (SELECT unid_id FROM unidad_medida WHERE unid_simbolo = 'kg'), 'inspeccion_oficial', (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec'), d, op, now(), now(), '2000-01-01'); END $x$$q$);
SELECT pg_temp.pe_valor('PE-41.b', $q$El reloj de sincronización lo pone el servidor, no el celular (paso 2)$q$, $q$SELECT count(*)::text FROM cosecha WHERE cose_t_sincronizacion < '2020-01-01'$q$, $q$0$q$);
SELECT pg_temp.pe_falla('PE-42', $q$La bitácora no se borra$q$, 'ana.admin', $q$DELETE FROM bitacora_auditoria$q$, $q$solo inserción$q$);
SELECT pg_temp.pe_valor('PE-43', $q$La bitácora nunca guarda contraseñas$q$, $q$SELECT count(*)::text FROM bitacora_auditoria WHERE bita_detalle::text LIKE '%argon2id%'$q$, $q$0$q$);
SELECT pg_temp.pe_pasa('PE-44.a', $q$Un cambio en una tabla auditada queda registrado (paso 1)$q$, 'sara.super', $q$UPDATE persona SET pers_direccion = 'Vereda La Paz' WHERE pers_cc = 1010000005$q$);
SELECT pg_temp.pe_valor('PE-44.b', $q$Un cambio en una tabla auditada queda registrado (paso 2)$q$, $q$SELECT count(*)::text FROM bitacora_auditoria WHERE bita_tabla = 'persona' AND bita_accion = 'UPDATE'$q$, $q$1$q$);
SELECT pg_temp.pe_falla('PE-45', $q$Un usuario de ámbito global (Administrador) no se asigna a un predio$q$, 'ana.admin', $q$INSERT INTO usuario_predio (usua_id, pred_id, rol_id, usup_desde) VALUES ((SELECT usua_id FROM usuario WHERE usua_usuario = 'ana.admin'), (SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1'), (SELECT rol_id FROM rol WHERE rol_codigo = 'AGRONOMO_SUPERVISOR'), current_date)$q$, $q$ámbito global$q$);
SELECT pg_temp.pe_falla('PE-46', $q$El estado de un archivo solo avanza (almacenado no vuelve a pendiente)$q$, 'andres.tec', $q$UPDATE archivo_adjunto SET arch_estado = 'pendiente_contenido'$q$, $q$solo avanza$q$);
SELECT pg_temp.pe_falla('PE-47', $q$La identidad de un archivo (hash) no se modifica$q$, 'andres.tec', $q$UPDATE archivo_adjunto SET arch_hash_sha256 = repeat('0', 64)$q$, $q$identidad$q$);
SELECT pg_temp.pe_pasa('PE-48.a', $q$Un aviso se marca leído una sola vez (paso 1)$q$, 'andres.tec', $q$UPDATE notificacion SET noti_leida_en = now() WHERE usua_id = (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')$q$);
SELECT pg_temp.pe_falla('PE-48.b', $q$Un aviso se marca leído una sola vez (paso 2)$q$, 'andres.tec', $q$UPDATE notificacion SET noti_leida_en = now() + interval '1 second' WHERE usua_id = (SELECT usua_id FROM usuario WHERE usua_usuario = 'andres.tec')$q$, $q$ya fue leída$q$);
SELECT pg_temp.pe_falla('PE-49', $q$El contenido de un aviso no se edita$q$, 'juan.tec', $q$UPDATE notificacion SET noti_titulo = 'otro' WHERE usua_id = (SELECT usua_id FROM usuario WHERE usua_usuario = 'juan.tec')$q$, $q$no se modifica$q$);

\o
\set QUIET off
\echo '== RESULTADO DE LAS PRUEBAS DE ESCRITORIO'
SELECT id, CASE WHEN ok THEN 'OK' ELSE 'FALLA' END AS estado, left(titulo, 70) AS escenario, left(obtenido, 60) AS obtenido FROM pe_resultado ORDER BY n;
SELECT count(*) FILTER (WHERE ok) AS ok, count(*) FILTER (WHERE NOT ok) AS fallas FROM pe_resultado;
\if :{?salida_tsv}
\o :salida_tsv
COPY (SELECT id, CASE WHEN ok THEN 'OK' ELSE 'FALLA' END, esperado, obtenido FROM pe_resultado ORDER BY n) TO STDOUT;
\o
\endif
ROLLBACK;
