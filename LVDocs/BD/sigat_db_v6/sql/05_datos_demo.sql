-- =====================================================================
-- SIGAT v6 - DATOS DE DEMOSTRACIÓN (FICTICIOS)  — solo para bases de desarrollo y capacitación
-- Necesita: 01, 02, 03 y 04. NO ejecutar en producción.
-- Para quitarlos: 05b_borrar_datos_demo.sql (deja solo los catálogos básicos de 02).
--
-- Escenario (el mismo que usan las pruebas de escritorio):
--   Predio «Finca El Mirador» (Pedro Productor) con 4 lotes A, B, C, D. Predio «Finca La Esperanza» (Marta) con el lote E.
--   Sara (Agrónomo/Supervisor) planifica: Andrés (Técnico) -> lotes A y C ; Juan (Técnico) -> lotes B y D.
--   Andrés visita el lote A el 2026-09-10 y lee 3 trampas (una lectura se corrige: versión 2).
--   Juan visita el lote A sin tenerlo asignado (aparece en v_visita_lote_sin_asignacion).
--   No hay umbral oficial (UQQ-004): el MTD se calcula, pero el concepto queda «no_emitido».
-- Las contraseñas son hashes de mentira: nadie puede entrar con ellos.
-- =====================================================================
SET search_path = sigat, public;

DO $demo$
DECLARE
  hash text := '$argon2id$v=19$m=65536,t=3,p=4$ZGVtb3NhbHQ$ZGVtbyBubyBsb2dpbg';
  v_ok int; v_ro int; v_rt int; v_rp int; v_ra int;
  v_reg int; v_dep int; v_mun int; v_cen int; v_adm int;
  v_tA int; v_tJ int;
  u_ana int; u_sara int; u_and int; u_juan int; u_ped int; u_mar int;
  v_pr1 int; v_pr2 int; v_ruta int; v_lA int; v_lB int; v_lC int; v_lD int; v_lE int;
  v_reti int; v_c1 bigint; v_c2 bigint; v_prog int; v_vigi int; v_loca int; v_arb int;
  v_tj1 int; v_tm2 int; v_tj3 int; v_ub1 bigint; v_ub2 bigint; v_ub3 bigint;
  v_disp uuid; v_disp2 uuid; v_peri bigint; v_cond int; v_cond2 int;
  v_vis uuid; v_vis2 uuid; v_l1 uuid := gen_random_uuid(); v_l2 uuid := gen_random_uuid(); v_l3 uuid := gen_random_uuid();
  v_f1 int; v_f2 int; v_ind bigint; v_plan1 uuid; v_plan2 uuid; v_plan3 uuid;
  v_arch uuid := gen_random_uuid(); v_hall uuid := gen_random_uuid();
  v_kg int; v_ha int; v_ml int; v_prod int; v_plaga int; v_seve int; v_crit int; v_tipm int; v_cate int;
  v_pol text := 'POLYGON((%s %s,%s %s,%s %s,%s %s,%s %s))';
  est_act int;
BEGIN
  SELECT esta_id INTO est_act FROM estado_registro WHERE esta_descripcion = 'activo';
  SELECT rol_id INTO v_ro FROM rol WHERE rol_codigo = 'ADMINISTRADOR';
  SELECT rol_id INTO v_rp FROM rol WHERE rol_codigo = 'PRODUCTOR';
  SELECT rol_id INTO v_rt FROM rol WHERE rol_codigo = 'TECNICO';
  SELECT rol_id INTO v_ra FROM rol WHERE rol_codigo = 'AGRONOMO_SUPERVISOR';
  SELECT unid_id INTO v_kg FROM unidad_medida WHERE unid_simbolo = 'kg';
  SELECT unid_id INTO v_ha FROM unidad_medida WHERE unid_simbolo = 'ha';
  SELECT unid_id INTO v_ml FROM unidad_medida WHERE unid_simbolo = 'mL/L';

  -- Geografía -----------------------------------------------------------------
  INSERT INTO region (regi_descripcion) VALUES ('Andina') RETURNING regi_id INTO v_reg;
  INSERT INTO departamento (depa_descripcion, regi_id, depa_codigo) VALUES ('Norte de Santander', v_reg, '54') RETURNING depa_id INTO v_dep;
  INSERT INTO rango_departamento VALUES (v_dep, -73.6, -72.0, 7.0, 9.3);
  INSERT INTO municipio (muni_descripcion, depa_id, muni_codigo) VALUES ('Pamplona', v_dep, '518') RETURNING muni_id INTO v_mun;
  INSERT INTO centro_acopio (cent_descripcion, depa_id) VALUES ('Centro de acopio Pamplona (DEMO)', v_dep) RETURNING cent_id INTO v_cen;

  -- Personas, técnicos, productores y usuarios ------------------------------------
  INSERT INTO persona (pers_cc, pers_nombre, pers_apellido, pers_telefono, pers_correo) VALUES
    (1010000001, 'Ana',    'Administradora', '3100000001', 'ana@demo.sigat.test'),
    (1010000002, 'Sara',   'Supervisora',    '3100000002', 'sara@demo.sigat.test'),
    (1010000003, 'Andrés', 'Técnico',        '3100000003', 'andres@demo.sigat.test'),
    (1010000004, 'Juan',   'Técnico',        '3100000004', 'juan@demo.sigat.test'),
    (1010000005, 'Pedro',  'Productor',      '3100000005', 'pedro@demo.sigat.test'),
    (1010000006, 'Marta',  'Productora',     '3100000006', 'marta@demo.sigat.test');
  INSERT INTO administrador (pers_cc, cent_id) VALUES (1010000001, v_cen) RETURNING admi_id INTO v_adm;
  INSERT INTO tecnico (pers_cc, cent_id, admi_id, tecn_fecha_registro, esta_id) VALUES (1010000003, v_cen, v_adm, '2026-01-10', est_act) RETURNING tecn_id INTO v_tA;
  INSERT INTO tecnico (pers_cc, cent_id, admi_id, tecn_fecha_registro, esta_id) VALUES (1010000004, v_cen, v_adm, '2026-01-10', est_act) RETURNING tecn_id INTO v_tJ;
  INSERT INTO productor (pers_cc, prod_fecha_registro, prod_tecnico_registro_id, muni_id) VALUES (1010000005, '2026-02-01', v_tA, v_mun), (1010000006, '2026-02-01', v_tA, v_mun);
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000001, 'ana.admin',   hash, v_ro, est_act) RETURNING usua_id INTO u_ana;
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000002, 'sara.super',   hash, v_ra, est_act) RETURNING usua_id INTO u_sara;
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000003, 'andres.tec',   hash, v_rt, est_act) RETURNING usua_id INTO u_and;
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000004, 'juan.tec',     hash, v_rt, est_act) RETURNING usua_id INTO u_juan;
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000005, 'pedro.prod',   hash, v_rp, est_act) RETURNING usua_id INTO u_ped;
  INSERT INTO usuario (pers_cc, usua_usuario, usua_contrasena, rol_id, esta_id) VALUES (1010000006, 'marta.prod',   hash, v_rp, est_act) RETURNING usua_id INTO u_mar;
  INSERT INTO perfil_usuario (usua_id) SELECT usua_id FROM usuario;

  -- Ruta, predios, lotes -------------------------------------------------------------
  INSERT INTO ruta (ruta_nombre, cent_id, muni_id, ruta_descripcion, ruta_codigo, ruta_fecha_registro, ruta_admin_registro_id, esta_id)
    VALUES ('Ruta Norte (DEMO)', v_cen, v_mun, 'Ruta de demostración', '0602', '2026-01-10', v_adm, est_act) RETURNING ruta_id INTO v_ruta;
  INSERT INTO predio (pred_codigo, pred_nombre, muni_id, pred_area, pers_cc, pred_geom, pred_fecha_registro, pred_tecnico_registro_id)
    VALUES ('DEMO-1', 'Finca El Mirador', v_mun, 12, 1010000005,
            ST_GeomFromText(format(v_pol, -72.6500,7.3700, -72.6400,7.3700, -72.6400,7.3800, -72.6500,7.3800, -72.6500,7.3700), 4326), '2026-02-02', v_tA)
    RETURNING pred_id INTO v_pr1;
  INSERT INTO predio (pred_codigo, pred_nombre, muni_id, pred_area, pers_cc, pred_geom, pred_fecha_registro, pred_tecnico_registro_id)
    VALUES ('DEMO-2', 'Finca La Esperanza', v_mun, 5, 1010000006,
            ST_GeomFromText(format(v_pol, -72.6300,7.3900, -72.6250,7.3900, -72.6250,7.3950, -72.6300,7.3950, -72.6300,7.3900), 4326), '2026-02-02', v_tA)
    RETURNING pred_id INTO v_pr2;

  -- Catálogos que la institución define: aquí solo los mínimos de la demo -----------------
  INSERT INTO variedad_cultivo (espc_id, vari_descripcion) SELECT espc_id, 'Variedad demo' FROM especie_cultivo;
  INSERT INTO vigilancia (vigi_descripcion, vigi_codigo) VALUES ('Vigilancia de Mosca de la Fruta', 1) RETURNING vigi_id INTO v_vigi;
  INSERT INTO localizacion (loca_descripcion, loca_codigo) VALUES ('Dentro del cultivo', 1) RETURNING loca_id INTO v_loca;
  INSERT INTO arbol (arbo_descripcion) VALUES ('Duraznero') RETURNING arbo_id INTO v_arb;
  INSERT INTO condicion_trampa (cond_descripcion) VALUES ('Normal') RETURNING cond_id INTO v_cond;
  INSERT INTO condicion_trampa (cond_descripcion) VALUES ('Dañada') RETURNING cond_id INTO v_cond2;
  INSERT INTO fenologia (feno_descripcion, feno_codigo) VALUES ('Floración', 1) RETURNING feno_id INTO v_f1;
  INSERT INTO fenologia (feno_descripcion, feno_codigo) VALUES ('Cuajado', 2) RETURNING feno_id INTO v_f2;
  INSERT INTO fenologia_regla (espc_id, feno_id, fenr_dias_desde, fenr_dias_hasta, fenr_vigente_desde)
    SELECT espc_id, v_f1, 0, 400, '2026-01-01' FROM especie_cultivo;
  INSERT INTO fenologia_regla (espc_id, feno_id, fenr_dias_desde, fenr_dias_hasta, fenr_vigente_desde)
    SELECT espc_id, v_f2, 401, 900, '2026-01-01' FROM especie_cultivo;
  INSERT INTO severidad (seve_descripcion, seve_orden) VALUES ('Media', 2) RETURNING seve_id INTO v_seve;
  INSERT INTO plaga_enfermedad (plag_descripcion, plag_tipo) VALUES ('Mosca de la fruta', 'plaga') RETURNING plag_id INTO v_plaga;
  INSERT INTO producto_fitosanitario (prof_nombre, prof_ingrediente_activo) VALUES ('Producto demo', 'ingrediente demo') RETURNING prof_id INTO v_prod;
  INSERT INTO criterio_bpa (crit_descripcion) VALUES ('Registro de aplicaciones al día') RETURNING crit_id INTO v_crit;
  SELECT tipm_id INTO v_tipm FROM tipo_manejo WHERE tipm_descripcion = 'Riego';
  SELECT cate_id INTO v_cate FROM categoria_notificacion WHERE cate_codigo = 'asignacion';

  -- Lotes con geometría --------------------------------------------------------------------
  INSERT INTO lote (lote_codigo, lote_descripcion, lote_area, pred_id, espc_id, vari_id, lote_fecha_plantacion, lote_fecha_registro, lote_tecnico_registro_id)
    SELECT c, 'Lote ' || c, 2.5, v_pr1, e.espc_id, (SELECT vari_id FROM variedad_cultivo LIMIT 1), '2025-03-01', '2026-02-03', v_tA
      FROM especie_cultivo e, unnest(ARRAY['A','B','C','D']) c;
  INSERT INTO lote (lote_codigo, lote_descripcion, lote_area, pred_id, espc_id, lote_fecha_plantacion, lote_fecha_registro, lote_tecnico_registro_id)
    SELECT 'E', 'Lote E', 3, v_pr2, espc_id, '2025-03-01', '2026-02-03', v_tA FROM especie_cultivo;
  SELECT lote_id INTO v_lA FROM lote WHERE pred_id = v_pr1 AND lote_codigo = 'A';
  SELECT lote_id INTO v_lB FROM lote WHERE pred_id = v_pr1 AND lote_codigo = 'B';
  SELECT lote_id INTO v_lC FROM lote WHERE pred_id = v_pr1 AND lote_codigo = 'C';
  SELECT lote_id INTO v_lD FROM lote WHERE pred_id = v_pr1 AND lote_codigo = 'D';
  SELECT lote_id INTO v_lE FROM lote WHERE pred_id = v_pr2;
  INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde, lotg_fuente) VALUES
    (v_lA, 1, ST_GeomFromText(format(v_pol, -72.6500,7.3700, -72.6450,7.3700, -72.6450,7.3750, -72.6500,7.3750, -72.6500,7.3700), 4326), '2026-02-03', 'demo'),
    (v_lB, 1, ST_GeomFromText(format(v_pol, -72.6450,7.3700, -72.6400,7.3700, -72.6400,7.3750, -72.6450,7.3750, -72.6450,7.3700), 4326), '2026-02-03', 'demo'),
    (v_lC, 1, ST_GeomFromText(format(v_pol, -72.6500,7.3750, -72.6450,7.3750, -72.6450,7.3800, -72.6500,7.3800, -72.6500,7.3750), 4326), '2026-02-03', 'demo'),
    (v_lD, 1, ST_GeomFromText(format(v_pol, -72.6450,7.3750, -72.6400,7.3750, -72.6400,7.3800, -72.6450,7.3800, -72.6450,7.3750), 4326), '2026-02-03', 'demo'),
    (v_lE, 1, ST_GeomFromText(format(v_pol, -72.6300,7.3900, -72.6250,7.3900, -72.6250,7.3950, -72.6300,7.3950, -72.6300,7.3900), 4326), '2026-02-03', 'demo');

  -- Accesos a predios, retícula y programa ------------------------------------------------------
  INSERT INTO usuario_predio (usua_id, pred_id, rol_id, usup_desde, usup_asignado_por) VALUES
    (u_sara, v_pr1, v_ra, '2026-02-01', u_ana), (u_sara, v_pr2, v_ra, '2026-02-01', u_ana),
    (u_and,  v_pr1, v_rt, '2026-02-01', u_ana), (u_juan, v_pr1, v_rt, '2026-02-01', u_ana);
  INSERT INTO reticula (pred_id, reti_resolucion_m) VALUES (v_pr1, 80) RETURNING reti_id INTO v_reti;
  INSERT INTO reticula_celda (reti_id, retc_codigo, retc_geom) VALUES
    (v_reti, 'A1', ST_GeomFromText(format(v_pol, -72.6500,7.3700, -72.6490,7.3700, -72.6490,7.3710, -72.6500,7.3710, -72.6500,7.3700), 4326)) RETURNING retc_id INTO v_c1;
  INSERT INTO reticula_celda (reti_id, retc_codigo, retc_geom) VALUES
    (v_reti, 'A2', ST_GeomFromText(format(v_pol, -72.6490,7.3700, -72.6480,7.3700, -72.6480,7.3710, -72.6490,7.3710, -72.6490,7.3700), 4326)) RETURNING retc_id INTO v_c2;
  INSERT INTO programa_inspeccion (pred_id, prog_version, prog_vigente_desde, prog_periodo_lectura_dias, prog_distancia_min_trampas_m, reti_id, prog_creado_por)
    VALUES (v_pr1, 1, '2026-01-01', 7, 40, v_reti, u_sara) RETURNING prog_id INTO v_prog;

  -- Trampas y ubicaciones (todas en el lote A) -----------------------------------------------------
  INSERT INTO trampa (tram_codigo, tipt_id, atra_id, esta_id, tram_fecha_registro, tram_tecnico_registro_id)
    SELECT '54518-602-' || n, (SELECT tipt_id FROM tipo_trampa WHERE tipt_paridad = CASE WHEN n % 2 = 1 THEN 'impar' ELSE 'par' END),
           (SELECT atra_id FROM atrayente WHERE atra_descripcion = 'Plug'), est_act, '2026-02-05', v_tA
      FROM generate_series(1, 3) n;
  SELECT tram_id INTO v_tj1 FROM trampa WHERE tram_codigo = '54518-602-1';
  SELECT tram_id INTO v_tm2 FROM trampa WHERE tram_codigo = '54518-602-2';
  SELECT tram_id INTO v_tj3 FROM trampa WHERE tram_codigo = '54518-602-3';
  INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ruta_id, retc_id, loca_id, arbo_id, ubic_long, ubic_lat, ubic_referencia) VALUES
    (v_tj1, v_pr1, v_lA, '2026-02-05', v_tA, v_vigi, v_ruta, v_c1, v_loca, v_arb, -72.64950, 7.37050, 'Junto al poste de entrada') RETURNING ubic_id INTO v_ub1;
  INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ruta_id, retc_id, loca_id, arbo_id, ubic_long, ubic_lat) VALUES
    (v_tm2, v_pr1, v_lA, '2026-02-05', v_tA, v_vigi, v_ruta, v_c2, v_loca, v_arb, -72.64850, 7.37050) RETURNING ubic_id INTO v_ub2;
  INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ruta_id, loca_id, arbo_id, ubic_long, ubic_lat) VALUES
    (v_tj3, v_pr1, v_lA, '2026-02-05', v_tA, v_vigi, v_ruta, v_loca, v_arb, -72.64700, 7.37300) RETURNING ubic_id INTO v_ub3;

  -- Planificaciones (las crea Sara; el actor de sesión es quien escribe) -----------------------------------
  PERFORM set_config('sigat.usuario_actual', u_sara::text, true);
  INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio, plan_fecha_fin, plan_observaciones)
    VALUES (u_and, u_sara, 'Inspección y lectura de trampas', '2026-09-01', '2026-09-30', 'Lotes A y C') RETURNING plan_id INTO v_plan1;
  INSERT INTO planificacion_lote VALUES (v_plan1, v_lA), (v_plan1, v_lC);
  INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio, plan_fecha_fin, plan_observaciones)
    VALUES (u_juan, u_sara, 'Inspección y lectura de trampas', '2026-09-01', '2026-09-30', 'Lotes B y D') RETURNING plan_id INTO v_plan2;
  INSERT INTO planificacion_lote VALUES (v_plan2, v_lB), (v_plan2, v_lD);
  INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio, plan_observaciones)
    VALUES (u_ped, u_sara, 'Aplicación de manejo sugerido', '2026-09-05', 'El productor debe aceptar o rechazar') RETURNING plan_id INTO v_plan3;
  INSERT INTO planificacion_lote VALUES (v_plan3, v_lB);
  PERFORM set_config('sigat.usuario_actual', u_ped::text, true);       -- Pedro acepta su planificación
  UPDATE planificacion SET plan_estado = 'aceptada' WHERE plan_id = v_plan3;
  INSERT INTO notificacion (usua_id, cate_id, noti_titulo, noti_cuerpo, noti_evento_clave) VALUES
    (u_and, v_cate, 'Nueva planificación', 'Tienes los lotes A y C del 1 al 30 de septiembre', 'plan:' || v_plan1),
    (u_juan, v_cate, 'Nueva planificación', 'Tienes los lotes B y D del 1 al 30 de septiembre', 'plan:' || v_plan2),
    (u_ped, v_cate, 'Nueva planificación', 'El supervisor te propone una aplicación en el lote B', 'plan:' || v_plan3);
  PERFORM set_config('sigat.usuario_actual', '', true);

  -- Dispositivos y periodo ----------------------------------------------------------------------------------
  INSERT INTO dispositivo (disp_nombre, disp_plataforma) VALUES ('Celular de Andrés (DEMO)', 'android') RETURNING disp_id INTO v_disp;
  INSERT INTO dispositivo (disp_nombre, disp_plataforma) VALUES ('Celular de Juan (DEMO)', 'android') RETURNING disp_id INTO v_disp2;
  INSERT INTO periodo_trampeo (lote_id, vigi_id, prog_id, peri_inicio, peri_fin, peri_estado) VALUES (v_lA, v_vigi, v_prog, '2026-09-01', '2026-09-14', 'cerrado') RETURNING peri_id INTO v_peri;

  -- Visitas -------------------------------------------------------------------------------------------------------
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (v_disp, gen_random_uuid(), u_and, 'visita', 'crear', gen_random_uuid(), md5('v1') || md5('v1b'), 'alta_nueva', '2026-09-10 18:00-05');
  INSERT INTO visita (disp_id, oper_id, usua_id, pred_id, ruta_id, visi_t_inicio_obs, visi_t_fin_obs, visi_t_captura)
    VALUES (v_disp, (SELECT max(oper_id) FROM operacion_sync), u_and, v_pr1, v_ruta, '2026-09-10 08:00-05', '2026-09-10 10:30-05', '2026-09-10 18:00-05') RETURNING visi_id INTO v_vis;
  INSERT INTO visita_lote VALUES (v_vis, v_lA, v_pr1);
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (v_disp2, gen_random_uuid(), u_juan, 'visita', 'crear', gen_random_uuid(), md5('v2') || md5('v2b'), 'alta_nueva', '2026-09-11 18:00-05');
  INSERT INTO visita (disp_id, oper_id, usua_id, pred_id, ruta_id, visi_t_inicio_obs, visi_t_fin_obs, visi_t_captura)
    VALUES (v_disp2, (SELECT max(oper_id) FROM operacion_sync), u_juan, v_pr1, v_ruta, '2026-09-11 09:00-05', '2026-09-11 09:40-05', '2026-09-11 18:00-05') RETURNING visi_id INTO v_vis2;
  INSERT INTO visita_lote VALUES (v_vis2, v_lA, v_pr1);   -- Juan NO tiene el lote A asignado

  -- Lecturas de las 3 trampas (la tercera se corrige: versión 2) ------------------------------------------------------
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (v_disp, gen_random_uuid(), u_and, 'lectura_trampa', 'crear', v_l1, md5('l1') || md5('l1b'), 'alta_nueva', '2026-09-10 18:00-05'),
           (v_disp, gen_random_uuid(), u_and, 'lectura_trampa', 'crear', v_l2, md5('l2') || md5('l2b'), 'alta_nueva', '2026-09-10 18:00-05'),
           (v_disp, gen_random_uuid(), u_and, 'lectura_trampa', 'crear', v_l3, md5('l3') || md5('l3b'), 'alta_nueva', '2026-09-10 18:00-05');
  INSERT INTO lectura_trampa (lect_registro_id, lect_version, visi_id, tram_id, ubic_id, lect_leida, lect_especimenes, cond_id, lect_linaje, usua_id, disp_id, oper_id, lect_t_observacion, lect_t_captura)
    SELECT v_l1, 1, v_vis, v_tj1, v_ub1, true, 2, v_cond, 'inspeccion_oficial', u_and, v_disp, (SELECT oper_id FROM operacion_sync WHERE oper_registro_id = v_l1), '2026-09-10 08:20-05', '2026-09-10 18:00-05';
  INSERT INTO lectura_trampa (lect_registro_id, lect_version, visi_id, tram_id, ubic_id, lect_leida, lect_especimenes, cond_id, lect_linaje, usua_id, disp_id, oper_id, lect_t_observacion, lect_t_captura)
    SELECT v_l2, 1, v_vis, v_tm2, v_ub2, true, 0, v_cond, 'inspeccion_oficial', u_and, v_disp, (SELECT oper_id FROM operacion_sync WHERE oper_registro_id = v_l2), '2026-09-10 08:40-05', '2026-09-10 18:00-05';
  INSERT INTO lectura_trampa (lect_registro_id, lect_version, visi_id, tram_id, ubic_id, lect_leida, lect_especimenes, cond_id, lect_linaje, usua_id, disp_id, oper_id, lect_t_observacion, lect_t_captura)
    SELECT v_l3, 1, v_vis, v_tj3, v_ub3, true, 4, v_cond, 'inspeccion_oficial', u_and, v_disp, (SELECT oper_id FROM operacion_sync WHERE oper_registro_id = v_l3), '2026-09-10 09:00-05', '2026-09-10 18:00-05';
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_version, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (v_disp, gen_random_uuid(), u_and, 'lectura_trampa', 'corregir', v_l3, 2, md5('l3c') || md5('l3d'), 'correccion', '2026-09-12 09:00-05');
  INSERT INTO lectura_trampa (lect_registro_id, lect_version, visi_id, tram_id, ubic_id, lect_leida, lect_especimenes, cond_id, lect_observaciones, lect_linaje, usua_id, disp_id, oper_id, lect_t_observacion, lect_t_captura)
    SELECT v_l3, 2, v_vis, v_tj3, v_ub3, true, 5, v_cond, 'Recuento corregido tras revisar la lámina', 'inspeccion_oficial', u_and, v_disp, (SELECT max(oper_id) FROM operacion_sync), '2026-09-10 09:00-05', '2026-09-12 09:00-05';

  -- Evidencia fotográfica de la lectura 1 ------------------------------------------------------------------------------
  INSERT INTO archivo_adjunto (arch_id, arch_clase, arch_nombre_original, arch_mime, arch_tamano_bytes, arch_hash_sha256, usua_id, disp_id, arch_t_captura)
    VALUES (v_arch, 'foto_evidencia', 'trampa1.jpg', 'image/jpeg', 245000, md5('foto') || md5('foto2'), u_and, v_disp, '2026-09-10 08:21-05');
  UPDATE archivo_adjunto SET arch_estado = 'almacenado', arch_ref_almacenamiento = 'demo/trampa1.jpg', arch_t_almacenado = now() WHERE arch_id = v_arch;
  INSERT INTO evidencia (evid_id, arch_id, evid_clase, lect_id, evid_observacion, usua_id, disp_id, oper_id)
    SELECT gen_random_uuid(), v_arch, 'foto_evidencia', lect_id, 'Foto de la lámina de la trampa 1', u_and, v_disp, oper_id FROM lectura_trampa WHERE lect_registro_id = v_l1 AND lect_version = 1;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (v_disp, gen_random_uuid(), u_and, 'hallazgo', 'crear', v_hall, md5('h1') || md5('h1b'), 'alta_nueva', '2026-09-10 18:00-05');
  INSERT INTO hallazgo (hall_registro_id, lote_id, retc_id, plag_id, seve_id, hall_observaciones, hall_linaje, usua_id, disp_id, oper_id, hall_t_observacion, hall_t_captura)
    VALUES (v_hall, v_lA, v_c1, v_plaga, v_seve, 'Fruta picada cerca de la trampa 1', 'inspeccion_oficial', u_and, v_disp, (SELECT max(oper_id) FROM operacion_sync), '2026-09-10 09:30-05', '2026-09-10 18:00-05');

  -- MTD del periodo calculado desde las lecturas válidas (sin umbral: UQQ-004) ----------------------------------------
  INSERT INTO indice_mtd (peri_id, indi_moscas, indi_trampas, indi_dias_exposicion, indi_resultado_contraste)
    SELECT v_peri, sum(lect_especimenes), count(DISTINCT tram_id), 7, 'sin_umbral' FROM fn_mtd_lectura_valida(v_peri) RETURNING indi_id INTO v_ind;
  INSERT INTO indice_mtd_lectura SELECT v_ind, lect_id FROM fn_mtd_lectura_valida(v_peri);
  INSERT INTO concepto_aptitud (lote_id, peri_id, indi_id, conc_resultado, conc_fecha_efecto) VALUES (v_lA, v_peri, v_ind, 'no_emitido', '2026-09-15');

  -- Autorreporte del productor y registros del campo ---------------------------------------------------------------------
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura) VALUES
    (v_disp, gen_random_uuid(), u_ped, 'etapa_declarada', 'crear', gen_random_uuid(), md5('e1') || md5('e1b'), 'alta_nueva', '2026-09-09 19:00-05'),
    (v_disp, gen_random_uuid(), u_and, 'etapa_declarada', 'crear', gen_random_uuid(), md5('e2') || md5('e2b'), 'alta_nueva', '2026-09-10 18:00-05'),
    (v_disp, gen_random_uuid(), u_ped, 'aplicacion_fitosanitaria', 'crear', gen_random_uuid(), md5('a1') || md5('a1b'), 'alta_nueva', '2026-09-08 19:00-05'),
    (v_disp, gen_random_uuid(), u_ped, 'cosecha', 'crear', gen_random_uuid(), md5('c1') || md5('c1b'), 'alta_nueva', '2026-09-08 19:10-05'),
    (v_disp, gen_random_uuid(), u_and, 'estimacion_produccion', 'crear', gen_random_uuid(), md5('s1') || md5('s1b'), 'alta_nueva', '2026-09-10 18:00-05');
  INSERT INTO etapa_declarada (etap_registro_id, lote_id, feno_id, etap_linaje, usua_id, disp_id, oper_id, etap_t_observacion, etap_t_captura)
    SELECT oper_registro_id, v_lA, v_f2, 'autorreporte', u_ped, v_disp, oper_id, '2026-09-09 18:00-05', '2026-09-09 19:00-05' FROM operacion_sync WHERE oper_entidad = 'etapa_declarada' AND usua_id = u_ped;
  INSERT INTO etapa_declarada (etap_registro_id, lote_id, feno_id, etap_linaje, usua_id, disp_id, oper_id, etap_t_observacion, etap_t_captura)
    SELECT oper_registro_id, v_lA, v_f1, 'inspeccion_oficial', u_and, v_disp, oper_id, '2026-09-10 09:45-05', '2026-09-10 18:00-05' FROM operacion_sync WHERE oper_entidad = 'etapa_declarada' AND usua_id = u_and;
  INSERT INTO aplicacion_fitosanitaria (apli_registro_id, lote_id, prof_id, apli_dosis, apli_dosis_uni_id, apli_area_tratada, apli_area_uni_id, pers_cc_responsable, apli_linaje, usua_id, disp_id, oper_id, apli_t_observacion, apli_t_captura)
    SELECT oper_registro_id, v_lA, v_prod, 2, v_ml, 2.5, v_ha, 1010000005, 'autorreporte', u_ped, v_disp, oper_id, '2026-09-08 07:00-05', '2026-09-08 19:00-05' FROM operacion_sync WHERE oper_entidad = 'aplicacion_fitosanitaria';
  INSERT INTO cosecha (cose_registro_id, lote_id, cose_fecha_esperada, cose_volumen_esperado, cose_volumen_uni_id, cose_linaje, usua_id, disp_id, oper_id, cose_t_observacion, cose_t_captura)
    SELECT oper_registro_id, v_lA, '2026-12-15', 800, v_kg, 'autorreporte', u_ped, v_disp, oper_id, '2026-09-08 19:00-05', '2026-09-08 19:10-05' FROM operacion_sync WHERE oper_entidad = 'cosecha';
  INSERT INTO estimacion_produccion (esti_registro_id, lote_id, esti_num_arboles, esti_rendimiento_arbol, esti_rendimiento_uni_id, esti_metodo, esti_linaje, usua_id, disp_id, oper_id, esti_t_observacion, esti_t_captura)
    SELECT oper_registro_id, v_lA, 200, 35, v_kg, 'conteo_muestra', 'inspeccion_oficial', u_and, v_disp, oper_id, '2026-09-10 10:00-05', '2026-09-10 18:00-05' FROM operacion_sync WHERE oper_entidad = 'estimacion_produccion';

  -- Revisión de la visita de Andrés por la supervisora --------------------------------------------------------------------------
  PERFORM set_config('sigat.usuario_actual', u_sara::text, true);
  UPDATE visita SET visi_estado_revision = 'aceptado', visi_revisada_por = u_sara, visi_revisada_en = now() WHERE visi_id = v_vis;
  PERFORM set_config('sigat.usuario_actual', '', true);
END $demo$;

-- Resumen de lo cargado ----------------------------------------------------------------------------------------------------------------------
SELECT 'usuarios' AS dato, count(*) FROM usuario UNION ALL SELECT 'lotes', count(*) FROM lote UNION ALL SELECT 'trampas', count(*) FROM trampa
UNION ALL SELECT 'lecturas (todas las versiones)', count(*) FROM lectura_trampa UNION ALL SELECT 'MTD', count(*) FROM indice_mtd;
