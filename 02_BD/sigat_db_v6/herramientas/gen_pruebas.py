#!/usr/bin/env python3
"""Genera pruebas_escritorio/ (SQL ejecutable + documento).  Uso: gen_pruebas.py outdir [resultados.tsv]"""
import sys, os, csv
OUT = sys.argv[1]; RES = {}
if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
    for r in csv.reader(open(sys.argv[2], encoding='utf-8'), delimiter='\t'):
        if len(r) >= 4: RES[r[0]] = (r[1], r[2], r[3])
def w(path, text):
    p = os.path.join(OUT, path); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w', encoding='utf-8').write(text)
U = lambda n: f"(SELECT usua_id FROM usuario WHERE usua_usuario = '{n}')"
LT = lambda c, p='DEMO-1': f"(SELECT lote_id FROM lote WHERE lote_codigo = '{c}' AND pred_id = (SELECT pred_id FROM predio WHERE pred_codigo = '{p}'))"
PRED1 = "(SELECT pred_id FROM predio WHERE pred_codigo = 'DEMO-1')"
TR = lambda n: f"(SELECT tram_id FROM trampa WHERE tram_codigo = '54518-602-{n}')"
VIS = lambda c: f"(SELECT array_agg(l.lote_codigo ORDER BY l.lote_codigo)::text FROM fn_lotes_visibles({U(c)}) v JOIN lote l USING (lote_id))"
INS_PLAN = lambda dest, crea: f"INSERT INTO planificacion (usua_id_destinatario, usua_id_creador, plan_actividad, plan_fecha_inicio) VALUES ({U(dest)}, {U(crea)}, 'Actividad de prueba', '2026-10-01')"
# (id, grupo, titulo, regla, pasos, esperado_texto, tipo, actor, sentencia, esperado_clave)
S = []
def add(*a): S.append(a)
G = {'A': 'A · Quién ve qué (visibilidad por rol)', 'B': 'B · Planificaciones (supervisor → técnico / productor)', 'C': 'C · Lecturas de trampa y versionado',
     'D': 'D · MTD y concepto de aptitud', 'E': 'E · Trampas y ubicaciones', 'F': 'F · Geometría, retícula y programa', 'G': 'G · Visitas y revisión',
     'H': 'H · Sincronización y reloj', 'I': 'I · Seguridad y auditoría', 'J': 'J · Archivos y avisos'}
# ---- A
add('PE-01','A','El técnico Andrés ve solo los lotes que le asignaron','RF-002 / RNF-015','Consultar fn_lotes_visibles para andres.tec. Su planificación pendiente incluye los lotes A y C.','{A,C}','valor','',VIS('andres.tec'),'{A,C}')
add('PE-02','A','El técnico Juan ve solo B y D (no ve los lotes de Andrés)','RF-002','Consultar fn_lotes_visibles para juan.tec.','{B,D}','valor','',VIS('juan.tec'),'{B,D}')
add('PE-03','A','El productor Pedro ve los lotes de su predio (A,B,C,D) pero no el E de Marta','RF-002','Consultar fn_lotes_visibles para pedro.prod (dueño del predio DEMO-1).','{A,B,C,D}','valor','',VIS('pedro.prod'),'{A,B,C,D}')
add('PE-04','A','La productora Marta ve solo su lote E','RF-002','Consultar fn_lotes_visibles para marta.prod.','{E}','valor','',VIS('marta.prod'),'{E}')
add('PE-05','A','El administrador ve todos los lotes','RF-002','Consultar fn_lotes_visibles para ana.admin (rol de ámbito global).','{A,B,C,D,E}','valor','',VIS('ana.admin'),'{A,B,C,D,E}')
add('PE-06','A','Andrés recibe en su teléfono las 3 trampas del lote A; Juan no recibe ninguna','fn_trampa_app','Contar las filas de fn_trampa_app para cada técnico (las trampas están en el lote A, que Juan no tiene asignado).','Andrés 3 · Juan 0','valor','',f"SELECT (SELECT count(*) FROM fn_trampa_app({U('andres.tec')}))::text || '-' || (SELECT count(*) FROM fn_trampa_app({U('juan.tec')}))::text",'3-0')
# ---- B
add('PE-07','B','Un técnico no puede crear planificaciones','fn_planificacion_valida','Con la sesión de Andrés (técnico) intentar crear una planificación para Juan.','Rechazado: «Solo un Agrónomo/Supervisor crea planificaciones»','falla','andres.tec',INS_PLAN('juan.tec','andres.tec'),'Solo un Agrónomo/Supervisor crea')
add('PE-08','B','El destinatario no puede ser Administrador','fn_planificacion_valida','Sara intenta planificar para ana.admin.','Rechazado: «El destinatario debe ser Técnico o Productor»','falla','sara.super',INS_PLAN('ana.admin','sara.super'),'destinatario debe ser')
add('PE-09','B','No se pueden asignar lotes de un predio al que el destinatario no tiene acceso','fn_planificacion_lote_valida','Sara crea una planificación para Andrés y le agrega el lote E (predio de Marta, donde Andrés no tiene acceso).','Rechazado: «El destinatario no tiene acceso al predio del lote»','falla','sara.super',
    f"DO $x$ DECLARE p uuid; BEGIN {INS_PLAN('andres.tec','sara.super')} RETURNING plan_id INTO p; INSERT INTO planificacion_lote VALUES (p, {LT('E','DEMO-2')}); END $x$",'no tiene acceso al predio')
add('PE-10','B','El técnico no puede rechazar (solo completar)','fn_planificacion_valida','Andrés intenta pasar su planificación pendiente a «rechazada».','Rechazado: transición pendiente → rechazada no permitida para Técnico','falla','andres.tec',
    f"UPDATE planificacion SET plan_estado = 'rechazada', plan_motivo_rechazo = 'No puedo' WHERE usua_id_destinatario = {U('andres.tec')}",'no permitida para el rol')
add('PE-11','B','Solo el destinatario responde: Sara no puede completar la planificación de Juan','fn_planificacion_valida','Con la sesión de Sara intentar completar la planificación de Juan.','Rechazado: «Solo el destinatario responde»','falla','sara.super',
    f"UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = {U('juan.tec')}",'Solo el destinatario responde')
add('PE-12','B','Andrés completa su planificación','fn_planificacion_valida','Con la sesión de Andrés pasar su planificación de pendiente a completada.','Aceptado','pasa','andres.tec',
    f"UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = {U('andres.tec')}",'')
add('PE-13','B','Al completarse, los lotes dejan de estar vigentes para el técnico (queda el historial)','v_asignacion_lote_tecnico','Consultar de nuevo qué lotes ve Andrés tras completar.','{}  (vacío)','valor','',f"SELECT COALESCE({VIS('andres.tec')}, '{{}}')",'{}')
add('PE-14','B','Pedro (productor) completa la planificación que ya había aceptado','fn_planificacion_valida','Pedro pasa su planificación de aceptada → completada (el productor sí acepta primero; el técnico no).','Aceptado','secuencia','pedro.prod',
    f"UPDATE planificacion SET plan_estado = 'completada' WHERE usua_id_destinatario = {U('pedro.prod')}",'')
add('PE-15','B','Una planificación completada no admite más lotes','fn_planificacion_lote_valida','Sara intenta agregar el lote C a la planificación de Pedro (ya completada).','Rechazado: «Los lotes de una planificación no pendiente … están congelados»','falla','sara.super',
    f"INSERT INTO planificacion_lote SELECT plan_id, {LT('C')} FROM planificacion WHERE usua_id_destinatario = {U('pedro.prod')}",'congelados')
# ---- C
LECT = lambda ver, tobs='NULL', tram='NULL', ubic='NULL': f"SELECT pg_temp.sql_lectura({ver}, {tobs}, {tram}, {ubic})"
add('PE-16','C','La corrección de una lectura reemplaza a la original (vigente = versión 2)','v_lectura_vigente · RN-009','La trampa 3 se leyó con 4 moscas (versión 1) y se corrigió a 5 (versión 2). Consultar las lecturas vigentes por trampa.','Trampa 1 = 2 · Trampa 2 = 0 · Trampa 3 = 5','valor','',
    "SELECT string_agg(lect_especimenes::text, ',' ORDER BY tram_id) FROM v_lectura_vigente",'2,0,5')
add('PE-17','C','No se puede saltar una versión (de la 2 a la 4)','fn_registro_version_valida','Insertar una versión 4 de la lectura de la trampa 3.','Rechazado: «Versión 4 inválida … se esperaba 3»','falla','andres.tec','EXEC:'+LECT(4),'inválida')
add('PE-18','C','La hora observada no puede cambiar entre versiones','fn_registro_version_valida · RN-009','Insertar la versión 3 cambiando t_observacion.','Rechazado: «t_observacion es inmutable»','falla','andres.tec','EXEC:'+LECT(3, "'2026-09-09 08:00-05'::timestamptz"),'inmutable')
add('PE-19','C','Una corrección no puede mover la lectura a otra trampa/ubicación','fn_lectura_valida','Insertar la versión 3 de la lectura de la trampa 3 apuntando a la trampa 2.','Rechazado: «La ubicación … no es de la trampa …»','falla','andres.tec','EXEC:'+LECT(3, 'NULL', TR(2)),'no es de la trampa')
add('PE-20','C','Las lecturas no se modifican (solo inserción)','fn_bloquear_modificacion','Intentar UPDATE sobre una lectura.','Rechazado: «es de solo inserción (append-only)»','falla','andres.tec',"UPDATE lectura_trampa SET lect_especimenes = 99",'solo inserción')
add('PE-21','C','No se puede leer una trampa en una fecha en que la ubicación aún no existía','fn_lectura_valida','Visita del 15-ene-2026 y lectura de la trampa 1, cuya ubicación vigente empieza el 5-feb-2026.','Rechazado: «La ubicación no estaba vigente el día observado»','falla','andres.tec',
    f"""DO $x$ DECLARE r lectura_trampa; op bigint; vid uuid; BEGIN
  SELECT * INTO r FROM lectura_trampa WHERE lect_version = 1 AND tram_id = {TR(1)};
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (r.disp_id, gen_random_uuid(), r.usua_id, 'visita', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  INSERT INTO visita (disp_id, oper_id, usua_id, pred_id, ruta_id, visi_t_inicio_obs, visi_t_fin_obs, visi_t_captura)
    SELECT r.disp_id, op, r.usua_id, pred_id, ruta_id, '2026-01-15 08:00-05', '2026-01-15 09:00-05', '2026-01-15 20:00-05' FROM visita WHERE visi_id = r.visi_id RETURNING visi_id INTO vid;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (r.disp_id, gen_random_uuid(), r.usua_id, 'lectura_trampa', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  r.lect_id := gen_random_uuid(); r.lect_registro_id := gen_random_uuid(); r.lect_version := 1; r.visi_id := vid; r.oper_id := op;
  r.lect_t_observacion := '2026-01-15 08:30-05'; r.lect_t_captura := '2026-01-15 20:00-05';
  INSERT INTO lectura_trampa SELECT r.*; END $x$""",'no estaba vigente')
# ---- D
add('PE-22','D','MTD calculado a mano = moscas / (trampas × días)','Fórmula MTD = M / (T × D)','Lecturas válidas del periodo 1–14 sep: 2 + 0 + 5 = 7 moscas; 3 trampas; 7 días de exposición. MTD = 7 / (3 × 7) = 7/21 = 0,3333.','0.3333','valor','',"SELECT round(indi_valor, 4)::text FROM indice_mtd",'0.3333')
add('PE-23','D','Solo las lecturas oficiales, leídas y vigentes del lote y del periodo alimentan el MTD','fn_mtd_lectura_valida · RN-013/014','Contar las lecturas que devuelve fn_mtd_lectura_valida para el periodo de la demo (3 trampas leídas).','3','valor','',"SELECT count(*)::text FROM fn_mtd_lectura_valida((SELECT peri_id FROM periodo_trampeo))",'3')
add('PE-24','D','Sin umbral oficial el concepto queda «no_emitido»','UQQ-004 · RF-024','Consultar el concepto vigente del lote A.','no_emitido','valor','',"SELECT conc_resultado FROM v_concepto_vigente",'no_emitido')
add('PE-25','D','No se puede emitir «apto» sin umbral configurado','fn_concepto_valida','Intentar registrar una versión 2 del concepto con resultado «apto» (con norma) cuando el MTD no tiene umbral.','Rechazado: «No se puede emitir apto/no_apto sin umbral configurado»','falla','sara.super',
    "DO $x$ DECLARE n int; BEGIN INSERT INTO norma (norm_codigo, norm_titulo, norm_emisor) VALUES ('N-DEMO', 'Norma de prueba', 'Institución') RETURNING norm_id INTO n; INSERT INTO concepto_aptitud (lote_id, peri_id, indi_id, conc_version, conc_resultado, conc_fecha_efecto, norm_id, conc_motivo) SELECT lote_id, peri_id, indi_id, 2, 'apto', '2026-09-20', n, 'prueba' FROM concepto_aptitud LIMIT 1; END $x$",'sin umbral')
add('PE-26','D','La etapa fenológica se deriva de la fecha de plantación y la regla vigente','fn_etapa_derivada · RN-012','Lote A plantado el 1-mar-2025; al 10-sep-2026 han pasado 558 días. Regla «Cuajado» = 401–900 días.','Cuajado','valor','',f"SELECT feno_descripcion FROM fenologia WHERE feno_id = fn_etapa_derivada({LT('A')}, '2026-09-10')",'Cuajado')
add('PE-27','D','Se detecta la discrepancia entre lo que declara el productor y lo que observa el técnico','v_etapa_discrepancia · RN-012','Pedro declaró «Cuajado» (autorreporte) y Andrés observó «Floración» (inspección oficial) en el lote A.','1 fila: Cuajado vs Floración','valor','',"SELECT count(*)::text || ' ' || (SELECT feno_descripcion FROM fenologia WHERE feno_id = d.feno_declarada) || ' vs ' || (SELECT feno_descripcion FROM fenologia WHERE feno_id = d.feno_observada) FROM v_etapa_discrepancia d GROUP BY d.feno_declarada, d.feno_observada",'1 Cuajado vs Floración')
# ---- E
add('PE-28','E','La paridad del número de trampa depende del tipo (Jackson impar)','fn_trampa_valida · RN-005','Crear la trampa 54518-602-4 (número par) de tipo Jackson.','Rechazado: «no respeta la paridad»','falla','andres.tec',
    "INSERT INTO trampa (tram_codigo, tipt_id, atra_id, esta_id, tram_fecha_registro, tram_tecnico_registro_id) SELECT '54518-602-4', (SELECT tipt_id FROM tipo_trampa WHERE tipt_descripcion = 'Jackson'), (SELECT atra_id FROM atrayente LIMIT 1), (SELECT esta_id FROM estado_registro LIMIT 1), current_date, (SELECT tecn_id FROM tecnico LIMIT 1)",'paridad')
UB = lambda lon, lat, fecha, tram: f"INSERT INTO ubicacion_trampa (tram_id, pred_id, lote_id, ubic_fecha, tecn_id, vigi_id, ubic_long, ubic_lat) SELECT {tram}, {PRED1}, {LT('A')}, '{fecha}', (SELECT tecn_id FROM tecnico LIMIT 1), (SELECT vigi_id FROM vigilancia LIMIT 1), {lon}, {lat}"
add('PE-29','E','Las coordenadas deben caer dentro del rango del departamento','fn_ubicacion_trampa_valida · RN-006','Ubicar la trampa 1 en longitud -80,0 (Norte de Santander va de -73,6 a -72,0).','Rechazado: «fuera del rango del departamento»','falla','andres.tec',UB('-80.0','7.37','2026-03-01',TR(1)),'fuera del rango')
add('PE-30','E','Una trampa no puede estar en dos puestos a la vez (vigencias que se solapan)','EXCLUDE ubicacion_trampa','La trampa 1 ya está ubicada desde el 5-feb-2026 sin fecha fin. Registrar otra ubicación desde el 1-mar-2026 sin cerrar la anterior.','Rechazado por restricción de exclusión (SQLSTATE 23P01)','falla','andres.tec',UB('-72.6495','7.3705','2026-03-01',TR(1)),'SQLSTATE:23P01')
add('PE-31','E','Un punto GPS se asigna al lote que lo contiene','fn_lote_que_contiene','Punto (-72,6425; 7,3725) está en el cuadrante del lote B.','B','valor','',"SELECT l.lote_codigo FROM lote l WHERE l.lote_id IN (SELECT fn_lote_que_contiene(ST_SetSRID(ST_MakePoint(-72.6425, 7.3725), 4326)))",'B')
add('PE-32','E','Las 3 trampas caen dentro de la geometría del lote A','v_trampa_lote_vigente · RF-012','Contar las trampas vigentes cuyo punto está dentro del lote.','3','valor','',"SELECT count(*)::text FROM v_trampa_lote_vigente WHERE dentro_del_lote",'3')
add('PE-33','E','El código de ruta de 9 dígitos se compone del Divipola + registro de ruta','v_ruta_codigo_ica · RN-005','Departamento 54 + municipio 518 + ruta 0602.','545180602','valor','',"SELECT ruta_codigo_9 FROM v_ruta_codigo_ica",'545180602')
# ---- F
add('PE-34','F','La geometría de un lote no puede salirse del predio','fn_lote_geometria_valida · RF-084','Registrar una nueva versión de geometría del lote B desplazada fuera del predio.','Rechazado: «queda fuera del límite del predio»','falla','sara.super',
    f"INSERT INTO lote_geometria (lote_id, lotg_version, lotg_geom, lotg_vigente_desde) VALUES ({LT('B')}, 2, ST_GeomFromText('POLYGON((-72.5 7.3,-72.49 7.3,-72.49 7.31,-72.5 7.31,-72.5 7.3))', 4326), now())",'fuera del límite')
add('PE-35','F','La resolución de la retícula debe ser múltiplo de la distancia mínima entre trampas','fn_programa_valida · RI-002 / RN-004','Nuevo programa con distancia mínima 40 m sobre una retícula de 90 m (90 no es múltiplo de 40).','Rechazado: «debe ser múltiplo de la distancia mínima»','falla','sara.super',
    f"DO $x$ DECLARE r int; BEGIN INSERT INTO reticula (pred_id, reti_resolucion_m) VALUES ({PRED1}, 90) RETURNING reti_id INTO r; INSERT INTO programa_inspeccion (pred_id, prog_version, prog_vigente_desde, prog_periodo_lectura_dias, prog_distancia_min_trampas_m, reti_id) VALUES ({PRED1}, 2, '2026-10-01', 7, 40, r); END $x$",'múltiplo')
add('PE-36','F','Una retícula no cambia de resolución (se crea otra)','fn_reticula_inmutable','Intentar cambiar la resolución de 80 a 100 m.','Rechazado: «no se modifican; cree otra retícula»','falla','sara.super',"UPDATE reticula SET reti_resolucion_m = 100",'no se modifican')
# ---- G
add('PE-37','G','Se detecta la visita a un lote no asignado, sin bloquear el registro','v_visita_lote_sin_asignacion','Juan visitó el lote A el 11-sep sin tenerlo asignado; Andrés sí lo tenía.','1 fila: juan.tec','valor','',"SELECT count(*)::text || ' ' || string_agg(u.usua_usuario, ',') FROM v_visita_lote_sin_asignacion v JOIN usuario u USING (usua_id)",'1 juan.tec')
add('PE-38','G','De una visita solo cambian las columnas de revisión','fn_visita_integridad','Intentar cambiar la hora de captura de una visita.','Rechazado: «solo se pueden modificar las columnas de revisión»','falla','sara.super',"UPDATE visita SET visi_t_captura = visi_t_captura + interval '1 hour'",'solo se pueden modificar')
add('PE-39','G','La supervisora puede poner una visita en revisión','fn_visita_integridad','Sara marca la visita pendiente (la de Juan) «en_revision».','Aceptado','pasa','sara.super',
    f"UPDATE visita SET visi_estado_revision = 'en_revision', visi_revisada_por = {U('sara.super')}, visi_revisada_en = now() WHERE visi_estado_revision = 'pendiente'",'')
# ---- H
add('PE-40','H','La misma operación del celular enviada dos veces no se duplica (idempotencia)','operacion_sync UNIQUE (dispositivo, id_cliente)','Reenviar una operación con el mismo dispositivo y el mismo identificador de cliente.','Rechazado por llave única (SQLSTATE 23505)','falla','andres.tec',
    "INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura) SELECT disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura FROM operacion_sync LIMIT 1",'SQLSTATE:23505')
add('PE-41','H','El reloj de sincronización lo pone el servidor, no el celular','fn_registro_version_valida','Insertar una cosecha con t_sincronizacion = año 2000 y comprobar que quedó con la hora del servidor.','0 filas con fecha anterior a 2020','secuencia_valor','andres.tec',
    f"""DO $x$ DECLARE op bigint; d uuid; BEGIN
  SELECT disp_id INTO d FROM dispositivo LIMIT 1;
  INSERT INTO operacion_sync (disp_id, oper_cliente_id, usua_id, oper_entidad, oper_accion, oper_registro_id, oper_hash_contenido, oper_clasificacion, oper_t_captura)
    VALUES (d, gen_random_uuid(), {U('andres.tec')}, 'cosecha', 'crear', gen_random_uuid(), md5(random()::text) || md5(random()::text), 'alta_nueva', now()) RETURNING oper_id INTO op;
  INSERT INTO cosecha (cose_registro_id, lote_id, cose_fecha_esperada, cose_volumen_esperado, cose_volumen_uni_id, cose_linaje, usua_id, disp_id, oper_id, cose_t_observacion, cose_t_captura, cose_t_sincronizacion)
    VALUES (gen_random_uuid(), {LT('C')}, '2026-12-20', 100, (SELECT unid_id FROM unidad_medida WHERE unid_simbolo = 'kg'), 'inspeccion_oficial', {U('andres.tec')}, d, op, now(), now(), '2000-01-01'); END $x$""",
    "SELECT count(*)::text FROM cosecha WHERE cose_t_sincronizacion < '2020-01-01'|0")
# ---- I
add('PE-42','I','La bitácora no se borra','fn_bloquear_modificacion','Intentar DELETE sobre bitacora_auditoria.','Rechazado: «solo inserción»','falla','ana.admin',"DELETE FROM bitacora_auditoria",'solo inserción')
add('PE-43','I','La bitácora nunca guarda contraseñas','fn_auditar · RF-083','Buscar el texto «argon2id» (formato del hash) en el detalle de la bitácora.','0','valor','',"SELECT count(*)::text FROM bitacora_auditoria WHERE bita_detalle::text LIKE '%argon2id%'",'0')
add('PE-44','I','Un cambio en una tabla auditada queda registrado','fn_auditar · RF-083','Cambiar la dirección de la persona Pedro y contar los UPDATE de persona en la bitácora.','1','secuencia_valor','sara.super',"UPDATE persona SET pers_direccion = 'Vereda La Paz' WHERE pers_cc = 1010000005","SELECT count(*)::text FROM bitacora_auditoria WHERE bita_tabla = 'persona' AND bita_accion = 'UPDATE'|1")
add('PE-45','I','Un usuario de ámbito global (Administrador) no se asigna a un predio','fn_usuario_predio_valida','Asignar a ana.admin al predio DEMO-1.','Rechazado: «ámbito global»','falla','ana.admin',
    f"INSERT INTO usuario_predio (usua_id, pred_id, rol_id, usup_desde) VALUES ({U('ana.admin')}, {PRED1}, (SELECT rol_id FROM rol WHERE rol_codigo = 'AGRONOMO_SUPERVISOR'), current_date)",'ámbito global')
# ---- J
add('PE-46','J','El estado de un archivo solo avanza (almacenado no vuelve a pendiente)','fn_archivo_adjunto_valida','Intentar regresar el archivo de la evidencia de «almacenado» a «pendiente_contenido».','Rechazado: «solo avanza desde pendiente_contenido»','falla','andres.tec',"UPDATE archivo_adjunto SET arch_estado = 'pendiente_contenido'",'solo avanza')
add('PE-47','J','La identidad de un archivo (hash) no se modifica','fn_archivo_adjunto_valida','Intentar cambiar el hash SHA-256 del archivo.','Rechazado: «La identidad … no se modifica»','falla','andres.tec',"UPDATE archivo_adjunto SET arch_hash_sha256 = repeat('0', 64)",'identidad')
add('PE-48','J','Un aviso se marca leído una sola vez','fn_notificacion_valida','Andrés marca su aviso como leído, y luego intenta marcarlo con otra hora.','Primero aceptado; luego rechazado: «ya fue leída»','secuencia_falla','andres.tec',
    f"UPDATE notificacion SET noti_leida_en = now() WHERE usua_id = {U('andres.tec')}",f"UPDATE notificacion SET noti_leida_en = now() + interval '1 second' WHERE usua_id = {U('andres.tec')}|ya fue leída")
add('PE-49','J','El contenido de un aviso no se edita','fn_notificacion_valida','Intentar cambiar el título de un aviso de Juan.','Rechazado: «no se modifica»','falla','juan.tec',f"UPDATE notificacion SET noti_titulo = 'otro' WHERE usua_id = {U('juan.tec')}",'no se modifica')

SQLHEAD = r"""-- =====================================================================
-- SIGAT v6 - PRUEBAS DE ESCRITORIO EJECUTABLES (__N__ escenarios)
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

"""
sql = [SQLHEAD.replace('__N__', str(len(S)))]
for (i, g, t, regla, pasos, esp, tipo, actor, sent, clave) in S:
    q = lambda s: "$q$" + s + "$q$"
    if tipo == 'valor':
        sql.append(f"SELECT pg_temp.pe_valor('{i}', {q(t)}, {q(sent)}, {q(clave)});")
    elif tipo == 'falla':
        if sent.startswith('EXEC:'):
            sql.append(f"DO $do$ BEGIN PERFORM pg_temp.pe_falla('{i}', {q(t)}, '{actor}', (SELECT * FROM ({sent[5:]}) z), {q(clave)}); END $do$;")
        else:
            sql.append(f"SELECT pg_temp.pe_falla('{i}', {q(t)}, '{actor}', {q(sent)}, {q(clave)});")
    elif tipo == 'pasa':
        sql.append(f"SELECT pg_temp.pe_pasa('{i}', {q(t)}, '{actor}', {q(sent)});")
    elif tipo == 'secuencia':   # pasa y luego el siguiente escenario prueba el efecto
        sql.append(f"SELECT pg_temp.pe_pasa('{i}', {q(t)}, '{actor}', {q(sent)});")
    elif tipo == 'secuencia_valor':
        cons, esperado = clave.split('|')
        sql.append(f"SELECT pg_temp.pe_pasa('{i}.a', {q(t + ' (paso 1)')}, '{actor}', {q(sent)});")
        sql.append(f"SELECT pg_temp.pe_valor('{i}.b', {q(t + ' (paso 2)')}, {q(cons)}, {q(esperado)});")
    elif tipo == 'secuencia_falla':
        seg, esperado = clave.split('|')
        sql.append(f"SELECT pg_temp.pe_pasa('{i}.a', {q(t + ' (paso 1)')}, '{actor}', {q(sent)});")
        sql.append(f"SELECT pg_temp.pe_falla('{i}.b', {q(t + ' (paso 2)')}, '{actor}', {q(seg)}, {q(esperado)});")
sql.append(r"""
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
""")
w('pruebas_escritorio/PE_ejecutable.sql', "\n".join(sql))
w('pruebas_escritorio/ejecutar_pruebas_escritorio.sh', """#!/bin/bash
# Carga la base de demostración y corre las pruebas de escritorio.  Uso: ./ejecutar_pruebas_escritorio.sh <cadena de conexión psql>
# ATENCIÓN: usar una base de PRUEBA vacía (instala el esquema y los datos de demo).
set -e
cd "$(dirname "$0")/.."
CONN="${1:?Indique la cadena de conexión de psql (base de prueba)}"
for f in sql/01_esquema_completo.sql sql/02_catalogos_basicos.sql sql/03_vistas.sql sql/04_funciones.sql sql/05_datos_demo.sql; do
  psql "$CONN" -X -q -v ON_ERROR_STOP=1 -f "$f" >/dev/null
done
psql "$CONN" -X -f pruebas_escritorio/PE_ejecutable.sql
""")
os.chmod(os.path.join(OUT, 'pruebas_escritorio/ejecutar_pruebas_escritorio.sh'), 0o755)

# ---------------- documento ----------------
md = ["""# Pruebas de escritorio · SIGAT v6

Una **prueba de escritorio** es seguir un caso con papel y lápiz: se parte de datos conocidos, se aplica la regla a mano, se anota qué *debería* pasar y después se compara con lo que la base hace de verdad. Este documento tiene **%d escenarios** sobre los datos de demostración (`sql/05_datos_demo.sql`); cada uno dice la regla que prueba, los pasos, el resultado esperado y el resultado obtenido en la última ejecución. El archivo `PE_ejecutable.sql` los corre todos de una vez (y no deja rastro: termina en ROLLBACK).

## Los datos de partida (la «hoja de trabajo»)

| Persona / usuario | Rol | Qué hace en la demo |
|---|---|---|
| Ana (`ana.admin`) | Administrador (ámbito global) | Ve todo; no se asigna a predios |
| Sara (`sara.super`) | Agrónomo/Supervisor | Crea planificaciones, revisa visitas; acceso a los dos predios |
| Andrés (`andres.tec`) | Técnico | Tiene asignados los lotes **A y C** (1–30 sep 2026) |
| Juan (`juan.tec`) | Técnico | Tiene asignados los lotes **B y D** |
| Pedro (`pedro.prod`) | Productor | Dueño de «Finca El Mirador» (lotes A, B, C, D) |
| Marta (`marta.prod`) | Productora | Dueña de «Finca La Esperanza» (lote E) |

**Lo que pasó en el campo:** el 10-sep-2026 Andrés visitó el lote A y leyó 3 trampas (54518-602-1 Jackson → 2 moscas; 54518-602-2 McPhail → 0; 54518-602-3 Jackson → 4, corregida después a **5**). Juan visitó el lote A el 11-sep sin tenerlo asignado. El periodo 1–14 sep se cerró con MTD = 7 / (3 × 7) = **0,3333**. No hay umbral oficial (UQQ-004), por eso el concepto es «no_emitido».

**Cómo se lee cada escenario:** *Esperado* es lo que usted debería predecir antes de mirar; *Obtenido* es lo que respondió la base en la última ejecución; el sello **OK** significa que coinciden.

> Los escenarios se ejecutan **en este orden** y algunos dependen del anterior (p. ej. PE-12 completa la planificación de Andrés y PE-13 comprueba el efecto).
""" % len(S)]
cur = None
for (i, g, t, regla, pasos, esp, tipo, actor, sent, clave) in S:
    if g != cur:
        md.append(f"\n## {G[g]}\n"); cur = g
    if tipo in ('secuencia_valor', 'secuencia_falla'):
        r1 = RES.get(i + '.a'); r2 = RES.get(i + '.b')
        est = (' · '.join(x[0] for x in (r1, r2) if x)) if (r1 and r2) else '—'
        obt = ' → '.join(x[2] for x in (r1, r2) if x) or '—'
    else:
        r = RES.get(i); est = r[0] if r else '—'; obt = r[2] if r else '—'
    sello = 'OK' if est in ('OK', 'OK · OK') else ('—' if est == '—' else 'FALLA')
    md.append(f"### {i} · {t}\n")
    md.append(f"- **Regla que se prueba:** {regla}\n- **Quién:** {actor if actor else 'consulta de lectura'}\n- **Pasos:** {pasos}\n- **Esperado:** {esp}\n- **Obtenido (última ejecución):** {obt} → **{sello}**\n")
w('pruebas_escritorio/PE_escenarios.md', "\n".join(md))
print('escenarios:', len(S))
