-- =====================================================================
-- SIGAT v6 - VISTAS (21)
-- Una vista es una consulta guardada con nombre: no almacena datos, los arma al consultarla.
--   v_*_vigente  -> última versión no anulada de cada registro lógico
--   v_*_app      -> forma que consumen las pantallas del teléfono
-- Necesita: 01_esquema_completo.sql. Se puede volver a ejecutar (CREATE OR REPLACE).
-- La autorización final (quién ve qué) la aplica el servidor con fn_lotes_visibles (04_funciones.sql).
-- =====================================================================
SET search_path = sigat, public;

-- 1. Código Divipola (departamento 2 dígitos + municipio 3 dígitos) --------------------
CREATE OR REPLACE VIEW v_municipio_divipola AS
SELECT m.muni_id, m.muni_descripcion, d.depa_id, d.depa_codigo, m.muni_codigo,
       d.depa_codigo || m.muni_codigo AS divipola
FROM municipio m JOIN departamento d USING (depa_id);
COMMENT ON VIEW v_municipio_divipola IS 'Código Divipola de 5 dígitos (dep+mun) para componer el código de trampa del ICA (RN-005).';

-- 2. Código de ruta de 9 dígitos del formato MF_UBI/MF_CAP ------------------------------
CREATE OR REPLACE VIEW v_ruta_codigo_ica AS
SELECT r.ruta_id, r.ruta_nombre, r.ruta_codigo, dv.divipola,
       dv.divipola || lpad(r.ruta_codigo, 4, '0') AS ruta_codigo_9
FROM ruta r JOIN v_municipio_divipola dv USING (muni_id)
WHERE r.ruta_codigo ~ '^[0-9]{1,4}$';
COMMENT ON VIEW v_ruta_codigo_ica IS 'Código Ruta de 9 dígitos del formato MF_UBI/MF_CAP = Divipola del municipio de la ruta (5) + registro de la ruta con 4 dígitos (54125 + 0602 = 541250602). Derivado, no se almacena (3FN). Solo rutas con municipio y registro numérico.';

-- 3. Lectura vigente ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_lectura_vigente AS
SELECT l.* FROM (SELECT DISTINCT ON (lect_registro_id) * FROM lectura_trampa
                  ORDER BY lect_registro_id, lect_version DESC) l
WHERE NOT l.lect_anulada;
COMMENT ON VIEW v_lectura_vigente IS 'Última versión no anulada de cada lectura (la que alimenta el MTD si el linaje es inspeccion_oficial).';

-- 4. Ubicación vigente de cada trampa y si cae dentro del lote ---------------------------
CREATE OR REPLACE VIEW v_trampa_lote_vigente AS
SELECT u.ubic_id, u.tram_id, t.tram_codigo, u.pred_id, u.lote_id, u.ubic_fecha, u.ubic_geom,
       (SELECT g.lotg_geom FROM lote_geometria g
         WHERE g.lote_id = u.lote_id AND g.lotg_vigente_hasta IS NULL) IS NULL AS lote_sin_geometria,
       COALESCE(ST_Covers((SELECT g.lotg_geom FROM lote_geometria g
                            WHERE g.lote_id = u.lote_id AND g.lotg_vigente_hasta IS NULL), u.ubic_geom), false) AS dentro_del_lote
FROM ubicacion_trampa u JOIN trampa t USING (tram_id)
WHERE u.ubic_fecha_fin IS NULL;
COMMENT ON VIEW v_trampa_lote_vigente IS 'Ubicación vigente de cada trampa y si su punto cae dentro de la geometría del lote asignado (advertencia RF-012, no bloqueo).';

-- 5. MTD vigente ------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_mtd_vigente AS
SELECT DISTINCT ON (peri_id, COALESCE(espm_id, 0)) *
FROM indice_mtd ORDER BY peri_id, COALESCE(espm_id, 0), indi_version DESC;
COMMENT ON VIEW v_mtd_vigente IS 'Última versión de MTD de cada periodo y especie.';

-- 6. Concepto vigente -------------------------------------------------------------------
CREATE OR REPLACE VIEW v_concepto_vigente AS
SELECT DISTINCT ON (lote_id, peri_id) *
FROM concepto_aptitud ORDER BY lote_id, peri_id, conc_version DESC;
COMMENT ON VIEW v_concepto_vigente IS 'Última versión del concepto de aptitud de cada lote y periodo.';

-- 7. Estimación total -------------------------------------------------------------------
CREATE OR REPLACE VIEW v_estimacion_total AS
SELECT e.esti_registro_id, e.lote_id, e.esti_version, e.esti_num_arboles, e.esti_rendimiento_arbol,
       e.esti_num_arboles * e.esti_rendimiento_arbol AS esti_total, u.unid_simbolo AS unidad
FROM (SELECT DISTINCT ON (esti_registro_id) * FROM estimacion_produccion
       ORDER BY esti_registro_id, esti_version DESC) e
JOIN unidad_medida u ON u.unid_id = e.esti_rendimiento_uni_id
WHERE NOT e.esti_anulada;
COMMENT ON VIEW v_estimacion_total IS 'Total estimado = árboles × rendimiento, en la misma unidad que el rendimiento por árbol (se asume que "por árbol" se refiere a la unidad de masa; ver pendientes).';

-- 8. Discrepancia de etapa fenológica (RN-012) -------------------------------------------
CREATE OR REPLACE VIEW v_etapa_discrepancia AS
WITH vig AS (SELECT DISTINCT ON (etap_registro_id) * FROM etapa_declarada
              ORDER BY etap_registro_id, etap_version DESC),
     v2 AS (SELECT * FROM vig WHERE NOT etap_anulada),
     oficial AS (SELECT DISTINCT ON (lote_id) * FROM v2 WHERE etap_linaje = 'inspeccion_oficial'
                  ORDER BY lote_id, etap_t_observacion DESC)
SELECT a.lote_id, a.etap_registro_id AS declarada_registro_id, a.feno_id AS feno_declarada,
       o.etap_registro_id AS oficial_registro_id, o.feno_id AS feno_observada,
       a.etap_t_observacion AS declarada_el, o.etap_t_observacion AS observada_el
FROM (SELECT DISTINCT ON (lote_id) * FROM v2 WHERE etap_linaje = 'autorreporte'
       ORDER BY lote_id, etap_t_observacion DESC) a
JOIN oficial o USING (lote_id)
WHERE a.feno_id <> o.feno_id;
COMMENT ON VIEW v_etapa_discrepancia IS 'RN-012: etapas fenológicas declaradas por el productor que difieren de la observada por el técnico en el mismo lote, para revisión del Agrónomo.';

-- 9. Evidencia por lectura (resuelta al registro lógico) ---------------------------------
CREATE OR REPLACE VIEW v_evidencia_lectura AS
SELECT l.lect_registro_id, e.evid_id, e.arch_id, e.evid_clase, e.evid_observacion, e.evid_geom, e.evid_t_sincronizacion
FROM evidencia e JOIN lectura_trampa l ON l.lect_id = e.lect_id;
COMMENT ON VIEW v_evidencia_lectura IS 'Evidencia fotográfica por lectura, resuelta al registro lógico (lect_registro_id) para que sobreviva a las correcciones de la lectura.';

-- 10. Acceso a predios (RF-002) ---------------------------------------------------------
CREATE OR REPLACE VIEW v_acceso_predio AS
SELECT up.usua_id, up.pred_id, up.rol_id, 'asignacion'::text AS origen
FROM usuario_predio up
WHERE up.usup_desde <= CURRENT_DATE AND (up.usup_hasta IS NULL OR up.usup_hasta > CURRENT_DATE)
UNION
SELECT u.usua_id, p.pred_id, u.rol_id, 'propietario'::text
FROM predio p JOIN usuario u ON u.pers_cc = p.pers_cc;
COMMENT ON VIEW v_acceso_predio IS 'RF-002: predios a los que un usuario tiene acceso hoy (asignación vigente o propietario). El Administrador (ámbito global) no necesita fila. La autorización final se aplica en el servidor (RNF-015).';

-- 11. Lotes asignados a cada técnico ------------------------------------------------------
CREATE OR REPLACE VIEW v_asignacion_lote_tecnico AS
SELECT p.usua_id_destinatario AS usua_id, pl.lote_id, p.plan_id, p.plan_estado,
       p.plan_fecha_inicio AS desde, p.plan_fecha_fin AS hasta,
       (p.plan_estado = 'pendiente') AS vigente
FROM planificacion p
JOIN planificacion_lote pl USING (plan_id)
JOIN usuario u ON u.usua_id = p.usua_id_destinatario
JOIN rol r ON r.rol_id = u.rol_id AND r.rol_codigo = 'TECNICO'
WHERE p.plan_estado IN ('pendiente', 'completada');
COMMENT ON VIEW v_asignacion_lote_tecnico IS 'Lotes que cada técnico tiene asignados y con qué fechas: salen de las planificaciones que el supervisor le asignó (el técnico no acepta: la asignación está vigente mientras esté pendiente; completada queda como historial).';

-- 12. Visitas a lotes no asignados ---------------------------------------------------------
CREATE OR REPLACE VIEW v_visita_lote_sin_asignacion AS
SELECT v.visi_id, v.usua_id, vl.lote_id, v.visi_t_inicio_obs,
       (v.visi_t_inicio_obs AT TIME ZONE p.pred_zona_horaria)::date AS dia_visita
FROM visita v
JOIN visita_lote vl USING (visi_id)
JOIN predio p ON p.pred_id = v.pred_id
JOIN usuario u ON u.usua_id = v.usua_id
JOIN rol r ON r.rol_id = u.rol_id AND r.rol_codigo = 'TECNICO'
WHERE NOT EXISTS (
  SELECT 1 FROM v_asignacion_lote_tecnico a
   WHERE a.usua_id = v.usua_id AND a.lote_id = vl.lote_id
     AND (v.visi_t_inicio_obs AT TIME ZONE p.pred_zona_horaria)::date
         BETWEEN a.desde AND COALESCE(a.hasta, a.desde));
COMMENT ON VIEW v_visita_lote_sin_asignacion IS 'Informe de validación: visitas de un técnico a lotes que no tenía asignados ese día. No bloquea el registro (el dato llega del celular sin conexión y no se descarta); sirve para revisar y para que el supervisor corrija la asignación.';

-- 13. Actividad por lote (visitas, aplicaciones y cosechas) --------------------------------
CREATE OR REPLACE VIEW v_actividad_lote AS
SELECT vl.lote_id, 'vigilancia'::text AS tipo, v.visi_id AS registro_id, v.visi_t_inicio_obs AS t_observacion, v.usua_id
FROM visita v JOIN visita_lote vl USING (visi_id)
UNION ALL
SELECT a.lote_id, 'aplicacion', a.apli_registro_id, a.apli_t_observacion, a.usua_id
FROM (SELECT DISTINCT ON (apli_registro_id) * FROM aplicacion_fitosanitaria ORDER BY apli_registro_id, apli_version DESC) a
WHERE NOT a.apli_anulada
UNION ALL
SELECT c.lote_id, 'cosecha', c.cose_registro_id, c.cose_t_observacion, c.usua_id
FROM (SELECT DISTINCT ON (cose_registro_id) * FROM cosecha ORDER BY cose_registro_id, cose_version DESC) c
WHERE NOT c.cose_anulada;
COMMENT ON VIEW v_actividad_lote IS 'Historial por lote (frontend ActivityRecord): visitas, aplicaciones y cosechas vigentes, del tipo vigilancia | aplicacion | cosecha.';

-- 14. Resumen por lote (RF-070 / RF-041 base) -----------------------------------------------
CREATE OR REPLACE VIEW v_resumen_lote AS
SELECT l.lote_id, l.pred_id, l.lote_descripcion,
       (SELECT count(*) FROM ubicacion_trampa u WHERE u.lote_id = l.lote_id AND u.ubic_fecha_fin IS NULL) AS trampas_vigentes,
       (SELECT max(a.apli_t_observacion) FROM aplicacion_fitosanitaria a
         WHERE a.lote_id = l.lote_id AND NOT a.apli_anulada
           AND a.apli_version = (SELECT max(a2.apli_version) FROM aplicacion_fitosanitaria a2 WHERE a2.apli_registro_id = a.apli_registro_id)) AS ultima_aplicacion,
       (SELECT max(v.visi_t_fin_obs) FROM visita v JOIN visita_lote vl USING (visi_id) WHERE vl.lote_id = l.lote_id) AS ultima_visita,
       (SELECT c.conc_resultado FROM v_concepto_vigente c WHERE c.lote_id = l.lote_id ORDER BY c.conc_fecha_efecto DESC, c.conc_id DESC LIMIT 1) AS concepto_vigente
FROM lote l;
COMMENT ON VIEW v_resumen_lote IS 'RF-070 / RF-041 (base): resumen por lote — trampas vigentes, última aplicación, última visita, concepto vigente.';

-- 15. Serie del MTD por lote ---------------------------------------------------------------
CREATE OR REPLACE VIEW v_mtd_serie_lote AS
SELECT p.lote_id, p.peri_id, p.peri_inicio, p.peri_fin, m.indi_valor AS mtd, m.indi_moscas, m.indi_trampas,
       m.indi_dias_exposicion, m.indi_umbral_aplicado AS umbral, m.indi_resultado_contraste AS contraste, m.esce_id
FROM periodo_trampeo p
JOIN v_mtd_vigente m ON m.peri_id = p.peri_id AND m.espm_id IS NULL;
COMMENT ON VIEW v_mtd_serie_lote IS 'Serie del MTD por lote y periodo (frontend MtdPoint / gráfica del resumen). El valor lo calcula el servidor; la app solo lo presenta.';

-- 16. Lote para la lista del teléfono -------------------------------------------------------
CREATE OR REPLACE VIEW v_lote_app AS
SELECT l.lote_id, l.lote_codigo, l.lote_descripcion, l.lote_area, l.pred_id, p.pred_nombre,
       pe.pers_nombre || ' ' || pe.pers_apellido AS productor, mu.muni_descripcion AS municipio,
       ec.espc_descripcion AS cultivo, vc.vari_descripcion AS variedad,
       EXISTS (SELECT 1 FROM periodo_trampeo t WHERE t.lote_id = l.lote_id AND t.peri_estado = 'abierto') AS vigilancia_activa,
       (SELECT count(*) FROM ubicacion_trampa u WHERE u.lote_id = l.lote_id AND u.ubic_fecha_fin IS NULL) AS trampas_vigentes
FROM lote l
JOIN predio p USING (pred_id)
JOIN persona pe ON pe.pers_cc = p.pers_cc
JOIN municipio mu ON mu.muni_id = p.muni_id
LEFT JOIN especie_cultivo ec ON ec.espc_id = l.espc_id
LEFT JOIN variedad_cultivo vc ON vc.vari_id = l.vari_id
WHERE l.lote_fecha_baja IS NULL;
COMMENT ON VIEW v_lote_app IS 'Lote con los datos que muestra la lista del frontend (Lot): predio, productor, municipio, cultivo, área, vigilancia activa y trampas vigentes. El estado pendiente/en curso/visitado es estado de la jornada en el dispositivo y no se guarda aquí.';

-- 17. Resumen fitosanitario del lote ----------------------------------------------------------
CREATE OR REPLACE VIEW v_lote_resumen_app AS
SELECT l.lote_id,
       ult.mtd, ult.escenario, ult.umbral, ult.contraste,
       (SELECT c.conc_resultado FROM v_concepto_vigente c WHERE c.lote_id = l.lote_id
         ORDER BY c.conc_fecha_efecto DESC, c.conc_id DESC LIMIT 1) AS concepto,
       (SELECT count(*) FROM visita_lote vl WHERE vl.lote_id = l.lote_id) AS inspecciones,
       (SELECT count(*) FROM (SELECT DISTINCT ON (apli_registro_id) * FROM aplicacion_fitosanitaria
                               ORDER BY apli_registro_id, apli_version DESC) a
         WHERE a.lote_id = l.lote_id AND NOT a.apli_anulada) AS aplicaciones,
       (SELECT count(*) FROM v_lectura_vigente lv JOIN ubicacion_trampa u ON u.ubic_id = lv.ubic_id
         WHERE u.lote_id = l.lote_id) AS lecturas,
       (SELECT COALESCE(sum(lv.lect_especimenes), 0) FROM v_lectura_vigente lv JOIN ubicacion_trampa u ON u.ubic_id = lv.ubic_id
         WHERE u.lote_id = l.lote_id) AS especimenes,
       (SELECT f.feno_descripcion FROM (SELECT DISTINCT ON (etap_registro_id) * FROM etapa_declarada
                                         ORDER BY etap_registro_id, etap_version DESC) e
          JOIN fenologia f USING (feno_id)
         WHERE e.lote_id = l.lote_id AND NOT e.etap_anulada ORDER BY e.etap_t_observacion DESC LIMIT 1) AS etapa_declarada,
       (SELECT max(c.cose_fecha_real) FROM (SELECT DISTINCT ON (cose_registro_id) * FROM cosecha
                                             ORDER BY cose_registro_id, cose_version DESC) c
         WHERE c.lote_id = l.lote_id AND NOT c.cose_anulada) AS ultima_cosecha,
       (SELECT count(*) FROM (SELECT DISTINCT ON (hall_registro_id) * FROM hallazgo
                               ORDER BY hall_registro_id, hall_version DESC) h
         WHERE h.lote_id = l.lote_id AND NOT h.hall_anulada) AS hallazgos
FROM lote l
LEFT JOIN LATERAL (
  SELECT s.mtd, e.esce_descripcion AS escenario, s.umbral, s.contraste
  FROM v_mtd_serie_lote s LEFT JOIN escenario_trampeo e USING (esce_id)
  WHERE s.lote_id = l.lote_id ORDER BY s.peri_fin DESC LIMIT 1) ult ON true;
COMMENT ON VIEW v_lote_resumen_app IS 'Resumen fitosanitario del lote (frontend LotSummary): MTD, escenario, umbral, concepto, conteos de inspecciones/aplicaciones/lecturas/especímenes, etapa declarada, cosecha y hallazgos vigentes. Todo calculado en el servidor; el umbral de exportación sigue vacío hasta que el ICA lo defina (UQQ-004).';

-- 18. Trampa para el teléfono --------------------------------------------------------------------
CREATE OR REPLACE VIEW v_trampa_app AS
SELECT t.tram_id, t.tram_codigo, tt.tipt_descripcion AS tipo, u.lote_id, u.pred_id, u.ubic_long AS longitud, u.ubic_lat AS latitud,
       rc.retc_codigo AS celda, er.esta_descripcion AS estado,
       ul.lect_t_observacion AS ultima_lectura, ul.lect_especimenes AS ultima_lectura_especimenes
FROM trampa t
JOIN tipo_trampa tt USING (tipt_id)
JOIN estado_registro er ON er.esta_id = t.esta_id
JOIN ubicacion_trampa u ON u.tram_id = t.tram_id AND u.ubic_fecha_fin IS NULL
LEFT JOIN reticula_celda rc ON rc.retc_id = u.retc_id
LEFT JOIN LATERAL (SELECT l.lect_t_observacion, l.lect_especimenes FROM v_lectura_vigente l
                    WHERE l.tram_id = t.tram_id ORDER BY l.lect_t_observacion DESC LIMIT 1) ul ON true;
COMMENT ON VIEW v_trampa_app IS 'Trampa con la forma del modelo Trap del frontend: código ICA, tipo, lote, coordenadas, celda, estado y última lectura.';

-- 19. Avisos de la bandeja de entrada -------------------------------------------------------------
CREATE OR REPLACE VIEW v_notificacion_app AS
SELECT n.noti_id, n.usua_id, n.noti_titulo, n.noti_cuerpo,
       n.noti_destino_ruta, n.noti_destino_argumento,
       n.noti_creada_en, n.noti_leida_en,
       c.cate_codigo, c.cate_descripcion,
       (n.noti_leida_en IS NULL) AS no_leida
FROM notificacion n
JOIN categoria_notificacion c USING (cate_id);
COMMENT ON VIEW v_notificacion_app IS 'Bandeja de avisos del productor (PW06b / P06-P): título, cuerpo, categoría, ruta de destino y estado de lectura. La app filtra por usua_id y ordena por no_leida y fecha.';

-- Compatibilidad con consumidores anteriores: contador de avisos no leídos por usuario.
CREATE OR REPLACE VIEW v_notificacion_resumen AS
SELECT u.usua_id, count(n.noti_id) FILTER (WHERE n.noti_leida_en IS NULL) AS no_leidas
FROM usuario u LEFT JOIN notificacion n USING (usua_id)
GROUP BY u.usua_id;
COMMENT ON VIEW v_notificacion_resumen IS 'Conteo de avisos no leídos por usuario (insignia de la campana en el frontend).';

-- 20. Planificación con nombres y lotes --------------------------------------------------------------
CREATE OR REPLACE VIEW v_planificacion AS
SELECT p.plan_id, p.plan_actividad, p.plan_fecha_inicio, p.plan_fecha_fin, p.plan_hora_desde, p.plan_hora_hasta,
       p.plan_estado, p.plan_observaciones, p.plan_motivo_rechazo, p.plan_creada_en, p.plan_respondida_en,
       p.usua_id_destinatario, pd.pers_nombre || ' ' || pd.pers_apellido AS destinatario, rd.rol_descripcion AS rol_destinatario,
       p.usua_id_creador, pc.pers_nombre || ' ' || pc.pers_apellido AS creador,
       p.arch_id_documento, p.plan_documento_clase,
       a.arch_nombre_original AS documento,
       a.arch_mime AS documento_mime,
       a.arch_tamano_bytes AS documento_bytes,
       a.arch_paginas AS documento_paginas,
       COALESCE((SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo) FROM planificacion_lote pl
                  JOIN lote l USING (lote_id) WHERE pl.plan_id = p.plan_id), '{}') AS lotes,
       COALESCE((SELECT array_agg(l.lote_descripcion ORDER BY l.lote_codigo) FROM planificacion_lote pl
                  JOIN lote l USING (lote_id) WHERE pl.plan_id = p.plan_id), '{}') AS lotes_descripcion
FROM planificacion p
JOIN usuario ud ON ud.usua_id = p.usua_id_destinatario JOIN persona pd ON pd.pers_cc = ud.pers_cc JOIN rol rd ON rd.rol_id = ud.rol_id
JOIN usuario uc ON uc.usua_id = p.usua_id_creador JOIN persona pc ON pc.pers_cc = uc.pers_cc
LEFT JOIN archivo_adjunto a ON a.arch_id = p.arch_id_documento;
COMMENT ON VIEW v_planificacion IS 'Planificación con nombres de destinatario/creador, documento adjunto y lotes: forma que consume el modelo Planning del frontend.';

-- 21. Registro de campo por revisar ----------------------------------------------------------------------
CREATE OR REPLACE VIEW v_registro_campo AS
SELECT v.visi_id, v.usua_id, pe.pers_nombre || ' ' || pe.pers_apellido AS tecnico, v.pred_id, pr.pred_nombre,
       v.visi_t_inicio_obs AS observada_el, v.visi_t_sincronizacion AS recibida_el,
       COALESCE((SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo) FROM visita_lote vl JOIN lote l USING (lote_id)
                  WHERE vl.visi_id = v.visi_id), '{}') AS lotes,
       (SELECT count(*) FROM lectura_trampa lt WHERE lt.visi_id = v.visi_id AND lt.lect_version = 1) AS trampas_leidas,
       v.visi_estado_revision AS estado_revision, v.visi_motivo_revision
FROM visita v
JOIN usuario u ON u.usua_id = v.usua_id JOIN persona pe ON pe.pers_cc = u.pers_cc
JOIN predio pr ON pr.pred_id = v.pred_id
WHERE v.visi_estado_revision <> 'aceptado';
COMMENT ON VIEW v_registro_campo IS 'Registro de campo pendiente de revisión del Agrónomo (frontend FieldRecord): técnico, fechas observada/recibida, lotes y trampas, estado de revisión.';


-- 22. Exportación GeoJSON para QGIS (compatibilidad QGIS Desktop / Web) -----------------------------------
CREATE OR REPLACE VIEW v_geojson_export AS
SELECT 
  l.lote_id,
  l.lote_codigo,
  l.lote_descripcion,
  lg.lotg_geom AS geom,
  ST_AsGeoJSON(lg.lotg_geom, 6)::jsonb AS geometria,
  lg.lotg_geojson AS geojson_importado,
  lg.lotg_geojson_fuente AS geojson_fuente,
  p.pred_id,
  p.pred_nombre,
  p.pred_geom,
  p.pred_geojson,
  p.pred_geojson_fuente,
  l.espc_id,
  l.vari_id,
  l.lote_area,
  l.lote_fecha_baja,
  lg.lotg_version,
  lg.lotg_vigente_desde,
  lg.lotg_vigente_hasta,
  CASE WHEN lg.lotg_vigente_hasta IS NULL THEN true ELSE false END AS es_vigente,
  ec.espc_descripcion AS cultivo,
  vc.vari_descripcion AS variedad,
  mu.muni_descripcion AS municipio,
  dv.divipola
FROM sigat.lote l
JOIN sigat.predio p USING (pred_id)
JOIN sigat.lote_geometria lg ON lg.lote_id = l.lote_id AND lg.lotg_vigente_hasta IS NULL
LEFT JOIN sigat.especie_cultivo ec ON ec.espc_id = l.espc_id
LEFT JOIN sigat.variedad_cultivo vc ON vc.vari_id = l.vari_id
LEFT JOIN sigat.municipio mu ON mu.muni_id = p.muni_id
LEFT JOIN sigat.v_municipio_divipola dv ON dv.muni_id = p.muni_id
WHERE l.lote_fecha_baja IS NULL;

COMMENT ON VIEW v_geojson_export IS 'Vista de exportación GeoJSON para QGIS: geometría vigente del lote en la columna geom (SRID 4326), el mismo dato en JSON (geometria) y datos del predio, cultivo, variedad, municipio y Divipola. En QGIS usa geom como columna de geometría; pred_geom es el límite del predio y no debe usarse como geometría del lote.';


-- 23. Actividad de lote detallada (Vista nueva / PW05, PW02b, P05) --------------------------------
CREATE OR REPLACE VIEW sigat.v_actividad_lote_detalle AS
SELECT 
    a.lote_id, 
    a.tipo, 
    a.registro_id, 
    a.t_observacion, 
    a.usua_id,
    pe.pers_nombre || ' ' || pe.pers_apellido AS responsable,
    r.rol_descripcion AS rol_responsable,
    CASE a.tipo
        WHEN 'vigilancia' THEN 'Visita de vigilancia'
        WHEN 'aplicacion' THEN 'Aplicación fitosanitaria'
        ELSE 'Cosecha'
    END AS titulo,
    CASE a.tipo
        WHEN 'vigilancia' THEN
            (SELECT count(*) FROM sigat.lectura_trampa lt
              WHERE lt.visi_id = a.registro_id)::text
            || ' de ' ||
            (SELECT count(*) FROM sigat.ubicacion_trampa u
              WHERE u.lote_id = a.lote_id
                AND u.ubic_fecha_fin IS NULL)::text
            || ' trampas revisadas'
        WHEN 'aplicacion' THEN
            COALESCE(
                (SELECT p.prof_nombre
                 FROM sigat.aplicacion_fitosanitaria x
                 JOIN sigat.producto_fitosanitario p USING (prof_id)
                 WHERE x.apli_registro_id = a.registro_id
                 ORDER BY x.apli_version DESC LIMIT 1),
                (SELECT x.apli_producto_texto
                 FROM sigat.aplicacion_fitosanitaria x
                 WHERE x.apli_registro_id = a.registro_id
                 ORDER BY x.apli_version DESC LIMIT 1)
            )
        ELSE
            'Cosecha esperada · ' ||
            to_char((SELECT x.cose_fecha_esperada
                     FROM sigat.cosecha x
                     WHERE x.cose_registro_id = a.registro_id
                     ORDER BY x.cose_version DESC LIMIT 1), 'DD Mon YYYY')
    END AS detalle,
    (a.tipo = 'vigilancia') AS es_inspeccion_oficial
FROM sigat.v_actividad_lote a
JOIN sigat.usuario u ON u.usua_id = a.usua_id
JOIN sigat.persona pe ON pe.pers_cc = u.pers_cc
JOIN sigat.rol r ON r.rol_id = u.rol_id;
COMMENT ON VIEW sigat.v_actividad_lote_detalle IS 'Historial con responsable, rol y detalle por tipo de actividad (Vista nueva / PW05, PW02b, P05).';


-- 24. Cosecha vigente por lote (Vista nueva / PW01, PW02, PW04, P04) --------------------------------
CREATE OR REPLACE VIEW sigat.v_cosecha_lote_vigente AS
SELECT DISTINCT ON (c.lote_id)
    c.lote_id, 
    c.cose_registro_id, 
    c.cose_version,
    c.cose_fecha_esperada, 
    c.cose_volumen_esperado,
    c.cose_fecha_real, 
    c.cose_volumen_real,
    u.unid_simbolo AS unidad, 
    c.cose_linaje
FROM sigat.cosecha c
JOIN sigat.unidad_medida u ON u.unid_id = c.cose_volumen_uni_id
WHERE NOT c.cose_anulada
ORDER BY c.lote_id, c.cose_version DESC, c.cose_t_observacion DESC;
COMMENT ON VIEW sigat.v_cosecha_lote_vigente IS 'Cosecha vigente por lote (esperada + real; Vista nueva / PW01, PW02, PW04, P04).';


-- 25. Última aplicación fitosanitaria por lote (Vista nueva / PW03, P02) --------------------------------
CREATE OR REPLACE VIEW sigat.v_aplicacion_ultima_lote AS
SELECT DISTINCT ON (af.lote_id)
    af.lote_id,
    af.apli_registro_id,
    af.apli_version,
    af.apli_t_observacion,
    COALESCE(pf.prof_nombre, af.apli_producto_texto) AS producto,
    af.apli_dosis,
    um_dosis.unid_simbolo AS dosis_unidad,
    af.apli_area_tratada,
    um_area.unid_simbolo AS area_unidad,
    pe.pers_nombre || ' ' || pe.pers_apellido AS responsable,
    af.apli_linaje
FROM sigat.aplicacion_fitosanitaria af
LEFT JOIN sigat.producto_fitosanitario pf ON pf.prof_id = af.prof_id
JOIN sigat.unidad_medida um_dosis ON um_dosis.unid_id = af.apli_dosis_uni_id
JOIN sigat.unidad_medida um_area ON um_area.unid_id = af.apli_area_uni_id
LEFT JOIN sigat.persona pe ON pe.pers_cc = af.pers_cc_responsable
WHERE NOT af.apli_anulada
ORDER BY af.lote_id, af.apli_version DESC, af.apli_t_observacion DESC;
COMMENT ON VIEW sigat.v_aplicacion_ultima_lote IS 'Última aplicación fitosanitaria por lote, con producto y días (Vista nueva / PW03, P02).';


-- 26. Última sincronización por dispositivo (Vista nueva / P01, P06, P07) --------------------------------
CREATE OR REPLACE VIEW sigat.v_ultima_sincronizacion AS
SELECT 
    d.disp_id, 
    u.usua_id, 
    d.disp_plataforma,
    max(o.oper_t_recepcion) AS ultima_recepcion,
    count(o.oper_id)        AS operaciones_recibidas
FROM sigat.dispositivo d
JOIN sigat.operacion_sync o USING (disp_id)
JOIN sigat.usuario u ON u.usua_id = o.usua_id
GROUP BY d.disp_id, u.usua_id, d.disp_plataforma;
COMMENT ON VIEW sigat.v_ultima_sincronizacion IS 'Última sincronización por usuario y dispositivo (Vista nueva / P01, P06, P07).';


-- 27. Resultado del servidor por operación del cliente (Vista nueva / P07b, P07c, P07d) --------------------------------
CREATE OR REPLACE VIEW sigat.v_operacion_confirmada AS
SELECT 
    o.usua_id, 
    o.disp_id, 
    o.oper_cliente_id, 
    o.oper_id,
    o.oper_entidad, 
    o.oper_clasificacion,
    o.oper_t_captura, 
    o.oper_t_recepcion,
    (SELECT r.rece_resultado
     FROM sigat.recepcion_sync r
     WHERE r.oper_id = o.oper_id
     ORDER BY r.rece_t DESC LIMIT 1) AS ultimo_resultado,
    (SELECT count(*) FROM sigat.recepcion_sync r WHERE r.oper_id = o.oper_id) AS reenvios
FROM sigat.operacion_sync o;
COMMENT ON VIEW sigat.v_operacion_confirmada IS 'Resultado del servidor por operación de cliente (Vista nueva / P07b, P07c, P07d): cierra el ciclo del móvil.';


-- 28. Serie del MTD por lote y escenario (Vista nueva / P02, P02-P) --------------------------------
CREATE OR REPLACE VIEW sigat.v_mtd_por_lote_escenario AS
SELECT 
    p.lote_id, 
    p.peri_id, 
    p.peri_inicio, 
    p.peri_fin, 
    m.indi_valor AS mtd, 
    m.indi_moscas, 
    m.indi_trampas,
    m.indi_dias_exposicion, 
    m.indi_umbral_aplicado AS umbral, 
    m.indi_resultado_contraste AS contraste,
    CASE WHEN m.esce_id IS NOT NULL THEN es.esce_descripcion ELSE 'No asignado' END AS escenario,
    CASE WHEN m.esce_id IS NOT NULL THEN es.esce_mtd_desde_defecto ELSE pu.prou_mtd_desde END AS mtd_desde,
    CASE WHEN m.esce_id IS NOT NULL THEN es.esce_mtd_hasta_defecto ELSE pu.prou_mtd_hasta END AS mtd_hasta
FROM sigat.periodo_trampeo p
JOIN sigat.v_mtd_vigente m ON m.peri_id = p.peri_id AND m.espm_id IS NULL
LEFT JOIN sigat.escenario_trampeo es ON es.esce_id = m.esce_id
LEFT JOIN sigat.programa_umbral pu ON pu.prog_id = p.prog_id AND pu.esce_id = m.esce_id;
COMMENT ON VIEW sigat.v_mtd_por_lote_escenario IS 'Serie del MTD por lote y escenario (Vista nueva / P02, P02-P): valor, periodo y escenario.';


-- 29. Resumen productor (Vista nueva / P01, P01-P, PW01) --------------------------------
CREATE OR REPLACE VIEW sigat.v_resumen_productor AS
SELECT 
    p.pred_id,
    p.pred_nombre,
    p.pred_geom,
    p.pred_area,
    mu.muni_descripcion AS municipio,
    l.lote_id,
    l.lote_codigo,
    l.lote_descripcion,
    l.lote_area,
    COALESCE(msc.mtd, 0) AS mtd,
    COALESCE(msc.escenario, 'Sin periodo') AS escenario,
    rl.trampas_vigentes,
    rl.ultima_aplicacion,
    rl.ultima_visita,
    rl.concepto_vigente
FROM sigat.predio p
JOIN sigat.municipio mu ON mu.muni_id = p.muni_id
JOIN sigat.lote l ON l.pred_id = p.pred_id AND l.lote_fecha_baja IS NULL
JOIN sigat.v_resumen_lote rl ON rl.lote_id = l.lote_id
LEFT JOIN LATERAL (
    SELECT msc2.mtd, msc2.escenario
    FROM sigat.v_mtd_por_lote_escenario msc2
    WHERE msc2.lote_id = l.lote_id
    ORDER BY msc2.peri_inicio DESC, msc2.peri_id DESC
    LIMIT 1
) msc ON true
WHERE rl.concepto_vigente IS NOT NULL;
COMMENT ON VIEW sigat.v_resumen_productor IS 'Resumen productor: predio, lotes, MTD, escenario y estado fitosanitario por lote (Vista nueva / P01, P01-P, PW01).';
