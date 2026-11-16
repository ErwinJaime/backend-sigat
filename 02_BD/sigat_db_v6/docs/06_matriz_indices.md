# Matriz de índices

299 índices y restricciones con índice.

| Nombre | Tabla | Columnas | Tipo | Para qué |
| --- | --- | --- | --- | --- |
| administrador_pkey | `administrador` | admi_id | PRIMARY KEY | Identifica cada fila |
| administrador_pers_cc_key | `administrador` | pers_cc | UNIQUE | Evita duplicados |
| aplicacion_fitosanitaria_pkey | `aplicacion_fitosanitaria` | apli_id | PRIMARY KEY | Identifica cada fila |
| aplicacion_fitosanitaria_oper_id_key | `aplicacion_fitosanitaria` | oper_id | UNIQUE | Evita duplicados |
| aplicacion_fitosanitaria_apli_registro_id_apli_version_key | `aplicacion_fitosanitaria` | apli_registro_id, apli_version | UNIQUE | Evita duplicados |
| arbol_pkey | `arbol` | arbo_id | PRIMARY KEY | Identifica cada fila |
| arbol_arbo_descripcion_key | `arbol` | arbo_descripcion | UNIQUE | Evita duplicados |
| archivo_adjunto_pkey | `archivo_adjunto` | arch_id | PRIMARY KEY | Identifica cada fila |
| archivo_adjunto_arch_id_arch_clase_key | `archivo_adjunto` | arch_id, arch_clase | UNIQUE | Evita duplicados |
| atrayente_pkey | `atrayente` | atra_id | PRIMARY KEY | Identifica cada fila |
| atrayente_atra_descripcion_key | `atrayente` | atra_descripcion | UNIQUE | Evita duplicados |
| bitacora_auditoria_pkey | `bitacora_auditoria` | bita_id | PRIMARY KEY | Identifica cada fila |
| bpa_verificacion_pkey | `bpa_verificacion` | bpav_id | PRIMARY KEY | Identifica cada fila |
| bpa_verificacion_oper_id_key | `bpa_verificacion` | oper_id | UNIQUE | Evita duplicados |
| bpa_verificacion_bpav_registro_id_bpav_version_key | `bpa_verificacion` | bpav_registro_id, bpav_version | UNIQUE | Evita duplicados |
| categoria_notificacion_pkey | `categoria_notificacion` | cate_id | PRIMARY KEY | Identifica cada fila |
| categoria_notificacion_cate_codigo_key | `categoria_notificacion` | cate_codigo | UNIQUE | Evita duplicados |
| categoria_notificacion_cate_descripcion_key | `categoria_notificacion` | cate_descripcion | UNIQUE | Evita duplicados |
| centro_acopio_pkey | `centro_acopio` | cent_id | PRIMARY KEY | Identifica cada fila |
| centro_acopio_cent_descripcion_key | `centro_acopio` | cent_descripcion | UNIQUE | Evita duplicados |
| concepto_aptitud_pkey | `concepto_aptitud` | conc_id | PRIMARY KEY | Identifica cada fila |
| concepto_aptitud_lote_id_peri_id_conc_version_key | `concepto_aptitud` | lote_id, peri_id, conc_version | UNIQUE | Evita duplicados |
| condicion_trampa_pkey | `condicion_trampa` | cond_id | PRIMARY KEY | Identifica cada fila |
| condicion_trampa_cond_descripcion_key | `condicion_trampa` | cond_descripcion | UNIQUE | Evita duplicados |
| cosecha_pkey | `cosecha` | cose_id | PRIMARY KEY | Identifica cada fila |
| cosecha_oper_id_key | `cosecha` | oper_id | UNIQUE | Evita duplicados |
| cosecha_cose_registro_id_cose_version_key | `cosecha` | cose_registro_id, cose_version | UNIQUE | Evita duplicados |
| criterio_bpa_pkey | `criterio_bpa` | crit_id | PRIMARY KEY | Identifica cada fila |
| criterio_bpa_crit_descripcion_key | `criterio_bpa` | crit_descripcion | UNIQUE | Evita duplicados |
| departamento_pkey | `departamento` | depa_id | PRIMARY KEY | Identifica cada fila |
| departamento_depa_descripcion_key | `departamento` | depa_descripcion | UNIQUE | Evita duplicados |
| departamento_depa_codigo_key | `departamento` | depa_codigo | UNIQUE | Evita duplicados |
| dispositivo_pkey | `dispositivo` | disp_id | PRIMARY KEY | Identifica cada fila |
| escenario_trampeo_pkey | `escenario_trampeo` | esce_id | PRIMARY KEY | Identifica cada fila |
| escenario_trampeo_esce_descripcion_key | `escenario_trampeo` | esce_descripcion | UNIQUE | Evita duplicados |
| escenario_trampeo_esce_orden_key | `escenario_trampeo` | esce_orden | UNIQUE | Evita duplicados |
| especie_cultivo_pkey | `especie_cultivo` | espc_id | PRIMARY KEY | Identifica cada fila |
| especie_cultivo_espc_descripcion_key | `especie_cultivo` | espc_descripcion | UNIQUE | Evita duplicados |
| especie_mosca_pkey | `especie_mosca` | espm_id | PRIMARY KEY | Identifica cada fila |
| especie_mosca_espm_descripcion_key | `especie_mosca` | espm_descripcion | UNIQUE | Evita duplicados |
| especie_mosca_espm_codigo_key | `especie_mosca` | espm_codigo | UNIQUE | Evita duplicados |
| estado_registro_pkey | `estado_registro` | esta_id | PRIMARY KEY | Identifica cada fila |
| estado_registro_esta_descripcion_key | `estado_registro` | esta_descripcion | UNIQUE | Evita duplicados |
| estimacion_produccion_pkey | `estimacion_produccion` | esti_id | PRIMARY KEY | Identifica cada fila |
| estimacion_produccion_oper_id_key | `estimacion_produccion` | oper_id | UNIQUE | Evita duplicados |
| estimacion_produccion_esti_registro_id_esti_version_key | `estimacion_produccion` | esti_registro_id, esti_version | UNIQUE | Evita duplicados |
| etapa_declarada_pkey | `etapa_declarada` | etap_id | PRIMARY KEY | Identifica cada fila |
| etapa_declarada_oper_id_key | `etapa_declarada` | oper_id | UNIQUE | Evita duplicados |
| etapa_declarada_etap_registro_id_etap_version_key | `etapa_declarada` | etap_registro_id, etap_version | UNIQUE | Evita duplicados |
| evidencia_pkey | `evidencia` | evid_id | PRIMARY KEY | Identifica cada fila |
| evidencia_oper_id_key | `evidencia` | oper_id | UNIQUE | Evita duplicados |
| evidencia_arch_id_evid_clase_key | `evidencia` | arch_id, evid_clase | UNIQUE | Evita duplicados |
| fenologia_pkey | `fenologia` | feno_id | PRIMARY KEY | Identifica cada fila |
| fenologia_feno_descripcion_key | `fenologia` | feno_descripcion | UNIQUE | Evita duplicados |
| fenologia_feno_codigo_key | `fenologia` | feno_codigo | UNIQUE | Evita duplicados |
| fenologia_regla_pkey | `fenologia_regla` | fenr_id | PRIMARY KEY | Identifica cada fila |
| hallazgo_pkey | `hallazgo` | hall_id | PRIMARY KEY | Identifica cada fila |
| hallazgo_oper_id_key | `hallazgo` | oper_id | UNIQUE | Evita duplicados |
| hallazgo_hall_registro_id_hall_version_key | `hallazgo` | hall_registro_id, hall_version | UNIQUE | Evita duplicados |
| imagen_diseno_pkey | `imagen_diseno` | imag_id | PRIMARY KEY | Identifica cada fila |
| imagen_diseno_imag_codigo_imag_version_key | `imagen_diseno` | imag_codigo, imag_version | UNIQUE | Evita duplicados |
| imagen_diseno_arch_id_arch_clase_key | `imagen_diseno` | arch_id, arch_clase | UNIQUE | Evita duplicados |
| indice_mtd_pkey | `indice_mtd` | indi_id | PRIMARY KEY | Identifica cada fila |
| indice_mtd_indi_id_peri_id_key | `indice_mtd` | indi_id, peri_id | UNIQUE | Evita duplicados |
| indice_mtd_lectura_pkey | `indice_mtd_lectura` | indi_id, lect_id | PRIMARY KEY | Identifica cada fila |
| lectura_trampa_pkey | `lectura_trampa` | lect_id | PRIMARY KEY | Identifica cada fila |
| lectura_trampa_oper_id_key | `lectura_trampa` | oper_id | UNIQUE | Evita duplicados |
| lectura_trampa_lect_registro_id_lect_version_key | `lectura_trampa` | lect_registro_id, lect_version | UNIQUE | Evita duplicados |
| localizacion_pkey | `localizacion` | loca_id | PRIMARY KEY | Identifica cada fila |
| localizacion_loca_descripcion_key | `localizacion` | loca_descripcion | UNIQUE | Evita duplicados |
| localizacion_loca_codigo_key | `localizacion` | loca_codigo | UNIQUE | Evita duplicados |
| lote_pkey | `lote` | lote_id | PRIMARY KEY | Identifica cada fila |
| lote_lote_id_pred_id_key | `lote` | lote_id, pred_id | UNIQUE | Evita duplicados |
| lote_pred_id_lote_codigo_key | `lote` | pred_id, lote_codigo | UNIQUE | Evita duplicados |
| lote_geometria_pkey | `lote_geometria` | lotg_id | PRIMARY KEY | Identifica cada fila |
| lote_geometria_lote_id_lotg_version_key | `lote_geometria` | lote_id, lotg_version | UNIQUE | Evita duplicados |
| lotg_vigencia_sin_solape | `lote_geometria` | lote_id WITH =, tstzrange(lotg_vigente_desde, lotg_vigente_hasta) WITH && | GiST (EXCLUDE) | Impide vigencias solapadas |
| manejo_agronomico_pkey | `manejo_agronomico` | mane_id | PRIMARY KEY | Identifica cada fila |
| manejo_agronomico_oper_id_key | `manejo_agronomico` | oper_id | UNIQUE | Evita duplicados |
| manejo_agronomico_mane_registro_id_mane_version_key | `manejo_agronomico` | mane_registro_id, mane_version | UNIQUE | Evita duplicados |
| municipio_pkey | `municipio` | muni_id | PRIMARY KEY | Identifica cada fila |
| municipio_depa_id_muni_codigo_key | `municipio` | depa_id, muni_codigo | UNIQUE | Evita duplicados |
| norma_pkey | `norma` | norm_id | PRIMARY KEY | Identifica cada fila |
| norma_norm_codigo_key | `norma` | norm_codigo | UNIQUE | Evita duplicados |
| notificacion_pkey | `notificacion` | noti_id | PRIMARY KEY | Identifica cada fila |
| notificacion_usua_id_noti_evento_clave_key | `notificacion` | usua_id, noti_evento_clave | UNIQUE | Evita duplicados |
| operacion_sync_pkey | `operacion_sync` | oper_id | PRIMARY KEY | Identifica cada fila |
| operacion_sync_disp_id_oper_cliente_id_key | `operacion_sync` | disp_id, oper_cliente_id | UNIQUE | Evita duplicados |
| paquete_campo_pkey | `paquete_campo` | paqu_id | PRIMARY KEY | Identifica cada fila |
| paquete_campo_pred_id_paqu_version_key | `paquete_campo` | pred_id, paqu_version | UNIQUE | Evita duplicados |
| perfil_usuario_pkey | `perfil_usuario` | usua_id | PRIMARY KEY | Identifica cada fila |
| periodo_trampeo_pkey | `periodo_trampeo` | peri_id | PRIMARY KEY | Identifica cada fila |
| periodo_trampeo_peri_id_lote_id_key | `periodo_trampeo` | peri_id, lote_id | UNIQUE | Evita duplicados |
| periodo_trampeo_sin_solape | `periodo_trampeo` | lote_id WITH =, vigi_id WITH =, daterange(peri_inicio, peri_fin, '[]') WITH && | GiST (EXCLUDE) | Impide vigencias solapadas |
| permiso_pkey | `permiso` | perm_id | PRIMARY KEY | Identifica cada fila |
| permiso_perm_codigo_key | `permiso` | perm_codigo | UNIQUE | Evita duplicados |
| persona_pkey | `persona` | pers_cc | PRIMARY KEY | Identifica cada fila |
| plaga_enfermedad_pkey | `plaga_enfermedad` | plag_id | PRIMARY KEY | Identifica cada fila |
| plaga_enfermedad_plag_descripcion_key | `plaga_enfermedad` | plag_descripcion | UNIQUE | Evita duplicados |
| planificacion_pkey | `planificacion` | plan_id | PRIMARY KEY | Identifica cada fila |
| planificacion_lote_pkey | `planificacion_lote` | plan_id, lote_id | PRIMARY KEY | Identifica cada fila |
| predio_pkey | `predio` | pred_id | PRIMARY KEY | Identifica cada fila |
| predio_pred_codigo_key | `predio` | pred_codigo | UNIQUE | Evita duplicados |
| preferencia_notificacion_pkey | `preferencia_notificacion` | usua_id, cate_id | PRIMARY KEY | Identifica cada fila |
| producto_fitosanitario_pkey | `producto_fitosanitario` | prof_id | PRIMARY KEY | Identifica cada fila |
| producto_fitosanitario_prof_nombre_key | `producto_fitosanitario` | prof_nombre | UNIQUE | Evita duplicados |
| producto_fitosanitario_prof_registro_key | `producto_fitosanitario` | prof_registro | UNIQUE | Evita duplicados |
| productor_pkey | `productor` | pers_cc | PRIMARY KEY | Identifica cada fila |
| programa_criterio_bpa_pkey | `programa_criterio_bpa` | prog_id, crit_id | PRIMARY KEY | Identifica cada fila |
| programa_inspeccion_pkey | `programa_inspeccion` | prog_id | PRIMARY KEY | Identifica cada fila |
| programa_inspeccion_pred_id_prog_version_key | `programa_inspeccion` | pred_id, prog_version | UNIQUE | Evita duplicados |
| programa_inspeccion_prog_id_pred_id_key | `programa_inspeccion` | prog_id, pred_id | UNIQUE | Evita duplicados |
| programa_inspeccion_sin_solape | `programa_inspeccion` | pred_id WITH =, daterange(prog_vigente_desde, prog_vigente_hasta) WITH && | GiST (EXCLUDE) | Impide vigencias solapadas |
| programa_umbral_pkey | `programa_umbral` | prog_id, esce_id | PRIMARY KEY | Identifica cada fila |
| rango_departamento_pkey | `rango_departamento` | depa_id | PRIMARY KEY | Identifica cada fila |
| recepcion_sync_pkey | `recepcion_sync` | rece_id | PRIMARY KEY | Identifica cada fila |
| region_pkey | `region` | regi_id | PRIMARY KEY | Identifica cada fila |
| region_regi_descripcion_key | `region` | regi_descripcion | UNIQUE | Evita duplicados |
| restablecimiento_clave_pkey | `restablecimiento_clave` | rest_id | PRIMARY KEY | Identifica cada fila |
| restablecimiento_clave_rest_token_hash_key | `restablecimiento_clave` | rest_token_hash | UNIQUE | Evita duplicados |
| reticula_pkey | `reticula` | reti_id | PRIMARY KEY | Identifica cada fila |
| reticula_reti_id_pred_id_key | `reticula` | reti_id, pred_id | UNIQUE | Evita duplicados |
| reticula_pred_id_reti_resolucion_m_key | `reticula` | pred_id, reti_resolucion_m | UNIQUE | Evita duplicados |
| reticula_celda_pkey | `reticula_celda` | retc_id | PRIMARY KEY | Identifica cada fila |
| reticula_celda_reti_id_retc_codigo_key | `reticula_celda` | reti_id, retc_codigo | UNIQUE | Evita duplicados |
| rol_pkey | `rol` | rol_id | PRIMARY KEY | Identifica cada fila |
| rol_rol_descripcion_key | `rol` | rol_descripcion | UNIQUE | Evita duplicados |
| rol_rol_codigo_key | `rol` | rol_codigo | UNIQUE | Evita duplicados |
| rol_permiso_pkey | `rol_permiso` | rol_id, perm_id | PRIMARY KEY | Identifica cada fila |
| ruta_pkey | `ruta` | ruta_id | PRIMARY KEY | Identifica cada fila |
| ruta_ruta_nombre_key | `ruta` | ruta_nombre | UNIQUE | Evita duplicados |
| ruta_cent_id_ruta_codigo_key | `ruta` | cent_id, ruta_codigo | UNIQUE | Evita duplicados |
| severidad_pkey | `severidad` | seve_id | PRIMARY KEY | Identifica cada fila |
| severidad_seve_descripcion_key | `severidad` | seve_descripcion | UNIQUE | Evita duplicados |
| severidad_seve_orden_key | `severidad` | seve_orden | UNIQUE | Evita duplicados |
| tecnico_pkey | `tecnico` | tecn_id | PRIMARY KEY | Identifica cada fila |
| tecnico_pers_cc_key | `tecnico` | pers_cc | UNIQUE | Evita duplicados |
| tecnico_tecn_codigo_key | `tecnico` | tecn_codigo | UNIQUE | Evita duplicados |
| tipo_manejo_pkey | `tipo_manejo` | tipm_id | PRIMARY KEY | Identifica cada fila |
| tipo_manejo_tipm_descripcion_key | `tipo_manejo` | tipm_descripcion | UNIQUE | Evita duplicados |
| tipo_trampa_pkey | `tipo_trampa` | tipt_id | PRIMARY KEY | Identifica cada fila |
| tipo_trampa_tipt_descripcion_key | `tipo_trampa` | tipt_descripcion | UNIQUE | Evita duplicados |
| trampa_pkey | `trampa` | tram_id | PRIMARY KEY | Identifica cada fila |
| trampa_tram_codigo_key | `trampa` | tram_codigo | UNIQUE | Evita duplicados |
| ubicacion_trampa_pkey | `ubicacion_trampa` | ubic_id | PRIMARY KEY | Identifica cada fila |
| ubicacion_trampa_ubic_id_tram_id_key | `ubicacion_trampa` | ubic_id, tram_id | UNIQUE | Evita duplicados |
| ubicacion_trampa_sin_solape | `ubicacion_trampa` | tram_id WITH =, daterange(ubic_fecha, ubic_fecha_fin) WITH && | GiST (EXCLUDE) | Impide vigencias solapadas |
| unidad_medida_pkey | `unidad_medida` | unid_id | PRIMARY KEY | Identifica cada fila |
| unidad_medida_unid_simbolo_key | `unidad_medida` | unid_simbolo | UNIQUE | Evita duplicados |
| usuario_pkey | `usuario` | usua_id | PRIMARY KEY | Identifica cada fila |
| usuario_pers_cc_key | `usuario` | pers_cc | UNIQUE | Evita duplicados |
| usuario_usua_proveedor_usua_sujeto_externo_key | `usuario` | usua_proveedor, usua_sujeto_externo | UNIQUE | Evita duplicados |
| usuario_predio_pkey | `usuario_predio` | usup_id | PRIMARY KEY | Identifica cada fila |
| usuario_predio_sin_solape | `usuario_predio` | usua_id WITH =, pred_id WITH =, daterange(usup_desde, usup_hasta) WITH && | GiST (EXCLUDE) | Impide vigencias solapadas |
| variedad_cultivo_pkey | `variedad_cultivo` | vari_id | PRIMARY KEY | Identifica cada fila |
| variedad_cultivo_espc_id_vari_descripcion_key | `variedad_cultivo` | espc_id, vari_descripcion | UNIQUE | Evita duplicados |
| variedad_cultivo_espc_id_vari_id_key | `variedad_cultivo` | espc_id, vari_id | UNIQUE | Evita duplicados |
| vigilancia_pkey | `vigilancia` | vigi_id | PRIMARY KEY | Identifica cada fila |
| vigilancia_vigi_descripcion_key | `vigilancia` | vigi_descripcion | UNIQUE | Evita duplicados |
| vigilancia_vigi_codigo_key | `vigilancia` | vigi_codigo | UNIQUE | Evita duplicados |
| visita_pkey | `visita` | visi_id | PRIMARY KEY | Identifica cada fila |
| visita_oper_id_key | `visita` | oper_id | UNIQUE | Evita duplicados |
| visita_visi_id_pred_id_key | `visita` | visi_id, pred_id | UNIQUE | Evita duplicados |
| visita_lote_pkey | `visita_lote` | visi_id, lote_id | PRIMARY KEY | Identifica cada fila |
| ix_departamento_regi_id | `departamento` | regi_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_administrador_cent_id | `administrador` | cent_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_centro_acopio_depa_id | `centro_acopio` | depa_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_tecnico_cent_id | `tecnico` | cent_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_tecnico_admi_id | `tecnico` | admi_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_tecnico_esta_id | `tecnico` | esta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_productor_prod_tecnico_registro_id | `productor` | prod_tecnico_registro_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_productor_prod_tecnico_actualizacion_id | `productor` | prod_tecnico_actualizacion_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_productor_muni_id | `productor` | muni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ruta_muni_id | `ruta` | muni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ruta_ruta_admin_registro_id | `ruta` | ruta_admin_registro_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ruta_ruta_admin_actualizacion_id | `ruta` | ruta_admin_actualizacion_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ruta_esta_id | `ruta` | esta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_rol_id | `usuario` | rol_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_esta_id | `usuario` | esta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_rol_permiso_perm_id | `rol_permiso` | perm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_predio_muni_id | `predio` | muni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_predio_pers_cc | `predio` | pers_cc | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_predio_pred_tecnico_registro_id | `predio` | pred_tecnico_registro_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_predio_pred_tecnico_actualizacion_id | `predio` | pred_tecnico_actualizacion_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lote_espc_id | `lote` | espc_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lote_espc_id_vari_id | `lote` | espc_id, vari_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lote_lote_tecnico_registro_id | `lote` | lote_tecnico_registro_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lote_lote_tecnico_actualizacion_id | `lote` | lote_tecnico_actualizacion_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_fenologia_regla_espc_id | `fenologia_regla` | espc_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_predio_usua_id | `usuario_predio` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_predio_pred_id | `usuario_predio` | pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_predio_rol_id | `usuario_predio` | rol_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_usuario_predio_usup_asignado_por | `usuario_predio` | usup_asignado_por | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_programa_inspeccion_reti_id_pred_id | `programa_inspeccion` | reti_id, pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_programa_inspeccion_norm_id | `programa_inspeccion` | norm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_programa_inspeccion_prog_creado_por | `programa_inspeccion` | prog_creado_por | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_programa_umbral_esce_id | `programa_umbral` | esce_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_fenologia_regla_feno_id | `fenologia_regla` | feno_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_paquete_campo_prog_id_pred_id | `paquete_campo` | prog_id, pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_tipt_id | `trampa` | tipt_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_atra_id | `trampa` | atra_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_esta_id | `trampa` | esta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_tram_tecnico_registro_id | `trampa` | tram_tecnico_registro_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_tram_tecnico_actualizacion_id | `trampa` | tram_tecnico_actualizacion_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_trampa_tram_tecnico_estado_id | `trampa` | tram_tecnico_estado_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_usua_id | `visita` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_pred_id | `visita` | pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_tram_id | `ubicacion_trampa` | tram_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_pred_id | `ubicacion_trampa` | pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_lote_id_pred_id | `ubicacion_trampa` | lote_id, pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_tecn_id | `ubicacion_trampa` | tecn_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_vigi_id | `ubicacion_trampa` | vigi_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_ruta_id | `ubicacion_trampa` | ruta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_retc_id | `ubicacion_trampa` | retc_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_loca_id | `ubicacion_trampa` | loca_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_ubicacion_trampa_arbo_id | `ubicacion_trampa` | arbo_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_operacion_sync_usua_id | `operacion_sync` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_operacion_sync_oper_resuelve_oper_id | `operacion_sync` | oper_resuelve_oper_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_ruta_id | `visita` | ruta_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_visi_revisada_por | `visita` | visi_revisada_por | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_lote_visi_id_pred_id | `visita_lote` | visi_id, pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_recepcion_sync_oper_id | `recepcion_sync` | oper_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bitacora_auditoria_usua_id | `bitacora_auditoria` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bitacora_auditoria_disp_id | `bitacora_auditoria` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_disp_id | `visita` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_visita_lote_lote_id_pred_id | `visita_lote` | lote_id, pred_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_visi_id | `lectura_trampa` | visi_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_tram_id | `lectura_trampa` | tram_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_ubic_id_tram_id | `lectura_trampa` | ubic_id, tram_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_cond_id | `lectura_trampa` | cond_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_atra_id | `lectura_trampa` | atra_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_usua_id | `lectura_trampa` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_lectura_trampa_disp_id | `lectura_trampa` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_pers_cc_responsable | `aplicacion_fitosanitaria` | pers_cc_responsable | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_lote_id | `aplicacion_fitosanitaria` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_prof_id | `aplicacion_fitosanitaria` | prof_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_apli_dosis_uni_id | `aplicacion_fitosanitaria` | apli_dosis_uni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_apli_area_uni_id | `aplicacion_fitosanitaria` | apli_area_uni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_usua_id | `aplicacion_fitosanitaria` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_aplicacion_fitosanitaria_disp_id | `aplicacion_fitosanitaria` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_cosecha_lote_id | `cosecha` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_cosecha_cose_volumen_uni_id | `cosecha` | cose_volumen_uni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_cosecha_usua_id | `cosecha` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_cosecha_disp_id | `cosecha` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_etapa_declarada_lote_id | `etapa_declarada` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_etapa_declarada_feno_id | `etapa_declarada` | feno_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_etapa_declarada_usua_id | `etapa_declarada` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_etapa_declarada_disp_id | `etapa_declarada` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_periodo_trampeo_lote_id | `periodo_trampeo` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_periodo_trampeo_vigi_id | `periodo_trampeo` | vigi_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_periodo_trampeo_prog_id | `periodo_trampeo` | prog_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_indice_mtd_peri_id | `indice_mtd` | peri_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_indice_mtd_espm_id | `indice_mtd` | espm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_indice_mtd_norm_id | `indice_mtd` | norm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_indice_mtd_esce_id | `indice_mtd` | esce_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_indice_mtd_lectura_lect_id | `indice_mtd_lectura` | lect_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_manejo_agronomico_disp_id | `manejo_agronomico` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_concepto_aptitud_peri_id_lote_id | `concepto_aptitud` | peri_id, lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_concepto_aptitud_indi_id_peri_id | `concepto_aptitud` | indi_id, peri_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_concepto_aptitud_norm_id | `concepto_aptitud` | norm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_lote_id | `hallazgo` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_retc_id | `hallazgo` | retc_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_plag_id | `hallazgo` | plag_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_seve_id | `hallazgo` | seve_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_usua_id | `hallazgo` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_hallazgo_disp_id | `hallazgo` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_programa_criterio_bpa_crit_id | `programa_criterio_bpa` | crit_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bpa_verificacion_visi_id_lote_id | `bpa_verificacion` | visi_id, lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bpa_verificacion_crit_id | `bpa_verificacion` | crit_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bpa_verificacion_usua_id | `bpa_verificacion` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_bpa_verificacion_disp_id | `bpa_verificacion` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_estimacion_produccion_lote_id | `estimacion_produccion` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_estimacion_produccion_esti_rendimiento_uni_id | `estimacion_produccion` | esti_rendimiento_uni_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_estimacion_produccion_usua_id | `estimacion_produccion` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_estimacion_produccion_disp_id | `estimacion_produccion` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_manejo_agronomico_lote_id | `manejo_agronomico` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_manejo_agronomico_tipm_id | `manejo_agronomico` | tipm_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_manejo_agronomico_usua_id | `manejo_agronomico` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_evidencia_hall_id | `evidencia` | hall_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_evidencia_usua_id | `evidencia` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_evidencia_disp_id | `evidencia` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_archivo_adjunto_usua_id | `archivo_adjunto` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_archivo_adjunto_disp_id | `archivo_adjunto` | disp_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_evidencia_lect_id | `evidencia` | lect_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_perfil_usuario_arch_id_foto_perf_foto_clase | `perfil_usuario` | arch_id_foto, perf_foto_clase | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_preferencia_notificacion_cate_id | `preferencia_notificacion` | cate_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_notificacion_cate_id | `notificacion` | cate_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_planificacion_usua_id_destinatario | `planificacion` | usua_id_destinatario | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_planificacion_usua_id_creador | `planificacion` | usua_id_creador | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_planificacion_arch_id_documento_plan_documento_clase | `planificacion` | arch_id_documento, plan_documento_clase | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_planificacion_lote_lote_id | `planificacion_lote` | lote_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_restablecimiento_clave_usua_id | `restablecimiento_clave` | usua_id | B-tree | Soporta la llave foránea (joins y borrados) |
| ix_evidencia_evid_geom_gist | `evidencia` | evid_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_hallazgo_hall_geom_gist | `hallazgo` | hall_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_lectura_trampa_lect_geom_gist | `lectura_trampa` | lect_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_lote_geometria_lotg_geom_gist | `lote_geometria` | lotg_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_predio_pred_geom_gist | `predio` | pred_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_reticula_celda_retc_geom_gist | `reticula_celda` | retc_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
| ix_ubicacion_trampa_ubic_geom_gist | `ubicacion_trampa` | ubic_geom | GiST | Consulta espacial (ST_Contains/ST_Intersects) |
