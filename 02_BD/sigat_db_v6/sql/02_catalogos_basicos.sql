-- =====================================================================
-- SIGAT v6 - CATÁLOGOS OFICIALES CONFIRMADOS EN LA DOCUMENTACIÓN
-- Los catálogos sin valores oficiales (severidad, plaga_enfermedad, criterio_bpa,
-- variedad_cultivo, producto_fitosanitario, fenologia, condicion_trampa,
-- norma, geografía DANE) NO se cargan: los define la institución.
-- escenario_trampeo y permiso SÍ se cargan aquí con datos oficiales.
-- (Especificación técnica y tabla de prioridades MVP lo exigen para el MVP.)
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

-- RN-018: escenarios oficiales de trampeo (OIEA / ICA) — origen de los umbrales MTD.
-- Valores de defecto propuestos por la especificación; la institución confirma los definitivos.
INSERT INTO escenario_trampeo (esce_descripcion, esce_orden, esce_mtd_desde_defecto, esce_mtd_hasta_defecto, esce_fuente) VALUES
  ('Escenario 1 – Baja infestación', 1, 0.0100, 0.1500, 'OIEA / ICA'),
  ('Escenario 2 – Infestación moderada', 2, 0.1500, 0.5000, 'OIEA / ICA'),
  ('Escenario 3 – Alta infestación', 3, 0.5000, 1.5000, 'OIEA / ICA'),
  ('Escenario 4 – Infestación severa', 4, 1.5000, NULL, 'OIEA / ICA');

-- RBAC productor: permisos que el frontend necesita para decidir qué acciones dibujar.
-- La API sigue siendo la autoridad final (RNF-015). Formato: recurso.acción
INSERT INTO permiso (perm_codigo, perm_descripcion) VALUES
  ('predio.leer',             'Leer información de los predios'),
  ('aplicacion.crear',        'Crear aplicaciones fitosanitarias'),
  ('cosecha.crear',           'Crear cosechas (esperada/real)'),
  ('planificacion.responder', 'Responder planificaciones asignadas'),
  ('notificacion.leer',       'Leer avisos de la bandeja'),
  ('perfil.editar',           'Editar el perfil de usuario');
