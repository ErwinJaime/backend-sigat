# Matriz de relaciones (llaves foráneas)

164 relaciones. Acción ON DELETE / ON UPDATE: la predeterminada de PostgreSQL (NO ACTION): no se puede borrar un registro referenciado.

| Tabla hija | Columnas | Tabla padre | Columnas padre | Cardinalidad | Participación de la hija |
| --- | --- | --- | --- | --- | --- |
| `administrador` | `pers_cc` | `persona` | `pers_cc` | 1:1 | obligatoria |
| `departamento` | `regi_id` | `region` | `regi_id` | N:1 | obligatoria |
| `municipio` | `depa_id` | `departamento` | `depa_id` | 1:1 | obligatoria |
| `administrador` | `cent_id` | `centro_acopio` | `cent_id` | N:1 | obligatoria |
| `ruta` | `cent_id` | `centro_acopio` | `cent_id` | 1:1 | obligatoria |
| `rango_departamento` | `depa_id` | `departamento` | `depa_id` | 1:1 | obligatoria |
| `centro_acopio` | `depa_id` | `departamento` | `depa_id` | N:1 | obligatoria |
| `variedad_cultivo` | `espc_id` | `especie_cultivo` | `espc_id` | 1:1 | obligatoria |
| `tecnico` | `pers_cc` | `persona` | `pers_cc` | 1:1 | obligatoria |
| `tecnico` | `cent_id` | `centro_acopio` | `cent_id` | N:1 | obligatoria |
| `tecnico` | `admi_id` | `administrador` | `admi_id` | N:1 | obligatoria |
| `tecnico` | `esta_id` | `estado_registro` | `esta_id` | N:1 | obligatoria |
| `productor` | `pers_cc` | `persona` | `pers_cc` | 1:1 | obligatoria |
| `productor` | `prod_tecnico_registro_id` | `tecnico` | `tecn_id` | N:1 | obligatoria |
| `productor` | `prod_tecnico_actualizacion_id` | `tecnico` | `tecn_id` | N:1 | opcional |
| `productor` | `muni_id` | `municipio` | `muni_id` | N:1 | obligatoria |
| `ruta` | `muni_id` | `municipio` | `muni_id` | N:1 | opcional |
| `ruta` | `ruta_admin_registro_id` | `administrador` | `admi_id` | N:1 | obligatoria |
| `ruta` | `ruta_admin_actualizacion_id` | `administrador` | `admi_id` | N:1 | opcional |
| `ruta` | `esta_id` | `estado_registro` | `esta_id` | N:1 | obligatoria |
| `usuario` | `pers_cc` | `persona` | `pers_cc` | 1:1 | obligatoria |
| `usuario` | `rol_id` | `rol` | `rol_id` | N:1 | obligatoria |
| `usuario` | `esta_id` | `estado_registro` | `esta_id` | N:1 | obligatoria |
| `rol_permiso` | `rol_id` | `rol` | `rol_id` | N:1 | obligatoria |
| `rol_permiso` | `perm_id` | `permiso` | `perm_id` | N:1 | obligatoria |
| `predio` | `muni_id` | `municipio` | `muni_id` | N:1 | obligatoria |
| `predio` | `pers_cc` | `productor` | `pers_cc` | N:1 | obligatoria |
| `predio` | `pred_tecnico_registro_id` | `tecnico` | `tecn_id` | N:1 | obligatoria |
| `predio` | `pred_tecnico_actualizacion_id` | `tecnico` | `tecn_id` | N:1 | opcional |
| `lote` | `pred_id` | `predio` | `pred_id` | 1:1 | obligatoria |
| `lote` | `espc_id` | `especie_cultivo` | `espc_id` | N:1 | opcional |
| `lote` | `espc_id`, `vari_id` | `variedad_cultivo` | `espc_id`, `vari_id` | N:1 | opcional |
| `lote` | `lote_tecnico_registro_id` | `tecnico` | `tecn_id` | N:1 | obligatoria |
| `lote` | `lote_tecnico_actualizacion_id` | `tecnico` | `tecn_id` | N:1 | opcional |
| `lote_geometria` | `lote_id` | `lote` | `lote_id` | 1:1 | obligatoria |
| `reticula` | `pred_id` | `predio` | `pred_id` | 1:1 | obligatoria |
| `fenologia_regla` | `espc_id` | `especie_cultivo` | `espc_id` | N:1 | obligatoria |
| `reticula_celda` | `reti_id` | `reticula` | `reti_id` | 1:1 | obligatoria |
| `usuario_predio` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `usuario_predio` | `pred_id` | `predio` | `pred_id` | N:1 | obligatoria |
| `usuario_predio` | `rol_id` | `rol` | `rol_id` | N:1 | obligatoria |
| `usuario_predio` | `usup_asignado_por` | `usuario` | `usua_id` | N:1 | opcional |
| `programa_inspeccion` | `pred_id` | `predio` | `pred_id` | 1:1 | obligatoria |
| `programa_inspeccion` | `reti_id`, `pred_id` | `reticula` | `reti_id`, `pred_id` | N:1 | opcional |
| `programa_inspeccion` | `norm_id` | `norma` | `norm_id` | N:1 | opcional |
| `programa_inspeccion` | `prog_creado_por` | `usuario` | `usua_id` | N:1 | opcional |
| `programa_umbral` | `prog_id` | `programa_inspeccion` | `prog_id` | N:1 | obligatoria |
| `programa_umbral` | `esce_id` | `escenario_trampeo` | `esce_id` | N:1 | obligatoria |
| `fenologia_regla` | `feno_id` | `fenologia` | `feno_id` | N:1 | obligatoria |
| `paquete_campo` | `pred_id` | `predio` | `pred_id` | 1:1 | obligatoria |
| `paquete_campo` | `prog_id`, `pred_id` | `programa_inspeccion` | `prog_id`, `pred_id` | N:1 | obligatoria |
| `trampa` | `tipt_id` | `tipo_trampa` | `tipt_id` | N:1 | obligatoria |
| `trampa` | `atra_id` | `atrayente` | `atra_id` | N:1 | obligatoria |
| `trampa` | `esta_id` | `estado_registro` | `esta_id` | N:1 | obligatoria |
| `trampa` | `tram_tecnico_registro_id` | `tecnico` | `tecn_id` | N:1 | obligatoria |
| `trampa` | `tram_tecnico_actualizacion_id` | `tecnico` | `tecn_id` | N:1 | opcional |
| `trampa` | `tram_tecnico_estado_id` | `tecnico` | `tecn_id` | N:1 | opcional |
| `visita` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `visita` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `visita` | `pred_id` | `predio` | `pred_id` | N:1 | obligatoria |
| `ubicacion_trampa` | `tram_id` | `trampa` | `tram_id` | N:1 | obligatoria |
| `ubicacion_trampa` | `pred_id` | `predio` | `pred_id` | N:1 | obligatoria |
| `ubicacion_trampa` | `lote_id`, `pred_id` | `lote` | `lote_id`, `pred_id` | N:1 | opcional |
| `ubicacion_trampa` | `tecn_id` | `tecnico` | `tecn_id` | N:1 | obligatoria |
| `ubicacion_trampa` | `vigi_id` | `vigilancia` | `vigi_id` | N:1 | obligatoria |
| `ubicacion_trampa` | `ruta_id` | `ruta` | `ruta_id` | N:1 | opcional |
| `ubicacion_trampa` | `retc_id` | `reticula_celda` | `retc_id` | N:1 | opcional |
| `ubicacion_trampa` | `loca_id` | `localizacion` | `loca_id` | N:1 | opcional |
| `ubicacion_trampa` | `arbo_id` | `arbol` | `arbo_id` | N:1 | opcional |
| `operacion_sync` | `disp_id` | `dispositivo` | `disp_id` | 1:1 | obligatoria |
| `operacion_sync` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `operacion_sync` | `oper_resuelve_oper_id` | `operacion_sync` | `oper_id` | N:1 | opcional |
| `visita` | `ruta_id` | `ruta` | `ruta_id` | N:1 | opcional |
| `visita` | `visi_revisada_por` | `usuario` | `usua_id` | N:1 | opcional |
| `visita_lote` | `visi_id`, `pred_id` | `visita` | `visi_id`, `pred_id` | N:1 | obligatoria |
| `recepcion_sync` | `oper_id` | `operacion_sync` | `oper_id` | N:1 | obligatoria |
| `bitacora_auditoria` | `usua_id` | `usuario` | `usua_id` | N:1 | opcional |
| `bitacora_auditoria` | `disp_id` | `dispositivo` | `disp_id` | N:1 | opcional |
| `visita` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `visita_lote` | `lote_id`, `pred_id` | `lote` | `lote_id`, `pred_id` | N:1 | obligatoria |
| `lectura_trampa` | `visi_id` | `visita` | `visi_id` | N:1 | obligatoria |
| `lectura_trampa` | `tram_id` | `trampa` | `tram_id` | N:1 | obligatoria |
| `lectura_trampa` | `ubic_id`, `tram_id` | `ubicacion_trampa` | `ubic_id`, `tram_id` | N:1 | opcional |
| `lectura_trampa` | `cond_id` | `condicion_trampa` | `cond_id` | N:1 | obligatoria |
| `lectura_trampa` | `atra_id` | `atrayente` | `atra_id` | N:1 | opcional |
| `lectura_trampa` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `lectura_trampa` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `lectura_trampa` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `aplicacion_fitosanitaria` | `pers_cc_responsable` | `persona` | `pers_cc` | N:1 | opcional |
| `aplicacion_fitosanitaria` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `aplicacion_fitosanitaria` | `prof_id` | `producto_fitosanitario` | `prof_id` | N:1 | opcional |
| `aplicacion_fitosanitaria` | `apli_dosis_uni_id` | `unidad_medida` | `unid_id` | N:1 | obligatoria |
| `aplicacion_fitosanitaria` | `apli_area_uni_id` | `unidad_medida` | `unid_id` | N:1 | obligatoria |
| `aplicacion_fitosanitaria` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `aplicacion_fitosanitaria` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `aplicacion_fitosanitaria` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `cosecha` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `cosecha` | `cose_volumen_uni_id` | `unidad_medida` | `unid_id` | N:1 | obligatoria |
| `cosecha` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `cosecha` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `cosecha` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `etapa_declarada` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `etapa_declarada` | `feno_id` | `fenologia` | `feno_id` | N:1 | obligatoria |
| `etapa_declarada` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `etapa_declarada` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `etapa_declarada` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `periodo_trampeo` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `periodo_trampeo` | `vigi_id` | `vigilancia` | `vigi_id` | N:1 | obligatoria |
| `periodo_trampeo` | `prog_id` | `programa_inspeccion` | `prog_id` | N:1 | obligatoria |
| `indice_mtd` | `peri_id` | `periodo_trampeo` | `peri_id` | N:1 | obligatoria |
| `indice_mtd` | `espm_id` | `especie_mosca` | `espm_id` | N:1 | opcional |
| `indice_mtd` | `norm_id` | `norma` | `norm_id` | N:1 | opcional |
| `indice_mtd` | `esce_id` | `escenario_trampeo` | `esce_id` | N:1 | opcional |
| `indice_mtd_lectura` | `indi_id` | `indice_mtd` | `indi_id` | N:1 | obligatoria |
| `indice_mtd_lectura` | `lect_id` | `lectura_trampa` | `lect_id` | N:1 | obligatoria |
| `manejo_agronomico` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `concepto_aptitud` | `lote_id` | `lote` | `lote_id` | 1:1 | obligatoria |
| `concepto_aptitud` | `peri_id`, `lote_id` | `periodo_trampeo` | `peri_id`, `lote_id` | N:1 | obligatoria |
| `concepto_aptitud` | `indi_id`, `peri_id` | `indice_mtd` | `indi_id`, `peri_id` | N:1 | obligatoria |
| `concepto_aptitud` | `norm_id` | `norma` | `norm_id` | N:1 | opcional |
| `hallazgo` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `hallazgo` | `retc_id` | `reticula_celda` | `retc_id` | N:1 | opcional |
| `hallazgo` | `plag_id` | `plaga_enfermedad` | `plag_id` | N:1 | obligatoria |
| `hallazgo` | `seve_id` | `severidad` | `seve_id` | N:1 | obligatoria |
| `hallazgo` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `hallazgo` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `hallazgo` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `programa_criterio_bpa` | `prog_id` | `programa_inspeccion` | `prog_id` | N:1 | obligatoria |
| `programa_criterio_bpa` | `crit_id` | `criterio_bpa` | `crit_id` | N:1 | obligatoria |
| `bpa_verificacion` | `visi_id`, `lote_id` | `visita_lote` | `visi_id`, `lote_id` | N:1 | obligatoria |
| `bpa_verificacion` | `crit_id` | `criterio_bpa` | `crit_id` | N:1 | obligatoria |
| `bpa_verificacion` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `bpa_verificacion` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `bpa_verificacion` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `manejo_agronomico` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `evidencia` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `estimacion_produccion` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `estimacion_produccion` | `esti_rendimiento_uni_id` | `unidad_medida` | `unid_id` | N:1 | obligatoria |
| `estimacion_produccion` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `estimacion_produccion` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `estimacion_produccion` | `oper_id` | `operacion_sync` | `oper_id` | 1:1 | obligatoria |
| `manejo_agronomico` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `manejo_agronomico` | `tipm_id` | `tipo_manejo` | `tipm_id` | N:1 | obligatoria |
| `manejo_agronomico` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `evidencia` | `hall_id` | `hallazgo` | `hall_id` | N:1 | opcional |
| `evidencia` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `evidencia` | `disp_id` | `dispositivo` | `disp_id` | N:1 | obligatoria |
| `archivo_adjunto` | `usua_id` | `usuario` | `usua_id` | N:1 | opcional |
| `archivo_adjunto` | `disp_id` | `dispositivo` | `disp_id` | N:1 | opcional |
| `evidencia` | `arch_id`, `evid_clase` | `archivo_adjunto` | `arch_id`, `arch_clase` | 1:1 | opcional |
| `evidencia` | `lect_id` | `lectura_trampa` | `lect_id` | N:1 | opcional |
| `imagen_diseno` | `arch_id`, `arch_clase` | `archivo_adjunto` | `arch_id`, `arch_clase` | 1:1 | obligatoria |
| `perfil_usuario` | `usua_id` | `usuario` | `usua_id` | 1:1 | obligatoria |
| `perfil_usuario` | `arch_id_foto`, `perf_foto_clase` | `archivo_adjunto` | `arch_id`, `arch_clase` | N:1 | opcional |
| `preferencia_notificacion` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
| `preferencia_notificacion` | `cate_id` | `categoria_notificacion` | `cate_id` | N:1 | obligatoria |
| `notificacion` | `usua_id` | `usuario` | `usua_id` | 1:1 | obligatoria |
| `notificacion` | `cate_id` | `categoria_notificacion` | `cate_id` | N:1 | obligatoria |
| `planificacion` | `usua_id_destinatario` | `usuario` | `usua_id` | N:1 | obligatoria |
| `planificacion` | `usua_id_creador` | `usuario` | `usua_id` | N:1 | obligatoria |
| `planificacion` | `arch_id_documento`, `plan_documento_clase` | `archivo_adjunto` | `arch_id`, `arch_clase` | N:1 | opcional |
| `planificacion_lote` | `plan_id` | `planificacion` | `plan_id` | N:1 | obligatoria |
| `planificacion_lote` | `lote_id` | `lote` | `lote_id` | N:1 | obligatoria |
| `restablecimiento_clave` | `usua_id` | `usuario` | `usua_id` | N:1 | obligatoria |
