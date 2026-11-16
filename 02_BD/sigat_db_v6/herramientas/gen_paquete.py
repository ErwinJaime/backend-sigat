#!/usr/bin/env python3
"""Genera el paquete SIGAT v6 a partir de sigat_v6.dbml (+ reglas CHECK y descripciones del documento v5).
Uso: gen_paquete.py <sigat_v6.dbml> <meta.json> <old.md> <directorio_salida>
"""
import re, sys, os, json, collections, html

DBML, META, OLDMD, OUT = sys.argv[1:5]
text = open(DBML, encoding='utf-8').read()
meta = json.load(open(META, encoding='utf-8'))
old = open(OLDMD, encoding='utf-8').read()
colmap = meta['colmap']                       # tabla -> {col_vieja: col_nueva}
glob = {}
for t, d in colmap.items():
    for o, n in d.items():
        glob.setdefault(o, n)
tok_re = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, glob), key=len, reverse=True)) + r')\b')
def renombrar(s, tabla=None):
    m = colmap.get(tabla, {}) if tabla else {}
    def f(mm):
        w = mm.group(1)
        return m.get(w, glob[w])
    return tok_re.sub(f, s)

# ------------------------------------------------------------------ parseo del DBML
T = collections.OrderedDict()
refs = []
groups = collections.OrderedDict()
cur = None; in_idx = False; grp = None
for ln in text.split('\n'):
    m = re.match(r'^Table (\w+) \{', ln)
    if m:
        cur = m.group(1); T[cur] = {'cols': [], 'pk': [], 'uniq': [], 'idx_pk': None}; in_idx = False; continue
    m = re.match(r'^TableGroup (\w+) \{', ln)
    if m:
        grp = m.group(1); groups[grp] = []; continue
    if grp and re.match(r'^\s+\w+$', ln):
        groups[grp].append(ln.strip()); continue
    if ln.startswith('}'):
        cur = None; grp = None; continue
    if cur is None:
        m = re.match(r'^Ref: (.+?) > (.+)$', ln)
        if m:
            def side(s):
                a, b = s.strip().split('.', 1)
                cols = [c.strip() for c in b.strip('()').split(',')]
                return a, cols
            refs.append((side(m.group(1)), side(m.group(2))))
        continue
    if ln.strip() == 'indexes {':
        in_idx = True; continue
    if in_idx:
        if ln.strip() == '}':
            in_idx = False; continue
        m = re.match(r'^\s+\(([^)]*)\) \[(.*)\]$', ln)
        cols = [c.strip() for c in m.group(1).split(',')]
        if 'pk' in m.group(2):
            T[cur]['pk'] = cols
        else:
            T[cur]['uniq'].append(cols)
        continue
    m = re.match(r'^\s+(\w+) ("[^"]+"|\S+) \[(.*)\]\s*$', ln)
    if m:
        name, typ, attrs = m.groups()
        nm = re.search(r"note: '(.*)'\s*$", attrs)
        note = nm.group(1) if nm else ''
        a = attrs[:nm.start()] if nm else attrs
        dm = re.search(r"default: `(.*?)`", a)
        c = {'name': name, 'type': typ.strip('"'), 'pk': bool(re.search(r'(^|, )pk(,|$)', a)),
             'notnull': 'not null' in a, 'unique': bool(re.search(r'(^|, )unique(,|$)', a)),
             'inc': 'increment' in a, 'default': dm.group(1) if dm else None, 'note': note}
        T[cur]['cols'].append(c)
        if c['pk']: T[cur]['pk'].append(name)
        if c['unique']: T[cur]['uniq'].append([name])
        continue

area_of = {}
area_name = {}
for g, ts in groups.items():
    num = int(g.split('_')[0]); area_name[num] = g.split('_', 1)[1].replace('_', ' ')
    for t in ts: area_of[t] = num

# ------------------------------------------------------------------ descripciones y reglas del documento v5
purposes = {}; checks = collections.defaultdict(list); audited = set()
parts = re.split(r'\n### `(\w+)`\n', old)
for i in range(1, len(parts), 2):
    n, b = parts[i], parts[i + 1]
    m = re.search(r'\*\*Para qué sirve\.\*\*\s*(.*?)\n\n', b, re.S)
    if m: purposes[n] = m.group(1).strip()
    for nm_, ex in re.findall(r'- `(\w+)`: `(.*?)`(?= - `\w+`: `|\n|$)', b):
        checks[n].append((nm_, ex))
    if 'fn_auditar' in b: audited.add(n)

def limpiar_ica(s):
    s = re.sub(r'\(formato MF_UBI «Registro de la ruta», p\. ej\. 602\)', '(p. ej. 602)', s)
    s = s.replace('Catálogo con los códigos del formato MF_CAP del ICA (esm_codigo_ica). ', 'Catálogo con códigos numéricos (espm_codigo). ')
    s = s.replace('que el ICA registra en el mismo catálogo pero no son especies', 'que se registran en el mismo catálogo pero no son especies')
    s = re.sub(r' El «Código Ruta» de 9 dígitos.*?\(ver v_ruta_codigo_ica\)\.', '', s)
    s = s.replace('código interno ICA del predio', 'código interno del predio')
    s = s.replace('identificada por su código ICA (RN-005: Divipola(5)-ruta o predio interno-número)', 'identificada por su código impreso (RN-005: Divipola(5)-ruta o predio interno-número)')
    s = s.replace('código ICA', 'código').replace('Código ICA', 'Código')
    s = re.sub(r'\bICA\b', '', s)
    s = re.sub(r'\s+([.,;])', r'\1', s)
    return re.sub(r'  +', ' ', s).strip()

def md_a_texto(s):
    s = s.replace('\\[', '[').replace('\\]', ']').replace('\\|', '|').replace('\\_', '_').replace('--', '–')
    return s


PURPOSE_OVERRIDE = {
 'especie_mosca': "Resultado de determinación taxonómica de mosca de la fruta (RN-015). espm_codigo es un código numérico opcional del catálogo. espm_tipo distingue especie, género sin especie (p. ej. Anastrepha sp.) y los resultados especiales «No captura» y «No Tephritidae», que se registran en el mismo catálogo pero no son especies.",
 'estimacion_produccion': "RF-030: producción esperada de un lote = número de árboles × rendimiento por árbol. El total NO se almacena: es derivado.",
 'etapa_declarada': "RF-044 / RN-012: etapa fenológica DECLARADA por el productor o el técnico, con fecha, valor y autor. La etapa derivada se calcula (fenologia_regla + fecha de plantación) y se compara con esta para revisión del Agrónomo.",
 'evidencia': "RDD-011 / RF-033: fotografía que respalda una lectura de trampa o un hallazgo (exactamente uno). Fecha de captura y hash viven en archivo_adjunto; aquí la georreferenciación y la observación. Solo inserción: la evidencia queda ligada a la versión de la lectura vigente al capturarla.",
 'planificacion': "Asignación de lotes a un técnico o planeación de actividades para un productor, creada por un Agrónomo/Supervisor. El tipo de destino (técnico/productor) no se guarda: se deduce del rol del destinatario. Productor: pendiente → aceptada | rechazada (con motivo); aceptada → completada. Técnico: no acepta ni rechaza; la asignación queda vigente (pendiente) y pasa a completada.",
 'predio': "Predio inscrito (RDD-001). pers_cc = productor responsable. pred_codigo = código interno del predio (parte del código de trampa cuando no hay ruta, RN-005). El número de lotes no se almacena: se cuenta.",
 'ruta': "Ruta de inspección de un centro de acopio. ruta_codigo = registro de la ruta (p. ej. 602) que forma parte del código de trampa (RN-005).",
 'ubicacion_trampa': "Asignación y ubicación de una trampa en un lote durante un intervalo [ubic_fecha, ubic_fecha_fin). Es la asignación EXPLÍCITA trampa–lote exigida por RN-013/RF-013 y conserva el historial de reubicaciones. Una trampa no puede tener dos ubicaciones simultáneas (EXCLUDE). lote_id es nulo solo en filas ubic_origen=legado pendientes de asignar.",
 'usuario_predio': "RF-002: predios a los que un usuario tiene acceso, con vigencia. El rol es ÚNICO por usuario (usuario.rol_id): esta tabla no repite el rol, solo dice dónde aplica. No puede tener dos asignaciones solapadas sobre el mismo predio. Solo admite usuarios con rol de ámbito predio (el Administrador es global). El alcance del Agrónomo/Supervisor es pendiente institucional.",
}

def purpose(t):
    if t in PURPOSE_OVERRIDE: return PURPOSE_OVERRIDE[t]
    p = purposes.get(t, '')
    p = renombrar(md_a_texto(p), t)
    p = limpiar_ica(p)
    p = re.sub(r'\s*\(?(?:ver|con la vista|se obtiene con la vista|vista) v_\w+[^.]*\.?', '.', p)
    p = re.sub(r'\.\.+', '.', p)
    return p

# ------------------------------------------------------------------ SQL
PRE = {t: d['prefix'] for t, d in meta['tables'].items()}
GEN = {
 ('indice_mtd', 'indi_valor'): "round(indi_moscas::numeric / NULLIF(indi_trampas * indi_dias_exposicion, 0), 6)",
 ('ubicacion_trampa', 'ubic_geom'): "ST_SetSRID(ST_MakePoint(ubic_long::float8, ubic_lat::float8), 4326)",
 ('trampa', 'tram_numero'): "(substring(tram_codigo from '([0-9]+)$'))::integer",
 ('lote_geometria', 'lotg_area_m2'): "ST_Area(lotg_geom::geography)",
}
EXCLUDES = {
 'lote_geometria': ("lotg_vigencia_sin_solape", "lote_id WITH =, tstzrange(lotg_vigente_desde, lotg_vigente_hasta) WITH &&"),
 'ubicacion_trampa': ("ubicacion_trampa_sin_solape", "tram_id WITH =, daterange(ubic_fecha, ubic_fecha_fin) WITH &&"),
 'usuario_predio': ("usuario_predio_sin_solape", "usua_id WITH =, pred_id WITH =, daterange(usup_desde, usup_hasta) WITH &&"),
 'periodo_trampeo': ("periodo_trampeo_sin_solape", "lote_id WITH =, vigi_id WITH =, daterange(peri_inicio, peri_fin, '[]') WITH &&"),
 'programa_inspeccion': ("programa_inspeccion_sin_solape", "pred_id WITH =, daterange(prog_vigente_desde, prog_vigente_hasta) WITH &&"),
}
APPEND_ONLY = ['aplicacion_fitosanitaria', 'bitacora_auditoria', 'bpa_verificacion', 'concepto_aptitud', 'cosecha',
               'estimacion_produccion', 'etapa_declarada', 'evidencia', 'hallazgo', 'indice_mtd_lectura', 'indice_mtd',
               'lectura_trampa', 'manejo_agronomico', 'operacion_sync', 'recepcion_sync', 'visita_lote']
VERSIONED = {t: PRE[t] for t, d in T.items() if all(any(c['name'] == PRE[t] + s for c in d['cols']) for s in ('_registro_id', '_version', '_t_observacion', '_t_sincronizacion'))}
SYNC_ONLY = {'visita': 'visi'}

def sqltype(c):
    ty = c['type']
    if ty.startswith('geometry'): return ty
    if ty == 'float8': return 'double precision'
    if ty == 'integer' and c['inc']: return 'integer GENERATED BY DEFAULT AS IDENTITY'
    if ty == 'bigint' and c['inc']: return 'bigint GENERATED BY DEFAULT AS IDENTITY'
    if ty == 'varchar': return 'varchar'
    if ty == 'character(2)' or ty.startswith('character('): return ty
    return ty

def q(s): return "'" + s.replace("'", "''") + "'"

import hashlib
def corto(n):
    if len(n) <= 63: return n
    return n[:54] + '_' + hashlib.md5(n.encode()).hexdigest()[:8]
def ukname(t, u): return corto(f"{t}_{'_'.join(u)}_key")
def fkname(child, cols): return corto(f"{child}_{'_'.join(cols)}_fkey")

def ddl_tabla(t):
    d = T[t]; lines = []
    for c in d['cols']:
        if (t, c['name']) in GEN:
            lines.append(f"  {c['name']} {c['type'] if not c['type'].startswith('geometry') else c['type']} GENERATED ALWAYS AS ({GEN[(t, c['name'])]}) STORED")
            continue
        s = f"  {c['name']} {sqltype(c)}"
        if c['default'] is not None and not c['inc']: s += f" DEFAULT {c['default']}"
        if c['notnull'] or c['pk']: s += " NOT NULL"
        lines.append(s)
    if d['pk']: lines.append(f"  CONSTRAINT {t}_pkey PRIMARY KEY ({', '.join(d['pk'])})")
    seen = set()
    for u in d['uniq']:
        k = tuple(u)
        if k in seen: continue
        seen.add(k)
        lines.append(f"  CONSTRAINT {ukname(t, u)} UNIQUE ({', '.join(u)})")
    return f"CREATE TABLE sigat.{t} (\n" + ",\n".join(lines) + "\n);"


CHECK_FIX = {
 ('escenario_trampeo','escenario_trampeo_rango_defecto_valido'): "((esce_mtd_desde_defecto IS NULL OR esce_mtd_desde_defecto >= 0) AND (esce_mtd_hasta_defecto IS NULL OR esce_mtd_hasta_defecto >= 0) AND (esce_mtd_desde_defecto IS NULL OR esce_mtd_hasta_defecto IS NULL OR esce_mtd_desde_defecto <= esce_mtd_hasta_defecto))",
 ('usuario','usuario_credencial_coherente'): "((usua_proveedor = 'local' AND usua_sujeto_externo IS NULL AND (usua_contrasena IS NOT NULL OR usua_requiere_reinicio)) OR (usua_proveedor = 'externo' AND usua_sujeto_externo IS NOT NULL AND usua_contrasena IS NULL))",
 ('lote','lote_fechas_validas'): "((lote_fecha_actualizacion IS NULL OR lote_fecha_actualizacion >= lote_fecha_registro) AND (lote_fecha_baja IS NULL OR lote_fecha_baja >= lote_fecha_registro))",
 ('operacion_sync','operacion_sync_entidad_valida'): "(oper_entidad IN ('visita','lectura_trampa','aplicacion_fitosanitaria','cosecha','etapa_declarada','hallazgo','bpa_verificacion','manejo_agronomico','estimacion_produccion'))",
 ('indice_mtd','indice_mtd_contraste_coherente'): "((indi_resultado_contraste = 'sin_umbral' AND indi_umbral_aplicado IS NULL AND norm_id IS NULL) OR (indi_resultado_contraste <> 'sin_umbral' AND indi_umbral_aplicado IS NOT NULL AND norm_id IS NOT NULL AND indi_valor IS NOT NULL))",
 ('archivo_adjunto','archivo_adjunto_estado_coherente'): "((arch_estado = 'pendiente_contenido' AND arch_ref_almacenamiento IS NULL AND arch_t_almacenado IS NULL AND arch_motivo_rechazo IS NULL) OR (arch_estado = 'almacenado' AND arch_ref_almacenamiento IS NOT NULL AND arch_t_almacenado IS NOT NULL AND arch_motivo_rechazo IS NULL) OR (arch_estado = 'rechazado' AND arch_motivo_rechazo IS NOT NULL))",
 ('archivo_adjunto','archivo_adjunto_mime_valido'): "(arch_mime IN ('image/jpeg','image/png','image/webp','application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'))",
}

def checks_de(t):
    out = []
    for nm_, ex in checks.get(t, []):
        nm2 = nm_.replace('_ica', '')
        ex2 = CHECK_FIX.get((t, nm_)) or renombrar(ex.replace('\\|', '|'), t)
        if ex2.count('(') != ex2.count(')'):
            print('AVISO regla truncada omitida', t, nm_); continue
        out.append((nm2, ex2))
    return out

def build_sql():
    o = []
    o.append("""-- =====================================================================
-- SIGAT v6 - ESQUEMA COMPLETO (PostgreSQL 16 + PostGIS)
-- Generado desde sigat_v6.dbml. Prefijo de columnas = primeras 4 letras de la tabla.
-- Crea el esquema "sigat" desde cero. NO contiene datos.
-- Ejecutar: psql -v ON_ERROR_STOP=1 -f 01_esquema_completo.sql
-- Requisitos: PostgreSQL 16 + PostGIS >= 3.3 + btree_gist (contrib).
-- =====================================================================

-- ##### 00. Base: extensiones, esquema y dominios
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;      -- EXCLUDE con "=" + rangos

CREATE SCHEMA IF NOT EXISTS sigat;
COMMENT ON SCHEMA sigat IS 'SIGAT - Sistema de gestión y monitoreo de cultivos de durazno (vigilancia de Ceratitis capitata). Esquema v6.';
SET search_path = sigat, public;

CREATE DOMAIN sigat.d_linaje AS text
  CHECK (VALUE IN ('inspeccion_oficial','autorreporte'));
COMMENT ON DOMAIN sigat.d_linaje IS 'RN-014: origen del dato. inspeccion_oficial = capturado por técnico (alimenta el MTD); autorreporte = capturado por el productor.';

CREATE DOMAIN sigat.d_clasificacion_operacion AS text
  CHECK (VALUE IN ('alta_nueva','alta_retroactiva','correccion','revisar','rechazada'));
COMMENT ON DOMAIN sigat.d_clasificacion_operacion IS 'ADR-04: clasificación que el servidor da a cada operación de sincronización recibida.';

CREATE DOMAIN sigat.d_estado_revision AS text
  CHECK (VALUE IN ('pendiente','en_revision','aceptado'));
COMMENT ON DOMAIN sigat.d_estado_revision IS 'Revisión del Agrónomo/Supervisor sobre una visita (origen: frontend; pendiente de confirmar como regla institucional).';

CREATE DOMAIN sigat.d_resultado_contraste AS text
  CHECK (VALUE IN ('por_debajo_umbral','igual_o_superior_umbral','sin_umbral'));
COMMENT ON DOMAIN sigat.d_resultado_contraste IS 'RF-024: resultado de contrastar el MTD con el umbral vigente. sin_umbral = no hay umbral configurado (UQQ-004): no se emite concepto.';
""")
    o.append("-- ##### 10. Tablas (74)\n")
    for g, ts in groups.items():
        num = int(g.split('_')[0])
        o.append(f"-- ---- Área {num}: {area_name[num]}")
        for t in sorted(ts):
            o.append(ddl_tabla(t) + "\n")
    o.append("-- ##### 20. Restricciones CHECK y de no-solapamiento (EXCLUDE)\n")
    for t in T:
        for nm_, ex in checks_de(t):
            o.append(f"ALTER TABLE sigat.{t} ADD CONSTRAINT {nm_} CHECK {ex};")
        if t in EXCLUDES:
            nm_, ex = EXCLUDES[t]
            o.append(f"ALTER TABLE sigat.{t} ADD CONSTRAINT {nm_} EXCLUDE USING gist ({ex});")
    o.append("\n-- ##### 30. Llaves foráneas (%d)\n" % len(refs))
    for (ct, cc), (pt, pc) in refs:
        o.append(f"ALTER TABLE sigat.{ct} ADD CONSTRAINT {fkname(ct, cc)} FOREIGN KEY ({', '.join(cc)}) REFERENCES sigat.{pt} ({', '.join(pc)});")
    o.append("\n-- ##### 40. Índices (llaves foráneas sin índice y espaciales)\n")
    for stmt in indices_extra():
        o.append(stmt[1])
    o.append("\n-- ##### 50. Funciones y disparadores\n")
    o.append(funciones_sql())
    o.append("\n-- ##### 90. Comentarios de tablas y columnas\n")
    for t, d in T.items():
        p = purpose(t)
        if p: o.append(f"COMMENT ON TABLE sigat.{t} IS {q(p)};")
        for c in d['cols']:
            if c['note']: o.append(f"COMMENT ON COLUMN sigat.{t}.{c['name']} IS {q(c['note'])};")
    return "\n".join(o) + "\n"

def covered(t, cols):
    """¿Las columnas son prefijo de la PK, de algún UNIQUE?"""
    d = T[t]
    cands = [d['pk']] + d['uniq']
    return any(len(c) >= len(cols) and c[:len(cols)] == list(cols) for c in cands)

def indices_extra():
    res = []; seen = set()
    for (ct, cc), _ in refs:
        if covered(ct, cc): continue
        k = (ct, tuple(cc))
        if k in seen: continue
        seen.add(k)
        nm_ = corto(f"ix_{ct}_{'_'.join(cc)}")
        res.append((nm_, f"CREATE INDEX {nm_} ON sigat.{ct} ({', '.join(cc)});", ct, cc, 'FK'))
    for t, d in T.items():
        for c in d['cols']:
            if c['type'].startswith('geometry'):
                nm_ = corto(f"ix_{t}_{c['name']}_gist")
                res.append((nm_, f"CREATE INDEX {nm_} ON sigat.{t} USING gist ({c['name']});", t, [c['name']], 'GiST'))
    return res

def funciones_sql():
    f = []
    f.append("""CREATE FUNCTION sigat.fn_usuario_actual() RETURNS integer
LANGUAGE sql STABLE SET search_path = sigat, public AS $$
  SELECT NULLIF(current_setting('sigat.usuario_actual', true), '')::integer
$$;
COMMENT ON FUNCTION sigat.fn_usuario_actual() IS 'Identificador usua_id del actor de la sesión, tomado del parámetro de sesión sigat.usuario_actual (lo fija la capa de aplicación con SET LOCAL).';

CREATE FUNCTION sigat.fn_bloquear_modificacion() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
BEGIN
  RAISE EXCEPTION 'La tabla %.% es de solo inserción (append-only): % no permitido. Para corregir un dato inserte una nueva versión.',
        TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP USING ERRCODE = 'integrity_constraint_violation';
END $$;
COMMENT ON FUNCTION sigat.fn_bloquear_modificacion() IS 'Trigger BEFORE UPDATE/DELETE para tablas de solo inserción (mediciones versionadas y bitácora).';

CREATE FUNCTION sigat.fn_bloquear_truncate() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
BEGIN
  RAISE EXCEPTION 'TRUNCATE no permitido en la tabla de solo inserción %.%', TG_TABLE_SCHEMA, TG_TABLE_NAME
        USING ERRCODE = 'integrity_constraint_violation';
END $$;
COMMENT ON FUNCTION sigat.fn_bloquear_truncate() IS 'Trigger BEFORE TRUNCATE: impide vaciar las tablas de solo inserción.';

-- Versionado append-only: TG_ARGV[0] = prefijo de 4 letras de la tabla.
CREATE FUNCTION sigat.fn_registro_version_valida() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
DECLARE
  p text := TG_ARGV[0];
  n jsonb := to_jsonb(NEW);
  mx integer; t0 timestamptz;
BEGIN
  EXECUTE format('SELECT coalesce(max(%1$s_version), 0) FROM sigat.%2$I WHERE %1$s_registro_id = $1', p, TG_TABLE_NAME)
     INTO mx USING (n ->> (p || '_registro_id'))::uuid;
  IF (n ->> (p || '_version'))::integer <> mx + 1 THEN
    RAISE EXCEPTION 'Versión % inválida para el registro % de %: se esperaba %',
      n ->> (p || '_version'), n ->> (p || '_registro_id'), TG_TABLE_NAME, mx + 1
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  IF mx >= 1 THEN
    EXECUTE format('SELECT %1$s_t_observacion FROM sigat.%2$I WHERE %1$s_registro_id = $1 AND %1$s_version = 1', p, TG_TABLE_NAME)
       INTO t0 USING (n ->> (p || '_registro_id'))::uuid;
    IF (n ->> (p || '_t_observacion'))::timestamptz <> t0 THEN
      RAISE EXCEPTION 't_observacion es inmutable entre versiones (RN-009) en %', TG_TABLE_NAME
        USING ERRCODE = 'integrity_constraint_violation';
    END IF;
  END IF;
  -- reloj del servidor: el cliente no controla t_sincronizacion
  NEW := jsonb_populate_record(NEW, jsonb_build_object(p || '_t_sincronizacion', now()));
  RETURN NEW;
END $$;
COMMENT ON FUNCTION sigat.fn_registro_version_valida() IS 'Garantiza versionado append-only coherente (1, 2, 3…), t_observacion inmutable y fija t_sincronizacion con el reloj del servidor.';

CREATE FUNCTION sigat.fn_marcar_sincronizacion() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
BEGIN
  NEW := jsonb_populate_record(NEW, jsonb_build_object(TG_ARGV[0] || '_t_sincronizacion', now()));
  RETURN NEW;
END $$;
COMMENT ON FUNCTION sigat.fn_marcar_sincronizacion() IS 'Fija t_sincronizacion con el reloj del servidor (TG_ARGV[0] = prefijo de la tabla).';

CREATE FUNCTION sigat.fn_visita_integridad() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'Las visitas no se borran' USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['visi_estado_revision','visi_motivo_revision','visi_revisada_por','visi_revisada_en'])
     <> (to_jsonb(OLD) - ARRAY['visi_estado_revision','visi_motivo_revision','visi_revisada_por','visi_revisada_en']) THEN
    RAISE EXCEPTION 'En una visita solo se pueden modificar las columnas de revisión' USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  RETURN NEW;
END $$;
COMMENT ON FUNCTION sigat.fn_visita_integridad() IS 'Visita: no se borra y solo se modifican las columnas de revisión del Agrónomo/Supervisor.';

CREATE FUNCTION sigat.fn_auditar() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = sigat, public AS $$
DECLARE rec jsonb; pk text := TG_ARGV[0]; det jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN rec := to_jsonb(OLD); ELSE rec := to_jsonb(NEW); END IF;
  IF TG_OP = 'UPDATE' THEN
    det := jsonb_build_object('antes', to_jsonb(OLD) - 'usua_contrasena', 'despues', to_jsonb(NEW) - 'usua_contrasena');
  ELSE
    det := rec - 'usua_contrasena';
  END IF;
  INSERT INTO sigat.bitacora_auditoria (bita_tabla, bita_registro, bita_accion, bita_detalle, usua_id)
  VALUES (TG_TABLE_NAME, rec ->> pk, TG_OP, det, sigat.fn_usuario_actual());
  RETURN NULL;
END $$;
CREATE FUNCTION sigat.fn_trampa_valida() RETURNS trigger
LANGUAGE plpgsql SET search_path = sigat, public AS $$
DECLARE par text; num integer;
BEGIN
  SELECT tipt_paridad INTO par FROM sigat.tipo_trampa WHERE tipt_id = NEW.tipt_id;
  num := (substring(NEW.tram_codigo from '([0-9]+)$'))::integer;   -- la columna generada aún no existe en un BEFORE
  IF par IS NOT NULL AND num IS NOT NULL
     AND ((par = 'impar' AND num % 2 = 0) OR (par = 'par' AND num % 2 = 1)) THEN
    RAISE EXCEPTION 'El número de trampa % no respeta la paridad (%) de su tipo (RN-005)', num, par
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;
  RETURN NEW;
END $$;
COMMENT ON FUNCTION sigat.fn_trampa_valida() IS 'RN-005: el número del código de la trampa debe respetar la paridad del tipo (Jackson impar, McPhail par).';

COMMENT ON FUNCTION sigat.fn_auditar() IS 'Trigger AFTER genérico que escribe en bitacora_auditoria (RF-083). Argumento: columna de la clave primaria. Nunca guarda contraseñas.';
""")
    for t in APPEND_ONLY:
        f.append(f"CREATE TRIGGER trg_{t}_ro BEFORE UPDATE OR DELETE ON sigat.{t} FOR EACH ROW EXECUTE FUNCTION sigat.fn_bloquear_modificacion();")
        f.append(f"CREATE TRIGGER trg_{t}_notruncate BEFORE TRUNCATE ON sigat.{t} FOR EACH STATEMENT EXECUTE FUNCTION sigat.fn_bloquear_truncate();")
    for t, p in VERSIONED.items():
        f.append(f"CREATE TRIGGER trg_{t}_version BEFORE INSERT ON sigat.{t} FOR EACH ROW EXECUTE FUNCTION sigat.fn_registro_version_valida('{p}');")
    f.append("CREATE TRIGGER trg_visita_sync BEFORE INSERT ON sigat.visita FOR EACH ROW EXECUTE FUNCTION sigat.fn_marcar_sincronizacion('visi');")
    f.append("CREATE TRIGGER trg_visita_integridad BEFORE UPDATE OR DELETE ON sigat.visita FOR EACH ROW EXECUTE FUNCTION sigat.fn_visita_integridad();")
    f.append("CREATE TRIGGER trg_trampa_valida BEFORE INSERT OR UPDATE ON sigat.trampa FOR EACH ROW EXECUTE FUNCTION sigat.fn_trampa_valida();")
    for t in T:
        if t in audited and t != 'bitacora_auditoria' and len(T[t]['pk']) == 1:
            f.append(f"CREATE TRIGGER trg_aud_{t} AFTER INSERT OR UPDATE OR DELETE ON sigat.{t} FOR EACH ROW EXECUTE FUNCTION sigat.fn_auditar('{T[t]['pk'][0]}');")
    return "\n".join(f)

def triggers_de(t):
    r = []
    if t in APPEND_ONLY: r.append('solo inserción (UPDATE/DELETE/TRUNCATE bloqueados)')
    if t in VERSIONED: r.append('versionado coherente + t_sincronizacion del servidor')
    if t == 'visita': r.append('t_sincronizacion del servidor; solo columnas de revisión modificables; no se borra')
    if t in audited and t != 'bitacora_auditoria' and len(T[t]['pk']) == 1: r.append('auditoría en bitacora_auditoria')
    if t == 'trampa': r.append('paridad del número según el tipo (Jackson impar, McPhail par)')
    return r

# ------------------------------------------------------------------ catálogos básicos (solo lo documentado)
CATALOGOS = """-- =====================================================================
-- SIGAT v6 - CATÁLOGOS BÁSICOS (solo valores que la documentación define)
-- Los catálogos sin valores oficiales (severidad, plaga_enfermedad, criterio_bpa,
-- variedad_cultivo, producto_fitosanitario, fenologia, condicion_trampa,
-- escenario_trampeo, norma, permiso, geografía DANE) NO se cargan: los define la institución.
-- =====================================================================
SET search_path = sigat, public;

INSERT INTO estado_registro (esta_descripcion) VALUES ('activo'), ('inactivo');

-- 4 roles confirmados. Ámbito: global = rige en todo el sistema; predio = sobre los predios asignados.
INSERT INTO rol (rol_descripcion, rol_codigo, rol_ambito) VALUES
  ('Administrador',          'ADMINISTRADOR',       'global'),
  ('Agrónomo/Supervisor',    'AGRONOMO_SUPERVISOR', 'predio'),
  ('Técnico',                'TECNICO',             'predio'),
  ('Productor',              'PRODUCTOR',           'predio');

-- RN-005: Jackson impar, McPhail par
INSERT INTO tipo_trampa (tipt_descripcion, tipt_paridad) VALUES ('Jackson', 'impar'), ('McPhail', 'par');

-- RN-008: plug 4-6 semanas; proteico hidrolizado 1-2 semanas
INSERT INTO atrayente (atra_descripcion, atra_vida_util_min_sem, atra_vida_util_max_sem) VALUES
  ('Plug', 4, 6), ('Proteico hidrolizado', 1, 2);

INSERT INTO especie_mosca (espm_descripcion, espm_codigo, espm_tipo) VALUES
  ('Ceratitis capitata', 1,  'especie'),
  ('Anastrepha sp.',     56, 'genero_sin_especie'),
  ('No captura',         51, 'sin_captura'),
  ('No Tephritidae',     54, 'no_tephritidae');

INSERT INTO especie_cultivo (espc_descripcion) VALUES ('Durazno');

-- RF-043: tipos de manejo agronómico
INSERT INTO tipo_manejo (tipm_descripcion) VALUES ('Riego'), ('Fertilización'), ('Poda'), ('Raleo'), ('Renovación');

-- Categorías de aviso de la pantalla de preferencias
INSERT INTO categoria_notificacion (cate_codigo, cate_descripcion) VALUES
  ('asignacion',                'Asignaciones'),
  ('alertas_fitosanitarias',    'Alertas fitosanitarias'),
  ('recordatorios_inspeccion',  'Recordatorios de inspección'),
  ('avisos_predio',             'Avisos del predio'),
  ('sincronizacion',            'Sincronización');

-- RN-017: unidades de ejemplo citadas en la documentación
INSERT INTO unidad_medida (unid_simbolo, unid_nombre, unid_magnitud) VALUES
  ('kg', 'kilogramo', 'masa'), ('ha', 'hectárea', 'area'), ('mL/L', 'mililitro por litro', 'concentracion');
"""

# ------------------------------------------------------------------ documentos
def tabla_md(headers, rows):
    s = '| ' + ' | '.join(headers) + ' |\n| ' + ' | '.join('---' for _ in headers) + ' |\n'
    for r in rows:
        s += '| ' + ' | '.join(str(x).replace('|', '\\|').replace('\n', ' ') for x in r) + ' |\n'
    return s

def gen_diccionario():
    o = ["# Diccionario de datos SIGAT v6\n",
         f"Generado desde `sigat_v6.dbml`. {len(T)} tablas, {sum(len(d['cols']) for d in T.values())} columnas. "
         "El prefijo de cada columna son las 4 primeras letras de su tabla (ver `07_prefijos.md`).\n"]
    for num in sorted(area_name):
        o.append(f"\n## Área {num} · {area_name[num]}\n")
        for t in sorted(t for t in T if area_of[t] == num):
            d = T[t]
            o.append(f"\n### `{t}` (prefijo `{PRE[t]}_`)\n")
            p = purpose(t)
            if p: o.append(p + "\n")
            rows = []
            for c in d['cols']:
                tipo = c['type'] + (' (identidad)' if c['inc'] else '') + (' (generada)' if (t, c['name']) in GEN else '')
                obl = 'sí' if (c['notnull'] or c['pk']) else 'no'
                rows.append((f"`{c['name']}`", tipo, obl, c['default'] or '', c['note']))
            o.append(tabla_md(['Columna', 'Tipo', 'Obligatorio', 'Por defecto', 'Significado'], rows))
            o.append(f"- **Clave primaria:** {', '.join('`'+c+'`' for c in d['pk'])}")
            if d['uniq']: o.append("- **No se puede repetir:** " + '; '.join('(' + ', '.join('`'+c+'`' for c in u) + ')' for u in d['uniq']))
            fks = [(cc, pt, pc) for (ct, cc), (pt, pc) in refs if ct == t]
            if fks: o.append("- **Se relaciona con:** " + '; '.join(f"({', '.join('`'+c+'`' for c in cc)}) → `{pt}`" for cc, pt, pc in fks))
            for nm_, ex in checks_de(t): o.append(f"- **Regla `{nm_}`:** `{ex}`")
            if t in EXCLUDES: o.append(f"- **Sin solapamiento `{EXCLUDES[t][0]}`:** `{EXCLUDES[t][1]}`")
            for tr in triggers_de(t): o.append(f"- **Disparador:** {tr}")
            o.append("")
    return "\n".join(o)

def gen_relaciones():
    rows = []
    for (ct, cc), (pt, pc) in refs:
        cm = {c['name']: c for c in T[ct]['cols']}
        obl = 'obligatoria' if all(cm[c]['notnull'] or cm[c]['pk'] for c in cc) else 'opcional'
        uno = covered(ct, cc) and (len(T[ct]['pk']) == len(cc) or any(u == list(cc) for u in T[ct]['uniq']))
        rows.append((f"`{ct}`", ', '.join(f'`{c}`' for c in cc), f"`{pt}`", ', '.join(f'`{c}`' for c in pc), '1:1' if uno else 'N:1', obl))
    return ("# Matriz de relaciones (llaves foráneas)\n\n" + f"{len(refs)} relaciones. Acción ON DELETE / ON UPDATE: la predeterminada de PostgreSQL (NO ACTION): no se puede borrar un registro referenciado.\n\n"
            + tabla_md(['Tabla hija', 'Columnas', 'Tabla padre', 'Columnas padre', 'Cardinalidad', 'Participación de la hija'], rows))

def gen_indices():
    rows = []
    for t, d in T.items():
        if d['pk']: rows.append((f"{t}_pkey", f"`{t}`", ', '.join(d['pk']), 'PRIMARY KEY', 'Identifica cada fila'))
        seen = set()
        for u in d['uniq']:
            if tuple(u) in seen: continue
            seen.add(tuple(u))
            rows.append((ukname(t, u), f"`{t}`", ', '.join(u), 'UNIQUE', 'Evita duplicados'))
        if t in EXCLUDES: rows.append((EXCLUDES[t][0], f"`{t}`", EXCLUDES[t][1], 'GiST (EXCLUDE)', 'Impide vigencias solapadas'))
    for nm_, _, t, cols, kind in indices_extra():
        rows.append((nm_, f"`{t}`", ', '.join(cols), 'GiST' if kind == 'GiST' else 'B-tree', 'Consulta espacial (ST_Contains/ST_Intersects)' if kind == 'GiST' else 'Soporta la llave foránea (joins y borrados)'))
    return "# Matriz de índices\n\n" + f"{len(rows)} índices y restricciones con índice.\n\n" + tabla_md(['Nombre', 'Tabla', 'Columnas', 'Tipo', 'Para qué'], rows)

def gen_prefijos():
    rows = [(f"`{t}`", f"`{PRE[t]}_`", area_of[t], f"`{PRE[t]}_id`" if any(c['name'] == PRE[t] + '_id' for c in T[t]['cols']) else '(sin id propio)') for t in sorted(T)]
    return ("# Prefijos de columnas (4 letras)\n\nCada columna empieza con las primeras 4 letras de su tabla. Las llaves foráneas llevan el prefijo de la tabla a la que apuntan. "
            "Si dos tablas darían las mismas 4 letras, la principal las conserva y la otra usa 3 letras + inicial de su 2.ª palabra (`lotg_`, `visl_`…). `rol` solo tiene 3 letras.\n\n"
            + tabla_md(['Tabla', 'Prefijo', 'Área', 'Llave primaria'], rows))

# ------------------------------------------------------------------ DBML por área y ER
def dbml_subset(tablas):
    out = ["Project sigat { database_type: 'PostgreSQL' }\n"]
    blocks = re.findall(r'^Table (\w+) \{.*?^\}', text, re.S | re.M)
    for m in re.finditer(r'^Table (\w+) \{.*?^\}\n', text, re.S | re.M):
        if m.group(1) in tablas: out.append(m.group(0))
    for (ct, cc), (pt, pc) in refs:
        if ct in tablas and pt in tablas:
            a = f"({', '.join(cc)})" if len(cc) > 1 else cc[0]
            b = f"({', '.join(pc)})" if len(pc) > 1 else pc[0]
            out.append(f"Ref: {ct}.{a} > {pt}.{b}")
    return "\n".join(out) + "\n"

def dot_graph(tablas, compacto=False):
    fk_cols = collections.defaultdict(set)
    for (ct, cc), _ in refs:
        fk_cols[ct].update(cc)
    L = ['digraph G {', ' rankdir=LR; splines=true; nodesep=0.35; ranksep=0.9; fontname="Helvetica";',
         ' node [shape=plain fontname="Helvetica" fontsize=9]; edge [color="#555555" arrowsize=0.7];']
    colors = {1: '#dbeafe', 2: '#dcfce7', 3: '#fef3c7', 4: '#fce7f3', 5: '#e5e7eb', 6: '#ffedd5', 7: '#ede9fe', 8: '#cffafe', 9: '#fee2e2'}
    for t in tablas:
        d = T[t]; col = colors[area_of[t]]
        rows = [f'<TR><TD BGCOLOR="{col}" ALIGN="LEFT"><B>{t}</B></TD></TR>']
        for c in d['cols']:
            if compacto and not (c['pk'] or c['name'] in fk_cols[t] or c['name'] in d['pk']): continue
            mark = ' 🔑' if c['name'] in d['pk'] else ''
            style = '<B>%s</B>' if c['name'] in d['pk'] else ('<I>%s</I>' if c['name'] in fk_cols[t] else '%s')
            rows.append(f'<TR><TD ALIGN="LEFT" PORT="{c["name"]}">{style % html.escape(c["name"])} <FONT COLOR="#777777">{html.escape(c["type"][:22])}</FONT></TD></TR>')
        L.append(f' {t} [label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="2">{"".join(rows)}</TABLE>>];')
    seen = set()
    for (ct, cc), (pt, pc) in refs:
        if ct in tablas and pt in tablas and (ct, pt, tuple(cc)) not in seen:
            seen.add((ct, pt, tuple(cc)))
            L.append(f' {ct} -> {pt};')
    L.append('}')
    return "\n".join(L)

# ------------------------------------------------------------------ salida
def w(path, content):
    p = os.path.join(OUT, path); os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding='utf-8').write(content)

w('sql/01_esquema_completo.sql', build_sql())
w('sql/02_catalogos_basicos.sql', CATALOGOS)
w('docs/03_diccionario_datos.md', gen_diccionario())
w('docs/05_matriz_relaciones.md', gen_relaciones())
w('docs/06_matriz_indices.md', gen_indices())
w('docs/07_prefijos.md', gen_prefijos())
w('diagramas/sigat.dbml', text)
for g, ts in groups.items():
    w(f'diagramas/dbml_por_area/{g}.dbml', dbml_subset(set(ts)))
    num = int(g.split('_')[0])
    w(f'diagramas/er_area_{num}.dot', dot_graph(sorted(ts)))
w('diagramas/er_general.dot', dot_graph(sorted(T), compacto=True))
import shutil
_base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static')
for _r, _d, _fs in os.walk(_base):
    for f in sorted(_fs):
        full = os.path.join(_r, f)
        c = open(full, encoding='utf-8').read()
        c = c.replace('__PREFIJOS__', ', '.join("'" + PRE[t] + "'" for t in sorted(T)))
        w(os.path.relpath(full, _base), c)
print('tablas', len(T), 'refs', len(refs), 'checks', sum(len(checks_de(t)) for t in T), 'auditadas', len([t for t in audited if t in T]))
