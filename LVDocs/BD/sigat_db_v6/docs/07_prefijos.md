# Prefijos de columnas (4 letras)

Cada columna empieza con las primeras 4 letras de su tabla. Las llaves foráneas llevan el prefijo de la tabla a la que apuntan. Si dos tablas darían las mismas 4 letras, la principal las conserva y la otra usa 3 letras + inicial de su 2.ª palabra (`lotg_`, `visl_`…). `rol` solo tiene 3 letras.

| Tabla | Prefijo | Área | Llave primaria |
| --- | --- | --- | --- |
| `administrador` | `admi_` | 2 | `admi_id` |
| `aplicacion_fitosanitaria` | `apli_` | 6 | `apli_id` |
| `arbol` | `arbo_` | 1 | `arbo_id` |
| `archivo_adjunto` | `arch_` | 9 | `arch_id` |
| `atrayente` | `atra_` | 1 | `atra_id` |
| `bitacora_auditoria` | `bita_` | 5 | `bita_id` |
| `bpa_verificacion` | `bpav_` | 8 | `bpav_id` |
| `categoria_notificacion` | `cate_` | 9 | `cate_id` |
| `centro_acopio` | `cent_` | 1 | `cent_id` |
| `concepto_aptitud` | `conc_` | 7 | `conc_id` |
| `condicion_trampa` | `cond_` | 1 | `cond_id` |
| `cosecha` | `cose_` | 6 | `cose_id` |
| `criterio_bpa` | `crit_` | 8 | `crit_id` |
| `departamento` | `depa_` | 1 | `depa_id` |
| `dispositivo` | `disp_` | 5 | `disp_id` |
| `escenario_trampeo` | `esce_` | 1 | `esce_id` |
| `especie_cultivo` | `espc_` | 1 | `espc_id` |
| `especie_mosca` | `espm_` | 1 | `espm_id` |
| `estado_registro` | `esta_` | 1 | `esta_id` |
| `estimacion_produccion` | `esti_` | 8 | `esti_id` |
| `etapa_declarada` | `etap_` | 6 | `etap_id` |
| `evidencia` | `evid_` | 9 | `evid_id` |
| `fenologia` | `feno_` | 1 | `feno_id` |
| `fenologia_regla` | `fenr_` | 3 | `fenr_id` |
| `hallazgo` | `hall_` | 8 | `hall_id` |
| `imagen_diseno` | `imag_` | 9 | `imag_id` |
| `indice_mtd` | `indi_` | 7 | `indi_id` |
| `indice_mtd_lectura` | `indm_` | 7 | (sin id propio) |
| `lectura_trampa` | `lect_` | 6 | `lect_id` |
| `localizacion` | `loca_` | 1 | `loca_id` |
| `lote` | `lote_` | 3 | `lote_id` |
| `lote_geometria` | `lotg_` | 3 | `lotg_id` |
| `manejo_agronomico` | `mane_` | 8 | `mane_id` |
| `municipio` | `muni_` | 1 | `muni_id` |
| `norma` | `norm_` | 1 | `norm_id` |
| `notificacion` | `noti_` | 9 | `noti_id` |
| `operacion_sync` | `oper_` | 5 | `oper_id` |
| `paquete_campo` | `paqu_` | 3 | `paqu_id` |
| `perfil_usuario` | `perf_` | 9 | (sin id propio) |
| `periodo_trampeo` | `peri_` | 7 | `peri_id` |
| `permiso` | `perm_` | 2 | `perm_id` |
| `persona` | `pers_` | 2 | (sin id propio) |
| `plaga_enfermedad` | `plag_` | 8 | `plag_id` |
| `planificacion` | `plan_` | 9 | `plan_id` |
| `planificacion_lote` | `plal_` | 9 | (sin id propio) |
| `predio` | `pred_` | 3 | `pred_id` |
| `preferencia_notificacion` | `pref_` | 9 | (sin id propio) |
| `producto_fitosanitario` | `prof_` | 1 | `prof_id` |
| `productor` | `prod_` | 2 | (sin id propio) |
| `programa_criterio_bpa` | `proc_` | 8 | (sin id propio) |
| `programa_inspeccion` | `prog_` | 3 | `prog_id` |
| `programa_umbral` | `prou_` | 3 | (sin id propio) |
| `rango_departamento` | `rang_` | 1 | (sin id propio) |
| `recepcion_sync` | `rece_` | 5 | `rece_id` |
| `region` | `regi_` | 1 | `regi_id` |
| `restablecimiento_clave` | `rest_` | 9 | `rest_id` |
| `reticula` | `reti_` | 3 | `reti_id` |
| `reticula_celda` | `retc_` | 3 | `retc_id` |
| `rol` | `rol_` | 1 | `rol_id` |
| `rol_permiso` | `rolp_` | 2 | (sin id propio) |
| `ruta` | `ruta_` | 2 | `ruta_id` |
| `severidad` | `seve_` | 8 | `seve_id` |
| `tecnico` | `tecn_` | 2 | `tecn_id` |
| `tipo_manejo` | `tipm_` | 8 | `tipm_id` |
| `tipo_trampa` | `tipt_` | 1 | `tipt_id` |
| `trampa` | `tram_` | 4 | `tram_id` |
| `ubicacion_trampa` | `ubic_` | 4 | `ubic_id` |
| `unidad_medida` | `unid_` | 1 | `unid_id` |
| `usuario` | `usua_` | 2 | `usua_id` |
| `usuario_predio` | `usup_` | 3 | `usup_id` |
| `variedad_cultivo` | `vari_` | 1 | `vari_id` |
| `vigilancia` | `vigi_` | 1 | `vigi_id` |
| `visita` | `visi_` | 6 | `visi_id` |
| `visita_lote` | `visl_` | 6 | (sin id propio) |
