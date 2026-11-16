---
title: "Arquitectura tecnologica"
subtitle: "Sistema de gestion y monitoreo de cultivos de durazno con fines de exportacion"
author: "Equipo de Arquitectura de Software"
date: "3 de octubre de 2026"
lang: es-CO
---

# Introduccion {#sec-intro-arq}

## Proposito {#sec-proposito-arq}

Este documento describe la arquitectura tecnologica del sistema de gestion y monitoreo de cultivos de
durazno con fines de exportacion, en adelante *el Sistema*. Describe el estilo arquitectonico, las
tecnologias elegidas y el motivo de cada eleccion, los cuatro niveles del modelo C4, el modelo temporal
que resuelve el problema central, el modelo de datos, los contratos de API y de datos, la estructura de
los repositorios de codigo y las puertas de calidad que este documento exige antes de fusionar, la
seguridad, la vista de despliegue y las decisiones de arquitectura registradas.

El documento es el contrato con el equipo de desarrollo: ademas de decir que se construye, dice donde
vive el codigo, como se comprueba que nadie ha cruzado una frontera y quien revisa cada fusion.

El documento **consume** el documento de levantamiento de requerimientos y no lo sustituye. Cada
decision arquitectonica que se justify por un requisito cita el identificador de ese requisito, de modo
que el lector puede verificar en un paso si la decision esta justificada o si es una preferencia del
equipo de arquitectura.

## Documentos relacionados {#sec-relacionados}

| Documento | Papel en este documento |
|---|---|
| *Levantamiento de requerimientos (ISO/IEC/IEEE 29148)* | Define **que** debe hacer el sistema. Este documento define **como** se construye |
| *Tabla de prioridades y MVP* | Define **en que orden** se construye, y es el documento que el equipo de desarrollo abre a diario |
| *Manual Tecnico de Trampeo de Moscas de la Fruta* (ICA, 2020) | Fuente normativa de las reglas de negocio |
| *Analisis del problema del proyecto* | Origen del enunciado y de las restricciones de contexto |

## Convenciones {#sec-convenciones-arq}

Las referencias `RF-nnn`, `RNF-nnn`, `RN-nnn`, `RST-nnn` y `UQQ-nnn` apuntan al documento de
levantamiento. Las referencias `ADR-nn` apuntan a las decisiones de arquitectura de la
seccion\nobreakspace\ref{adr}, registradas ahi en formato resumido y en formato completo dentro de la entrega
documental del proyecto.

## Que es C4 y por que se usa aqui {#sec-c4}

El modelo C4 (Simon Brown) organiza una arquitectura en cuatro niveles de zoom con granularidad
creciente: contexto de sistema, contenedores, componentes y codigo. Se acompana de dos vistas
adicionales que en este problema son tan importantes como los propios niveles: la **vista dinamica**,
que muestra como colaboran las piezas en un escenario concreto, y la **vista de despliegue**, que
muestra donde se ejecuta cada pieza en el mundo fisico.

La razon por la que C4 es el metodo adecuado aqui y no otro es que este sistema tiene una propiedad
que casi ningun diagrama de cajas representa bien: **dos de sus piezas principales no conversan
durante el proceso que mas importa**. El dispositivo opera horas sin red y el servidor recibe la
informacion despues. Un diagrama de componentes dibujado como si todo ocurriera en linea daria una
arquitectura que fallaria en el campo. Por eso la vista dinamica de la seccion\nobreakspace\ref{sec-c4-dinamica} no
es un extra: es el criterio de aceptacion arquitectonico del proyecto.

## Profundidad de la documentacion {#sec-profundidad}

Con un equipo de diez personas en once semanas, entregar los cuatro niveles de C4 mas las dos vistas
es factible, pero solo con una regla explicita de profundidad.

| Nivel | Producto | Profundidad en esta fase | Condicion |
|---|---|---|---|
| C0 | Contexto de sistema | Completa | Concluido con el alcance definido |
| C1 | Contenedores | Completa | Es la frontera con el equipo de desarrollo |
| C2 | Componentes | **Selectiva**: solo el nucleo de registro e historial y el motor de sincronizacion | Son los que concentran la complejidad |
| C3 | Codigo | **No se entrega.** Se entrega el contrato de datos, el de API y la estructura de carpetas que el codigo debe respetar | Se delega al equipo de desarrollo; lo comprueba la integracion continua |
| Dinamica | Escenario de visita, carga tardia y alta retroactiva | Completa | Es el criterio de aceptacion arquitectonico |
| Despliegue | Campo y nube | Completa | Deriva de RF-060 y RST-001 |

Esta tabla es una decision, no una omision. Documentada, es defendible; no documentada, se vuelve un
hueco que alguien descubrira tarde.

# Estilo arquitectonico {#sec-estilo}

## La pregunta que hay que responder primero {#sec-estilo-pregunta}

La idea inicial del proyecto era construir el sistema como una aplicacion de microservicios. Esa
decision merece un analisis honesto antes de adoptarla o descartarla, porque «microservicios» es una
palabra que suele usarse para nombrar una aspiracion en lugar de una necesidad.

**Que necesita el sistema.** De los requisitos del documento de levantamiento, los que tienen impacto
directo sobre el estilo arquitectonico son cinco:

1. RF-060: la visita se ejecuta sin conexion y la carga ocurre despues.
2. RF-065 y RF-054: un registro que llega fuera de orden obliga a **recalcular** el MTD y **reemitir** el
   concepto de aptitud de un periodo ya publicado.
3. RF-024: el concepto de aptitud debe poder reconstruirse tal como se habria emitido en cualquier
   fecha pasada.
4. RN-003 y RN-014: el umbral y la etapa fenologica aplicables dependen de la fecha del periodo.
5. RF-083: toda operacion debe quedar en una bitacora que no admite modificacion.

El punto 2 es el decisivo. Un alta retroactiva **no es una peticion**: es una operacion que toca
simultaneamente la serie de mediciones, el indice MTD del periodo, el concepto de aptitud emitido y la
bitacora de auditoria. Si esas cuatro cosas viven en servicios distintos, el sistema debe resolver una
transaccion distribuida entre ellos, o aceptar que queden inconsistentes entre si.

## La decision {#sec-estilo-decision}

> **El Sistema se construye como un monolito modular con fronteras de microservicio.** Un solo
> despliegue, con modulos de dominio explicitos, cada uno con su contrato, su modelo de datos logico y
> su frontera de ownership; y un registro formal de que modulos son **candidatos** a extraer como
> servicios independientes si aparece una necesidad concreta.

La razon de elegir esta via y no la de microservicios desde el inicio no es el tamaño del equipo, que es
un argumento de proyecto y no de arquitectura. Es que **el problema de consistencia transaccional del
sistema esta concentrado en el nucleo de registro, y un nucleo transaccional es exactamente lo que los
microservicios no saben hacer**. Repartirlo entre servicios obligaria a inventar una transaccion
distribuida para resolver un problema que no existe todavia.

Lo que si se hace, y es la parte que evita repetir esta discusion en seis meses, es **diseñar el nucleo
como si ya fuera un conjunto de servicios**:

- Cada modulo tiene un **contrato de entrada y salida** explicito, definido en terminos de operaciones
  idempotentes con clave de idempotencia.
- Las communication entre modulos es **por contrato**, no por acceso directo a tablas.
- Los modulos que mas probablemente se extraen —por tener carga o ciclo propio— **no comparten tablas**
  con los demas desde el dia uno.
- Cada modulo tiene una **frontera de datos declarada** en el modelo de datos, de modo que extraerlo sea
  mover un esquema, no reescribir la aplicacion.

## Los tres modulos que seran servicios si el proyecto lo necesita {#sec-estilo-candidatos}

No todos los modulos tienen el mismo perfil. Estos tres son los que, por su naturaleza, son candidatos
reales a extraccion desde el MVP:

| Modulo | Por que es candidato natural | Señal que justificaria extraerlo |
|---|---|---|
| **Evidencia e imagenes** | Almacena binarios, no filas. Su ciclo de vida, su politica de retencion y su perfil de carga (transferencia de archivos pesados sobre enlace intermitente) no tienen nada que ver con el resto | Volumen de imagenes que hace inviable la base transaccional |
| **Concepto de aptitud y reportes** | Es una lectura analitica sobre datos ya cerrados. Puede ser lento, cacheable y reconstruible | Latencia de los reportes que degrada la operacion transaccional |
| **Notificaciones y recordatorios** | Necesita un agente que programe recordatorios y una cola de trabajo con reintentos | Si se conecta a un canal institucional (correo, SMS, llamada) |

Los otros cuatro —configuracion de predios, registro e historial, catalogo, sincronizacion y
autorizacion— **no son candidatos a extraer**. Su volumen es el del ICA, su carga es la de sus
usuarios, y separarlos solo produciria latencia de red en el camino critico sin contrapartida.

> **Nota sobre la sincronizacion como servicio.** El motor de sincronizacion tiene carga asincrona
> —reprocesar periodos, recalcular indices, reemitir conceptos— y esa asincronia es real. Pero esa
> carga se resuelve **con una cola de trabajo dentro del mismo despliegue**, no con un despliegue
> separado. Un despliegue separado solo se justifica cuando el recurso que se agota es la maquina, y en
> este caso no lo es: el cuello de botella es el enlace rural del dispositivo, no el servidor.

## Lo que se descarta de la idea de microservicios {#sec-estilo-descarta}

| Idea | Motivo de la exclusion |
|---|---|
| Base de datos por servicio | El nucleo de registro necesita una transaccion unica; dividirla introduce consistencia eventual donde hoy hay una garantia fuerte |
| Descubrimiento de servicios | No hay servicios independientes: hay modulos dentro de un despliegue |
|balanceo de carga entre servicios | No aplica a un despliegue unico |
| Trazabilidad distribuida obligatoria | El proceso asincrono si necesita traza, pero dentro de una sola unidad de despliegue es un registro estructurado, no OpenTelemetry |
| Malla de API o bus de eventos | No hay servicios que descubirse. La comunicacion interna es por contrato en proceso |

**Esto no es un paso cero hacia los microservicios.** Es la decision de no pagar el costo de operacion
distribuida hasta que un modulo demuestre que lo necesita, dejando por escrito cuales son esos tres
modulos y cual es la señal que justificaria extraerlos.

# Decisiones tecnologicas {#sec-tecnologias}

Este apartado no es una lista de herramientas. Cada eleccion se presenta con la razon por la que las
alternativas fueron descartadas, porque una decision tecnologica sin alternativas descartadas
documentadas no es una decision: es una preferencia.

## Cliente movil {#sec-tec-movil}

**Flutter.** Requisito que lo obliga: RST-003 y la declaracion del proyecto de construir en Flutter.

| Criterio | Flutter | React Native | Nativo (Kotlin y Swift) |
|---|---|---|---|
| Rendimiento de listas largas y mapas | Bueno | Bueno | Excelente |
| Soporte de mapa con tiles sin conexion | Bueno | Regular | Excelente |
| Un solo codigo para dos plataformas | Si | Si | No |
| Camara y codigo QR | Nativo del ecosistema | Requiere biblioteca de terceros | Nativo |
| Almacenamiento local relacional | Si | Si | Si |
| Tamaño de la aplicacion | Medio | Medio | Bajo |
| Curva de aprendizaje para el equipo | Media | Baja | Alta (dos lenguajes) |

**Decision.** Flutter, por el requisito explicito del proyecto y porque cubre camara, GPS, almacenamiento
local y mapas en un solo entorno.

**Aclaracion importante sobre el mapa.** La decision de Flutter no resuelve por si sola el problema del
mapa sin conexion, que es el riesgo tecnico mas grande de este proyecto. Ese problema tiene su propia
decision, en el apartado de motor de mapas.

## Base de datos local del dispositivo {#sec-tec-local}

**SQLite con una capa de acceso que use reactive statements.**

| Criterio | SQLite | Base in-memory (Drift, Isar, Realm) | Preferences / archivos |
|---|---|---|---|
| Consultas relacionales y joins | Si | Parcial | No |
| Transacciones ACID | Si | Parcial | No |
| Cifrado del contenido | Si, con extension | Variable | No |
| Tolerancia a corrupcion por corte de energia | Alta | Baja | Media |
| Consultas espaciales | Con extension | No | No |

**Decision.** SQLite.

La razon determinante no es el rendimiento sino **la tolerancia a la corrupcion**. Este sistema escribe
en campo, con el dispositivo cerrandose sin advertencia, y un registro a medio escribir que se pierde es
exactamente el problema que el proyecto viene a resolver. SQLite con escritura atomica y una base en
memoria que se reconstruye al abrir son soluciones de riesgo opuesto: la segunda es mas rapida y la
primera sobrevive al corte de energia.

## Motor de mapas {#sec-tec-mapas}

Esta es la decision tecnica mas importante del cliente movil, porque determina si la app funciona en
campo o no.

| Criterio | MapLibre GL | flutter_map (con Leaflet) | Mapbox GL | Google Maps SDK |
|---|---|---|---|---|
| Tiles raster para uso sin conexin | Si | Si | Si, con terminos | Si, con terminos |
| Vectores y teselas propias | Si | Si | Si | No |
| Poligonos con atributos | Si | Si | Si | Limitado |
| Terminos de uso y costo | Sin cobros | Sin cobros | Requiere plan | Requiere clave y pago |
| Riesgo de licencia al cachear en el dispositivo | Bajo | Bajo | Medio | Alto |
| Calidad de la documentacion en espanol | Media | Media | Alta | Alta |

**Decision.** MapLibre GL como motor de render, con **tiles raster** servidos desde el proveedor de
imagen que el ICA contrate.

Tres razones, en orden de peso:

1. **La licencia.** Es la unica opcion que no introduce un riesgo contractual al cachear mosaicos en el
   dispositivo de un tercero. Con el enlace rural del problema, cachear es obligatorio, y por lo tanto
   la licencia deja de ser un detalle.
2. **Los poligonos con atributos.** El sistema necesita dibujar el limite de cada lote, la retícula de
   celdas y la trampa, con atributos. Todos los motores lo hacen, pero solo los basados en vector gestionan
   bien muchos poligonos simultaneos sin degradarse.
3. **La independencia del proveedor.** Cambiar de proveedor de imagen debe cambiar una URL de tiles, no
   reescribir la aplicacion.

**Riesgo que esta decision no elimina.** MapLibre resuelve el render, no la disponibilidad de los datos:
si no hay mosaicos en el dispositivo, no hay mapa. Por eso RNF-020 limita el tamano del paquete de campo
y por eso el documento de requerimientos deja la eleccion del proveedor como pregunta abierta UQQ-007.

> **Aclaracion tecnica que suele pasarse por alto.** Los mapas de mapas caching en el dispositivo tienen
   dos capas con problemas distintos: el **tile cache** (los recortes de imagen) y el **pack de
   geometria** (los poligonos de lote y trampa, que son pequenos). Los poligonos deben almacenarse en la
   base local como tablas con columna geometrica, no solo como tiles: asi pueden consultarse sin conexion
   por atributos, que es lo que hace posible llenar el formulario de un lote sin red. Este es el motivo por
   el que la base local es **espacial** y no una simple tabla de recursos.

## Geometria en el cliente {#sec-tec-geo-local}

**PostgreSQL con PostGIS en el servidor**, y la misma semantica en el cliente mediante una extension
espacial de SQLite.

La razon de no guardar las geometrias como archivos GeoJSON separados es que el formulario necesita
**consultar por atributo** -«dame el lote que contiene este punto»- y eso es una consulta de base de
datos, no una lectura de archivo.

## Servidor {#sec-tec-backend}

**Python con FastAPI, sobre un despliegue de aplicacion.**

La razon de elegir FastAPI sobre otras opciones es especifica y verificable: **el tipado estatico con
validacion de pydantic genera el contrato de la API a partir del codigo**, lo que significa que el
contrato que consume el equipo de desarrollo (OpenAPI) no puede quedar desactualizado respecto a lo que
el servidor realmente acepta. En un proyecto donde el equipo de desarrollo es otro, esa propiedad vale
mas que el rendimiento, que aqui no es el cuello de botella.

Ese contrato generado es ademas el unico artefacto que se intercambia entre los tres repositorios del
proyecto, y se describe en la seccion\nobreakspace\ref{sec-repos-unidad}.

## Almacenamiento de imagenes {#sec-tec-objetos}

**Almacenamiento de objetos con acceso por referencia.** Los binarios no van a la base de datos.

La razon es el perfil de los datos: las fotografias tienen un volumen y un ciclo de vida distintos al
transaccional, y la politica de retencion que se defina para ellas probablemente no sera la misma. Meterlas
en la base de datos obliga a aplicar la misma politica a todo.

## Infraestructura {#sec-tec-infra}

Contenedores, un despliegue de aplicacion, una base de datos con PostGIS, un almacen de objetos y una cola
de trabajo. **No se decide ni proveedor ni region en este documento**, porque no hay dato de volumen
(UQQ-008) y esa decision pertenece al proyecto de infraestructura, no al de arquitectura de software.

> **Lo que si se decide: el perfil de despliegue.** El despliegue de campoor es gratuito y estatico (el
> paquete de campo), y el de produccion es de baja concurrencia y alta latencia aceptable (RNF-008
> admite sesenta segundos). Esta combinacion permite un despliegue pequeno y economico sin comprometer
> ninguna caracteristica de calidad requerida.

# Modelo temporal {#sec-temporal}

Esta seccion es la que justifica el proyecto. Si el resto de la arquitectura se resumiera en un diagrama,
esto necesita un modelo propio.

## El problema, enunciado con precision {#sec-temporal-problema}

Tres situaciones del enunciado convergen en un solo defecto de diseno:

1. El tecnico sale del predio con datos anotados el lunes.
2. El tecnico regresa tres semanas despues, con datos anotados ese dia.
3. Ambos suben su informacion, y el orden en que el sistema la recibe **no coincide** con el orden en que
   fue observada.

Si el sistema guarda «la ultima fecha que vi para este lote», la serie del lote queda mal. Si el sistema
sobrescribe valores, se pierde el pasado. Si el sistema ordena por la hora de llegada, el historico
miente.

## Los tres relojes {#sec-temporal-relojes}

El sistema no guarda «una fecha». Guarda **tres**, con significado distinto y con reglas de
inmutabilidad distintas.

| Tiempo | Que significa | Se puede modificar | Ordena el dominio |
|---|---|---|---|
| `t_observacion` | Cuando el tecnico tomo la medicion en el predio | **Nunca**, una vez sincronizado | **Si**, es el orden canonico |
| `t_captura` | Cuando se digito en el dispositivo | No | No; sirve para auditar la labor |
| `t_sincronizacion` | Cuando llego al servidor | Asignada por el servidor | No |

Una cuarta dimension, no un reloj, acompana a las tres: la **version**, que es un entero que incrementa en
cada correccion y que, junto con `t_observacion`, forma la identidad logica del dato.

![Modelo temporal. Los tres relojes del dominio -observacion, captura y sincronizacion- y el efecto de una carga fuera de orden: el registro del viernes llega despues del registro del jueves y entra en su posicion real, sin alterar el historico ya calculado.](diagrams/modelo-temporal-bitemporal.png){width=\textwidth #fig-temporal}

## Las seis reglas {#sec-temporal-reglas}

> **R-T1 · Orden canonico.** El orden del dominio es `t_observacion` ascendente. A igualdad de
> `t_observacion`, desempata `(t_captura, identificador)`. El tiempo de llegada al servidor no participa
> jamas del orden.
>
> **R-T2 · Alta retroactiva.** Si llega un registro cuyo `t_observacion` es anterior al ultimo ya
> sincronizado **y que no existia**, no es una actualizacion: es un alta. Se inserta en su posicion
> cronologica real y la serie se recalcula. El sistema responde `aceptado, tipo: alta_retroactiva`.
>
> **R-T3 · Correccion sin sobrescritura.** Si el registro ya existia y el usuario cambia un valor, se crea
> una version `n+1` que conserva la anterior. La version anterior permanece consultable. La pregunta
> «que se registro originalmente el lunes» siempre tiene respuesta.
>
> **R-T4 · Idempotencia.** Reintentar el envio de una operacion ya recibida no duplica nada. La clave de
> idempotencia es `(dispositivo, cliente_id)` con `cliente_id` derivado del reloj de observacion, mas una
> huella de contenido; si llega el mismo `cliente_id` con contenido distinto, se rechaza y se reporta
> como conflicto.
>
> **R-T5 · Solapamiento marcado, no decidido.** Si el `t_observacion` cae dentro de una ventana ya
> cubierta por otro muestreo del mismo tipo para el mismo lote y trampa, el sistema no elige un ganador:
> marca la operacion `revisar` y la devuelve al usuario para confirmacion humana. La automatizacion no
> debe decidir que medicion es la buena en materia fitosanitaria.
>
> **R-T6 · Deriva del reloj.** El dispositivo compara su reloj con la referencia del campo al iniciar la
> visita. Si la deriva supera un umbral definido, el sistema marca el registro con `deriva_reloj` y pide
> confirmacion explicita del usuario al enviarlo. Un reloj de telefono manipulado no debe poder falsear
> una serie fitosanitaria.

## Reglas de negocio con fecha de efecto {#sec-temporal-fechas}

Dos reglas adicionales hacen que lo anterior no se pierda en la traduccion a papel:

- **Serie historica.** El MTD de un lote en un periodo se recalcula si llega un registro de ese periodo.
  El valor recalculado conserva el valor anterior con su fecha de recalculo, de modo que se puede
  mostrar «MTD del lote 7 la semana del 12: **2,1 %**, recalculado el dia 24 a **1,4 %** por alta
  retroactiva».
- **Concepto de aptitud.** El concepto se reemite con **fecha de efecto** igual al `t_observacion` del
  registro que lo disparo. Un consumidor que consulta el estado de un lote «al dia 12» obtiene el estado
  que habria obtenido entonces, no el de hoy.

## Consecuencias de diseno que se aceptan {#sec-temporal-consecuencias}

Toda esta disciplina tiene un precio, y conviene decirlo antes de que lo pregunten.

| Consecuencia aceptada | Por que es el precio correcto |
|---|---|
| La base de datos es append-only para las mediciones | Es la unica forma de que el historico sea auditable |
| Un alta retroactiva dispara trabajo asincrono de reproceso | Reconstruir el pasado cuesta; ocultarlo costaria mas |
| El dispositivo guarda mas datos localmente | El almacenamiento local barato es lo que hace posible la operacion sin senal |
| Un registro puede quedar en estado `revisar` sin que el usuario entienda por que | Preferible a que el sistema decida en silencio un dato fitosanitario |
| La fotografia pesa mas que el dato y sube despues | El dato numerico es lo que sostiene el tramite; la imagen es soporte |

# Modelo de dominio {#sec-dominio}

## Principios de modelado {#sec-dominio-principios}

Tres principios gobiernan el modelo, y cada uno responde a un hallazgo del documento de levantamiento:

**El objeto que importa para el tramite es el par (lote, fecha).** Todo lo demas son atributos, evidencia o
configuracion de ese par. Es la consecuencia directa de RN-003: el umbral aplicable depende de la fecha,
de modo que la unidad de informacion no puede ser el lote sino el lote en un momento.

**La etapa fenologica se deriva, no se captura como verdad (RN-012).** El sistema la calcula a partir de
la fecha de observacion, la fecha de plantacion y la tabla de etapas vigente en esa fecha. El usuario
puede **declarar** una etapa; esa declaracion se guarda con su fecha, su valor y su autor, y se marca como
`declarada` frente a `derivada`. Cuando ambas difieren, el sistema muestra las dos y registra la
discrepancia. No se descarta ninguna. Guardar la etapa como dato capturado produce exactamente el tipo de
inconsistencia entre visitas que el proyecto viene a eliminar.

**El linaje se marca en el dato, no en la aplicacion.** Cada registro sabe si es `autorreporte` o
`inspeccion_oficial`, y las reglas se aplican por linaje (RN-014).

## Entidades nucleo {#sec-dominio-entidades}

| Entidad | Descripcion | Campos esenciales |
|---|---|---|
| **Predio** | Unidad productiva inscrita ante el ICA | Codigo, nombre, municipio, departamento, geometria, area, responsable |
| **Programa de inspeccion** | Configuracion vigente del predio | Vigencia desde y hasta, ciclo, umbral MTD, periodo de trampeo, checklist BPA, catalogos |
| **Lote** | Subdivision del predio con etapa propia | Codigo, poligono, area, variedad, fecha de plantacion, lote activo, version de geometria |
| **Reticula (celda)** | Subdivision del lote sobre la imagen satelital | Codigo, poligono, resolucion en metros, fecha de corte de imagen |
| **Trampa** | Punto de monitoreo de un lote | Codigo ICA (Divipola + ruta + numero con paridad), tipo, atrayente, lote que vigila, coordenadas WGS84, fechas de instalacion y retiro |
| **Serie de lectura** | Conjunto de lecturas de un lote en un periodo de trampeo | Lote, periodo, inicio, fin, dias de exposicion, estado del periodo |
| **Lectura de trampa** | Moscas capturadas en una trampa en una fecha | Trampa, numero de especimenes, estado de la trampa, fechas de cambio, `t_observacion`, `t_captura`, `t_sincronizacion`, version, linaje |
| **Indice MTD** | Resultado agregado del muestreo de un lote en un periodo | Lote, especie, periodo, M, T, D, MTD, unidad, umbral aplicado, cumple |
| **Concepto de aptitud** | Documento que habilita o bloquea la exportacion | Lote, periodo, resultado, fecha de efecto, norma aplicada, version |
| **Etapa declarada** | Etapa reportada por un usuario | Lote, etapa, fecha de observacion, origen, autor |
| **Diagnostico de especie** | Resultado de laboratorio de una muestra | Muestra, especie, fecha de diagnostico, enlaces a lecturas |
| **Verificacion de BPA** | Resultado de un criterio agronomico en la visita | Lote, visita, criterio, cumple, observacion, evidencia |
| **Hallazgo** | Signo o sintoma observado | Lote, celda, catalogo, severidad, fecha de observacion, autor, linaje |
| **Aplicacion fitosanitaria** | Registro del productor | Lote, producto, dosis, area, responsable, fecha, linaje |
| **Cosecha** | Registro del productor | Lote, volumen y fecha esperados, volumen y fecha reales, metodo, linaje |
| **Evidencia** | Imagen que respalda una medicion | Hash, referencia, fecha de captura, georreferentacion, entidad asociada |
| **Visita** | Sesion de inspeccion en un predio | Tecnico, fecha de inicio y fin observadas, lotes cubiertos, ruta, estado |
| **Version de registro** | Revision de un dato ya sincronizado | Registro, version, valor anterior, valor nuevo, autor, fecha |

## Reglas de validacion {#sec-dominio-validaciones}

Estas reglas se aplican en el dispositivo, para la forma, y se revalidan en el servidor, para el dominio,
porque un dispositivo puede estar desactualizado respecto a la configuracion vigente.

| Regla | Donde se valida | Mensaje al usuario |
|---|---|---|
| La fecha de observacion no puede estar en el futuro respecto a la fecha de captura | Cliente y servidor | «La fecha de medicion no puede ser futura» |
| La fecha de observacion debe caer dentro del periodo de trampeo de la trampa | Cliente y servidor | «La fecha no esta dentro del periodo de la trampa» |
| La trampa debe pertenecer al lote indicado | Servidor | «La trampa no pertenece a este lote» |
| El numero de especimenes no puede ser negativo | Cliente y servidor | «Valor no valido» |
| El umbral vigente en la fecha del periodo debe existir | Servidor | «No hay umbral configurado para esa fecha; concepto no emitido» |
| El lote debe estar activo en el periodo inspeccionado | Servidor | «El lote no estaba activo en esa fecha» |
| El codigo de trampa debe ser unico dentro del predio | Servidor | «Duplicidad de codigo de trampa» |
| La resolucion de la reticula debe superar la distancia minima entre trampas | Servidor | «La reticula es menor que la distancia minima entre trampas» |

> **La ultima regla tiene un origen concreto.** Deriva de RN-004: el Manual exige de 40 a 60 metros entre
> trampas. Una reticula de veinte metros haria que dos trampas quedaran en celdas distintas aunque
> estuvieran separadas por menos de la distancia minima. El sistema no lo permite porque generaria
> inconsistencias en la ubicacion de trampas que despues nadie podria explicar.

## Resolucion del MTD: donde ocurre {#sec-dominio-mtd}

La decision de donde se calcula el MTD tiene consecuencias directas sobre la capacidad de operar sin
conexion, y conviene razonarla.

- **En el dispositivo:** el tecnico veria el valor al instante. Pero el umbral vigente y la tabla de etapas
  pueden haber cambiado desde la ultima sincronizacion, con lo cual el valor mostrado en campo podria no
  ser el que el servidor emitira despues. Es una divergencia visible y contraindicida.
- **En el servidor:** el valor es siempre el correcto porque se calcula con la version de umbral y de
  tabla que vigente a la fecha del periodo. El dispositivo puede mostrar un valor estimado, marcado como
  tal.

**Decision: el MTD se calcula en el servidor, y el dispositivo muestra una estimacion marcada como
estimada.** El tecnico necesita la cifra en campo para decidir el rumbo de la visita; lo que no puede
permitir el sistema es que esa cifra tenga una autoridad normativa que no tiene. La sincronizacion
diferida es lo que hace aceptable este compromiso.

> **Nota sobre la contradiccion con ADR-01 del documento de arquitectura previo.** Un documento anterior
> del proyecto decidio que el dispositivo no evalua ninguna regla de negocio. Este documento corrige
> esa decision para el MTD y la etapa fenologica especificamente: el dispositivo calcula una estimacion
> para mostrarla en pantalla, claramente marcada como no normativa, y el servidor es el unico que emite el
> valor con autoridad. La regla se mantiene intacta para todo lo demas.

# Modelo C4 {#sec-c4-modelo}

## Nivel 1 - Contexto de sistema {#sec-c4-c0}

![Contexto de sistema. La aplicacion movil de inspeccion y el backend de sincronizacion dentro de la frontera del sistema; el resto son actores o sistemas externos.](diagrams/c4-nivel1-contexto.png){width=\textwidth #fig-contexto}

**Que establece la vista.** El sistema de alcance es unico y tiene una frontera clara: captura de
inspeccion en campo, estructura del predio y los lotes, historico temporal y concepto de aptitud por
lote. Todo lo demas es sistema externo.

**Decisiones de frontera que se toman aqui y no se revisan despues:**

- **El proveedor de imagenes satelitales es externo.** El sistema consume mosaicos; no genera, procesa ni
  almacena imagenes de satelite por cuenta propia. La consecuencia arquitectonica es que el uso de la
  imagen queda sujeto a un contrato de licencia cuyo uso -terminos de servicio, cuota, cache permitido- es
  un riesgo de proyecto, no un detalle tecnico (RST-007, UQQ-007).
- **La autenticacion se delega al directorio institucional.** El sistema no administra credenciales de
  empleados del ICA; valida identidades contra el proveedor institucional (RI-008).
- **El consumo del historico y del concepto se expone como servicio.** No es un reporte descargado a
  mano: el supervisor y el proceso de exportacion consultan el sistema (RI-009).
- **El laboratorio es sistema externo.** Recibe la relacion de muestras y devuelve el diagnostico de
  especie. No hay integracion automatica en el MVP (fuera de alcance), pero el modelo de datos esta
  diseno para que la haya en v0.2.

## Nivel 2 - Contenedores {#sec-c4-c1}

![Contenedores del sistema. El dispositivo en campo, el enlace intermitente y la plataforma en nube, donde los modulos del monolito se despliegan juntos en un solo proceso, con sus contratos y su almacenamiento.](diagrams/c4-nivel2-contenedores.png){width=\textwidth #fig-contenedores}

**Los contenedores y por que existen.** Los contenedores 2 a 7 son **modulos dentro de un mismo proceso**: se separan por contrato, no por despliegue (ADR-14).

| # | Contenedor | Responsabilidad | Por que es un contenedor y no una clase |
|---|---|---|---|
| 1 | **Aplicacion movil** | Toda la interaccion en campo: mapa, formularios, calculo de estimacion, almacenamiento local y cola de envio | Corre en un dispositivo con recursos, sistema operativo y ciclo de vida propios; su modo de fallo -perder senal- es un hecho de diseno |
| 2 | **API de Inspeccion** | Contrato HTTP para el dispositivo y para consumidores internos | Frontera de despliegue y de versionado; permite evolucionar sin romper el cliente ya instalado en campo |
| 3 | **Modulo de Sincronizacion** | Recibe lotes idempotentes, decide que se acepta, que se rechaza y que entra en conflicto, y devuelve cursor de avance | Aisla la complejidad de la carga fuera de orden; es el componente que da nombre al problema |
| 4 | **Nucleo de Registro e Historial** | Almacena mediciones de forma append-only y resuelve el orden temporal y las versiones | Unico lugar donde se decide como se ordena el pasado; ver seccion\nobreakspace\ref{sec-temporal} |
| 5 | **Modulo de Configuracion de Predios** | Programa de inspeccion por predio: ciclo, umbral MTD, periodo de trampeo, checklist de BPA, catalogos | Materializa RST-002: la personalizacion no vive en el codigo sino en datos |
| 6 | **Modulo de Imagenes y Evidencia** | Mosaicos satelitales, fotografias de lote y almacenamiento de binarios | Almacenamiento de objetos con ciclo de vida distinto al transaccional; no debe ir a la base de datos |
| 7 | **Modulo de Concepto y Reportes** | Emite el concepto por lote y periodo, y responde consultas de historico | Lectura analitica sobre datos ya cerrados; se puede aislar del camino critico |
| 8 | **Base de datos de registro** | Series historicas, geometrias, configuracion, bitacora | Estado durable; exige geometria (PostGIS) y versionado de filas |
| 9 | **Almacenamiento de objetos** | Binarios de imagen y fotografias | Volumen alto, acceso por referencia, politica de retencion diferente |
| 10 | **Cola de trabajo interna** | Reproceso asincrono de periodos afectados por altas retroactivas | El reproceso es trabajo asincrono real y no debe bloquear la respuesta de la carga. Es una cola del mismo proceso, no un servicio aparte |

**La frontera mas importante de la figura es la linea punteada que separa el dispositivo del resto**: en
la practica hay un actor dentro de la frontera y otro fuera, y **no es una frontera de red sino una
frontera de verdad**. Ningun evento de negocio debe depender de que exista conexion durante la visita.

## Nivel 3 - Componentes {#sec-c4-c2}

![Componentes del nucleo de registro e historial y del motor de sincronizacion. El detalle se limita a los componentes con responsabilidades que condicionan la arquitectura; el resto se describe por contrato.](diagrams/c4-nivel3-componentes.png){width=\textwidth #fig-componentes}

El nivel 3 se profundiza unicamente donde esta la complejidad. Los componentes del **Modulo de Registro e
Historial** son:

- **Endpoint de sincronizacion** — recibe lotes de operaciones idempotentes.
- **Validador de invariantes** — forma, dominio permitido, pertenencia de la trampa al lote y coherencia
  de fechas. Descarta lo mal formado *antes* de tocar el historico, para que un error de captura en campo
  no contamine la serie.
- **Motor temporal bitemporal** — ordena por fecha de observacion, inserta altas retroactivas y versiona
  correcciones. **Es el componente que justifica el proyecto.**
- **Motor de umbrales MTD** — agrega el muestreo del periodo y lo contrasta contra el umbral vigente *a la
  fecha del periodo*, no contra el vigente hoy.
- **Registrador de auditoria** — bitacora append-only de toda accion, con actor y huella.
- **Publicador de eventos de dominio** — emite el cambio de estado de aptitud con su fecha de efecto, para
  que los consumidores reaccionen a tiempo.

Los componentes del **Modulo de Sincronizacion** son:

- **Receptor de lotes** — acepta el envio y responde rapido; no ejecuta el reproceso.
- **Clasificador de operaciones** — decide, por operacion, si es alta nueva, alta retroactiva, correccion,
  idempotente repetida, a revisar o rechazada, y por que (R-T2 a R-T5).
- **Encolador de reproceso** — encola el recalculo de los periodos afectados por cada alta retroactiva.
- **Procesador de reproceso** — ejecuta el recalculo del MTD y la reemision del concepto con su fecha de
  efecto.

## Vista dinamica: el escenario que juzga la arquitectura {#sec-c4-dinamica}

![Vista dinamica. Tres actos encadenados -captura en campo, carga fuera de orden y reproceso de una serie- que juzgan si la arquitectura resuelve el problema real.](diagrams/vista-dinamica-visita.png){width=\textwidth #fig-dinamica}

La figura se lee como una prueba. El **Acto 3** es la pregunta que el sistema debe responder correctamente,
y la respuesta del servidor esta escrita en el panel derecho:

> `aceptado: true` · `tipo: alta_retroactiva` · la serie del lote 12 se recalculo e inserto en su posicion
> real · el concepto de aptitud se reemitio con **fecha de efecto = miercoles**.

Ese ultimo punto es la respuesta de negocio que hace util el sistema: cuando entra un registro antiguo,
el ICA no solo tiene el dato; tiene la posibilidad de reconstruir **en que estado estaba el lote el dia en
que se tomo ese muestreo**.

# Contratos {#sec-contratos}

## Contrato de sincronizacion {#sec-contrato-sync}

La unidad de intercambio es una **operacion idempotente**, no un registro. La distincion importa: una
operacion lleva su resultado, y un lote de operaciones puede aceptarse de forma parcial.

```json
{
  "operaciones": [
    {
      "cliente_id": "d5f3a1c2-9b8e-4a7c-8f21-3e6d0a4b7c91",
      "dispositivo": "TIC-042",
      "tipo": "lectura_trampa",
      "linaje": "inspeccion_oficial",
      "t_observacion": "2026-09-15T09:40:00-05:00",
      "t_captura": "2026-09-15T10:02:00-05:00",
      "version": 1,
      "deduplicacion": "recorrido_predio_042",
      "datos": {
        "trampa_codigo": "68276-042-001",
        "lote_codigo": "L-01",
        "numero_especimenes": 3,
        "estado_trampa": "lectura_normal"
      }
    }
  ]
}
```

La respuesta se emite **por operacion**, nunca como un todo o nada:

```json
{
  "resultados": [
    {
      "cliente_id": "d5f3a1c2-9b8e-4a7c-8f21-3e6d0a4b7c91",
      "estado": "aceptado",
      "tipo_resultado": "alta_retroactiva",
      "serie_recalculada": true,
      "concepto_reemitido": true,
      "fecha_efecto": "2026-09-15T09:40:00-05:00"
    }
  ],
  "cursor": "2026-09-15T09:40:00-05:00"
}
```

Los estados posibles de una operacion son exactamente los que define R-T2 a R-T5:

| `tipo` | Significado para el cliente |
|---|---|
| `alta_nueva` | El registro es nuevo y su fecha de observacion es posterior a la ultima del lote |
| `alta_retroactiva` | El registro es nuevo y su fecha de observacion es anterior a la ultima del lote: se inserta en su posicion real |
| `correccion` | El registro reemplaza una version anterior, que se conserva |
| `idempotente_repetida` | El servidor ya tenia esa operacion; no se creo nada nuevo |
| `revisar` | El registro se solapa con otro y queda pendiente de confirmacion del usuario |
| `rechazada` | El registro no cumple una invariante y no entra al historico |

**Regla de diseno del contrato.** El cliente nunca debe interpretar un `rechazada` como un fallo de la
sincronizacion que hay que reintentar. `revisar` y `rechazada` son decisiones de negocio que requieren
intervencion del usuario; reintentarlas automaticamente produce un bucle infinito de operaciones que no
van a cambiar de resultado.

## Contrato de datos: la tabla de mediciones {#sec-contrato-datos}

La tabla central del sistema, donde vive la regla temporal:

```sql
CREATE TABLE medicion (
  id                  UUID PRIMARY KEY,
  predio_id           UUID NOT NULL REFERENCES predio (id),
  entidad_tipo        TEXT NOT NULL,     -- 'lectura_trampa' | 'aplicacion' | 'cosecha' | 'hallazgo'
  entidad_id          UUID NOT NULL,
  linaje              TEXT NOT NULL,     -- 'autorreporte' | 'inspeccion_oficial'
  t_observacion       TIMESTAMPTZ NOT NULL,
  t_captura           TIMESTAMPTZ NOT NULL,
  t_sincronizacion    TIMESTAMPTZ,
  version             INTEGER NOT NULL DEFAULT 1,
  desplazamiento_reloj BOOLEAN NOT NULL DEFAULT FALSE,
  cliente_id          TEXT NOT NULL,
  dispositivo         TEXT NOT NULL,
  payload             JSONB NOT NULL,
  anulada             BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX ix_medicion_idempotencia
  ON medicion (dispositivo, cliente_id, version);

CREATE INDEX ix_medicion_orden
  ON medicion (entidad_tipo, entidad_id, t_observacion, t_captura);

CREATE INDEX ix_medicion_sincronizacion
  ON medicion (t_sincronizacion) WHERE t_sincronizacion IS NULL;
```

Tres decisiones del esquema merecen explicacion:

- **El indice unico de idempotencia** incluye `version`, porque una correccion es una operacion nueva con
  la misma identidad logica pero version distinta. Si no lo incluyera, la correccion se rechazaria como
  duplicada.
- **El indice de orden** termina en `t_captura` para materializar la regla R-T1, que desempata por
  captura. Sin ese segundo criterio, dos registros con la misma `t_observacion` devolverian un orden
  arbitrario y el historico dejaria de ser deterministico.
- **El indice de sincronizacion** es parcial sobre las filas no sincronizadas: es el indice que sostiene la
  cola de trabajo, y evita que el indice se degrade con cada registro ya consolidado.

## Contrato de datos: geometria versionada {#sec-contrato-geo}

```sql
CREATE TABLE lote_geometria (
  id             UUID PRIMARY KEY,
  lote_id        UUID NOT NULL REFERENCES lote (id),
  version        INTEGER NOT NULL,
  poligono       GEOMETRY (Polygon, 4326) NOT NULL,
  area_m2        NUMERIC NOT NULL,
  vigente_desde  DATE NOT NULL,
  vigente_hasta  DATE,
  UNIQUE (lote_id, version)
);
```

> **Por que la geometria tiene version propia.** Si un productor redibuja el limite de un lote, los
> muestreos antiguos siguen debiendo estar referidos al contorno que se midio entonces. Ademas, un cambio
> de geometria puede alterar el area y por tanto la normalizacion del MTD. La medicion apunta a la version
> de geometria vigente en su `t_observacion`; por eso la geometria no puede ser una columna que se
> sobrescribe.

# Vista de despliegue {#sec-despliegue}

![Vista de despliegue. Dos entornos -predio rural sin cobertura y nube del proyecto-, el enlace intermitente como elemento del modelo y los modulos del servidor desplegados en un mismo proceso.](diagrams/vista-despliegue.png){width=\textwidth #fig-despliegue}

La vista de despliegue hace explicita la consecuencia de la seccion\nobreakspace\ref{sec-c4-modelo}: **el sistema
tiene dos entornos que no comparten supuestos**, y el primero es el que opera el ICA la mayor parte del
tiempo.

- **Entorno 1 - Predio.** El dispositivo es autonomo. Guarda mosaicos, geometria y la cola de salidas
  pendientes. Su modo de fallo caracteristico no es «dejar de funcionar», sino «acumular trabajo». La
  arquitectura debe hacer que ese trabajo acumulado sea recuperable y visible.
- **Entorno 2 - Nube.** Contenedores, base de datos y almacenamiento. El enlace rural es intermitente por
  diseno, no por averia.

**Postura operativa derivada.** RPO efectivo cero para los datos capturados: la copia local es la garantia
de que una medicion no se pierde por un fallo de red. RTO de horas para el servidor, lo que es admisible
para un tramite fitosanitario que no tiene una ventana de minutos.

# Repositorios, estructura de codigo y control de calidad {#sec-repos}

Las secciones anteriores dicen que se construye. Esta dice donde vive el codigo, como esta organizado
dentro de cada repositorio y que comprueba la integracion continua antes de permitir una fusion. Forma
parte de la arquitectura y no de la practica del equipo porque tres decisiones de este documento solo
existen si algo las verifica: las fronteras de modulo (ADR-14), la cobertura de las reglas de negocio
(RNF-017) y la version de los diagramas (RNF-018). Sin verificacion, una frontera es una preferencia que
el siguiente desarrollador borra sin darse cuenta.

## Tres repositorios, tres pilas, un contrato {#sec-repos-unidad}

| Repositorio | Pila | Contiene | Puente con los otros repositorios |
|---|---|---|---|
| `ica-durazno-app` | Flutter y Dart | Aplicacion movil, base local, cola de envio y mapa | Fija `openapi.json` como archivo versionado |
| `ica-durazno-api` | Python y FastAPI | Modulos del monolito, migraciones, cola de trabajo y pruebas | Publica `openapi.json` generado desde el codigo |
| `ica-durazno-web` | React y TypeScript | Backoffice: administracion, reportes e importacion historica | Fija `openapi.json` y genera el cliente TypeScript |

**Decision.** Tres repositorios, uno por pila y por ciclo de vida, y ninguno de ellos contiene artefactos
documentales. La web se agrega como tercer cliente del mismo contrato (ADR-18), no como un segundo
backend.

El servidor es un monolito modular con un unico despliegue (ADR-14): dividirlo en varios repositorios
dividiria un proceso que se despliega junto y introduciria fronteras de red donde el modelo dice que no
las hay. Los clientes, en cambio, tienen otro lenguaje, otro ciclo de vida y otra forma de fallar: el movil
se instala en campo y permanece ahi meses sin actualizarse; la web es un backoffice que despliega
varias veces al dia y nunca opera sin red. Un monorepo con las tres pilas acoplaria tres
cadenas de integracion continua que no se deben nada -el analisis de Flutter bloqueando un despliegue de
Python, o al reves- a cambio de una raiz compartida que ningun codigo necesita.

> **La frontera de repositorio sigue la frontera de verdad.** La vista dinamica de la
> seccion\nobreakspace\ref{sec-c4-dinamica} separa el dispositivo del resto del sistema, y esa separacion es la mas
> importante del proyecto: el dispositivo opera horas sin conversar con nadie del otro lado. La web no
> cruza esa frontera: es un consumidor del mismo servidor. Tener tres repositorios es la consecuencia
> literal de dos ciclos de vida de cliente distintos, no una preferencia de organizacion.

El unico elemento que cruza de un repositorio a otro es el **contrato OpenAPI**, y cruza en una sola
direccion: lo genera el servidor a partir de su propio codigo (seccion\nobreakspace\ref{sec-tec-backend}), se
publica en cada fusion y cada cliente lo consume como archivo fijado y versionado. De este modo, que el
contrato este actualizado no depende de que alguien lo recuerde.

## Estructura de carpetas: los modulos como directorios {#sec-repos-estructura}

Un modulo de ADR-14 es una carpeta con su propio dominio y sus propias pruebas. Si no es una carpeta,
es una idea.

| Carpeta en `ica-durazno-api` | Contenedor C4 que materializa |
|---|---|
| `src/ica_api/api/` | 2 · Contrato HTTP: rutas y esquemas |
| `src/ica_api/modules/sincronizacion/` | 3 · Receptor, clasificador, encolador y procesador de reproceso |
| `src/ica_api/modules/registro/` | 4 · Motor temporal, validador de invariantes, umbrales y bitacora |
| `src/ica_api/modules/configuracion/` | 5 · Programa de inspeccion, catalogos y reticula |
| `src/ica_api/modules/imagenes/` | 6 · Mosaicos, fotografias y almacenamiento de objetos |
| `src/ica_api/modules/concepto/` | 7 · Concepto por lote e historico de consultas |
| `src/ica_api/infra/`, `migrations/`, `contracts/`, `tests/` | 8 a 10 · Base de datos, cola, objetos, esquema versionado y `openapi.json` |

| Carpeta en `ica-durazno-app` | Responsabilidad |
|---|---|
| `lib/core/` | Tiempo, geolocalizacion, almacenamiento local y cola de envio: lo que toda pantalla necesita |
| `lib/features/visita/`, `lib/features/mapa/` | Captura en campo y el mapa que la sostiene |
| `lib/features/historial/`, `lib/features/reportes/` | Lectura de series y resumen por lote |
| `lib/features/autorreporte/`, `lib/features/configuracion/` | Linea de datos del productor y programa de inspeccion descargado |
| `lib/contracts/` | Cliente generado desde `openapi.json`: lo unico que toca el puente |
| `test/`, `integration_test/` | Pruebas de dominio y la visita completa en modo avion |

| Carpeta en `ica-durazno-web` | Responsabilidad |
|---|---|
| `src/app/` | Composicion, router, providers y layouts |
| `src/pages/` | Pantallas finas: solo componen features |
| `src/features/` | Predios, lotes, trampas, lecturas, MTD, reportes, usuarios, catalogos e importaciones |
| `src/components/` | UI compartida, tablas, graficos y mapas |
| `src/lib/` | Cliente API generado, auth, permisos, validacion y formato |
| `src/contracts/` | `openapi.json` fijado y tipos TypeScript generados |
| `tests/` | Pruebas unitarias y E2E con Playwright |

La estructura detallada de los tres repositorios, sus patrones y sus puertas de calidad se desarrolla en
el documento *Estructura de repositorios y patrones de diseno*.

**Tres reglas que impiden que la estructura sea decorativa:**

1. Un directorio de modulo solo importa de su propio modulo, de `api/` y de `infra/`. Importar otro
   modulo esta prohibido, y la prohibicion es ejecutable.
2. Las dependencias apuntan hacia `core`: `features` importa de `core` y nunca al reves. Eso es lo que
   permite probar el dominio sin un dispositivo.
3. Cada regla de negocio tiene un unico hogar. El orden temporal vive en `modules/registro/` y en
   ninguna otra parte: una segunda copia de esa logica es un defecto, no una optimizacion.

> **Lo que la estructura no puede comprobar.** ADR-07 prohibe condicionales por predio en el codigo: la
> personalizacion es configuracion. Esa regla no la detecta el analisis estatico, la detecta la
> revision de un revisor que sabe que buscar. Es la unica regla de esta seccion que depende de una
> persona, y por eso queda escrita.

## Puertas de calidad {#sec-repos-puertas}

Ninguna fusion avanza sin verde. Las verificaciones locales son comodidad para quien programa; la
autoridad es la integracion continua del repositorio, y su configuracion vive dentro del repositorio,
versionada como codigo: cambiar una puerta es un cambio que pasa por revision, igual que cualquier otra
linea.

| Puerta | En `ica-durazno-app` | En `ica-durazno-api` | Que impide |
|---|---|---|---|
| Formato | `dart format` | `ruff format` | Discusiones de estilo dentro de una revision |
| Analisis estatico | `flutter analyze` con reglas estrictas | `ruff check` y `mypy` | Errores y tipos inseguros antes de que alguien lea el diff |
| Fronteras de modulo | `custom_lint` con reglas de dependencia | `import-linter` con los contratos de la seccion anterior | Un import que cruce un modulo fuera de su contrato (ADR-14) |
| Pruebas | `flutter test` | `pytest` | Regresion de regla de negocio, con cobertura minima del 80% (RNF-017) |
| Contrato | Cliente regenerado desde `openapi.json` fijado | Diff del `openapi.json` generado | Un cambio incompatible con el cliente ya instalado en campo |
| Secretos | Barrido de credenciales en cada fusion | Barrido y dependencias vulnerables | Claves o tokens subidos al repositorio |

RNF-017 se materializa en la fila de pruebas: el ochenta por ciento es una puerta que bloquea la fusion,
no una meta de equipo. Se mide sobre las reglas de negocio del documento de levantamiento, no sobre la
capa de interfaz, porque lo que el proyecto no puede perder es el comportamiento y no el numero. Las
pruebas de integracion que cierran los hitos del documento de prioridades -visita completa en modo
avion, alta retroactiva en su posicion real- corren en la misma puerta.

## Ramas, revisiones y versiones {#sec-repos-flujo}

**Decision.** Trunk-based con ramas cortas, fusion por *pull request* con revision obligatoria, y dos
revisiones en los caminos criticos.

- **`main` siempre verde y siempre desplegable.** Ramas menores de tres dias, fusionadas por *squash*;
  una rama que crece mas que eso se parte en dos.
- **Proteccion de rama:** sin escritura directa sobre `main` y ninguna fusion sin al menos una revision.
- **`CODEOWNERS` sobre los caminos que sostienen decisiones de este documento:** `contracts/openapi.json`,
  `modules/sincronizacion/`, `modules/registro/` (el motor temporal), `migrations/` y cualquier cambio
  en la estructura de carpetas. Esos cambios exigen ademas **una segunda revision por una persona
  distinta**: nadie fusiona por su cuenta una decision que toca el contrato o el orden temporal.
- **Versiones:** el MVP completo es la etiqueta `v0.1` en los tres repositorios, y cada entrega posterior
  avanza a `v0.2`, `v0.3` y asi sucesivamente, siguiendo la tabla de exclusiones del documento de
  prioridades. La aplicacion lleva ademas un contador de construccion que permite identificar, con una
  instalacion en campo, que version del contrato esta usando.

## Lo que no entra en los repositorios {#sec-repos-no-doc}

Los repositorios contienen codigo y los artefactos que el codigo genera: migraciones, pruebas y
`openapi.json`. **No contienen** los tres documentos de la entrega, los ADR en formato completo, los
diagramas en SVG ni los PDF. Todo eso es la entrega documental del proyecto, y se versiona por version
de documento -v1.0, v1.1, v1.2- y no por *commits*.

> **De donde sale el SVG.** Cada figura de este documento se entrega ademas como codigo fuente en
> formato SVG dentro de `diagrams/`, para poder regenerarse de forma determinista y quedar versionada
> con la version de este documento. El diagrama es el artefacto; el SVG es su fuente.

Esa regla es la forma en que se cumple RNF-018: cuando una fusion cambia una frontera -extraer un
modulo, separar un contenedor, alterar la topologia de despliegue-, el hito no se cierra hasta que los
diagramas SVG correspondientes se actualizan y el documento de arquitectura sube de version. La
verificacion es inspeccionar que la version del documento coincida con la etiqueta de la entrega.

Ninguno de los dos entregables se queda atras del otro: el codigo sin su diagrama deja una frontera que
nadie puede revisar, y el diagrama sin su codigo queda como una intencion.

# Seguridad y datos personales {#seguridad}

## Minimos del sector {#seguridad-minimos}

- **Autenticacion delegada** al directorio institucional; el sistema no almacena credenciales de
  empleados del ICA (RI-008).
- **Cifrado en transito** sobre TLS 1.2 o superior, sin excepcion (RNF-012).
- **Cifrado en reposo en el dispositivo**, con autenticacion local para desbloquear la aplicacion (RNF-013).
- **Control de acceso por rol** aplicado en el servidor, con independencia de lo que la interfaz ofrezca
  (RNF-015).
- **Minimizacion** de datos personales: solo los necesarios para la trazabilidad, y no el recorrido del
  usuario fuera del predio (RNF-014).
- **Bitacora de accesos** a datos de personas identificables.

## Riesgo residual que no se elimina {#seguridad-riesgo}

> **Las fotografias pueden contener personas o actividad productiva identificable.** El sistema registra
> evidencia fotografica porque el usuario lo pide, pero el Manual del ICA no la exige. Esto significa que
> la evidencia fotografica es un **activo de riesgo**, no un activo de valor normativa. La consecuencia
> concreta es que su retencion y su control de acceso pueden ser mas restrictivos que los de los datos
> fitosanitarios, y que esa diferencia debe ser una decision consciente y no un accidente.

Esta es la razon por la que RF-033 es *Should* y no *Must*: no solo es que el ICA no lo pida, es que
aceptarlo sin controles especificos transfiere un riesgo al sistema.

# Decisiones de arquitectura {#adr}

Registro resumido de las decisiones. El formato completo se registra en la entrega documental del
proyecto, con fecha y estado; los repositorios de codigo no guardan documentos.

**ADR-01 · El dispositivo es la fuente de captura, no una cache.** *Aceptada.* El servidor no participa
en la captura. El cliente valida forma, no reglas de negocio, salvo la estimacion de MTD y de etapa
fenologica, que son indicativas y se marcan como tales. *Consecuencia:* el equipo de desarrollo debe poder
operar la visita entera con el dispositivo en modo avion.

**ADR-02 · `t_observacion` es inmutable.** *Aceptada.* Una vez sincronizado, un registro no puede cambiar
su fecha de observacion, ni por correccion. Lo que se corrige es el valor medido. *Consecuencia:* si el
tecnico se equivoco de dia, se anula el registro y se crea uno nuevo, dejando ambos visibles.

**ADR-03 · Mediciones append-only con versiones.** *Aceptada.* No hay `UPDATE` sobre una medicion
sincronizada. Hay inserciones y versiones. *Consecuencia:* la tabla crece de forma monotona; las consultas
de la serie leen la version vigente y las de auditoria leen todas.

**ADR-04 · Clasificacion explicita de cada operacion recibida.** *Aceptada.* El motor de sincronizacion
clasifica cada operacion como `alta_nueva`, `alta_retroactiva`, `correccion`, `idempotente_repetida`,
`revisar` o `rechazada`, y devuelve el resultado por operacion. Un lote parcialmente aceptado es un
resultado normal. *Consecuencia:* el cliente puede mostrar exactamente que se guardo y que no.

**ADR-05 · El umbral MTD se versiona con vigencia.** *Aceptada.* El umbral, la formula, el periodo de
agregacion y la tabla de etapas fenologicas son entidades versionadas con `vigente_desde` y
`vigente_hasta`. Cada medicion guarda la version con la que fue interpretada. *Consecuencia:* un cambio
de umbral no altera el pasado. Si el umbral aplicable a un periodo no existe, **no se emite concepto**; el
sistema lo dice en lugar de adivinar.

**ADR-06 · La geometria del lote se versiona aparte de las mediciones.** *Aceptada.* El poligono del lote
es una entidad versionada y las mediciones apuntan a la version vigente en su fecha de observacion.
*Consecuencia:* un cambio de geometria genera un evento, porque puede alterar el area y por tanto la
normalizacion del MTD.

**ADR-07 · La personalizacion es configuracion, nunca condicional en el codigo.** *Aceptada.* Un predio se
personaliza mediante un programa de inspeccion versionado: umbral, ciclo, checklist, catalogos, trampas,
reticula y proveedor de imagen. El codigo no contiene `if (predio == ...)`. *Consecuencia:* atender un
predio nuevo es una operacion de configuracion, no un despliegue.

**ADR-08 · El enlace intermitente es un elemento del modelo, no un error.** *Aceptada.* Se diseña para
transmision **cero** durante la visita. La sincronizacion es una actividad posterior, por lotes, con
reintentos, y la falta de conexion no es una excepcion. *Consecuencia:* la experiencia de la aplicacion no
debe diferenciar «no hay senal» de «no se guardo».

**ADR-09 · La configuracion de un predio viaja precargada en el dispositivo.** *Aceptada.* El dispositivo
puede abrir un predio y trabajar en el sin ninguna llamada a la red: programa de inspeccion, geometria,
reticula y mosaicos se descargan cuando el usuario programa la visita. *Consecuencia:* obliga a una cache
de imagen con politica de tamano, y es la razon por la que el uso de la imagen queda sujeto al contrato
del proveedor.

**ADR-10 · Idioma, unidades y formatos se fijan en el dominio.** *Aceptada.* El dominio almacena fechas
en UTC con la zona horaria del predio asociada, numeros en unidades explicitas con su campo de unidad
(RN-017), y texto en espanol Colombia. *Consecuencia:* una visita que cruza el mediodia no produce
mediciones con horas ambiguas, y un lote no se reposa por el uso de coma decimal.

**ADR-11 · Datos personales dentro del alcance de la arquitectura.** *Aceptada.* Se aplican
minimizacion, cifrado en transito y en reposo, control de acceso por rol y bitacora de accesos, con atencion
a la Ley 1581 de 2012. *Consecuencia:* las fotografias pueden contener actividad identificable, y su
politica de retencion se define antes del despliegue.

**ADR-12 · La evidencia viaja por debajo del dato.** *Aceptada.* En cada lote de sincronizacion, el motor
prioriza el dato numerico y la evidencia fotografica se envia despues, sin bloquear el cierre de la visita.
*Consecuencia:* la confirmacion al usuario llega antes, y si el dispositivo se queda sin bateria durante la
subida de fotos, el dato critico ya esta confirmado.

**ADR-13 · El MTD se calcula en el servidor; el dispositivo muestra una estimacion.** *Aceptada, y
corrige la decision previa del proyecto sobre este punto.* El umbral vigente y la tabla de etapas pueden
cambiar entre la ultima sincronizacion y la fecha de la lectura, de modo que un valor calculado en campo
puede diferir del que el servidor emitira. El dispositivo muestra una estimacion marcada como no
normativa para apoyar la decision de campo. *Consecuencia:* se acepta una divergencia visible entre lo que
se ve en el predio y lo que se emite, a cambio de que el concepto de aptitud tenga siempre un unico autor.

**ADR-14 · Monolito modular con fronteras de microservicio.** *Aceptada.* Ver seccion\nobreakspace\ref{sec-estilo}. *Consecuencia:*
cada modulo se diseña con contrato explicito y frontera de datos, de modo que extraerlo sea mover un
esquema. Los candidatos a extraccion son Evidencia e Imagenes, Concepto y Reportes, y Notificaciones, y
cada uno tiene una senal explicita que justificaria hacerlo.

**ADR-15 · La estimacion no es el MTD.** *Aceptada.* Toda cifra mostrada en el dispositivo que no provenga
del servidor debe marcarse visualmente como estimacion. *Consecuencia:* el equipo de desarrollo debe
incluir ese marcador en la interfaz y probarlo, porque es la defensa del sistema frente a un uso
indebido de una cifra provisional.

**ADR-16 · Dos repositorios de solo codigo, unidos por el contrato OpenAPI.** *Aceptada.* El codigo vive
en `ica-durazno-app` y `ica-durazno-api`, uno por pila y por ciclo de vida, y ninguno contiene artefactos
documentales. *Consecuencia:* los documentos, los ADR y los diagramas en SVG forman parte de la entrega
documental con su propia version, y los modulos de ADR-14 siguen siendo directorios de un unico
repositorio y de un unico despliegue. *Extendida por ADR-18:* el principio se mantiene; el numero de
clientes pasa de dos a tres.

**ADR-17 · Las fronteras de modulo se verifican con analisis estatico, no con convencion.** *Aceptada.*
La integracion continua bloquea la fusion si un import cruza un modulo fuera de su contrato, si el
contrato OpenAPI cambia de forma incompatible o si la cobertura de las reglas de negocio cae del ochenta
por ciento (RNF-017). *Consecuencia:* toda fusion exige revision, y los caminos criticos -contrato,
sincronizacion, motor temporal y migraciones- exigen la revision del responsable de arquitectura y una
segunda revision antes de fusionarse.

**ADR-18 · Tercer repositorio para el backoffice web.** *Aceptada.* Se agrega `ica-durazno-web`
(React + TypeScript + Vite) como cliente del mismo contrato OpenAPI. No crea un segundo backend ni una
base de datos propia; consume los recursos y permisos de `ica-durazno-api`. *Consecuencia:* ADR-16 pasa
de dos a tres repositorios; el contrato se publica una vez y se generan dos clientes, Dart y TypeScript;
la web no duplica reglas de negocio y la vista C4 de contenedores incorpora el contenedor web.

# Trazabilidad requisito a decision {#trazabilidad}

Cada requisito con impacto arquitectonico y la decision que lo atiende. Los requisitos no listados se
atienden sin decision arquitectonica especifica.

| Requisito | Decision arquitectonica | Verificacion arquitectonica |
|---|---|---|
| RF-005, RF-006 | ADR-09 | Paquete de campo contiene imagen y reticula |
| RF-008, RDD-004 | ADR-05 (nomenclatura versionada) | Trampa con codigo Divipola + ruta + paridad |
| RF-020, RF-021, RF-022 | ADR-03 | Lecturas append-only con periodo de trampeo |
| RF-023 | ADR-13, RN-001 | MTD calculado con la formula del Manual |
| RF-024 | ADR-05 | Umbral vigente a la fecha del periodo |
| RF-025, RF-026 | ADR-03 | Estado pendiente de diagnostico conservado |
| RF-040 a RF-042 | ADR-07, RN-014 | Autorreporte como configuracion, sin efecto normativo |
| RF-044 | RN-012 | Etapa derivada y declarada conviven |
| RF-050, RF-051 | ADR-02 | Tres relojes en toda medicion |
| RF-052 | ADR-03 | Version n+1 conserva la anterior |
| RF-053, RF-054 | ADR-02, ADR-05 | Reemision con fecha de efecto |
| RF-060, RF-061 | ADR-08, ADR-01 | Visita completa en modo avion |
| RF-062, RF-064 | ADR-04 | Resultado por operacion, idempotencia |
| RF-065 | R-T2, ADR-02 | Alta retroactiva inserta en su posicion real |
| RF-066 | R-T5 | Operacion marcada para revision |
| RF-067 | ADR-12 | Evidencia debajo del dato |
| RF-080, RF-081 | ADR-07 | Predio nuevo = configuracion |
| RF-084 | ADR-06 | Version de geometria por fecha |
| RI-002 | RN-004 | Reticula mayor a la distancia minima entre trampas |
| RNF-009, RNF-011 | ADR-08, ADR-03 | Cero perdida y cero duplicados |
| RNF-016 | ADR-07 | Incorporar predio sin cambiar codigo |
| RNF-017 | ADR-17 | Cobertura de las reglas de negocio como puerta de fusion |
| RNF-018 | ADR-16 | Diagramas actualizados y nueva version del documento en cada cambio de frontera |

# Riesgos de la arquitectura {#riesgos}

| ID | Riesgo | Prob. | Impacto | Mitigacion |
|---|---|---|---|---|
| RK-01 | Definicion oficial del MTD no entregada | Baja | Alto | **Mitigado por el analisis documental**: la formula del Manual es M/(T x D) y la unidad es moscas/trampa/dia. Lo que falta es el umbral de exportacion (UQQ-004), que queda como parametro versionado sin valor por defecto |
| RK-02 | El concepto de lote no esta en la norma del ICA | Alta | Alto | UQQ-001 y UQQ-002; el modelo lo trata como concepto configurable, y MTD queda condicionado a la asignacion trampa-lote |
| RK-03 | Tamano de la cache offline inaceptable en el dispositivo | Media | Medio | RNF-020 limita el tamano del paquete; descarga por zona y no por predio completo |
| RK-04 | Consumo de imagen no permitido por el contrato | Media | Alto | MapLibre reduce el riesgo de licencia tecnica; el riesgo contractual se resuelve en UQQ-007 antes de construir |
| RK-05 | Deriva del reloj de los dispositivos falsea series | Media | Alto | R-T6, validacion de deriva al iniciar la visita |
| RK-06 | Un tecnico sube datos del cuaderno mucho despues | Alta | Bajo | Alta retroactiva (R-T2): el dato entra donde corresponde |
| RK-07 | Datos personales expuestos por fotografias | Media | Alto | ADR-11; retencion diferenciada para evidencia fotografica |
| RK-08 | La cadencia real de visita no coincide con ninguna fuente | Media | Medio | El sistema no supone cadencias: visita y lectura de trampa son series independientes |
| RK-09 | La estimacion en campo se confunde con el MTD emitido | Media | Alto | ADR-15: marcador visual de estimacion, verificado como parte de la entrega |
| RK-10 | El equipo de desarrollo empieza antes de que la arquitectura este estable | Media | Medio | Hito de cierre formal; este documento y el de requerimientos son el contrato |
| RK-11 | Las puertas de calidad se relajan y las fronteras de modulo se erosionan | Media | Alto | ADR-17: comprobaciones bloqueantes y `CODEOWNERS` sobre contrato, sincronizacion, motor temporal y migraciones; ninguna puerta se desactiva sin un ADR nuevo que la reemplace |

# Preguntas abiertas que afectan a la arquitectura {#preguntas-arq}

Estas preguntas se resuelven con el ICA o con el equipo del proyecto. Las que ya estan en el documento de
levantamiento se referencian alli.

| ID | Pregunta | Responsable | Limite |
|---|---|---|---|
| UQQ-005 | Tamano de celda de la reticula en metros, con el minimo que impone RN-004 | Arquitecto geospatial | Semana 6 |
| UQQ-007 | Proveedor de imagen con licencia compatible con cache en el dispositivo | Arquitecto geospatial | Semana 1 |
| UQQ-009 | Versiones de Android e iOS a soportar | Arquitecto movil | Semana 2 |
| UQQ-012 | Tiempo maximo aceptable entre la captura y la disponibilidad en el historico | Analista de negocio | Semana 5 |
| UQQ-013 | Si el sistema se despliega en infraestructura propia del ICA o en nube, y quien la opera | Seguridad y plataforma | Semana 4 |
| UQQ-014 | Politica de retencion de la evidencia fotografica y de los datos de recorrido | Seguridad | Semana 5 |
| UQQ-015 | Volumen de imagenes por predio y consecuencia sobre el almacenamiento de objetos | Arquitecto geospatial | Semana 6 |

# Anexos {#anexos-arq}

## Plantilla de ADR {#plantilla-adr-arq}

```text
# ADR-NN · Titulo de la decision
Estado:      Propuesta | Aceptada | Reemplazada por ADR-MM
Fecha:       AAAA-MM-DD
Autores:     AR-XX, AR-YY
Afecta a:    RF-nnn, RNF-nnn, RN-nnn

## Contexto
Que fuerza o restriccion obliga a decidir.

## Opciones consideradas
- Opcion A: descripcion, y lo bueno y lo malo
- Opcion B: descripcion
- Opcion C: descripcion

## Decision
Que se decide, en una frase.

## Consecuencias
- Consecuencia positiva
- Consecuencia negativa que aceptamos
- Que queda prohibido hacer a partir de ahora
```

## Glosario tecnico {#glosario-arq}

**ANEXO** - Sin dependencias externas. Se aplica a los modulos del nucleo.

**BITACORA** - Registro append-only de operaciones con actor, momento y version afectada.

**COLA DE TRABAJO** - Mecanismo que ejecuta el reproceso asincrono sin bloquear la respuesta de la
carga.

**DOMINIO** - Conjunto de reglas del negocio que el sistema implementa, con su vocabulario propio.

**ESQUEMA CON TRES RELOJES** - Modelo que separa el momento de la observacion, el de la captura y el de la
sincronizacion de todo dato de campo.

**IDEMPOTENCIA** - Propiedad de una operacion que puede ejecutarse varias veces sin producir mas de un
efecto.

**MAPA BASE** - Capa de imagen que se dibuja debajo de las capas de datos del sistema.

**MODULO** - Unidad de codigo con contrato explicito y frontera de datos, que puede vivir en el mismo
despliegue o extraerse como servicio.

**PAQUETE DE CAMPO** - Conjunto de imagenes, geometrias y catalogos que se descarga para trabajar en un
predio sin conexion.

**POSTGIS** - Extension de PostgreSQL que anade soporte de operaciones geometricas e indexacion espacial.

**RETICULA** - Cuadricula regular superpuesta sobre la imagen del predio, de resolucion configurable.

**VERSIONADO DE GEOMETRIA** - Historial de cambios del poligono de un lote, para que cada medicion quede
referida al contorno vigente en su fecha.

## Referencias {#referencias-arq}

- Simon Brown. *Visualising Software Architecture*. C4 Model.
- ISO/IEC/IEEE 29148: Requirements Engineering.
- ISO/IEC 25010: Modelo de calidad del producto de software.
- Manual Tecnico de Trampeo de Moscas de la Fruta. ICA, 2020.
- Resolucion 995 de 2019. ICA.
- Ley 1581 de 2012. Ministerio de Comercio, Industria y Turismo.

\vfill
\begin{center}
\small\itshape
Fin del documento. Este documento consume el documento de levantamiento de requerimientos y debe
leerse junto con el. Los ADR, los diagramas en SVG y los contratos ejecutables forman parte de la
entrega documental del proyecto; los tres repositorios de codigo no contienen artefactos documentales.
\end{center}