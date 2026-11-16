---
title: "Levantamiento de requerimientos"
subtitle: "Sistema de gestion y monitoreo de cultivos de durazno con fines de exportacion"
author: "Equipo de Arquitectura de Software"
date: "3 de octubre de 2026"
lang: es-CO
---

# Introduccion {#sec-intro}

## Proposito {#sec-proposito}

Este documento especifica los requisitos del sistema de gestion y monitoreo de cultivos de durazno
con fines de exportacion, en adelante *el Sistema*. Es el entregable de la etapa de levantamiento de
requerimientos y sigue la estructura y las caracteristicas que exige la norma **ISO/IEC/IEEE 29148:
Requirements Engineering**.

El documento esta escrito para ser usado sin contexto previo, porque tiene dos lectores distintos y
ninguno de los dos acompanara al otro: el equipo de arquitectura, que necesita saber exactamente que
restriccion debe satisfacer cada decision de diseno, y el equipo de desarrollo, que recibira este
documento junto con el de arquitectura tecnologica sin acceso a las conversaciones con el ICA que
dieron origen a estos requisitos.

De los tres documentos de esta entrega, este es el **mas conservador y el mas trazable**: no contiene
decisiones de implementacion. Cuando aqui aparece la palabra *debe*, se trata de una obligacion
verificable. Cuando aparece *convendria* o *se propone*, se trata de una sugerencia que el equipo de
desarrollo puede rechazar sin romper el contrato.

## Alcance del documento {#sec-alcance-doc}

El documento cubre: las partes interesadas, las tecnicas de levantamiento efectivamente aplicadas y las
que faltan, los requisitos funcionales, no funcionales, de datos, de interfaz y las restricciones, las
reglas de negocio, los casos de uso, la matriz de trazabilidad, el metodo de validacion y verificacion,
y la priorizacion que define el alcance del MVP.

El documento **no** cubre: el diseno de la interfaz de usuario, el modelo de datos en detalle, los
contratos de API ni las decisiones de arquitectura. Esos elementos estan en el documento de
arquitectura tecnologica.

## Definiciones {#sec-definiciones}

Se usan las siguientes definiciones, tomadas de la norma o del contexto del proyecto.

: **Requisito.** Necesidad que el sistema debe satisfacer, expresada de forma verificable y sin
ambiguedad. La norma prefiere el termino *requisito* sobre *especificacion* cuando se trata de una
necesidad, y sobre *funcion*, que describe lo que el sistema hace y no lo que deberia hacer.

: **Requisito funcional.** Comportamiento o funcion que el sistema debe realizar.

: **Requisito no funcional.** Cualidad o restriccion que el sistema debe cumplir, relativa a calidad,
interaccion, rendimiento, seguridad o diseno.

: **Restriccion.** Limitacion sobre las soluciones de diseno o sobre el entorno del sistema que proviene
de fuera del sistema.

: **Regla de negocio.** Enunciado que define o acota un aspecto del comportamiento del negocio. Una
regla de negocio no es un requisito: es una verdad del dominio que **limita** que soluciones son
aceptables.

: **Prioridad MoSCoW.** Metodo de priorizacion que clasifica cada requisito en *Must* (obligatorio),
*Should* (deseable pero no imprescindible), *Could* (deseable si hay tiempo) y *Won't* (fuera de
alcance en esta fase).

: **Trazabilidad.** Capacidad de vincular cada requisito con su origen, con los casos de uso que lo
ejercitan, con las reglas de negocio que lo condicionan y con el metodo por el que se verificara.

: **Pregunta sin respuesta (UQQ).** Punto del requerimiento que no pudo determinarse con la evidencia
disponible y que requiere la decision de una persona con autoridad para tomarla.

## Referencias {#sec-referencias-doc}

- **ISO/IEC/IEEE 29148:2018.** *Systems and software engineering - Life cycle processes - Requirements
  engineering*. Base de la estructura y de las caracteristicas de los requisitos de este documento.
- **ISO/IEC 25010:2011.** Modelo de calidad del producto de software. Base de la taxonomia de los
  requisitos no funcionales, clasificados por caracteristica de calidad.
- **Manual Tecnico de Trampeo de Moscas de la Fruta.** Instituto Colombiano Agropecuario, Subgerencia
  de Proteccion Vegetal, Direccion Tecnica de Epidemiologia y Vigilancia Fitosanitaria, Programa
  Nacional de Moscas de la Fruta, 2020. **Es la fuente normativa primaria de este levantamiento.**
- **Resolucion 995 de 2019.** Medidas fitosanitarias para el control de la mosca del Mediterraneo
  (*Ceratitis capitata*) en predios productores de durazno y plantas empacadoras.
- **Resolucion 8461 de 2019.** Norma citada por el Manual como marco de las medidas aplicables a los
  predios registrados para exportacion de frutas. Su contenido no fue accesible durante este
  levantamiento (ver UQQ-004).
- **Ley 1581 de 2012.** Ley General de Proteccion de Datos Personales en Colombia.
- **Resolucion 106407 de 2021.** Medidas de manejo de moscas de la fruta.

## Estructura del documento {#sec-estructura-doc}

La seccion 2 describe el contexto y las partes interesadas. La seccion 3 declara las tecnicas de
levantamiento aplicadas, con su estado. La seccion 4 contiene los requisitos. La seccion 5 describe
los casos de uso. La seccion 6 presenta la trazabilidad. La seccion 7 explica como se validan y
verifican. La seccion 8 prioriza los requisitos y define el MVP. La seccion 9 registra los riesgos del
levantamiento y la seccion 10, las preguntas sin respuesta.

# Descripcion general {#sec-general}

## Contexto del problema {#sec-contexto}

El Instituto Colombiano Agropecuario adelanta, para predios de durazno registrados para exportacion,
un conjunto de inspecciones que hoy se ejecutan sobre papel. Un tecnico llega al predio, recorre los
lotes en un orden que el mismo fija, anota en un cuaderno los datos de cada trampa y de cada lote, y
luego transcribe ese cuaderno a una planilla en la oficina del municipio.

Sobre esa forma de trabajar se acumulan cuatro efectos. Primero, el cuaderno **pierde la nocion de
cuando se tomo cada medicion**, de modo que el historico de un lote deja de ser una serie ordenada.
Segundo, cuando el tecnico regresa y sube al sistema datos de una visita anterior, no hay forma de
distinguir un dato nuevo de una correccion de uno viejo. Tercero, al no existir copia digital
estructurada, el ICA no puede construir indicadores sobre que predios cumplen mejor o peor. Cuarto, y
con mayor efecto sobre el campo, **el productor no tiene ninguna forma de registrar lo que hace en su
lote entre visitas**: fumigaciones, cosechas, manejo agronomico. Esa informacion existe hoy unicamente
como conocimiento del productor y se pierde.

De esta descripcion se sigue una consecuencia de alcance que la norma exige declarar: el Sistema no es
unicamente una herramienta de inspeccion, es un **sistema de gestion de cultivo** cuyo producto
principal es el historico confiable de cada lote.

## Un hallazgo de terminologia que condiciona el modelo de datos {#sec-hallazgo-lote}

Durante el analisis del Manual Tecnico de Trampeo se verifico un hecho que no aparece en el enunciado
del proyecto y que tiene consecuencias directas sobre el modelo de datos:

> La palabra **«lote» no aparece ni una sola vez** en el Manual Tecnico de Trampeo de Moscas de la
> Fruta. El manual usa *predio*, *ruta de trampeo*, *sitio de monitoreo* y *area*. El concepto de
> lote con etapa fenologica propia proviene de la descripcion del problema, no de la directriz del ICA.

Esto no es un detalle menor. Significa que **el lote es un concepto del productor y del proceso de
exportacion, mientras que la trampa es un concepto del ICA**, y que la relacion entre ambos -que
trampa vigila que lote, y con que densidad- no esta establecida por la norma sino por la practica.

La decision de adopcion en este levantamiento, que debe ser validada por el ICA, es:

: **Regla de correspondencia lote-trampa.** El Sistema requiere que cada trampa del predio tenga
asignado el lote que vigila, y que cada lote declare cuantas trampas lo vigilan. Sin esta
correspondencia explicita, el MTD de un lote no puede calcularse, porque el MTD se define sobre el
*numero de trampas atendidas* y la definicion de «atendida» requiere saber a que lote pertenece la
trampa. Este dato se captura en la configuracion del predio, no en el codigo (RN-013).

La consecuencia es un requisito que no estaba en el enunciado: **RF-013**, registrar y consultar la
asignacion trampa-lote.

## Un segundo hallazgo: el manual no menciona codigos QR ni fotografias {#sec-hallazgo-qr}

La verificacion del Manual arrojo dos ausencias que conviene declarar de forma explicita, porque son
dos mecanismos que las propuestas anteriores usan como si fueran estandar del ICA.

| Mecanismo | Estado en el Manual Tecnico de Trampeo | Consecuencia para el Sistema |
|---|---|---|
| **Codigo QR** | Cero apariciones. La identificacion de trampas se hace por **codigo numerico impreso** en un ordenamiento normado | El QR es un **mecanismo propuesto**, no un estandar ICA. Debe ser un requisito *Should*, con alternativa numerica equivalente |
| **Evidencia fotografica** | Cero apariciones de «foto» o «fotografiar». El manual define evidencia fisica: especimen en alcohol al 70 % etiquetado, tarjeta de control de servicio firmada y acta de siembra | La fotografia es **valor agregado**, no cumplimiento normativo. Debe ser *Should*, no *Must* |

: **Consecuencia metodologica.** Un requisito que se apoya en un mecanismo que la directriz del ICA
no contempla no puede marcarse como *Must* de cumplimiento. Se marca *Should* de valor agregado y se
documenta su origen como decision de diseno. Esta distincion se mantiene en toda la seccion 4.

## El estandar de nomenclatura de trampas {#sec-nomenclatura}

El manual si define, en cambio, como se nombra una trampa, y esa definicion es obligatoria:

> «La **nomenclatura de las trampas** esta compuesta por los **codigos de la Division Politica y
> Administrativa (Divipola) del Departamento Nacional de Estadistica (DANE)** de acuerdo a su
> ubicacion y el **codigo de ruta o predio interno ICA**. La trampa **Jackson siempre va marcada con
> numeros impares** al final de su codigo (**1, 3, 5, 7** etc.) y la trampa **McPhail con numeros
> pares.»

Y el significado del codigo:

> «**Codigo N°:** corresponde al **numero completo de la ruta seguido del numero de la trampa**.»

: **Consecuencia de diseno.** Cualquier esquema de identificacion de trampas que se proponga -
incluidos los codigos QR- debe **contener** la nomenclatura ICA como su identificador canonico, y no
reemplazarla. Un QR no puede tener un identificador propio desconectado de la numeracion oficial,
porque entonces el inventario de trampas del ICA quedaria partido en dos sistemas de nombres. Esta
decision se formaliza en RN-005 y se implementa en RF-013 y RF-030.

Ademas, el manual exige que cada trampa sea georreferificada al instalarse:

> «cada una de las trampas debe ser **georeferenciada y numerada**, diligenciando la informacion en el
> formato de campo establecido por el ICA».

y fija el datum y la precision:

> «se utilizan equipos como el **GPS** o aplicaciones en celular con **Datum: WGS84** y sistema de
> coordenadas en **Grados Decimales (hddd.ddddd° o GG.GGGGG°) ; se deben utilizar 5 unidades
> decimales».

Cinco decimales equivalen aproximadamente a 1,1 metros de resolucion en la equator. Es un requisito
verificable y con cifra: RNF-006.

## Dos linajes de datos, no un solo registro {#sec-dos-linajes}

El enunciado del proyecto mezcla dos cosas que el ICA trata de manera distinta:

| | **Autorreporte del productor** | **Inspeccion oficial ICA** |
|---|---|---|
| Quien registra | El productor o su encargado | El tecnico del ICA |
| Cuando | En cualquier momento, entre visitas | Durante la visita programada |
| Para que | Planificar, comparar, preparar la visita | Sustentar el tramite de exportacion |
| Efecto sobre el tramite | **Ninguno por si mismo** | **Determinante** |
| Campos propios | Fumigaciones, cosecha esperada y real, manejo, observaciones | Lectura de trampas, MTD, cumplimiento de buenas practicas en visita, hallazgos del tecnico |
| Nombre tecnico en este documento | **Autorreporte** | **Inspeccion oficial** |

: **Decision de alcance.** El Sistema soporta ambos linajes en una sola aplicacion, con dos perfiles de
usuario, y **marca cada registro con su linaje**. Un autorreporte del productor nunca genera un
concepto de aptitud para exportar ni alimenta el calculo del MTD.

La razon de esta separacion es de naturaleza juridica y operativa, no de gusto: si un dato
autoinformado entrara al calculo del MTD, el concepto de aptitud dejaria de estar sustentado en una
inspeccion del ICA y el tramite de exportacion quedaria apoyado en evidencia no verificable. Es decir:
la separacion protege al productor y protege al ICA a la vez.

Ademas, la inspeccion oficial tiene una cadencia propia definida por el manual que es **muy distinta**
de la cadencia de la visita del tecnico:

> «El periodo de revision para las trampas es **cada 7-14 dias** (tabla 6), para vigilancia tipo 2, la
> DTEVF concertara con el responsable seccional el rango de lectura de 7 o 14 dias para las rutas
> establecidas.»

Esto genera el requisito **RF-022** -la serie de lectura de trampa por periodo- como una entidad
distinta de la visita. El Sistema no puede suponer que hay una visita cada vez que hay una lectura.

## Partes interesadas {#sec-partes}

La norma exige identificar las partes interesadas y registrar sus necesidades. Se identificaron seis,
con una diferencia importante entre las tres primeras y las tres ultimas: las tres primeras son
**usuarios del sistema**; las tres siguientes son **partes interesadas sin acceso al sistema** que, sin
embargo, condicionan el diseno.

| ID | Parte | Rol | Que necesita del Sistema | Nivel de interaccion |
|---|---|---|---|---|
| **INS** | Productor de durazno | Dueno o responsable del cultivo | Saber si su lote puede exportar; comparar cosecha esperada y real; dejar registrado lo que hizo | **Usuario diario, sin conocimiento tecnico** |
| **TIC** | Tecnico inspector del ICA | Ejecuta la visita y registra la inspeccion oficial | Recorrer el predio orientado; registrar lecturas sin conectividad; que el historico no se altere | **Usuario diario en campo, sin conectividad** |
| **SUP** | Supervisor o coordinator sectional del ICA | Consolida, supervisa y rinde cuentas | Ver el estado de todos los predios; detectar predios en riesgo; exportar el resumen de una visita | **Usuario de consulta, con conectividad** |
| **EICA** | Direccion Tecnica de Epidemiologia y Vigilancia Fitosanitaria (DTEVF) | Define la norma y el programa de inspeccion | Que los datos que alimentan los indicadores del programa se puedan consolidar en los formatos oficiales | **Parte interesada, consume datos en lote** |
| **LAB** | Laboratorio de diagnostico de moscas de la fruta | Confirma la especie de los especimenes | Recibir la relacion de muestras con numero de ruta, municipio, numero de trampa, fecha de colecta y numero de especimenes | **Parte interesada, intercambio de datos** |
| **ORG** | Organismos de control, certificacion de calidad y compradores | Auditan y exigen trazabilidad de la fruta exportada | Poder reconstruir el estado fitosanitario de un lote en una fecha pasada | **Parte interesada, solo consulta** |

La distincion entre **TIC** y **INS** es la que mas condiciona el diseno de la aplicacion, y explica una
decision que aparece en todos los requisitos: **el lenguaje de la aplicacion no puede ser tecnico para
el productor**. Un campo llamado «indice MTD» es correcto para el tecnico y es un obstaculo para el
productor. La regla de redaccion aplicable a los requisitos del linaje de autorreporte es RN-016.

: **Requisito derivado de la distincion de partes.** El Sistema debe permitir que un mismo usuario
tenga uno o varios roles sobre predios distintos, y que la interfaz presente informacion distinta
segun el rol activo. Requisito: **RF-002**.

## Funciones de alto nivel del Sistema {#sec-funciones-alto-nivel}

Agrupadas por capacidad, las funciones que el Sistema debe cubrir son:

1. **Identidad y configuracion.** Saber quien es el usuario, sobre que predios opera y con que reglas.
2. **Orientacion geografica.** Mostrar el predio, sus lotes y sus trampas sobre imagen satelital, con
   una reticula de referencia, y operar sin conexion.
3. **Captura de la inspeccion oficial.** Registrar la lectura de trampas y los hallazgos de la
   visita, con fecha de observacion fiable.
4. **Captura del autorreporte.** Registrar fumigaciones, cosecha esperada y real y manejo agronomico.
5. **Consolidacion temporal.** Calcular el MTD, contrastarlo contra el umbral vigente y reconstruir el
   estado de un lote en cualquier fecha pasada.
6. **Sincronizacion diferida.** Aceptar datos que llegan fuera de orden, con idempotencia y sin
   sobrescribir el pasado.
7. **Consulta y resumen.** Entregar al tecnico, al productor y al supervisor la informacion que cada uno
   necesita, en su propio lenguaje.

# Tecnicas de levantamiento {#sec-tecnicas}

La norma, en su seccion 5, define un conjunto de tecnicas para obtener informacion de las partes
interesadas. Declarar cuales se aplicaron y cuales no es parte del entregable: una especificacion que
no dice de donde salio cada requisito no es auditable.

## Tecnicas efectivamente aplicadas {#sec-tecnicas-aplicadas}

**T1 - Analisis documental.** Se analizo como fuente primaria el *Manual Tecnico de Trampeo de Moscas
de la Fruta* (ICA, 2020), texto de 21 paginas, junto con los documentos de analisis del problema y de
arquitectura preliminar del proyecto. De este analisis se extrajeron: la definicion operativa del MTD,
los umbrales por escenario de trampeo, la nomenclatura de trampas, el datum y la precision exigida para
la georreferenciacion, la cadencia de lectura, el ciclo de vida de los atrayentes, la distancia minima
entre trampas y los formatos oficiales de registro. **Todos los requisitos marcados con origen T1
provienen de aqui y son verificables contra el texto fuente.**

**T2 - Analisis del problema.** Se descompuso el enunciado del proyecto en restricciones y problemas
diferenciados. De este ejercicio salieron los requisitos de trazabilidad temporal (RF-051 a RF-054) y
la separacion en dos linajes de datos.

**T3 - Clasificacion por similitud y cardinalidad.** Se agruparon las funcionalidades pedidas por
dominio y seuento las menciones de cada una en las fuentes. Esto permitio detectar que «registrar el
recorrido» aparece como peticion explicita mientras que «registrar la fumigacion» aparece como
peticion incidental, y que el primero es mucho menos critico que el segundo. La priorizacion de la
seccion 8 es el resultado de aplicar esta tecnica.

**T4 - Preguntas abiertas estructuradas.** Se formularon 35 preguntas de criterio para los elementos
que el analisis documental no puede resolver: precision de GPS requerida, volumen de predios,
presupuesto, gama de dispositivos, politica de datos personales ante perdida del dispositivo,
plataforma objetivo (Android, iOS o ambas). De ellas, 12 siguen abiertas y estan registradas como
UQQ-001 a UQQ-012.

## Tecnicas declaradas pero no aplicadas {#sec-tecnicas-no-aplicadas}

Se declara explicitamente lo que **no** se hizo, para que el lector no asuma una validacion que no
ocurrio.

**T5 - Entrevistas a partes interesadas.** **No realizadas.** No hubo entrevista formal con ningun
tecnico del ICA, ni con ningun productor. Este es el faltante mas importante del levantamiento y la
razon por la que la seccion 10 tiene doce preguntas abiertas y no dos.

**T6 - Observacion directa del proceso.** **No realizada.** No se observo una visita real. En
consecuencia, la secuencia de pasos de la visita descrita en este documento es una reconstruccion
razonada a partir del enunciado, no una observacion.

**T7 - Talleres de requisitos (GRP).** **No realizados.**

**T8 - Prototipos de interfaz y pruebas de usabilidad.** **No realizados.** Existe un prototipo de
nivel de arquitectura, no de interfaz.

> **Advertencia metodologica que este documento asume.** Los requisitos marcados con origen T1 son
> verificables contra el Manual del ICA y no requieren confirmacion. Los marcados con origen T2 o T3
> provienen del analisis del enunciado y **requieren validacion con el ICA antes de convertirse en
> compromiso contractual**. Los que no tienen origen declarado provienen de este documento como
> propuesta de diseno y son responsabilidad del equipo de arquitectura.

## Correspondencia entre el enunciado y la norma del ICA {#sec-enunciado-vs-norma}

Una de las observaciones mas utiles de este levantamiento es que **el enunciado del proyecto y el
Manual del ICA no dicen lo mismo en tres puntos concretos**. Se documentan aqui porque cada uno produce
un requisito de diseno distinto segun cual de las dos fuentes se privilegiara.

| Punto | Enunciado del proyecto | Manual del ICA | Requisito que se genera |
|---|---|---|---|
| **Frecuencia de la revision** | El tecnico revisa «cada 4 meses» | La lectura de trampas es «cada 7-14 dias» | RF-022: la lectura de trampa es una serie propia, independiente de la visita |
| **Unidad de medida del muestreo** | «MTD del lote» | El MTD se define sobre *trampas atendidas* y *dias de exposicion* | RN-001 y RF-023: el MTD se calcula por lote solo si existe asignacion trampa-lote |
| **Base de la exportacion** | «bajo cierto porcentaje MTD impiden la exportacion» | Los umbrales de la Tabla 1 son por **escenario de trampeo**, no de exportacion; la norma de exportacion es la Resolucion 8461 de 2019, no accesible | RF-024 y UQQ-004: el umbral de exportacion es un parametro versionado y **no se inventa** |

: **Decision metodologica.** Ante la divergencia, **prevalece el Manual del ICA** y la divergencia se
registra como pregunta abierta, no como decision de diseno. Esta regla se aplica en todo el documento.# Requisitos del sistema {#sec-requisitos}

## Convenciones {#sec-convenciones}

Cada requisito lleva un identificador estable, un enunciado en una sola oracion, un origen, una
prioridad y un metodo de verificacion. Las caracteristicas que la norma exige -claridad, singularidad,
numeracion, prioridad, verificabilidad, trazabilidad, consistencia y no ambiguedad- se aplican de
forma uniforme.

Los identificadores usan estos prefijos:

| Prefijo | Significado | Cantidad |
|---|---|---|
| `RF-nnn` | Requisito funcional | 58 |
| `RNF-nnn` | Requisito no funcional | 20 |
| `RDD-nnn` | Requisito de datos | 12 |
| `RI-nnn` | Requisito de interfaz | 9 |
| `RST-nnn` | Restriccion | 10 |
| `RN-nnn` | Regla de negocio | 17 |
| `UQQ-nnn` | Pregunta sin respuesta | 12 |
| `RSK-nnn` | Riesgo del levantamiento | 8 |

: **Criterio de singularidad.** Un requisito describe **una** obligacion. Si un enunciado contiene dos
obligaciones separables -«registrar X y calcular Y»- se divide en dos requisitos. Los siete requisitos
que inicialmente violaban este criterio fueron separados durante la redaccion; el caso mas claro fue
«registrar la produccion estimada», que se partio en RF-030 (estimacion) y RF-031 (cosecha real).

## Requisitos funcionales {#sec-rf}

### Grupo A - Identidad, acceso y configuracion del predio

: **RF-001 Autenticacion.** El Sistema debe autenticar a un usuario antes de permitirle operar sobre un
predio. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-002 Autorizacion por rol y predio.** El Sistema debe autorizar cada operacion en funcion del rol
del usuario y del predio sobre el que opera, y debe permitir que un mismo usuario tenga roles
distintos sobre predios distintos. *Origen: T2, INS y TIC. Prioridad: Must. Verificacion: prueba.*

: **RF-003 Consulta del programa de inspeccion vigente.** El Sistema debe mostrar al usuario el
programa de inspeccion vigente del predio: ciclo de cultivo, umbral de MTD aplicable, checklist de
buenas practicas, catalogos de trampas, de enfermedades y enfermedades y de trampeo. *Origen: T1. Prioridad: Must.
Verificacion: prueba.*

: **RF-004 Descarga del paquete de campo del predio.** El Sistema debe permitir al usuario descargar,
para un predio asignado, el paquete de campo que contiene geometria de lotes, reticula, trampas,
catalogos y umbrales, y debe mantenerlo disponible para su uso sin conexion. *Origen: T2. Prioridad:
Must. Verificacion: prueba.*

### Grupo B - Orientacion geografica, reticula y recorrido

: **RF-005 Visualizacion del predio con imagen satelital.** El Sistema debe mostrar la imagen satelital
del predio con los limites de cada lote superpuestos. *Origen: T2. Prioridad: Must. Verificacion:
demostracion.*

: **RF-006 Superposicion de reticula configurable.** El Sistema debe superponer una reticula regular
sobre la imagen del predio, cuya resolucion en metros sea un parametro configurado por predio y no un
valor fijo en el codigo. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-007 Identificacion de lote y de celda por seleccion.** El Sistema debe permitir asignar un
registro a un lote y a una celda de reticula por seleccion en el mapa. *Origen: T2. Prioridad: Must.
Verificacion: demostracion.*

: **RF-008 Captura de la trampa por celda.** El Sistema debe registrar la trampa dentro de la celda de
reticula en la que se encuentra. *Origen: T1, el manual exige que cada trampa este georreferenciada y
numerada. Prioridad: Must. Verificacion: prueba.*

: **RF-009 Registro y consulta del recorrido de la visita.** El Sistema debe registrar y mostrar el
recorrido realizado dentro del predio, en orden cronologico, y distinguir las zonas ya recorridas de
las pendientes. *Origen: T2. Prioridad: Should. Verificacion: demostracion.*

: **RF-010 Marcado geografico de un hallazgo.** El Sistema debe permitir marcar un hallazgo fitosanitario
en un punto del mapa y asociarlo al lote y a la celda correspondientes. *Origen: T2. Prioridad: Must.
Verificacion: demostracion.*

: **RF-011 Lectura de codigo QR de trampa.** El Sistema debe leer un codigo QR asociado a una trampa y
resolverlo contra el catalogo local. *Origen: propuesta de diseno. Prioridad: Should. Verificacion:
prueba.*

: **RF-012 Validacion de coherencia entre trampa, lote y presencia.** El Sistema debe comparar la
identidad de la trampa leida, el lote asignado y la ubicacion reportada por el dispositivo, y debe
registrar la evidencia de esa comparacion; cuando la comparacion no coincida, el Sistema debe
**advertir y pedir confirmacion al usuario, sin bloquear el registro por defecto**. *Origen: T2.
Prioridad: Must. Verificacion: prueba.*

> **Nota sobre RF-011 y RF-012.** El QR es una comodidad de captura, **no una prueba de presencia**. Un
> QR puede fotografiarse y reutilizarse, y el propio enunciado del proyecto no plantea la
> geolocalizacion en tiempo real. Por eso RF-012 combina tres evidencias -QR, GPS y hora- y su
> resultado es una advertencia con registro, no un bloqueo.

: **RF-013 Asignacion de lote a trampa.** El Sistema debe permitir asignar a cada trampa del predio el
lote que vigila, y debe mantener la correspondencia inversa -cuantas trampas vigilan cada lote- de
modo que el conjunto de trampas que sustenta un MTD quede determinado de forma explicita.
*Origen: T2, requisito que no estaba en el enunciado y que se deriva de la definicion de MTD de la
seccion 10 del Manual. Prioridad: Must. Verificacion: prueba.*

### Grupo C - Inspeccion oficial ICA

: **RF-020 Registro de lectura de trampa.** El Sistema debe registrar, por cada trampa leida, el numero
de especimenes capturados y la fecha de lectura. *Origen: T1, el manual define el numero de
especimenes como dato de la tabla de relacion de muestras. Prioridad: Must. Verificacion: prueba.*

: **RF-021 Registro de instalacion y mantenimiento de la trampa.** El Sistema debe registrar la fecha de
instalacion de la trampa, la fecha de cambio de su cuerpo y las fechas de cambio de atrayente.
*Origen: T1, el manual define estos campos para la trampa Jackson y para la McPhail. Prioridad:
Should. Verificacion: prueba.*

: **RF-022 Serie de lectura por periodo de trampeo.** El Sistema debe agrupar las lecturas de trampa en
un periodo de trampeo y determinar el numero de dias de exposicion, usando la fecha de instalacion, la
fecha de retiro o lectura y las lecturas intermedias. *Origen: T1, el MTD usa el numero promedio de
dias de exposicion. Prioridad: Must. Verificacion: prueba.*

: **RF-023 Calculo del MTD del lote.** El Sistema debe calcular el MTD de un lote en un periodo como el
total de moscas capturadas dividido por el producto del numero de trampas atendidas y el numero de
dias de exposicion, y debe calcularlo **por especie**. *Origen: T1, seccion 10 del Manual. Prioridad:
Must. Verificacion: analisis.*

: **RF-024 Contraste contra el umbral y emision del concepto de aptitud.** El Sistema debe contrastar
el MTD de un lote en un periodo contra el umbral vigente **a la fecha de ese periodo** y debe emitir el
concepto de aptitud del lote con la norma aplicada y la fecha de efecto. *Origen: T1. Prioridad: Must.
Verificacion: analisis.*

: **RF-025 Estado de diagnostico pendiente.** El Sistema debe mantener cada registro de trampa en estado
*pendiente de diagnostico* hasta que el laboratorio confirme la especie, y debe mostrar ese estado de
forma visible. *Origen: T1, el manual indica que la especie se obtiene por diagnostico en laboratorio.
Prioridad: Must. Verificacion: prueba.*

: **RF-026 Enlace del resultado de laboratorio.** El Sistema debe permitir registrar el resultado del
diagnostico de especie de una muestra y enlazarlo a los registros de trampa que la originaron.
*Origen: T1. Prioridad: Should. Verificacion: prueba.*

: **RF-027 Relacion de muestras para radicacion al laboratorio.** El Sistema debe generar la relacion de
muestras con los campos que el manual exige: numero de ruta, municipio, numero de trampa ordenado en
forma descendente, fecha de colecta en formato anio/mes/dia y numero de especimenes. *Origen: T1.
Prioridad: Should. Verificacion: inspeccion.*

: **RF-028 Registro del cumplimiento de buenas practicas agricolas.** El Sistema debe registrar, por
lote y por visita, el resultado de cada criterio del checklist de buenas practicas vigente, con
cumplimiento, observacion y evidencia opcional. *Origen: T2. Prioridad: Should. Verificacion: prueba.*

: **RF-029 Registro de hallazgos fitosanitarios desde catalogo.** El Sistema debe permitir registrar
plagas, enfermedades y hongos observados en un lote desde un catalogo configurable, con su severidad
declarada y el origen de la observacion. *Origen: T2. Prioridad: Should. Verificacion: prueba.*

: **RF-030 Registro de la produccion estimada de un lote.** El Sistema debe registrar la produccion
esperada de un lote, con su fecha de estimacion, el numero de arboles, el rendimiento esperado por
arbol y el metodo de estimacion. *Origen: T2. Prioridad: Should. Verificacion: prueba.*

: **RF-031 Registro de la cosecha real de un lote.** El Sistema debe registrar la cosecha realmente
obtenida en un lote, con su fecha, el volumen recolectado y la incidencia observada. *Origen: T2.
Prioridad: Should. Verificacion: prueba.*

: **RF-032 Comparacion entre produccion estimada y real.** El Sistema debe presentar la comparacion
entre la produccion estimada y la real de un lote, con la desviacion absoluta y relativa. *Origen: T2.
Prioridad: Must. Verificacion: prueba.*

: **RF-033 Evidencia fotografica de una medicion o hallazgo.** El Sistema debe permitir adjuntar
fotografias a un registro de trampa, a una visita o a un hallazgo. *Origen: propuesta de diseno, el
manual no la exige. Prioridad: Should. Verificacion: demostracion.*

### Grupo D - Autorreporte del productor

: **RF-040 Registro de aplicacion fitosanitaria.** El Sistema debe permitir al productor registrar una
aplicacion fitosanitaria con su fecha, el producto aplicado, la dosis, el area tratada y la persona
responsable. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-041 Consulta de la ultima aplicacion por lote.** El Sistema debe mostrar la ultima aplicacion
fitosanitaria registrada en cada lote y el numero de dias transcurridos desde ella. *Origen: T2.
Prioridad: Must. Verificacion: prueba.*

: **RF-042 Registro de cosecha esperada y real de un lote.** El Sistema debe permitir al productor
registrar la fecha y el volumen esperado de cosecha y la fecha y el volumen realmente recolectado, como
un unico registro de cosecha con dos componentes. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-043 Registro de manejo agronomico.** El Sistema debe permitir registrar operaciones de manejo
aplicadas a un lote: riego, fertilizacion, poda, thinning y renovacion. *Origen: T2. Prioridad: Could.
Verificacion: prueba.*

: **RF-044 Etapa fenologica declarada por el productor.** El Sistema debe permitir al productor declarar
la etapa fenologica de un lote, como valor distinto de la etapa derivada del ciclo de cultivo.
*Origen: T2. Prioridad: Should. Verificacion: prueba.*

### Grupo E - Serie historica y derivados {#sec-rf-serie}

: **RF-050 Linea de tiempo de un lote.** El Sistema debe mostrar la linea de tiempo de un lote con los
registros ordenados por fecha de observacion, mostrando para cada registro que se registro, cuando se
observo y quien lo registro. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-051 Registro de la fecha de observacion en todo dato de campo.** El Sistema debe almacenar, para
todo dato capturado en campo, la fecha y hora en que fue observado, distinta de la fecha en que se
digito y de la fecha en que llego al servidor. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-052 Conservacion del pasado.** El Sistema debe conservar toda version previa de un dato
corregido, de modo que la pregunta por lo que se registro originalmente en una fecha dada tenga
siempre respuesta. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-053 Reconstruccion del estado de un lote en una fecha pasada.** El Sistema debe poder
entregar el estado de aptitud de un lote tal como se habria obtenido en cualquier fecha pasada.
*Origen: T2. Prioridad: Should. Verificacion: analisis.*

: **RF-054 Actualizacion de la serie al llegar un dato fuera de orden.** El Sistema debe recalcular el
MTD y el concepto de aptitud de un lote cuando la llegada de un registro cambia el valor de un periodo
ya calculado, y debe reportar el valor anterior, el nuevo y la fecha del recalculo. *Origen: T2.
Prioridad: Must. Verificacion: analisis.*

### Grupo F - Funcionamiento sin conexion y sincronizacion {#sec-rf-offline}

: **RF-060 Ejecucion de la visita sin conexion.** El Sistema debe permitir realizar, registrar y cerrar
completamente una visita en un predio sin cobertura de datos moviles ni de wifi. *Origen: T2,
restriccion declarada. Prioridad: Must. Verificacion: demostracion en modo avion.*

: **RF-061 Persistencia local inmediata.** El Sistema debe persistir en el dispositivo, en el momento en
que el usuario confirma cada registro, sin esperar confirmacion del servidor. *Origen: T2. Prioridad:
Must. Verificacion: prueba.*

: **RF-062 Cola de salida con reintentos.** El Sistema debe mantener una cola de operaciones pendientes
de envio, reintentarlas automaticamente cuando haya conexion y no eliminar un registro local aunque el
envio falle. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-063 Resultado de sincronizacion por operacion.** El Sistema debe informar el resultado de cada
operacion enviada de forma individual, y debe aceptar que un lote de operaciones se acepte de forma
parcial. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-064 Idempotencia del envio.** El Sistema debe garantizar que el reintento del envio de una operacion ya
recibida no produzca duplicados. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-065 Alta retroactiva.** El Sistema debe aceptar y colocar en su posicion cronologica real un
registro cuya fecha de observacion sea anterior a la de datos ya sincronizados. *Origen: T2.
Prioridad: Must. Verificacion: prueba.*

: **RF-066 Operacion marcada para revision.** El Sistema debe marcar una operacion como *revisar*,
en lugar de decidirla automaticamente, cuando su fecha de observacion se solape con una ventana ya
cubierta para el mismo lote y tipo de muestreo. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-067 Envio de la evidencia fotografica en segundo plano.** El Sistema debe enviar la evidencia
fotografica despues que el dato numerico, sin bloquear el cierre de la visita. *Origen: T2. Prioridad:
Should. Verificacion: prueba.*

: **RF-068 Invalidacion del paquete de campo por cambio de configuracion.** El Sistema debe detectar
que la version del programa de inspeccion del predio cambio y debera exigir la actualizacion del
paquete de campo antes de iniciar una visita. *Origen: T1 y T2. Prioridad: Should. Verificacion:
prueba.*

### Grupo G - Consulta, resumen y reportes {#sec-rf-consulta}

: **RF-070 Resumen del lote para la visita del tecnico.** El Sistema debe generar un resumen por lote
que presente, en un solo pantallazo: MTD del ultimo periodo, umbral aplicable, cumple o no cumple,
etapa fenologica, cumplimiento de buenas practicas, dias desde la ultima aplicacion fitosanitaria,
estimacion de cosecha contra cosecha real y hallazgos vigentes. *Origen: T2, peticion explicita del
enunciado. Prioridad: Must. Verificacion: demostracion.*

: **RF-071 Resumen del predio.** El Sistema debe generar un resumen por predio con el estado de aptitud
de cada lote y la tendencia del MTD de los ultimos periodos. *Origen: T2. Prioridad: Must.
Verificacion: demostracion.*

: **RF-072 Historico de inspecciones.** El Sistema debe permitir consultar las inspecciones oficiales y
los autorreportes de un predio, filtrando por lote, por periodo y por tipo. *Origen: T2. Prioridad:
Must. Verificacion: prueba.*

: **RF-073 Exportacion del resumen de visita.** El Sistema debe permitir exportar el resumen de una
visita en un documento imprimible. *Origen: T2. Prioridad: Should. Verificacion: inspeccion.*

: **RF-074 Alertas de vencimiento y de incumplimiento.** El Sistema debe generar una alerta cuando un
lote supere el umbral de MTD, cuando se cumpla un periodo de lectura de trampa o cuando una aplicacion
fitosanitaria se aproxime a su fecha de renovacion recomendada. *Origen: T2. Prioridad: Could.
Verificacion: prueba.*

: **RF-075 Indicadores de gestion de predios.** El Sistema debe permitir obtener, para un conjunto de
predios, el indicador de proportion de lotes en aptitud, la tendencia del MTD y el cumplimiento de
buenas practicas. *Origen: T2. Prioridad: Could. Verificacion: analisis.*

### Grupo H - Administracion y gobernanza {#sec-rf-admin}

: **RF-080 Parametrizacion del programa de inspeccion por predio.** El Sistema debe permitir a un
administrador definir y versionar el programa de inspeccion de un predio: ciclo, umbral de MTD,
periodo de trampeo, checklist de buenas practicas, catalogos, reticula y proveedor de imagen. *Origen:
T2. Prioridad: Must. Verificacion: prueba.*

: **RF-081 Gestion de catalogos.** El Sistema debe permitir administrar los catalogos de trampas y
atrayentes, de enfermedades y plagas, de buenas practicas y de productos fitosanitarios. *Origen: T1 y
T2. Prioridad: Must. Verificacion: prueba.*

: **RF-082 Gestion de usuarios y roles.** El Sistema debe permitir crear, desactivar y asignar roles a
usuarios. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-083 Bitacora de auditoria.** El Sistema debe registrar, en una bitacora que no admite
modificacion, toda operacion relevante con su actor, su fecha de observacion, su fecha de captura, su
fecha de sincronizacion y la version afectada. *Origen: T2. Prioridad: Must. Verificacion: prueba.*

: **RF-084 Validacion de geometrias recibidas.** El Sistema debe validar toda geometria recibida antes
de almacenarla, comprobando que sea valida, que falls dentro del predio y que los campos de
georreferentacion cumplen el datum y la precision exigidos. *Origen: T1. Prioridad: Must.
Verificacion: prueba.*

: **RF-085 Versionado de la geometria de lotes.** El Sistema debe conservar la version vigente de la
geometria de un lote y asociar cada medicion a la version de geometria que estaba vigente en su fecha
de observacion. *Origen: T2. Prioridad: Should. Verificacion: prueba.*

## Requisitos no funcionales {#sec-rnf}

Los requisitos no funcionales se clasifican por caracteristica de calidad segun ISO/IEC 25010 y se
formulan con cifra, porque un requisito no funcional sin cifra no es verificable.

### Usabilidad {#sec-rnf-usabilidad}

: **RNF-001 Registro de lectura de trampa en dos minutos.** El Sistema debe permitir registrar la
lectura de una trampa en un maximo de dos minutos y con un maximo de tres interacciones, para un
tecnico con experiencia previa en trampeo. *Origen: T2. Verificacion: prueba de usabilidad.*

: **RNF-002 Umbral de error en captura de cantidades.** El Sistema debe impedir la confirmacion de un
registro con una cantidad negativa o no numerica, y debe señalarlo sin descartar lo ya escrito.
*Origen: T1. Verificacion: prueba.*

: **RNF-003 Lenguaje no tecnico para el productor.** Los mensajes y las etiquetas dirigidas al
productor deben formularse en lenguaje corriente y no usar acronimos tecnicos sin explicacion; los
acronimos tecnicos solo deben aparecer en el contexto del rol tecnico. *Origen: T2. Verificacion:
inspeccion.*

: **RNF-004 Operacion con una mano y con guantes.** Los controles de la visita deben poder operarse con
una sola mano y en pantallas de tamano reducido. *Origen: T2. Verificacion: demostracion.*

### Rendimiento {#sec-rnf-rendimiento}

: **RNF-005 Duracion de la jornada de campo.** El Sistema debe soportar una jornada continua de
operacion de seis horas con localizacion activa, sin agotar la bateria del dispositivo antes de
terminar la jornada, con la frecuencia de muestreo de posicion configurable. *Origen: T2.
Verificacion: prueba de campo.*

: **RNF-006 Precision de la georreferenciacion.** El Sistema debe almacenar la precision reportada por
el dispositivo en cada posicion y debe registrar coordenadas con datum WGS84 en grados decimales con
cinco decimales. *Origen: T1, el Manual exige cinco decimales. Verificacion: inspeccion de datos.*

: **RNF-007 Tiempo de respuesta del mapa sin conexion.** El Sistema debe desplazar y desplazar el mapa
de un predio sin conexion con una fluidez que no interrumpa el registro, en un dispositivo de gama
media. *Origen: T2. Verificacion: prueba de rendimiento.*

: **RNF-008 Tiempo de sincronizacion por lote de operaciones.** El Sistema debe procesar un envio de
doscientas operaciones en un tiempo total no superior a sesenta segundos, medido desde el envio hasta
la confirmacion por operacion. *Origen: T2. Verificacion: prueba de rendimiento.*

### Confiabilidad {#sec-rnf-confiabilidad}

: **RNF-009 Cero perdida de registros confirmados.** El Sistema debe garantizar que ningun registro
confirmado por el usuario se pierda por fallo de red, de bateria o de proceso, y debe demostrarlo
mediante una prueba de operacion completa en modo avion seguida de reinicio del dispositivo.
*Origen: T2. Verificacion: prueba.*

: **RNF-010 Recuperacion ante perdida del dispositivo.** El Sistema debe permitir que una inspeccion
registrada pero no sincronizada pueda recuperarse desde la copia local sin intervencion del usuario.
*Origen: T2. Verificacion: prueba.*

: **RNF-011 Ausencia de duplicados por reintento.** El Sistema debe garantizar que ninguna operacion
sincronizada se procese dos veces ante reintento, particion de red o reinicio del cliente.
*Origen: T2. Verificacion: prueba.*

### Seguridad y privacidad {#sec-rnf-seguridad}

: **RNF-012 Cifrado en transito.** Toda comunicacion entre el dispositivo y el servidor debe realizarse
sobre TLS 1.2 o superior. *Origen: T2. Verificacion: inspeccion.*

: **RNF-013 Cifrado en reposo en el dispositivo.** Los datos del Sistema deben almacenarse cifrados en
el dispositivo y el acceso al dispositivo debe requerir autenticacion local. *Origen: T2. Verificacion:
inspeccion.*

: **RNF-014 Proteccion de datos personales.** El Sistema debe|Minimizar los datos personales
almacenados, atender la Ley 1581 de 2012 y mantener bitacora de los accesos a datos de personas
identificables. *Origen: T2. Verificacion: inspeccion.*

: **RNF-015 Control de acceso por rol.** El Sistema debe impedir el acceso a operaciones no autorizadas
en el servidor, con independencia de lo que la interfaz ofrezca. *Origen: T2. Verificacion: prueba.*

### Mantenibilidad y evolutividad {#sec-rnf-mantenibilidad}

: **RNF-016 Predio nuevo sin cambio de codigo.** El Sistema debe permitir incorporationar un predio
nuevo, con sus lotes, trampas, umbral y catalogos, mediante datos de configuracion y sin modificacion
del codigo fuente ni de una nueva version publicada. *Origen: T2. Verificacion: prueba.*

: **RNF-017 Cobertura de pruebas del nucleo de reglas.** El Sistema debe cubrir con pruebas
automatizadas, como minimo, el ochenta por ciento de las reglas de negocio de la seccion de reglas de
negocio de este documento. *Origen: T2. Verificacion: analisis de cobertura.*

: **RNF-018 Evidencia de cada diagrama de arquitectura.** El Sistema debe contar con los diagramas de
contexto, contenedores, componentes, vista dinamica y vista de despliegue, y cada cambio de frontera
debe quedar registrado como version de esos diagramas. *Origen: T2. Verificacion: inspeccion.*

### Compatibilidad y portabilidad {#sec-rnf-compatibilidad}

: **RNF-019 Plataformas objetivo.** El Sistema debe ejecutarse en el conjunto de versiones de sistema
operativo movil que el ICA defina como soportadas, y ese conjunto debe declararse antes del inicio de
la construccion. *Origen: T2, con UQQ-009. Verificacion: inspeccion.*

: **RNF-020 Tamano del paquete de campo.** El paquete de campo de un predio no debe exceder un
tamano maximo definido por el administrador, y el Sistema debe advertir al usuario antes de superarlo.
*Origen: T2. Verificacion: prueba.*

## Requisitos de datos {#sec-rdd}

Los requisitos de datos describen la informacion que el Sistema debe retener. El detalle del esquema,
con tipos, claves e indices, corresponde al documento de arquitectura tecnologica.

: **RDD-001 Identidad del predio.** El Sistema debe almacenar codigo, nombre, municipio, departamento,
geometria, area y responsable de cada predio. *Origen: T2. Prioridad: Must.*

: **RDD-002 Identidad y geometria versionada del lote.** El Sistema debe almacenar codigo, poligono,
area, variedad, fecha de plantacion y estado del lote, con versionado de la geometria. *Origen: T2.
Prioridad: Must.*

: **RDD-003 Celda de reticula.** El Sistema debe almacenar codigo, poligono, resolucion en metros y
fecha de corte de imagen de cada celda de reticula. *Origen: T2. Prioridad: Must.*

: **RDD-004 Trampa con su nomenclatura ICA.** El Sistema debe almacenar codigo conforme a la
nomenclatura del Manual -codigo Divipola, codigo de ruta o predio interno y numero de trampa con
paridad segun el tipo-, tipo de trampa, atrayente, lote que vigila, coordenadas WGS84 con cinco
decimales y fechas de instalacion y retiro. *Origen: T1. Prioridad: Must.*

: **RDD-005 Lectura de trampa.** El Sistema debe almacenar, por trampa y por fecha de lectura, el
numero de especimenes capturados, el estado de la trampa, las fechas de cambio de cuerpo y de
atrayente, las observaciones y el estado de diagnostico. *Origen: T1. Prioridad: Must.*

: **RDD-006 Indices de muestreo calculados.** El Sistema debe almacenar el MTD por lote, por especie y
por periodo, junto con el total de moscas, el numero de trampas atendidas, el numero de dias de
exposicion, el umbral aplicado y el resultado del contraste. *Origen: T1. Prioridad: Must.*

: **RDD-007 Umbral y programa versionados.** El Sistema debe almacenar el umbral de MTD, su unidad, su
periodo de vigencia y la norma que lo sustenta, de modo que un cambio de umbral no altere los
resultados historicos. *Origen: T1 y T2. Prioridad: Must.*

: **RDD-008 Serie de aplicaciones fitosanitarias.** El Sistema debe almacenar, por lote, el producto,
la dosis, el area tratada, el responsable y la fecha de cada aplicacion fitosanitaria. *Origen: T2.
Prioridad: Must.*

: **RDD-009 Serie de cosechas.** El Sistema debe almacenar, por lote, el volumen y la fecha esperados y
el volumen y la fecha realmente cosechados, con su metodo de registro. *Origen: T2. Prioridad: Must.*

: **RDD-010 Marcas temporales de todo dato de campo.** El Sistema debe almacenar, para todo dato de
campo, la fecha de observacion, la fecha de captura y la fecha de sincronizacion, con sus fuentes, y
debe registrar la deriva del reloj del dispositivo cuando se detecte. *Origen: T2. Prioridad: Must.*

: **RDD-011 Evidencia asociada.** El Sistema debe asociar a cada evidencia fotografica su hash, su
referencia de almacenamiento, su fecha de captura y su georreferentacion. *Origen: propuesta de
diseno. Prioridad: Should.*

: **RDD-012 Cumplimiento de buenas practicas y hallazgos.** El Sistema debe almacenar el resultado de
cada criterio de buenas practicas y cada hallazgo del catalogo, con su fecha de observacion, su autor y
su origen. *Origen: T2. Prioridad: Should.*

## Requisitos de interfaz {#sec-ri}

: **RI-001 Superficie movil.** El Sistema debe operar como aplicacion movil en el dispositivo del
tecnico y del productor. *Origen: T2. Prioridad: Must.*

: **RI-002 Resolucion de mapa programable.** El Sistema debe permitir configurar la resolucion de la
reticula en metros por predio, y el valor debe ser múltiplo de la distancia minima entre trampas que
la norma exige (vease RN-004). *Origen: T1 y T2. Prioridad: Must.*

: **RI-003 Origen de la imagen satelital.** El Sistema debe consumir mosaicos satelitales de un
proveedor externo dentro de su licencia de uso, y no debe generar ni procesar imagenes de satelite por
cuenta propia. *Origen: T2. Prioridad: Must.*

: **RI-004 Almacenamiento local de imagen.** El Sistema debe almacenar en el dispositivo el recorte de
imagen del area de trabajo asignada y su politica de almacenamiento. *Origen: T2. Prioridad: Must.*

: **RI-005 Exportacion documental.** El Sistema debe generar documentos en formato PDF para el resumen
de visita y para la relacion de muestras. *Origen: T2. Prioridad: Should.*

: **RI-006 Salida de datos agregados.** El Sistema debe permitir extraer, para el programa de
vigilancia, los consolidados de capturas y muestreo en los formatos oficiales del ICA. *Origen: T1.
Prioridad: Should.*

: **RI-007 Operacion sin teclado.** Los formularios de captura en campo deben poder diligenciarse sin
teclado fisico para los valores numericos. *Origen: T2. Prioridad: Should.*

: **RI-008 Identidad institucional.** El Sistema debe validar las identidades del personal contra el
proveedor institucional del ICA y no debe almacenar credenciales propias de empleados del ICA. *Origen:
T2. Prioridad: Should.*

: **RI-009 Plataforma de consulta institucional.** El Sistema debe ofrecer una superficie de consulta
para el supervisor y para el proceso de exportacion, accesible con conectividad y con informacion
propia de cada rol. *Origen: T2. Prioridad: Must.*

## Restricciones {#sec-rst}

: **RST-001 Sin cobertura de red en el predio.** La ausencia total de conectividad de datos es la
condicion normal del predio durante la visita y no una excepcion. *Origen: T2, declarado en el
enunciado.*

: **RST-002 Personalizacion por predio.** La solucion no es un producto generico de fitosanitologia: se
configura para predios concretos. *Origen: T2, declarado en el enunciado.*

: **RST-003 La aplicacion es movil.** No se requiere aplicacion de escritorio para el trabajo de campo.
*Origen: T2.*

: **RST-004 El desarrollo lo ejecuta otro equipo.** Este documento no implementa codigo; su producto es
el contrato de requisitos para un equipo de construccion. *Origen: T2.*

: **RST-005 El tramite de exportacion no se automatiza.** El Sistema produce el insumo tecnico; la
licencia fitosanitaria de movimentilizacion y el certificado de exportacion siguen siendo parte del
proceso institucional. *Origen: T2.*

: **RST-006 No se implementa diagnostico automatico.** El Sistema registra y cataloga hallazgos; no los
identifica mediante inteligencia artificial ni los procesa por imagen. *Origen: T2.*

: **RST-007 No se sustituye la imagen satelital.** Se consume la de un proveedor existente, dentro de su
licencia. *Origen: T2.*

: **RST-008 No se capturan hora por lectura.** El Manual no registra hora de lectura; el Sistema no debe
exigirla, aunque puede almacenarla si el dispositivo la provee. *Origen: T1.*

: **RST-009 Los diagnosticos de especie son externas.** La identificacion de especie se realiza en
laboratorio; el Sistema no la calcula. *Origen: T1.*

: **RST-010 Un unico marco temporal.** Todos los datos del Sistema se expresan en un unico idioma de
fecha y zona, definido en la especificacion de datos. *Origen: T2.*

## Reglas de negocio {#sec-rn}

Las reglas de negocio no son requisitos: son verdades del dominio que acotan que soluciones son
aceptables. Todas las que llevan origen T1 son verificables contra el texto del Manual.

: **RN-001 Formula del MTD.** El MTD se calcula como el numero total de moscas capturadas dividido por
el producto del numero de trampas atendidas y el numero promedio de dias en que las trampas estuvieron
expuestas en campo, y se calcula **por especie**. El MTD es el indice tecnico de moscas trampa dia.
*Origen: T1, seccion 10 del Manual.*

: **RN-002 Escenarios de trampeo y umbrales.** El Manual clasifica los escenarios de trampeo segun el
valor del MTD: area infestada con MTD mayor a 1; supresion con MTD entre 1 y 0,1; erradicacion con MTD
entre 0,1 y 0; exclusion con MTD entre 0 y 0. El sistema debe soportar estos escenarios como
parametros configurables por predio. *Origen: T1, Tabla 1, matriz de escenarios de trampeo (OIEA,
2005).*

> **Nota sobre RN-002.** Estos cuatro umbrales corresponden a **escenarios de trampeo**, no a un
> criterio de exportacion. El Manual no define un umbral de exportacion; remite a la Resolucion 8461
> de 2019. Por eso RF-024 exige que el umbral de exportacion sea un parametro versionado, y por eso
> UQQ-004 sigue abierta. **El sistema no debe inventar ese valor.**

: **RN-003 Vigencia del umbral.** El umbral aplicable a un periodo es el vigente **a la fecha de ese
periodo**, no el vigente hoy. *Origen: T1 y T2.*

: **RN-004 Distancia minima entre trampas.** Las trampas deben ubicarse a una distancia minima de 40 a
60 metros entre ellas, y las trampas Jackson cebadas con trimedlure deben separarse de las McPhail a
esa misma distancia por el efecto repelente del atrayente. *Origen: T1.*

> **Consecuencia de diseno derivada de RN-004.** La retícula del predio debe tener una resolucion
> **mayor que 60 metros**, y en la practica conviene que sea un multiplo de esa distancia, de modo que
> dos trampas nunca caigan en celdas contiguas por error de registro. Esta consecuencia no
> estaba en el enunciado del proyecto y es una de las razones por las que RI-002 exige que la
> resolucion sea parametro y no constante.

: **RN-005 Nomenclatura de trampas.** El codigo de una trampa se compone del codigo Divipola del
municipio, el codigo de ruta o predio interno del ICA y el numero de la trampa; las trampas Jackson se
numeran con impares y las McPhail con pares. *Origen: T1.*

: **RN-006 Georreferentacion.** Las trampas se georreferencian en datum WGS84, en grados decimales, con
cinco decimales. *Origen: T1.*

: **RN-007 Cadencia de lectura.** El periodo de revision de las trampas es de siete a catorce dias,
segun el tipo de vigilancia; para predios de exportacion aplica el rango de siete a catorce dias. *Origen:
T1, Tabla 6.*

: **RN-008 Vida util del atrayente.** El atrayente plug se cambia cada cuatro a seis semanas; el
atrayente proteico hidrolizado dura de una a dos semanas en campo. *Origen: T1, Tabla 3.*

: **RN-009 Inmutabilidad de la fecha de observacion.** Una vez sincronizado, un registro no puede
cambiar su fecha de observacion. Si el tecnico se equivoco de dia, se anula el registro y se crea uno
nuevo con la fecha correcta, dejando ambos visibles. *Origen: T2.*

: **RN-010 Idempotencia.** El reintento de envio de una operacion ya recibida no produce duplicados; si
la misma identidad de operacion llega con contenido distinto, se rechaza y se reporta como
conflicto. *Origen: T2.*

: **RN-011 Solapamiento marcado, no decidido.** Cuando una lectura con fecha de observacion cae dentro de
una ventana ya cubierta para el mismo lote y tipo de muestreo, el sistema marca la operacion *revisar* y
la devuelve al usuario para confirmacion humana; no elige un ganador automatico. *Origen: T2.*

: **RN-012 Etapa fenologica derivada, no capturada.** La etapa fenologica de un lote se deriva de la
fecha de observacion, de la fecha de plantacion y de la tabla de etapas vigente en esa fecha. El
productor y el tecnico pueden **declarar** una etapa; esa declaracion se conserva con su fecha, su
valor y su autor, y se marca como declarada frente a derivada. Cuando ambas difieren, el sistema
muestra las dos y registra la discrepancia. *Origen: T2.*

: **RN-013 Asignacion trampa-lote.** Ningun MTD de lote puede calcularse sin que exista asignacion
explicita de la trampa al lote. *Origen: T1, derivado.*

: **RN-014 Autorreporte sin efecto normativo.** Un registro del linaje de autorreporte no alimenta el
calculo del MTD ni la emision de un concepto de aptitud. *Origen: T2.*

: **RN-015 Diagnostico de especie en laboratorio.** La especie de un especimen se establece por
diagnostico en laboratorio; el registro de campo almacena el numero de especimenes capturados y queda
en estado pendiente hasta que el laboratorio confirme. *Origen: T1.*

: **RN-016 Redaccion no tecnica para el productor.** Un requisito dirigido al perfil del productor se
redacta en lenguaje corriente, sin acronimos tecnicos, y se acompaña de la unidad de medida cuando el
dato es numerico. *Origen: T2.*

: **RN-017 Indicadores con unidad explicita.** Todo dato numerico del Sistema se almacena con su
unidad, y ninguna magnitud se almacena como numero desnudo. *Origen: T1 y T2.*# Casos de uso {#sec-casos}

La norma exige que los requisitos se organicen de forma que se pueda verificar su satisfaccion. Los
casos de uso cumplen esa funcion: cada requisito funcional debe ser ejercido por al menos un caso de
uso, y cada caso de uso debe declarar su flujo principal, sus precondiciones, sus postcondiciones y
las excepciones que el sistema debe distinguir.

## Catalogo de casos de uso {#sec-casos-catalogo}

| ID | Caso de uso | Actor principal | Requisitos que ejercita |
|---|---|---|---|
| **CU-01** | Descargar el paquete de campo de un predio | TIC, INS | RF-003, RF-004, RST-002 |
| **CU-02** | Abrir un predio y orientarse en el mapa | TIC, INS | RF-005, RF-006, RF-007, RF-013 |
| **CU-03** | Registrar una lectura de trampa | TIC | RF-020, RF-021, RF-022, RF-013, RF-011, RF-012, RNF-001 |
| **CU-04** | Registrar una visita completa en campo sin conexion | TIC | RF-060, RF-061, RF-009, RF-010 |
| **CU-05** | Sincronizar la cola de salidas | TIC, INS | RF-062, RF-063, RF-064 |
| **CU-06** | Cargar datos de una visita anterior | TIC | RF-065, RF-054, RN-010 |
| **CU-07** | Corregir un dato ya sincronizado | TIC, INS | RF-052, RN-009 |
| **CU-08** | Resolver una operacion marcada para revision | TIC | RF-066, RN-011 |
| **CU-09** | Registrar una aplicacion fitosanitaria | INS | RF-040, RF-041 |
| **CU-10** | Registrar cosecha esperada y real | INS | RF-042, RF-031 |
| **CU-11** | Consultar el resumen del lote en la visita | TIC, SUP | RF-070, RF-072 |
| **CU-12** | Consultar el estado de un lote en una fecha pasada | SUP, TIC | RF-053, RF-050 |
| **CU-13** | Parametrizar el programa de inspeccion de un predio | Administrador | RF-080, RF-081, RF-082 |
| **CU-14** | Registrar y depurar la especie de una muestra | EICA, LAB | RF-025, RF-026, RN-015 |
| **CU-15** | Generar la relacion de muestras para el laboratorio | TIC | RF-027, RI-005 |

## Flujos detalados de los casos de uso criticos {#sec-casos-flujos}

### CU-03 · Registrar una lectura de trampa {#flujo-cu03}

Este es el caso de uso mas frecuente del sistema y el que mas veces se ejecutara en una visita. Por
eso es tambien el que tiene el requisito no funcional mas estricto: dos minutos y tres
interacciones (RNF-001).

**Precondiciones.** El usuario esta autenticado; el paquete de campo del predio esta descargado y es
vigente; la trampa esta asociada a un lote (RN-013).

**Flujo principal.**

1. El usuario abre el predio y selecciona el lote desde el mapa o desde la lista.
2. El sistema muestra las trampas del lote con su codigo ICA y su tipo.
3. El usuario escanea el codigo QR de la trampa, o selecciona la trampa de la lista si el QR no esta
   disponible.
4. El sistema resuelve la identidad de la trampa, la compara con el lote abierto y con la ubicacion
   reportada por el dispositivo, y **registra la evidencia de esa comparacion** (RF-012).
5. Si la comparacion no coincide, el sistema **advierte y pide confirmacion**, sin bloquear el
   formulario (RF-012).
6. El usuario registra el numero de especimenes y las observaciones (RF-020).
7. El sistema persiste el registro de forma local e inmediata, con la fecha de observacion, la fecha
   de captura y el identificador del dispositivo (RF-061, RDD-010).
8. El sistema encola la operacion de salida y muestra el estado *pendiente de envio* (RF-062).

**Postcondiciones.** Existe un registro local con fecha de observacion, tres marcas temporales,
identidad de trampa y lote, y una operacion en la cola de salidas. No se ha realizado ninguna llamada
de red.

**Excepciones que el sistema debe distinguir.**

| Excepcion | Respuesta del sistema |
|---|---|
| QR ilegible o ausente | Permite seleccionar la trampa de la lista y marca el origen como seleccion manual |
| Trampa no encontrada en el catalogo | Bloquea el vinculo automatico y exige seleccion manual; no descarta el dato |
| Trampa asociada a otro lote | Advierte, muestra el lote que el sistema tiene asignado y pide confirmacion |
| Sin trampas en el lote | Informa que el lote no tiene trampas registradas y ofrece registrar la lectura como observacion de campo sin MTD |
| Periodo sin dias de exposicion cerrados | Registra la lectura y marca el periodo como abierto; el MTD no se emite hasta cerrar el periodo |

### CU-06 · Cargar datos de una visita anterior {#flujo-cu06}

Es el caso de uso que justifica la arquitectura. Es tambien el menos frecuente en el uso diario y el
mas frecuente en la capacidad de dano si se implementa mal.

**Precondiciones.** El usuario tiene operaciones en la cola de salidas cuyas fechas de observacion son
anteriores a la de datos ya sincronizados.

**Flujo principal.**

1. El sistema detecta la conexion y envia las operaciones pendientes por lotes.
2. El servidor clasifica cada operacion recibida y devuelve un resultado por operacion (RF-063).
3. Para una operacion cuya fecha de observacion es anterior al ultimo dato ya sincronizado y que no
   existia, el servidor la clasifica como **alta retroactiva** y la inserta en su posicion cronologica
   real (RF-065).
4. El servidor recalcula el MTD y el concepto de aptitud de los periodos afectados, y reporta el valor
   anterior, el nuevo y la fecha del recalculo (RF-054).
5. El sistema muestra al usuario, en lenguaje corriente, que el registro entro en su lugar y que el
   resumen de ese lote cambio.

**Postcondiciones.** La serie del lote esta ordenada por fecha de observacion, no por fecha de llegada.
Ningun dato previo fue sobrescrito.

**Excepcion critica.** Si la operacion se solapa con una ventana ya cubierta para el mismo lote y
tipo de muestreo, el sistema **no decide**: la marca como *revisar* y la devuelve al usuario (RF-066,
RN-011). Esta excepcion no es un fallo del sistema; es una decision de diseno que protege la
credibilidad del dato fitosanitario.

### CU-11 · Consultar el resumen del lote en la visita {#flujo-cu11}

Este caso de uso responde a la peticion explicita del enunciado: llegar a la visita con un resumen
imprimible y comparable con la visita anterior.

**Precondiciones.** El usuario tiene acceso al predio; el historial hasta la fecha de consulta esta
disponible, ya sea en el dispositivo o en el servidor.

**Fluxo principal.**

1. El usuario abre el predio y selecciona el lote.
2. El sistema presenta, en un solo pantallazo: MTD del ultimo periodo cerrado con su unidad, umbral
   aplicable y si el lote cumple; etapa fenologica derivada y etapa declarada, con la discrepancia si
   existe; cumplimiento de buenas practicas del ultimo mes; dias transcurridos desde la ultima
   aplicacion fitosanitaria; produccion estimada contra cosecha real con su desviacion; hallazgos
   vigentes; y el numero de trampas con lectura al dia.
3. El usuario compara con la visita anterior sin salir de la pantalla.
4. El usuario puede exportar el resumen en PDF para entregarlo (RF-073).

**Postcondiciones.** El usuario tiene el estado del lote y su tendencia, y puede detectar en un minuto
los tres casos mas frecuentes de un rechazo: MTD alto, falta de lectura de una trampa, y desviacion
fuerte entre estimada y real.

> **Nota de diseno de la informacion.** Este pantallazo esta ordenado por la probabilidad de que algo
> impida la exportacion, no por la completitud del dato fitosanitario. Un resumen ordenado por
> completitud obliga al tecnico a leerlo entero; uno ordenado por riesgo le permite decidir en el
> primer minuto.

### CU-14 · Registrar y depurar la especie de una muestra {#flujo-cu14}

**Precondiciones.** Existen registros de trampa en estado *pendiente de diagnostico*; el laboratorio
emitio un resultado.

**Flujo principal.**

1. El Supervisor o el rol de la DTEVF carga el resultado del laboratorio con su codigo de muestra.
2. El sistema enlaza el resultado a todos los registros de trampa que corresponden a esa muestra.
3. El sistema recalcula el MTD **por especie**, ahora con la especie confirmada (RF-023).
4. El sistema conserva el valor calculado previamente con la especie pendiente, para auditoria.

**Postcondiciones.** Los registros tienen especie confirmada; el MTD por especie esta vigente; el
concepto de aptitud del periodo se reemite con la norma aplicada.

**Excepcion.** Si el resultado de laboratorio no se puede enlazar de forma univoca, el sistema lo
reporta como pendiente de enlazado en lugar de asignarlo por aproximacion.

# Trazabilidad {#sec-trazabilidad}

## Matriz de cobertura de requisitos funcionales {#sec-traz-rf}

La matriz responde a dos preguntas que la norma exige: si cada requisito es ejercido por al menos un
caso de uso, y si cada caso de uso proviene de al menos un requisito.

| Requisito | Caso de uso | Reglas de negocio aplicables | Origen |
|---|---|---|---|
| RF-001, RF-002 | CU-01 | - | T2 |
| RF-003, RF-004 | CU-01 | RN-003, RST-002 | T2 |
| RF-005, RF-006 | CU-02 | RN-004 | T2 |
| RF-007, RF-008 | CU-02, CU-03 | RN-005, RN-006, RN-013 | T1, T2 |
| RF-013 | CU-02 | RN-013 | T2 |
| RF-009 | CU-04 | - | T2 |
| RF-010 | CU-04 | RN-013 | T2 |
| RF-011, RF-012 | CU-03 | RN-005 | Diseno |
| RF-020, RF-021 | CU-03 | RN-007, RN-008 | T1 |
| RF-022, RF-023 | CU-03 | RN-001, RN-013 | T1 |
| RF-024 | CU-11 | RN-002, RN-003 | T1 |
| RF-025, RF-026 | CU-14 | RN-015 | T1 |
| RF-027 | CU-15 | RN-005, RN-006 | T1 |
| RF-028 | CU-11 | - | T2 |
| RF-029 | CU-11 | - | T2 |
| RF-030, RF-031, RF-032 | CU-10 | - | T2 |
| RF-033 | CU-03, CU-11 | - | Diseno |
| RF-040, RF-041 | CU-09 | RN-017 | T2 |
| RF-042 | CU-10 | RN-017 | T2 |
| RF-043 | CU-09 | - | T2 |
| RF-044 | CU-11 | RN-012 | T2 |
| RF-050, RF-051 | CU-06, CU-12 | RN-009 | T2 |
| RF-052 | CU-07 | RN-009 | T2 |
| RF-053 | CU-12 | RN-003 | T2 |
| RF-054 | CU-06 | RN-003 | T2 |
| RF-060, RF-061 | CU-04 | RST-001 | T2 |
| RF-062, RF-063, RF-064 | CU-05 | RN-010 | T2 |
| RF-065, RF-066 | CU-06 | RN-010, RN-011 | T2 |
| RF-067 | CU-05 | - | T2 |
| RF-068 | CU-01 | RN-003 | T1, T2 |
| RF-070, RF-071, RF-072 | CU-11 | RN-012, RN-014 | T2 |
| RF-073 | CU-11 | - | T2 |
| RF-074, RF-075 | CU-11 | - | T2 |
| RF-080, RF-081, RF-082 | CU-13 | RN-003, RN-002 | T1, T2 |
| RF-083 | transversal | RN-009 | T2 |
| RF-084, RF-085 | CU-13 | RN-006 | T1, T2 |
| - | no asignados | - | Cuatro propuestas **descartadas** que reservaron identificador y no llegaron a especificarse |

> **Resultado de la matriz.** Las cuatro propuestas descartadas proceden de una descomposicion inicial que
> se desplazaron a una seccion de trazabilidad al detectar que sus tres ideas -verificacion de la correspondencia entre visita y
> lugar asignado, reasignacion de visitas y gestion de asignaciones- pertenecen al proceso de
> programacion del ICA y no al de registro, y a que la reasignacion de una visita **no es un mecanismo
> de recuperacion de datos**: el estado del cultivo y de las trampas cambia entre una visita y otra, de
> modo que los conteos de la visita reasignada no son comparables con los de la original. Se conservan
> como peticion de segunda version.

## Trazabilidad de las reglas de negocio del ICA {#sec-traz-rn}

| Regla | Concepto del Manual | Requisito que la pone en el sistema |
|---|---|---|
| RN-001 | Indice tecnico de moscas trampa dia, seccion 10 | RF-023, RDD-006 |
| RN-002 | Matriz de escenarios de trampeo, Tabla 1 | RF-024, RF-080 |
| RN-004 | Distancia minima de 40 a 60 metros entre trampas | RI-002, RF-006 |
| RN-005 | Nomenclatura: Divipola, ruta ICA, Jackson impar y McPhail par | RDD-004, RF-013 |
| RN-006 | Datum WGS84, grados decimales, cinco decimales | RNF-006, RF-084 |
| RN-007 | Revision de trampas cada 7 a 14 dias, Tabla 6 | RF-022, RF-074 |
| RN-008 | Vida util de atrayentes de 4 a 6 semanas y de 1 a 2 semanas | RF-021 |
| RN-015 | Diagnostico de especie en laboratorio | RF-025, RF-026 |
| - | Campo de georreferentacion de la trampa (WGS84, 5 decimales) | RF-008 |
| - | Relacion de muestras con seis columnas definidas | RF-027 |
| - | Formatos oficiales MF_Cap, MF_Ubi y de servicio en campo | RI-006 |

## Trazabilidad de los requisitos no funcionales {#sec-traz-rnf}

| Requisito | Caracteristica de calidad (ISO/IEC 25010) | Riesgo que mitiga |
|---|---|---|
| RNF-001, RNF-003, RNF-004 | Usabilidad | Rechazo por el tecnico y por el productor |
| RNF-005, RNF-007, RNF-008 | Rendimiento | Abandono de la herramienta en campo |
| RNF-006 | Exactitud funcional | Rechazo del dato por imprecision |
| RNF-009, RNF-010, RNF-011 | Fiabilidad | Perdida de historico, que es el problema original |
| RNF-012 a RNF-015 | Seguridad | Exposicion de datos de personas y del predio |
| RNF-016, RNF-017 | Mantenibilidad | Crecimiento del costo por cada predio nuevo |
| RNF-018, RNF-020 | Portabilidad y mantenibilidad | Crecimiento del cliente movil |
| RNF-019 | Compatibilidad | Fragmentacion de dispositivos en campo |

# Validacion y verificacion {#sec-vv}

## Metodos por tipo de requisito {#sec-vv-metodos}

La norma define cuatro metodos de verificacion: inspeccion, analisis, prueba y demostracion. Cada
requisito de la seccion 4 tiene asignado uno. La siguiente tabla resume el reparto y explica el criterio.

| Metodo | Cuando se usa | Requisitos que lo usan | Ejemplo en este proyecto |
|---|---|---|---|
| **Inspeccion** | Cuando el resultado es un documento o una propiedad observable de un artefacto | RI-005, RI-006, RNF-012, RNF-013, RNF-014, RNF-018 | Revisar que el resumen en PDF contenga MTD, umbral y fecha de efecto |
| **Analisis** | Cuando la correccion depende de un calculo o de una regla | RF-023, RF-024, RF-054, RF-053, RF-075, RF-084 | Verificar que el MTD de un conjunto de lecturas conocido da el valor esperado |
| **Prueba** | Cuando el comportamiento se ejerce sobre el sistema | Todos los RF restantes y la mayoria de los RNF | Registrar una lectura, reiniciar el dispositivo y comprobar que el registro sigue ahi |
| **Demostracion** | Cuando la evidencia de que el requisito se cumple es una operacion observable en el contexto real | RF-005, RF-009, RF-010, RF-033, RF-060 | Realizar una visita completa en modo avion y cerrar la visita |

## Criterios de verificacion de los requisitos mas criticos {#sec-vv-criterios}

| Requisito | Criterio de aceptacion observable |
|---|---|
| RF-060 | Un tecnico completa una visita de al menos ocho trampas en un predio sin cobertura, desde la apertura hasta el cierre, sin que ninguna accion dependa de la red |
| RF-061 | Tras confirmar un registro y forzar el cierre de la aplicacion, el registro persiste |
| RF-064 | El mismo envio repetido tres veces con corte de red en el camino no produce mas de un registro |
| RF-065 | Un registro con fecha de observacion de hace treinta dias, enviado despues de uno de ayer, aparece en la linea de tiempo **antes** que el de ayer |
| RF-054 | El MTD del periodo afectado muestra valor anterior, valor nuevo y fecha del recalculo |
| RF-066 | Un registro solapado queda en estado *revisar* y no altera la serie hasta que el usuario confirme |
| RF-023 | Un conjunto de lecturas de prueba produce un MTD exactamente igual al calculo manual con la formula del Manual |
| RF-012 | Una trampa fuera del lote asignado produce advertencia y exige confirmacion, no un bloqueo |
| RNF-009 | El historico de un lote es identico antes y despues de reiniciar el dispositivo en modo avion |

## Procedimiento de control de cambios {#sec-control-cambios}

Los requisitos no son inmutables; lo que debe ser inmutable es su trazabilidad. Todo cambio sigue este
ciclo:

1. **Solicitud.** Se registra el cambio con su motivacion, quien lo solicita y que requisito o regla
   afecta.
2. **Impacto.** Se evalua el impacto sobre el dominio, sobre la configuracion por predio, sobre los
   datos ya capturados y sobre el trabajo del equipo de desarrollo.
3. **Decision.** Se aprueba, se rechaza o se aplaza. Un rechazo debe_WRITTEN su razon.
4. **Version.** El requisito aprobado cambia de version y se actualiza la matriz de trazabilidad de la
   seccion 6.
5. **Reverificacion.** Se revisa si el metodo de verificacion del requisito sigue siendo suficiente.

> **Regla de oro del control de cambios.** Un requisito que cambia despues de la semana 11, cuando el
> equipo de desarrollo ya empezo, no se modifica: se anota como requisito de la version siguiente.
> La unica excepcion es un error de especificacion que impida construir algo, y en ese caso el cambio
> se hace con una nota que explique por que fue inevitable.

# Priorizacion y definicion del MVP {#sec-prioridades}

## Criterio de priorizacion {#sec-prior-criterio}

La priorizacion no se hizo por lo importante que parece cada funcionalidad, sino por una pregunta
operativa: **que ocurre en el campo si esta funcionalidad no existe?**

La regla que se aplico ordena las cosas de forma distinta a la intuicion:

1. Sin **captura sin conexion** (RF-060 a RF-066) no hay sistema. Es el nucleo.
2. Sin **lectura de trampa y MTD** (RF-020 a RF-027) no hay tramite de exportacion. Es el segundo
   nucleo.
3. Sin **conservacion del pasado** (RF-051, RF-052) no hay historico confiable, que es el problema
   que se quiere resolver. Es el tercer nucleo.
4. Todo lo demas se ordena por el costo de que falte, medido en dinero y en tiempo del ICA.
5. Las funciones de consulta y reporte van **antes** que las funciones de automatizacion, porque una
   funcion de consulta mal hecha cuesta horas y una de automatizacion mal hecha cuesta meses.

## Distribucion de prioridades {#sec-prior-distribucion}

| Prioridad | Cantidad de RF | Proporcion | Que significa en la practica |
|---|---|---|---|
| **Must** | 39 de 58 | 67 % | Sin esto el sistema no cumple su proposito |
| **Should** | 16 de 58 | 28 % | Valor agregado importante, reemplazable por un procedimiento manual |
| **Could** | 3 de 58 | 5 % | Entregable cuando el nucleo este estable |
| **Won't** | 0 de 58 | 0 % | Fuera de alcance en esta version. Ningun requisito especificado como *Won't*: lo que se descarto salio antes de especificarse, y lo que se postergo quedo como *Should* o *Could* |

## Alcance del MVP {#sec-mvp}

El MVP se define por lo que **permite hacer de punta a punta**, no por lo que tiene mas funciones. El
criterio de corte es una frase:

> **Un tecnico puede, en un predio sin cobertura, recorrer sus lotes, registrar la lectura de sus
> trampas con su codigo ICA, cerrar la visita, subirla despues aunque hayan llegado datos
> anteriores, y ver el resumen del lote con el MTD, el umbral y la fecha de efecto.**

Si el sistema no puede hacer eso completo, no es un MVP: es una demo.

| Incluido en el MVP | Funcion |
|---|---|
| Identidad, roles y configuracion del predio | RF-001 a RF-004 |
| Mapa del predio, lotes y reticula | RF-005 a RF-008 |
| Asignacion de lote a trampa | RF-013 |
| Lectura de trampa con codigo ICA y validacion de coherencia | RF-012, RF-013, RF-020 a RF-022 |
| Calculo de MTD, umbral versionado y concepto de aptitud | RF-023, RF-024 |
| Captura sin conexion, cola, idempotencia, alta retroactiva y correccion versionada | RF-060 a RF-066 |
| Marcas temporales y linea de tiempo | RF-050, RF-051, RF-052 |
| Resumen del lote y consulta de historico | RF-070, RF-072 |
| Autorreporte del productor: fumigaciones y cosecha | RF-040, RF-041, RF-042 |
| Parametrizacion del programa de inspeccion y catalogos | RF-080, RF-081 |
| Bitacora y validacion de geometrias | RF-083, RF-084 |

## Lo que queda fuera del MVP y por que {#sec-mvp-fuera}

| Funcionalidad | Motivo de la exclusion |
|---|---|
| Enlace del resultado de laboratorio (RF-026) | Depende de un intercambio con el laboratorio que aun no esta definido (UQQ-006). El estado *pendiente* si se implementa, porque sin el los datos se pierden de vista |
| Relacion de muestras automatica (RF-027) | Se puede seguir usando el formato en papel sin perdida de informacion en el MVP |
| Evidencia fotografica (RF-033) | El Manual no la exige. Se puede sustituir por notas textuales en el MVP |
| Recorrido y marcado geografico detallado (RF-009, RF-010) | El dato de origen del problema es el muestreo, no el recorrido. Se puede registrar a mano sin bloquear el tramite |
| Indicadores de gestion de predios (RF-075) | Se calculan despues; el dato historico ya estara disponible |
| Asignacion y reasignacion de visitas (cuatro propuestas descartadas de programacion de visitas) | Pertenece al proceso de programacion del ICA, no al de registro |
| Resolucion de solapamientos por reglas automaticas (parte de RF-066) | El MVP marca *revisar* y devuelve al usuario; automatizar la decision requiere historia que todavia no existe |
| Notificaciones y alertas (RF-074) | Depende del canal de comunicacion institucional, no definido |

## Roadmap posterior al MVP {#sec-roadmap}

La secuencia posterior no es «anadir mas cosas»: es **cerrar los tres huecos que quedaron abiertos**.

| Incremento | Objetivo | Funcionalidades |
|---|---|---|
| **v0.2 · Cierre del ciclo de laboratorio** | Que el dato de campo llegue completo hasta el diagnostico | RF-026, RF-027, RI-006 |
| **v0.3 · Gestion del productor** | Que el productor deje de usar papel en su tarea diaria | RF-043, RF-044, RF-032 mejorado, comparaciones de rendimiento |
| **v0.4 · Evidencia y georreferencia fina** | Que el registro en campo se apoye con imagen y con recorrido | RF-009, RF-010, RF-033, RF-053 |
| **v0.5 · Consolidation institucional** | Que el dato sirva para el programa y para la auditoria | RF-075, RF-074, RI-009 ampliado, RF-085 |
| **v0.6 · Asignaciones** | Integrar la programacion de visitas | Programacion de visitas (descartada) |

## Dependencias criticas del MVP {#sec-mvp-dependencias}

Cuatro dependencias pueden bloquear el MVP y conviene nombrarlas ahora:

| Dependencia | Que se necesita | Si no llega |
|---|---|---|
| **Umbral de exportacion** (UQQ-004) | La expresion numerica del umbral que habilita o bloquea la exportacion | El sistema calcula el MTD y **no emite concepto**; el vista previa del concept queda vacia, que es preferible a emitir un valor inventado |
| **Asignacion trampa-lote** (RN-013) | Confirmar que las trampas del predio se pueden asignar a lotes y con que criterio | Sin ella no hay MTD por lote. Se resuelve con una estimacion por defecto y se marca como tal |
| **Resolucion de reticula** (UQQ-005) | Tamano de celda en metros | Se adopta el valor por defecto que exige RN-004, mayor a 60 metros |
| **Proveedor de imagen** (UQQ-007) | Un proveedor cuya licencia permita cache en el dispositivo | Se usa imagen ortometrica propia del predio, o un fondo vectorial minimo, y se documenta el impacto |

# Riesgos del levantamiento {#sec-riesgos-levantamiento}

Estos riesgos no son del sistema: son riesgos del **proceso de obtener los requisitos**. Se listan
porque cada uno tiene una consecuencia distinta en el costo del proyecto.

| ID | Riesgo | Prob. | Impacto | Mitigacion prevista |
|---|---|---|---|---|
| RSK-01 | No hubo entrevista con ningun tecnico del ICA | Alta | Alto | La semana 1 del proyecto debe incluir una sesion de validacion con al menos dos tecnicos; el documento se reemitira como version 1.1 con sus correcciones |
| RSK-02 | No se observo una visita real | Alta | Medio | Observar dos visitas antes de cerrar el modelo de dominio; el equipo de arquitectura ya lo programo en su semana de descubrimiento |
| RSK-03 | El concepto de lote no esta en la norma y su definicion operativa no esta confirmada | Alta | Alto | UQQ-001 y UQQ-002; el modelo de datos lo trata como concepto configurable y no asumido |
| RSK-04 | El umbral de exportacion no fue accesible | Media | Alto | El umbral es parametro versionado sin valor por defecto; el sistema bloquea la emision del concepto en lugar de adivinar |
| RSK-05 | La cadencia real de visita del ICA no coincide con ninguna de las dos fuentes | Media | Medio | El sistema no supone cadencias: la visita y la lectura de trampa son series independientes |
| RSK-06 | El volumen real de predios, lotes y trampas es desconocido | Media | Medio | Sin impacto en el modelo; solo afecta el dimensionamiento, que se deja como pregunta abierta |
| RSK-07 | Las propuestas previas asumian QR y fotografia como estandar del ICA | Alta | Bajo | Este documento los degrada a *Should* de valor agregado, lo que evita construir sobre una premise incorrecta |
| RSK-08 | La terminologia del Manual y la del proyecto no coinciden | Media | Medio | Cada terminos relevante tiene una regla de correspondencia explicita y una pregunta abierta asociada |

# Preguntas sin respuesta {#sec-uqq}

Una pregunta sin respuesta no es un defecto de este documento: es un hallazgo. Lo que seria un defecto
es que no estuviera registrada, porque entonces alguien la decidiria mas tarde sin informacion y sin
saber que era una decision.

Cada pregunta tiene un responsable y una fecha limite. La fecha limite es la semana del plan en la que
la respuesta deja de ser bloqueante.

| ID | Pregunta | Responsable | Limite | Bloquea a |
|---|---|---|---|---|
| UQQ-001 | Cual es la definicion operativa de lote que usa el ICA para la exportacion, y coincide con la del productor | Analista de negocio | Semana 2 | Modelo de datos, RN-013 |
| UQQ-002 | Cuantas trampas vigilan cada lote y con que criterio se asigna una trampa a un lote | Analista de negocio | Semana 2 | RF-023, calculo del MTD |
| UQQ-003 | Confirmar la lectura de 7 a 14 dias para predios de exportacion y quien define el rango por seccion | Analista de negocio | Semana 2 | RF-022, RF-074 |
| UQQ-004 | Expresion numerica del umbral de MTD que habilita o bloquea la exportacion, y en que norma se fija | Analista de negocio | Semana 3 | RF-024, concepto de aptitud |
| UQQ-005 | Tamano de celda de la reticula en metros | Arquitecto geospatial | Semana 6 | RF-006, RI-002 |
| UQQ-006 | Como se entrega el resultado de laboratorio y en que formato llega al sistema | Analista de negocio | Semana 4 | RF-025, RF-026 |
| UQQ-007 | Que proveedor de imagen satelital tiene licencia que permita cache en el dispositivo | Arquitecto geospatial | Semana 1 | RF-005, RNF-020 |
| UQQ-008 | Cuantos predios, lotes, trampas y tecnicos activos tiene el ICA | Analista de negocio | Semana 3 | Dimensionamiento |
| UQQ-009 | Que versiones de Android e iOS deben soportarse | Arquitecto movil | Semana 2 | RNF-019 |
| UQQ-010 | Cuanto tiempo debe conservarse un historico de lote | Analista de negocio | Semana 4 | Retencion y respaldo |
| UQQ-011 | Que datos personales se consideran sensibles y quien es el responsable del tratamiento | Seguridad | Semana 3 | RNF-014 |
| UQQ-012 | Cual es el tiempo maximo aceptable entre la captura en campo y la disponibilidad en el historico | Analista de negocio | Semana 5 | Prioridad del envio de evidencia |

> **Nota sobre la fecha limite.** Si una pregunta llega a su fecha limite sin respuesta, no se bloquea
> el proyecto: se aplica el valor por defecto declarado en este documento y se registra la decision como
> un ADR en el documento de arquitectura tecnologica, junto con el costo de haberla tomado sin
> informacion. Un supuesto documentado es recuperable; un supuesto silencioso no.

# Anexos {#sec-anexos-doc}

## Glosario {#glosario-doc}

**APTITUD** - Condicion de un lote para ser habilitado a exportar, determinada por el contraste de sus
indices de monitoreo contra los umbrales vigentes.

**APTO / NO APTO** - Resultado del contraste de un lote contra el umbral en un periodo determinado.

**ATRAYENTE** - Producto natural o sintetico que origina la acumulacion de insectos al ser inducidos a
desplazarse hacia su origen.

**AUTORREPORTE** - Registro ingrado por el productor sobre su propia actividad. No tiene efecto
normativo.

**BPA** - Buenas Practicas Agricolas. Conjunto de criterios agronomicos que se verifican en la visita.

**CELDA DE RETICULA** - Subdivision cuadrangular del predio, de tamano configurable, usada como unidad
de referencia y de registro.

**CICLO DE 52 SEMANAS** - Periodo productivo de un lote de durazno, desde la floracion hasta la
poscosecha, que permite escalonar lotes para tener produccion todo el ano.

**DIAGNOSTICO DE ESPECIE** - Identificacion de la especie de un especimen, realizada en laboratorio, no en
campo.

**DIVIPOLA** - Codificacion de la Division Politica y Administrativa del Departamento Nacional de
Estadistica (DANE), usada como parte de la nomenclatura de trampas.

**INSPECCION OFICIAL** - Registro ingrado por el tecnico del ICA. Es el unico linaje con efecto
normativo.

**LINTA** - Pellcula pegante que retiene los insectos capturados en la trampa Jackson. Se cambia segun
su estado.

**LOTE** - Subdivision del predio con etapa de crecimiento propia dentro del ciclo. Es un concepto del
productor y del proceso de exportacion, no del Manual de Trampeo.

**McPHAIL** - Trampa con retention humeda, cebada con proteina hidrolizada. Se numera con numeros
pares.

**JACKSON** - Trampa con retention seca y pegajosa, cebada con trimedlure, metileugenol o cuelure. Se
numera con numeros impares.

**MTD** - Indice tecnico de moscas trampa dia. Es el total de moscas capturadas dividido por el producto
del numero de trampas atendidas y el numero promedio de dias de exposicion, calculado por especie.

**PREDIO** - Unidad productiva inscrita ante el ICA, sobre la que se realiza la inspeccion.

**RETICULA** - Cuadricula regular superpuesta sobre la imagen del predio.

**RUTA DE TRAMPEO** - Recorrido o conjunto de sitios de monitoreo. Es el termino que usa el Manual donde
el proyecto usa *lote*.

**SIN COBERTURA** - Zona sin senal de datos moviles ni de wifi. Es la condicion normal del predio.

## Trazabilidad de este documento {#sec-anexos-traz}

| Documento | relacion |
|---|---|
| *Manual Tecnico de Trampeo de Moscas de la Fruta* (ICA, 2020) | Fuente normativa primaria. Origen T1 |
| ISO/IEC/IEEE 29148 | Estructura, convenciones y metodos de verificacion de este documento |
| ISO/IEC 25010 | Taxonomia de los requisitos no funcionales |
| Documento de arquitectura tecnologica | Consume este documento y lo traza en la matriz requisito-decision |
| Analisis del problema del proyecto | Origen T2 |