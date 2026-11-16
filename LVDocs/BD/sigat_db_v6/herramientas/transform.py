import re, json, sys, collections

SRC = sys.argv[1]
OUT = sys.argv[2]
META = sys.argv[3]

text = open(SRC, encoding='utf-8').read()
lines = text.split('\n')

# prefijo propio ANTIGUO de cada tabla (None = tabla sin columnas propias)
OLD = {
 'administrador':'adm','aplicacion_fitosanitaria':'apf','arbol':'arb','archivo_adjunto':'adj','atrayente':'atr',
 'bitacora_auditoria':'aud','bpa_verificacion':'bpv','categoria_notificacion':'cnt','centro_acopio':'cac',
 'concepto_aptitud':'cap','condicion_trampa':'con','cosecha':'cos','criterio_bpa':'cbp','departamento':'dep',
 'dispositivo':'dis','escenario_trampeo':'esq','especie_cultivo':'esc','especie_mosca':'esm','estado_registro':'est',
 'estimacion_produccion':'esp','etapa_declarada':'etd','evidencia':'evi','fenologia':'fen','fenologia_regla':'fer',
 'hallazgo':'hal','imagen_diseno':'ima','indice_mtd':'mtd','indice_mtd_lectura':None,'lectura_trampa':'lec',
 'localizacion':'loc','lote':'lot','lote_geometria':'log','manejo_agronomico':'man','municipio':'mun','norma':'nor',
 'notificacion':'not','operacion_sync':'ope','paquete_campo':'paq','perfil_usuario':'perf','periodo_trampeo':'ptr',
 'permiso':'prm','persona':'per','plaga_enfermedad':'ple','planificacion':'pla','planificacion_lote':None,
 'predio':'pre','preferencia_notificacion':'pno','producto_fitosanitario':'pfs','productor':'prod',
 'programa_criterio_bpa':None,'programa_inspeccion':'pri','programa_umbral':'pru','rango_departamento':'rgd',
 'recepcion_sync':'rec','region':'reg','restablecimiento_clave':'rcl','reticula':'ret','reticula_celda':'rce',
 'rol':'rol','rol_permiso':None,'ruta':'rut','severidad':'sev','tecnico':'tec','tipo_manejo':'tim','tipo_trampa':'tit',
 'trampa':'tra','ubicacion_trampa':'ubi','unidad_medida':'uni','usuario':'usu','usuario_predio':'usp',
 'variedad_cultivo':'var','vigilancia':'vig','visita':'vis','visita_lote':None,
}

# --- prefijo NUEVO: primeras 4 letras (sin guiones bajos) del nombre de la tabla
tables = [m.group(1) for m in re.finditer(r'^Table (\w+) \{', text, re.M)]
assert set(tables) == set(OLD), set(tables) ^ set(OLD)

def first4(t):
    return re.sub(r'_', '', t)[:4]

groups = collections.defaultdict(list)
for t in tables:
    groups[first4(t)].append(t)

NEW = {}
for p, ts in groups.items():
    if len(ts) == 1:
        NEW[ts[0]] = p
        continue
    # colisión: la tabla "raíz" conserva las 4 letras; las demás usan 3 letras + inicial de la 2.ª palabra
    roots = {'lote':'lote','visita':'visita','indice':'indice_mtd','planificacion':'planificacion',
             'usuario':'usuario','reticula':'reticula','rol':'rol','fenologia':'fenologia','programa':'programa_inspeccion',
             'productor':'productor'}
    root = None
    for t in ts:
        if t in roots.values():
            root = t
    for t in ts:
        if t == root:
            NEW[t] = p
        else:
            w = t.split('_')
            NEW[t] = w[0][:3] + w[1][0]
NEW['rol'] = 'rol'   # el nombre solo tiene 3 letras
# bpa_verificacion -> 'bpav' (ya sale de first4 sin guion bajo)

# unicidad
inv = collections.defaultdict(list)
for t, p in NEW.items():
    inv[p].append(t)
dups = {p: ts for p, ts in inv.items() if len(ts) > 1}
assert not dups, dups

# prefijo antiguo -> tabla dueña
OLD2TABLE = {p: t for t, p in OLD.items() if p}
assert len(OLD2TABLE) == len([p for p in OLD.values() if p])

# --- parseo
col_re = re.compile(r'^(\s+)(\w+) (.+?) \[(.*)\]\s*$')
col_re_nobr = re.compile(r'^(\s+)(\w+) (\S+)\s*$')

OVERRIDES = {
  ('operacion_sync', 'ope_resuelve_ope_id'): 'oper_resuelve_oper_id',
}
ICA_COLS = {'esm_codigo_ica','fen_codigo_ica','loc_codigo_ica','vig_codigo_ica','tec_codigo_ica','tra_codigo_ica','pfs_registro_ica'}

def newname(table, col):
    key = (table, col)
    if key in OVERRIDES:
        return OVERRIDES[key]
    own = OLD[table]
    if own and (col == own + '_id' or col.startswith(own + '_')):
        # ¿es realmente propia? (perfil_usuario.usu_id no empieza por 'perf')
        res = NEW[table] + col[len(own):]
    else:
        pre = col.split('_')[0]
        if pre not in OLD2TABLE:
            raise Exception(f'prefijo desconocido {table}.{col}')
        res = NEW[OLD2TABLE[pre]] + col[len(pre):]
    if col in ICA_COLS:
        res = re.sub(r'_ica$', '', res)
    return res

# recorrer tablas
cur = None
colmap = collections.defaultdict(dict)   # table -> old -> new
for ln in lines:
    m = re.match(r'^Table (\w+) \{', ln)
    if m:
        cur = m.group(1); continue
    if ln.startswith('}'):
        cur = None; continue
    if cur and not ln.strip().startswith(('indexes', '(', '}')):
        m = col_re.match(ln) or col_re_nobr.match(ln)
        if m:
            colmap[cur][m.group(2)] = newname(cur, m.group(2))

# unicidad por tabla
for t, d in colmap.items():
    vals = list(d.values())
    assert len(vals) == len(set(vals)), (t, [v for v in vals if vals.count(v) > 1])

# mapa global old -> new (para notas); detectar conflictos
glob = {}
for t, d in colmap.items():
    for o, n in d.items():
        if o in glob and glob[o] != n:
            print('CONFLICTO global', o, glob[o], n)
        glob.setdefault(o, n)

tok_re = re.compile(r'\b(' + '|'.join(sorted(map(re.escape, glob), key=len, reverse=True)) + r')\b')
def fix_text(s):
    return tok_re.sub(lambda m: glob[m.group(1)], s)

# --- reemplazos de redacción (ICA y notas erróneas)
NOTE_FIX = {
 'esm_codigo_ica': "Código numérico de la especie en el catálogo de captura (1 = Ceratitis capitata, 51 = No captura, 54 = No Tephritidae, 56 = Anastrepha sp.). Nulo para especies agregadas localmente.",
 'esm_tipo': "Naturaleza del resultado de determinación: especie, genero_sin_especie, sin_captura o no_tephritidae.",
 'fen_codigo_ica': "Código numérico de la etapa fenológica (nulo si la etapa no tiene código).",
 'loc_codigo_ica': "Código numérico de la localización de la trampa.",
 'vig_codigo_ica': "Código numérico del tipo de vigilancia.",
 'pre_codigo': "Código interno del predio (parte del código de trampa cuando no hay ruta). Único.",
 'pfs_registro_ica': "Número de registro oficial del producto (opcional, único).",
 'rut_codigo': "Código de la ruta (alfanumérico, hasta 10); único dentro del centro de acopio.",
 'tec_codigo_ica': "Código del recolector: Divipola (5 dígitos) + consecutivo de 3 dígitos. Nulo si no tiene.",
 'tra_codigo_ica': "Código oficial impreso en la trampa. Formato verificado de forma mínima (el Manual Técnico T1 no está disponible): ver pendientes.",
 # notas que estaban copiadas por error de otra columna
 'lot_tecnico_registro_id': "Técnico que registró el lote. Referencia a tecnico(tec_id).",
 'pre_tecnico_registro_id': "Técnico que registró el predio. Referencia a tecnico(tec_id).",
 'prod_tecnico_registro_id': "Técnico que registró al productor. Referencia a tecnico(tec_id).",
 'tra_tecnico_registro_id': "Técnico que registró la trampa. Referencia a tecnico(tec_id).",
 'rut_admin_registro_id': "Administrador que registró la ruta. Referencia a administrador(adm_id).",
 'lot_tecnico_actualizacion_id': "Técnico que hizo la última actualización del lote. Referencia a tecnico(tec_id).",
 'pre_tecnico_actualizacion_id': "Técnico que hizo la última actualización del predio. Referencia a tecnico(tec_id).",
 'prod_tecnico_actualizacion_id': "Técnico que hizo la última actualización del productor. Referencia a tecnico(tec_id).",
 'tra_tecnico_actualizacion_id': "Técnico que hizo la última actualización de la trampa. Referencia a tecnico(tec_id).",
 'tra_tecnico_estado_id': "Técnico que cambió por última vez el estado de la trampa. Referencia a tecnico(tec_id).",
 'rut_admin_actualizacion_id': "Administrador que hizo la última actualización de la ruta. Referencia a administrador(adm_id).",
 'ruta.mun_id': "Municipio al que pertenece la ruta (aporta los 5 dígitos Divipola del código de ruta). Nulo hasta confirmarlo.",
}

def note_of(table, old):
    return NOTE_FIX.get(old) or NOTE_FIX.get(f'{table}.{old}')

# --- emitir
out = []
cur = None
in_index = False
n_icacols = 0
meta = {'tables': {}, 'refs': []}
for ln in lines:
    m = re.match(r'^Table (\w+) \{', ln)
    if m:
        cur = m.group(1); in_index = False
        meta['tables'][cur] = {'prefix': NEW[cur], 'cols': []}
        out.append(ln); continue
    if cur and ln.strip() == 'indexes {':
        in_index = True; out.append(ln); continue
    if cur and in_index:
        if ln.strip() == '}':
            in_index = False; out.append(ln); continue
        m = re.match(r'^(\s+)\(([^)]*)\)(.*)$', ln)
        cols = [c.strip() for c in m.group(2).split(',')]
        cols = [colmap[cur][c] for c in cols]
        out.append(f"{m.group(1)}({', '.join(cols)}){m.group(3)}"); continue
    if ln.startswith('}'):
        cur = None; out.append(ln); continue
    if cur:
        m = col_re.match(ln)
        if m:
            ind, name, typ, attrs = m.groups()
            nn = colmap[cur][name]
            nm = re.search(r"note: '((?:[^']|'')*)'", attrs)
            if nm:
                fixed = note_of(cur, name)
                body = fix_text(fixed if fixed else nm.group(1))
                attrs = attrs[:nm.start()] + "note: '" + body.replace("'", "\\'") .replace("\\'\\'", "\\'") + "'" + attrs[nm.end():]
            out.append(f"{ind}{nn} {typ} [{attrs}]")
            meta['tables'][cur]['cols'].append({'old': name, 'new': nn, 'type': typ, 'attrs': attrs})
            continue
        m = col_re_nobr.match(ln)
        if m:
            ind, name, typ = m.groups()
            out.append(f"{ind}{colmap[cur][name]} {typ}"); continue
    # Refs
    m = re.match(r'^Ref: (.+?) ([<>-]) (.+)$', ln)
    if m:
        def fixref(side):
            mm = re.match(r'^(\w+)\.(\(.*\)|\w+)$', side)
            t, c = mm.group(1), mm.group(2)
            if c.startswith('('):
                cs = [x.strip() for x in c[1:-1].split(',')]
                c = '(' + ', '.join(colmap[t][x] for x in cs) + ')'
            else:
                c = colmap[t][c]
            return f'{t}.{c}'
        a, op, b = fixref(m.group(1)), m.group(2), fixref(m.group(3))
        out.append(f'Ref: {a} {op} {b}')
        meta['refs'].append([a, op, b]); continue
    out.append(ln)

res = '\n'.join(out)
res = res.replace('// SIGAT – esquema final (PostgreSQL 16 + PostGIS). Generado desde el catálogo; pegar en https://dbdiagram.io/d',
                  '// SIGAT – esquema v6 (PostgreSQL 16 + PostGIS). Prefijo de columnas = primeras 4 letras del nombre de la tabla. Pegar en https://dbdiagram.io/d')
open(OUT, 'w', encoding='utf-8').write(res)
meta['new_prefix'] = NEW
meta['colmap'] = colmap
json.dump(meta, open(META, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('tablas', len(tables))
print({p: t for t, p in NEW.items() if first4(t) != p})
