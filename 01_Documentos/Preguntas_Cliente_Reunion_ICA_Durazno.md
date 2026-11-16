---
title: "Preguntas para la reunión con el cliente"
subtitle: "Cruce del cuestionario de levantamiento con el documento de requerimientos"
author: "Equipo de Arquitectura de Software"
date: "18 de octubre de 2026"
lang: es-CO
---

# Propósito y método {-}

Sistema en juego: **sistema de gestión y monitoreo de cultivos de durazno con fines de exportación** (ICA).

Este documento es el resultado de cruzar `Cuestionario_Levantamiento_Requisitos_Durazno.docx` (instrumento en blanco) con `Levantamiento_Requerimientos_ICA_Durazno.md` (versión 1.0, 3 de octubre de 2026). Cada ítem del cuestionario se contrastó con el levantamiento. Si el levantamiento ya lo resolvió por análisis del Manual de Trampeo (origen T1), la pregunta **no se hace** en la reunión (sección 7). Si quedó abierto (UQQ) o requiere validación del ICA (origen T2, RSK), entra a la agenda con su prioridad:

- **P1** – Bloquea el MVP. Sin respuesta se aplica el valor por defecto y se registra un ADR con su costo.
- **P2** – Bloquea decisiones de diseño o dimensionamiento.
- **P3** – Confirma una decisión ya adoptada. Se pregunta en 30 segundos, no se debate.

# Bloqueantes del MVP: las doce preguntas sin respuesta (P1)

| # | Pregunta para el cliente | UQQ | Ítems del cuestionario | Qué se bloquea | Si no llega respuesta |
|---|---|---|---|---|---|
| 1.1 | ¿Cómo define el ICA operativamente un **lote** para exportación, y coincide con la definición que usa el productor? La palabra «lote» no existe en el Manual de Trampeo (usa *predio*, *ruta de trampeo*, *sitio de monitoreo*). | UQQ-001 | 3.1, 5.6, 5.7 | Modelo de datos, RN-013 | El lote se trata como concepto configurable, no asumido (RSK-03) |
| 1.2 | ¿Cuántas trampas vigilan cada lote y con qué criterio se asigna una trampa a un lote? | UQQ-002 | 4.9, 7.1, 13.1 | RF-023 (cálculo de MTD por lote) | Estimación por defecto marcada como tal; sin esto no hay MTD por lote |
| 1.3 | Para predios de exportación, ¿la lectura de trampas es realmente cada **7 a 14 días** (Manual, Tabla 6)? El enunciado del proyecto dice «cada 4 meses». ¿Quién define el rango por sección (7 o 14 días)? | UQQ-003 | 3.2, 13.2 | RF-022, RF-074 | El sistema no supone cadencias: visita y lectura quedan como series independientes (RSK-05) |
| 1.4 | ¿Cuál es la **expresión numérica del umbral de MTD** que habilita o bloquea la exportación y en qué norma se fija? El Manual remite a la Resolución 8461 de 2019, que no fue accesible. | UQQ-004 | 16.1 | RF-024, concepto de aptitud | El sistema calcula el MTD pero **no emite concepto** (preferible a inventar el valor) |
| 1.5 | ¿En qué formato entrega el laboratorio el resultado de diagnóstico de especie (papel, correo, planilla, sistema)? | UQQ-006 | 7.1 | RF-025, RF-026, ciclo de laboratorio (v0.2) | El estado *pendiente de diagnóstico* sí se implementa; el enlace queda para v0.2 |
| 1.6 | ¿Qué proveedor de imagen satelital tiene **licencia que permita cache en el dispositivo**? ¿El ICA tiene licencia propia, usamos una existente o una ortofoto propia del predio? | UQQ-007 | 5.8, 6.2, 6.3, 14.3 | RF-005, RI-003, RI-004 | Fondo vectorial mínimo o ortofoto propia; se documenta el impacto |
| 1.7 | ¿Cuántos **predios, lotes, trampas y técnicos activos** tiene el ICA hoy en el programa de durazno? | UQQ-008 | 3.5, 3.6, 5.1, 5.2, 13.1–13.4 | Dimensionamiento, RNF-008, RNF-020 | Sin impacto en el modelo; afecta solo dimensionamiento (RSK-06) |
| 1.8 | ¿Qué **versiones de Android e iOS** deben soportarse? ¿Android exclusivamente o ambas plataformas? | UQQ-009 | 15.1, 15.5, 4.4 | RNF-019, RI-001 | Debe declararse antes de iniciar la construcción |
| 1.9 | ¿Cuánto tiempo debe conservarse el histórico de un lote (5, 10 años, indefinido)? | UQQ-010 | 13.5 | Retención y respaldo | Política de retención mínima propuesta por el equipo |
| 1.10 | ¿Qué datos personales se consideran sensibles y quién es el **responsable del tratamiento** (Ley 1581 de 2012)? | UQQ-011 | 12.4, 12.5, 9.6 | RNF-014 | Minimización de datos por defecto |
| 1.11 | ¿Cuál es el tiempo máximo aceptable entre la captura en campo y la disponibilidad del dato en el histórico? | UQQ-012 | 10.1, 11.4 | Prioridad del envío de evidencia fotográfica (RF-067) | El dato numérico primero, la foto en segundo plano sin bloquear |
| 1.12 | ¿Tamaño de celda de la retícula en metros? (Restricción normativa: debe ser mayor a 60 m por la distancia mínima entre trampas — RN-004.) | UQQ-005 | 5.6, 5.7, 6.4 | RF-006, RI-002 | Valor por defecto mayor a 60 m y múltiplo de la distancia mínima |

> **Nota para la reunión:** las preguntas 1.4, 1.6 y 1.12 conviene traerlas con una **propuesta de valor por defecto escrita**, para que el cliente sólo diga «sí» o corrija. Las preguntas 1.1 a 1.3 requieren traer extractos del Manual de Trampeo (sección 10 y Tablas 1 y 6) para mostrar de dónde salen.

# Decisiones ya adoptadas que el cliente debe ratificar (P3)

El levantamiento tomó decisiones explícitas que el cliente debe ratificar. Son preguntas de sí/no con contexto breve.

| # | Pregunta para el cliente | Decisión adoptada | Referencia |
|---|---|---|---|
| 2.1 | ¿Está de acuerdo en que **cada trampa tenga asignado el lote que vigila** y que el sistema exija esa correspondencia para calcular el MTD por lote? | Asignación trampa-lote explícita, capturada en la configuración del predio | RN-013, RF-013 |
| 2.2 | ¿Confirma que un **autorreporte del productor** (fumigaciones, cosecha, manejo) nunca genera concepto de aptitud ni alimenta el cálculo del MTD? La inspección oficial del ICA es el único linaje con efecto normativo. | Separación en dos linajes de datos, con marca de linaje en cada registro | Sección «Dos linajes», RN-014 |
| 2.3 | ¿Acepta que el **QR** de la trampa sea un mecanismo de comodidad (Should) y no un estándar del ICA? El Manual identifica trampas por código numérico impreso. El sistema mantiene la nomenclatura ICA (Divipola + ruta + número impar/par) como identificador canónico. | QR degradado a *Should*, con alternativa de selección manual | RSK-07, RN-005, RF-011 |
| 2.4 | ¿Acepta que la **fotografía** sea valor agregado (Should) y no requisito de cumplimiento? El Manual exige evidencia física: especimen en alcohol al 70 %, tarjeta de control firmada, acta de siembra. | Fotografía *Should*, sustitutable por notas textuales en el MVP | RF-033, RSK-07 |
| 2.5 | ¿Está de acuerdo en que el sistema, al detectar **incoherencia** entre trampa leída, lote asignado y ubicación GPS, **advierta y pida confirmación sin bloquear** el registro? | Advertencia con registro de evidencia, no bloqueo | RF-012, 16.4 |
| 2.6 | Regla de corrección: una vez sincronizado, un registro **no cambia su fecha de observación**; si el técnico se equivocó, se anula y se crea uno nuevo con la fecha correcta, ambos visibles. ¿Quién puede anular: el propio técnico, o solo el supervisor? | Inmutabilidad del pasado + anulación versionada (falta definir el rol) | RN-009, RF-052, 11.7, 16.5 |
| 2.7 | Cuando dos lecturas se solapen en el mismo periodo (por ejemplo, dos técnicos o una carga retroactiva), el sistema las marca «**revisar**» y las devuelve a un humano. ¿Quién resuelve ese estado: el técnico o el supervisor sectional? | Solapamiento marcado, no decidido automáticamente | RN-011, RF-066, 11.5, 11.6 |
| 2.8 | Si el umbral de exportación (1.4) no se entrega, el sistema calcula el MTD pero **no emite concepto de aptitud**. ¿Acepta esta conducta? | Sin valor inventado: vista previa del concepto vacía | Sección «Dependencias críticas del MVP», UQQ-004 |
| 2.9 | ¿Confirma que el recorrido del técnico dentro del predio es **deseable pero no crítico** (Should), y que el dato de origen del problema es el muestreo de trampas? | Recorrido fuera del MVP, en v0.4 | RF-009, sección «Fuera del MVP» |
| 2.10 | La aplicación no automatiza el trámite de exportación (licencia de movimentilización y certificado siguen en papel/institucional): solo produce el insumo técnico. ¿Es correcto el alcance? | Alcance declarado como restricción | RST-005 |

# Operación real: para cerrar el faltante metodológico (P1/P2)

El levantamiento declara que **no hubo entrevistas con técnicos del ICA ni observación de una visita real** (T5 y T6 no aplicadas; RSK-01 y RSK-02). Estas preguntas son el sustituto mínimo de esas técnicas.

| # | Pregunta para el cliente | Ítem del cuestionario | Por qué importa |
|---|---|---|---|
| 3.1 | ¿Quién realiza hoy el monitoreo: solo el técnico del ICA, o también el productor cuenta algo? | 3.1 | Define los perfiles reales (INS vs TIC) |
| 3.2 | Descríbanos el recorrido completo de una visita: quién fija el orden de los lotes, cuántas trampas recorre un técnico al día, cuánto demora cada lectura. | 3.2 | La secuencia del documento es una reconstrucción razonada, no una observación |
| 3.3 | ¿Qué formatos en papel usan hoy exactamente? ¿Traen ejemplares del formato de campo, la tarjeta de control de servicio y la relación de muestras? | 3.3 | El sistema debe reproducir los formatos oficiales (RI-006) |
| 3.4 | ¿Cuáles son los problemas concretos que hoy les cuestan más: perder el histórico, no distinguir correcciones, no poder comparar predios, otra cosa? | 3.4 | Valida que el problema descrito en el enunciado sea el real |
| 3.5 | ¿Qué campos son **obligatorios** para guardar una inspección según su procedimiento? ¿Se puede guardar una lectura sin número de especímenes o sin estado de la trampa? | 7.7 | Define la validación del formulario (RNF-002, CU-03) |
| 3.6 | ¿El técnico registra hoy la **hora** de la lectura de trampa? El Manual no la exige y el sistema no la capturará por defecto. | 7.1 | Confirma RST-008 |
| 3.7 | ¿Existe hoy un **inventario georreferenciado de trampas** (coordenadas de instalación)? Si existe, ¿en qué formato y quién lo tiene? | 4.2, 4.3 | RDD-004 y RF-084 exigen coordenadas WGS84 con 5 decimales |
| 3.8 | ¿Con qué **precisión** puede trabajar el técnico en campo hoy? ¿Disponen de receptor GNSS externo o solo del celular? | 4.1, 4.5 | RNF-006 exige 5 decimales (~1,1 m) en la georreferenciación de trampas |
| 3.9 | Cuando la precisión GPS sea insuficiente o se pierda la señal, ¿qué debe hacer la aplicación: advertir, pedir reintento, o registrar igualmente con la precisión obtenida? | 4.6, 4.7 | RF-012 advierte; falta confirmar el caso de pérdida de señal |
| 3.10 | ¿A qué **distancia** del técnico respecto a la trampa se considera que la inspección «ocurrió»? ¿Hay una tolerancia aceptable (por ejemplo 10, 20 metros)? | 16.2 | RF-012 compara ubicación pero el umbral de distancia no está definido |
| 3.11 | ¿Necesitan que el técnico vea el **histórico de visitas anteriores del predio en campo sin conexión**, o basta con el resumen del periodo actual? | 10.3 | Define el tamaño del paquete de campo (RF-004, RNF-020) |
| 3.12 | ¿Cuántos días puede estar un técnico sin volver a una zona con cobertura (peor caso razonable)? | 10.1, 10.2 | Dimensiona la cola de sincronización y la batería (RNF-005, RNF-008) |
| 3.13 | ¿Qué debe ocurrir si un lote no tiene trampas asociadas y el técnico quiere registrar una observación de campo? | 7.1 | El sistema ya propone registrar sin MTD; validar |

# Cartografía, dispositivos y mapas offline (P2)

| # | Pregunta para el cliente | Ítem del cuestionario | Referencia |
|---|---|---|---|
| 4.1 | ¿Los **límites geográficos de los lotes existen** hoy? ¿En qué formato (shapefile, GeoJSON, KML, plano)? ¿Quién los entrega? | 5.3, 5.4 | RDD-002, RF-084 |
| 4.2 | ¿Quién es el **responsable** de crear, validar y corregir los límites de los lotes: el ICA, el productor o un tercero (IGAC, consultor)? | 5.5 | RF-085 (versionado de geometría) |
| 4.3 | ¿Qué información cartográfica debe estar disponible sin Internet: solo lotes y trampas, también caminos, o imagen satelital completa? | 5.8, 5.9, 6.1 | RF-004, RI-004 |
| 4.4 | ¿El ICA tiene **datos propios** (ortofotos, cadastro) o licencia de algún servicio de mapas? ¿Se deben evitar servicios de mapas pagos? | 6.2, 14.3 | UQQ-007, RST-007 |
| 4.5 | ¿Cada cuánto cambian los límites de un lote o la imagen del predio? ¿Con qué frecuencia hay que actualizar los mapas offline? | 6.6 | RF-068 |
| 4.6 | ¿Quién **provee los dispositivos**: el ICA o el técnico usa el suyo propio? ¿Qué modelos y gama aproximada? | 15.2, 15.3, 4.4 | RNF-007 (gama media), RNF-019 |
| 4.7 | ¿Cuánto **almacenamiento** libre tienen los dispositivos para el paquete de campo y las fotos? | 6.5, 15.3 | RNF-020 |
| 4.8 | ¿Se dispone de **dispositivos de prueba** distintos para las pruebas de usabilidad y rendimiento? | 15.4 | RNF-001, RNF-007 |
| 4.9 | ¿Cómo se define la **instalación de una trampa Jackson** en un lote: cuántas trampas por hectárea, y depende de la variedad o de la etapa del cultivo? | 4.9 | RN-004 (40–60 m entre trampas), UQQ-002 |
| 4.10 | ¿Qué **catálogo oficial de plagas, enfermedades y hongos del durazno** aplican? ¿Existe una lista del ICA o se usa la del manual de moscas? | 7.3, 7.4 | RF-029, RF-081 |
| 4.11 | ¿El técnico debe seleccionar de listas o puede escribir texto libre en los hallazgos? | 7.5 | RF-029 (catálogo configurable + observaciones) |
| 4.12 | ¿Qué información debe descargarse obligatoriamente al teléfono antes de salir (paquete de campo)? ¿Incluye catálogos, umbrales, histórico? | 10.3 | RF-004 |

# Laboratorio, seguridad y gobierno (P2)

| # | Pregunta para el cliente | Ítem del cuestionario | Referencia |
|---|---|---|---|
| 5.1 | ¿Cómo se relacionan las muestras con el laboratorio hoy: qué campos lleva la relación de muestras y quién la radica? | 7.1, 18 | RF-027, RN-005, RN-006 |
| 5.2 | ¿El ICA tiene **proveedor de identidad institucional** (correo/Active Directory/SSO)? ¿Los productores se autentican igual que el personal del ICA? | 12.1, 12.2 | RI-008, RF-001 |
| 5.3 | ¿Qué **permisos** necesita cada rol: productor, técnico, supervisor, administrador, laboratorio, dirección técnica? ¿Quién administra los usuarios? | 12.3, 3.7, 3.8 | RF-002, RF-082, CU-13 |
| 5.4 | Si un teléfono se pierde o es robado: ¿el ICA puede **bloquearlo o borrarlo remotamente** (MDM)? ¿O confiamos solo en el cifrado local? | 12.6 | RNF-013 |
| 5.5 | ¿Cuánto tiempo puede durar una **sesión autenticada sin conexión**? Un técnico puede estar días sin cobertura. | 12.7 | RST-001, RF-060 |
| 5.6 | ¿Se conserva o se elimina la información **EXIF** de las fotos (que puede contener datos del dispositivo)? | 9.6 | RNF-014, RDD-011, UQQ-011 |
| 5.7 | ¿Cuántas fotos por inspección se esperan y a qué calidad? ¿Qué pasa si el teléfono se llena antes de sincronizar? | 9.2, 9.3, 9.5, 13.4 | RF-067, RNF-020 |
| 5.8 | ¿La plataforma de consulta institucional (para supervisor, dirección técnica y exportación) es parte de esta fase o una fase posterior? | — | RI-009 |

# Negocio, volumen y presupuesto (P2)

| # | Pregunta para el cliente | Ítem del cuestionario | Referencia |
|---|---|---|---|
| 6.1 | ¿Cuál es el **presupuesto inicial** para infraestructura y hay presupuesto mensual para servidores, almacenamiento, mapas o servicios externos? | 14.1, 14.2 | No cubierto en el levantamiento |
| 6.2 | ¿Se debe evitar el uso de **servicios de mapas pagos**? ¿Debe poder operar con infraestructura gratuita o de bajo costo al inicio? | 14.3, 14.4 | Condiciona UQQ-007 |
| 6.3 | ¿Qué **tecnología ya tiene disponible** el ICA (servidores, nube institucional, correo, sistemas como SIVIPA u otros)? | 14.5, 2 (contexto) | RI-008 |
| 6.4 | ¿Se espera **crecer a otros cultivos, frutas u otros predios**? El programa de moscas de la fruta cubre más que el durazno. | 13.6 | RNF-016, RST-002 (todo configurable por predio) |
| 6.5 | ¿Quién recibe y usa el **concepto de aptitud** que emite el sistema: el técnico, el supervisor, la dirección técnica, el comprador? | 16.1, 18 | RF-024, partes ORG y EICA |
| 6.6 | ¿Los **compradores u organismos de auditoría** exigen hoy reconstruir el estado fitosanitario de un lote en una fecha pasada? ¿Con qué profundidad de histórico? | 13.5 | RF-053, UQQ-010 |
| 6.7 | ¿Se espera que el **productor** use la app en su propio teléfono? ¿Tiene smartphone y conectividad en la finca? | 3.1, 3.5 | RF-040 a RF-044 (autorreporte), RNF-003 |

# Preguntas que no hay que hacer: ya respondidas en el levantamiento

No gastar tiempo de la reunión en estas: el documento ya las responde, y en varios casos el Manual del ICA las obliga. Basta con mencionarlas si alguien las plantea.

| Ítem del cuestionario | Respuesta ya resuelta | Referencia |
|---|---|---|
| 4.8, 16.3 ¿Guardar la precisión GPS en cada registro? | **Sí.** Se almacena la precisión reportada por el dispositivo; coordenadas WGS84 con 5 decimales | RNF-006, RN-006 |
| 7.6 ¿Identificación automática de plagas por IA? | **No.** El sistema registra y cataloga; no diagnostica por imagen ni IA | RST-006 |
| 12.1 ¿Se requiere autenticación? | **Sí.** Autenticación antes de operar sobre un predio | RF-001 |
| 10.4 ¿Qué información permanece local hasta sincronizar? | **Todo lo capturado**, con persistencia inmediata y cola de salida | RF-061, RF-062 |
| 10.5, 10.6, 10.7 ¿Sin batería, cierre inesperado o reinicio? | Cero pérdida de registros confirmados; recuperación desde copia local | RNF-009, RNF-010, RF-061 |
| 11.1, 11.2, 11.3, 11.4 ¿Qué y cómo se sincroniza, y qué pasa si falla? | Cola automática con reintentos, resultado por operación, aceptación parcial, idempotencia | RF-062 a RF-064, RN-010 |
| 11.8 ¿Historial/auditoría de modificaciones? | **Sí.** Bitácora inmutable con actor, fechas y versiones | RF-083 |
| 8.3 ¿Zonas inspeccionadas y pendientes? | **Sí** (prioridad Should, fuera del MVP; v0.4) | RF-009 |
| 5.6, 5.7 ¿Dividir lotes en zonas internas? | Se usa la **celda de retícula** como subdivisión de referencia, con resolución configurable por predio | RF-006, RI-002 |
| 9.4 ¿Fotografías completamente offline? | **Sí.** Se envían después del dato numérico, sin bloquear el cierre de la visita | RF-067 |
| 7.1 ¿Qué registrar al inspeccionar una trampa? | Número de especímenes, fecha de lectura, estado, cambios de cuerpo y atrayente, observaciones, estado de diagnóstico | RF-020, RF-021, RDD-005 |
| 16.4 ¿Ubicación incorrecta accidental? | Advierte, muestra el lote asignado y pide confirmación sin bloquear | RF-012 |
| 11.7 ¿Editar inspecciones históricas? | No se edita la fecha de observación: se anula y se recrea, ambos visibles (falta definir quién anula — ver 2.6) | RN-009, RF-052 |
| 18 (lista) ¿Qué precisión GPS es necesaria? | 5 decimales WGS84 para georreferenciación de trampas | RNF-006 |

# Solicitud metodológica para abrir la reunión (P1)

Proponer en la reunión, como primer punto:

1. **Entrevista con al menos dos técnicos del ICA** en la semana 1 (mitiga RSK-01). Sin ella, el documento se reemitirá como v1.1 con correcciones.
2. **Observar al menos dos visitas reales** antes de cerrar el modelo de dominio (mitiga RSK-02). El equipo de arquitectura ya las tiene programadas en su semana de descubrimiento.
3. **Traer a la reunión:** el Manual de Trampeo (sección 10 y Tablas 1, 3 y 6), la **Resolución 8461 de 2019** (fuente del umbral de exportación, UQQ-004), un ejemplar de los formatos de campo en papel (MF\_Cap, MF\_Ubi, tarjeta de control de servicio) y, si es posible, un inventario de trampas georreferenciado.
4. Confirmar quién tiene **autoridad para decidir** cada tema: la DTEVF define la norma; la seccional ejecuta; el productor es usuario. Varias preguntas de la sección 1 solo pueden responderse con una persona que pueda decidir.

# Apéndice. Correspondencia cuestionario y levantamiento {-}

| Sección del cuestionario | Estado tras el cruce |
|---|---|
| 3. Usuarios y operación | Abierta en su totalidad (T5/T6 no aplicadas). Ver sección 3 |
| 4. GPS y precisión | 4.8 resuelta; 4.9 parcialmente (RN-004); resto abierta |
| 5. Lotes y cartografía | 5.6/5.7 parcialmente (retícula); resto bloqueada por UQQ-005, UQQ-007, UQQ-008 |
| 6. Mapas offline | 6.1 y 6.3 resueltas en diseño; 6.2/6.4/6.6 abiertas |
| 7. Inspecciones y trampas | 7.1 y 7.6 resueltas; 7.3/7.4/7.5 abiertas (catálogo); 7.7 abierta |
| 8. Recorridos | 8.1/8.3 decididas (Should, fuera del MVP); 8.2/8.4/8.5 abiertas |
| 9. Fotografías | 9.4 resuelta; 9.1 ratificable (Should); 9.2/9.3/9.5/9.6 abiertas |
| 10. Offline | 10.3 a 10.7 resueltas en diseño; 10.1/10.2 abiertas (volumen temporal) |
| 11. Sincronización | 11.1 a 11.4 y 11.8 resueltas; 11.5 a 11.7 requieren política del cliente (2.6, 2.7) |
| 12. Seguridad | 12.1 resuelta; 12.2/12.3/12.4/12.5/12.6/12.7 abiertas |
| 13. Volumen | Abierta (UQQ-008, UQQ-010) |
| 14. Presupuesto | Abierta en su totalidad |
| 15. Dispositivos | Abierta (UQQ-009) |
| 16. Validación de inspecciones | 16.3 y 16.4 resueltas; 16.1/16.2/16.5 abiertas |
| 18. Validación externa | Incorporada en secciones 1, 3 y 4 |
