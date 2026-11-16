---
title: "Implementacion de MapLibre con Flutter"
subtitle: "Guia tecnica de integracion del mapa, geolocalizacion y uso sin conexion"
author: "Equipo de Arquitectura de Software"
date: "14 de octubre de 2026"
lang: es-CO
---

# Proposito y alcance del documento {#sec-proposito-maplibre}

Este documento explica **como se integra MapLibre con Flutter** en el sistema de gestion y monitoreo de
cultivos de durazno. Es una guia de implementacion: no justifica la eleccion de la tecnologia (eso esta en
la *Arquitectura tecnologica*) sino que describe, con nombre de paquete, version, configuracion por
plataforma y codigo, como se construye el mapa, como se obtiene la geolocalizacion y como funciona el mapa
sin conexion.

La guia cubre las necesidades del proyecto que dependen del mapa:

| Necesidad | Requisitos | Donde se trata |
|---|---|---|
| Orientar al tecnico en el predio, con lotes, reticula y trampas | RF-005 a RF-007, RI-002, RI-004 | Seccion\nobreakspace\ref{sec-capas} |
| Mostrar la ubicacion del usuario sobre el mapa | RI-001 | Seccion\nobreakspace\ref{sec-geolocalizacion} |
| Marcar un hallazgo en un punto | RF-010 (v0.4) | Seccion\nobreakspace\ref{sec-interaccion} |
| Registrar el recorrido de la visita | RF-009 (v0.4) | Seccion\nobreakspace\ref{sec-casos} |
| Operar el mapa sin conexion en el predio | RF-060, RST-001 | Seccion\nobreakspace\ref{sec-offline} |

> **Version de referencia.** Esta guia se escribio contra el paquete `maplibre_gl` **^0.27.1** y su
> documentacion oficial. Las API pueden evolucionar; antes de actualizar el paquete, revisar la guia de
> migracion del propio proyecto MapLibre Flutter.

# Por que MapLibre (recordatorio de la decision) {#sec-porque-maplibre}

MapLibre GL se eligio por tres razones que condicionan la implementacion y conviene tener presentes al leer
esta guia:

1. **Licencia.** Es la unica opcion que no introduce riesgo contractual al cachear mosaicos en el
   dispositivo, y en este proyecto cachear es obligatorio porque el predio no tiene red.
2. **Poligonos con atributos.** El sistema dibuja el limite de cada lote, la reticula de celdas y las
   trampas, con atributos, y necesita consultarlos sin conexion.
3. **Independencia del proveedor.** Cambiar de proveedor de imagen debe ser cambiar una URL de tiles, no
   reescribir la aplicacion.

**Lo que MapLibre no resuelve.** El motor renderiza; no garantiza que existan mosaicos en el dispositivo.
Si no hay imagen descargada, no hay mapa. Por eso el paquete de campo debe descargarse antes de la visita y
el proveedor de imagen es una dependencia externa (UQQ-007).

# Requisitos de plataforma y versiones minimas {#sec-versiones}

El paquete impone un piso de versiones. Instalar sobre una version inferior produce fallos de compilacion
poco evidentes (por ejemplo, en Android, el lado nativo apunta a Java 21 y un JDK 17 falla con
`invalid source release: 21`).

| Plataforma | Version minima |
|---|---|
| Flutter | 3.29.0 |
| Dart | 3.7.0 |
| Android | API 21 (Android 5.0) |
| iOS | iOS 13 |
| Web | WebGL2 (no aplica a este proyecto) |
| JDK (solo compilacion Android) | 21 |

> **Alcance de plataformas en este proyecto.** El sistema es una aplicacion movil (RST-003); el objetivo son
> **Android e iOS**. Web queda fuera del alcance, aunque el paquete lo soporte, porque no tiene la
> componente de ubicacion ni el modo sin conexion que el problema exige.

# Instalacion y configuracion por plataforma {#sec-instalacion}

## Dependencia del paquete {#sec-instalacion-paquete}

```bash
flutter pub add maplibre_gl
```

En `pubspec.yaml`:

```yaml
dependencies:
  maplibre_gl: ^0.27.1
  permission_handler: ^11.0.0   # solicitar permisos de ubicacion
  geolocator: ^13.0.0           # posicion, precision y marca de tiempo del GPS
  path_provider: ^2.1.0         # rutas para sprites, glifos y base offline
```

> **Por que tres paquetes y no uno.** `maplibre_gl` **no solicita permisos por si mismo**: hay que pedirlos
> con `permission_handler` antes de encender el punto azul. Y `geolocator` se agrega porque la posicion que
> entrega el puck no incluye siempre la marca de tiempo del satelite, que es la defensa contra la deriva del
> reloj del dispositivo (R-T6).

## Android {#sec-instalacion-android}

Permisos de ubicacion en `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
  <!-- Siempre: ubicacion aproximada -->
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <!-- Solo si la app necesita ubicacion precisa (nuestro caso: marcar hallazgos) -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
</manifest>
```

Requisitos de compilacion: `minSdkVersion` 21 o superior y **JDK 21**.

## iOS {#sec-instalacion-ios}

Descripcion de uso en `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Mostrar su ubicacion en el mapa de inspeccion</string>
```

El paquete se distribuye como paquete Swift y como podspec de CocoaPods, asi que funciona con el soporte de
Swift Package Manager de Flutter y con CocoaPods, sin configuracion adicional.

## Permisos en tiempo de ejecucion {#sec-instalacion-permisos}

El permiso se pide **antes** de encender el puck. Si no se concede, la aplicacion debe seguir siendo
utilizable en modo degradado: sin punto azul y con seleccion manual de la trampa.

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureLocationPermission() async {
  final status = await Permission.locationWhenInUse.request();
  return status.isGranted;
}
```

## Arranque {#sec-instalacion-arranque}

Dos llamadas opcionales que mejoran la primera impresion del usuario. Ninguna es obligatoria, pero conviene
decidirlas de forma consciente:

```dart
void main() {
  // Antes de runApp(): la primera pantalla del tecnico es el mapa.
  // Adelanta la inicializacion del motor. Es fire-and-forget, no se espera.
  MapLibreMap.preWarm();

  // Solo si se necesita que contenido Flutter se dibuje ENCIMA del mapa
  // (por ejemplo un panel flotante). Cuesta mas render en Android.
  // MapLibreMap.useHybridComposition = true;

  runApp(const MyApp());
}
```

# El mapa base: widget, controlador y camara {#sec-mapa-base}

## El widget MapLibreMap {#sec-mapa-widget}

```dart
import 'package:maplibre_gl/maplibre_gl.dart';

MapLibreMap(
  styleString: MapLibreStyles.openfreemapLiberty,
  initialCameraPosition: const CameraPosition(
    target: LatLng(5.03, -75.46), // centro del predio (WGS84)
    zoom: 15,
  ),
  onMapCreated: (controller) => _controller = controller,
  onStyleLoadedCallback: _onStyleLoaded, // TODO lo que agregue datos va aqui
)
```

El `MapLibreMapController` se entrega en `onMapCreated`. Todo lo demas (fuentes, capas, anotaciones,
ubicacion manual) se hace con ese controlador.

> **Regla de oro.** Las fuentes y capas **solo** pueden agregarse despues de que el estilo haya cargado, es
> decir desde `onStyleLoadedCallback`, **no** desde `onMapCreated`. Y si en algun momento se cambia el
> estilo con `setStyle()`, MapLibre borra todo lo agregado y `onStyleLoadedCallback` vuelve a dispararse: hay
> que volver a agregarlo alli.

## El estilo {#sec-mapa-estilo}

`styleString` acepta exactamente cuatro formas. Cualquier otra cosa se interpreta como una clave de asset y
deja el mapa en blanco sin lanzar error.

| Donde esta el estilo | Que pasar a `styleString` |
|---|---|
| Un servidor | su URL: `'https://servidor/estilos/ica.json'` |
| Un archivo en disco | su ruta absoluta: `'$cache/style.json'` |
| Un asset de Flutter | su clave de asset: `'assets/estilos/ica.json'` |
| Constructor en Dart | la cadena JSON del estilo |

Constantes incorporadas:

```dart
MapLibreStyles.demo               // tiles de demostracion de MapLibre (solo desarrollo)
MapLibreStyles.openfreemapLiberty // OpenFreeMap Liberty (libre, sin clave)
```

## Controles de camara {#sec-mapa-camara}

| Metodo | Efecto |
|---|---|
| `controller.animateCamera(CameraUpdate, {duration})` | Animacion suave tipo vuelo |
| `controller.moveCamera(CameraUpdate)` | Salto instantaneo, sin animacion |
| `controller.easeCamera(CameraUpdate, {interpolation})` | Interpolacion a lo largo de una trayectoria |
| `controller.queryCameraPosition()` | Lee centro, zoom, orientacion y tilt actuales |

`CameraUpdate` se construye con fabricas: `newLatLng`, `newLatLngZoom`, `newCameraPosition` (posicion +
zoom + orientacion + tilt), `newLatLngBounds`, `zoomIn`, `zoomOut`, `zoomTo`, `zoomBy`, `bearingTo`,
`tiltTo`, `scrollBy`.

**Encajonar el predio (lo habitual al abrir un lote):**

```dart
await controller.animateCamera(
  CameraUpdate.newLatLngBounds(
    LatLngBounds(
      southwest: const LatLng(5.02, -75.47),
      northeast: const LatLng(5.04, -75.45),
    ),
    left: 40, top: 40, right: 40, bottom: 40, // margen en pixeles
  ),
);
```

**Dejar centro visible bajo un panel.** Si un panel inferior tapa parte del mapa, el centro geometrico deja
de ser el centro que ve el usuario. `setPadding` desplaza el encuadre y todas las llamadas posteriores lo
respetan:

```dart
await controller.setPadding(bottom: 240, animated: true); // el panel se abrio
await controller.animateCamera(CameraUpdate.newLatLng(trampa));
await controller.setPadding(animated: true);              // el panel se cerro
```

**Reaccionar al movimiento:** los callbacks `onCameraMove` y `onCameraIdle` estan desactivados por
rendimiento; se habilitan con `trackCameraPosition: true`.

# Capas de datos del predio: lotes, reticula y trampas {#sec-capas}

Esta es la parte central del proyecto. El mapa no se limita a mostrar imagen satelital: dibuja **poligonos
de lote**, **una reticula de celdas**, **puntos de trampa** y sus **etiquetas**, y debe poder decir sobre que
lote o celda se toco.

## El patron fuente + capa {#sec-capas-patron}

Una fuente GeoJSON no dibuja nada por si sola: siempre necesita al menos una capa que la lea.

```dart
// 1. La fuente: contiene los datos
await controller.addGeoJsonSource('lotes', lotesFeatureCollection);

// 2. La capa: define como se dibujan
await controller.addFillLayer(
  'lotes',            // id de la fuente
  'lotes-relleno',    // id de la capa (unico en todo el estilo)
  FillLayerProperties(
    fillColor: '#296CA8',
    fillOpacity: 0.15,
    fillOutlineColor: '#1F3A5F',
  ),
);
```

Varias capas pueden leer la misma fuente (por ejemplo, un relleno y un borde).

## Fuentes: incrustada o remota {#sec-capas-fuentes}

**Datos incrustados en el codigo** (los que vienen de la base local espacial):

```dart
await controller.addGeoJsonSource('trampas', {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'id': 'T-001', // id propio: permite actualizar un feature suelto
      'properties': {'codigo': 'R-05-1-013', 'estado': 'activa'},
      'geometry': {'type': 'Point', 'coordinates': [-75.46, 5.03]}, // [lng, lat]
    },
  ],
});
```

**Traida de una URL** (MapLibre la descarga y cachea):

```dart
await controller.addSource(
  'reticula',
  const GeojsonSourceProperties(data: 'https://servidor/reticula.geojson'),
);
```

> **Atencion al orden de las coordenadas.** En GeoJSON y en MapLibre las coordenadas son `[longitud,
> latitud]`, al reves que en `LatLng(latitud, longitud)` de Dart. Un mapa que sale en el oceano Indico suele
> ser este error.

## Capas segun el elemento {#sec-capas-tipos}

| Elemento del proyecto | Tipo de capa | Propiedades principales |
|---|---|---|
| Limite o relleno del lote | Relleno (`addFillLayer`) | `fillColor`, `fillOpacity`, `fillOutlineColor` |
| Reticula de celdas | Linea (`addLineLayer`) | `lineColor`, `lineWidth`, `lineDasharray` |
| Trampa | Circulo (`addCircleLayer`) | `circleRadius`, `circleColor`, `circleStrokeWidth` |
| Codigo o etiqueta | Simbolo (`addSymbolLayer`) | `textField`, `textSize`, `textFont` |

**Estilo segun los datos (expresiones).** El color o el tamaño pueden depender de una propiedad del
feature, sin tocar Dart:

```dart
await controller.addCircleLayer(
  'trampas',
  'trampas-estado',
  CircleLayerProperties(
    circleColor: [
      'match', ['get', 'estado'],
      'activa', '#2ECC71',
      'vencida', '#E74C3C',
      '#95A5A6', // por defecto
    ],
    circleRadius: 6,
  ),
);
```

**Filtrar una capa.** Dos capas sobre la misma fuente pueden mostrar subconjuntos distintos:

```dart
await controller.addCircleLayer(
  'trampas', 'trampas-activas',
  const CircleLayerProperties(circleColor: '#2ECC71'),
  filter: ['==', ['get', 'estado'], 'activa'],
);
```

## Actualizar los datos {#sec-capas-actualizar}

| Necesidad | Metodo |
|---|---|
| Reemplazar todos los features (filtros, refresco) | `controller.setGeoJsonSource(id, coleccion)` |
| Actualizar un solo feature por su id | `controller.setGeoJsonFeature(id, feature)` |
| Restyling de un feature sin reenviar datos | `controller.setFeatureState(...)` |

> **Rendimiento.** Para una linea de decenas de miles de puntos, MapLibre codifica el GeoJSON en un
> *isolate* de fondo en Android e iOS, de modo que la interfaz no se congela. Aun asi, preferir
> `setGeoJsonSource` (en lote) sobre bucles de llamadas individuales, y `setGeoJsonFeature` cuando solo
> cambia un feature.

## Que lote contiene este punto {#sec-capas-consulta}

Para saber sobre que lote o celda se toco, hay dos caminos:

1. **Consultar la base local espacial** (preferido sin conexion): la geometria vive en tablas con columna
   geometrica y la consulta «dame el lote que contiene este punto» es una consulta de base de datos, no una
   lectura de archivo. Este es el motivo por el que la base local es **espacial**.
2. **Preguntar al mapa** por lo dibujado bajo el dedo: el callback `onFeatureTapped` entrega el id del
   feature y el id de la capa; las propiedades se obtienen con `queryRenderedFeatures()`.

# Interaccion: tocar el mapa y marcar un hallazgo {#sec-interaccion}

```dart
MapLibreMap(
  onMapClick: (point, latLng) {
    // Se toco el mapa: latLng es la coordenada del dedo
  },
  onMapLongClick: (point, latLng) {
    // Pulsacion larga: es el gesto para marcar (evita marcas accidentales)
  },
)
```

**Flujo de RF-010 (marcar un hallazgo).**

1. El tecnico mantiene pulsado el punto del hallazgo.
2. Se recibe `latLng` y se redondea a **5 cifras decimales** (WGS84, grados decimales, requisito del ICA).
3. Se resuelve a que **lote** y **celda** pertenece el punto (seccion\nobreakspace\ref{sec-capas-consulta}).
4. Se dibuja una marca en el mapa (un `addCircle` o un feature en una fuente GeoJSON).
5. Se guarda el hallazgo en la base local con la geometria y las marcas temporales.

> **Recordatorio de alcance.** El marcado geografico de hallazgos (RF-010) esta **fuera del MVP** (X-05) y
> vuelve en v0.4. La integracion se documenta aqui porque es la misma que se usara entonces.

# Geolocalizacion: el GPS y el punto azul {#sec-geolocalizacion}

MapLibre muestra la ubicacion con un puck: un punto, un anillo de precision y, opcionalmente, un indicador
de rumbo. Dos cosas lo gobiernan: una **fuente** de posiciones y un **modo de seguimiento** que decide como
la camara sigue al usuario.

## Habilitar el puck {#sec-geolocalizacion-puck}

```dart
MapLibreMap(
  styleString: MapLibreStyles.openfreemapLiberty,
  initialCameraPosition: const CameraPosition(target: LatLng(5.03, -75.46), zoom: 15),
  myLocationEnabled: true,
  myLocationTrackingMode: MyLocationTrackingMode.tracking,
  onUserLocationUpdated: (UserLocation loc) {
    // loc.position  (LatLng) -> redondear a 5 cifras y guardar si aplica
    // loc.accuracy  (metros)  -> si es alta, el punto no es fiable
  },
)
```

Recuerde pedir el permiso (seccion\nobreakspace\ref{sec-instalacion-permisos}) **antes** de encenderlo.

## Modos de seguimiento {#sec-geolocalizacion-modos}

| Modo | Comportamiento de la camara |
|---|---|
| `none` | La camara no sigue la ubicacion |
| `tracking` | Sigue la posicion |
| `trackingCompass` | Sigue la posicion y gira con la brujula del dispositivo |
| `trackingGps` | Sigue la posicion y gira con la direccion de avance |

En este proyecto el modo util es `tracking` (seguir sin rotar) mientras el tecnico se orienta; `trackingGps`
solo tiene sentido sobre una vista inclinada tipo navegacion.

## Inclinar la camara sin cortar el seguimiento {#sec-geolocalizacion-tilt}

Las llamadas normales de camara (`animateCamera`, `easeCamera`, `moveCamera`) **no conocen el seguimiento**,
y en Android lo cortan. Para inclinar manteniendo el modo:

```dart
await controller.updateMyLocationTrackingMode(MyLocationTrackingMode.trackingGps);
await controller.setTrackingCameraOptions(
  tilt: 45, // grados, de 0 a 60
  duration: const Duration(milliseconds: 250),
);
```

Requiere un modo distinto de `none` ya activo; en otro caso lanza `PlatformException` con codigo
`TRACKING_NOT_ACTIVE`. Solo Android e iOS.

## Afinar el motor de ubicacion {#sec-geolocalizacion-motor}

```dart
MapLibreMap(
  myLocationEnabled: true,
  locationEnginePlatforms: const LocationEnginePlatforms.android(
    enableHighAccuracy: true,
    interval: 1000, // ms
  ),
)
```

En iOS el GPS continuo es costoso para un mapa abierto mucho tiempo; el motor puede funcionar a pulsos:

```dart
locationEnginePlatforms: const LocationEnginePlatforms.iOS(
  intervalMs: 30000,   // un pulso cada 30 s
  pulseWindowMs: 5000, // GPS encendido 5 s por pulso
)
```

## Fuente de ubicacion manual (para pruebas y receptores externos) {#sec-geolocalizacion-manual}

Si la fuente no es el GPS del dispositivo (un receptor externo, una ruta simulada, una posicion que llega
por red), se empuja cada posicion:

```dart
MapLibreMap(
  myLocationEnabled: true,
  locationSource: const ManualLocationSource(),
  myLocationTrackingMode: MyLocationTrackingMode.trackingGps,
)

await controller.updateManualLocation(
  ManualLocationUpdate(
    target: const LatLng(5.031, -75.462),
    bearing: 42,             // direccion de avance
    speed: 4.2,              // m/s
    horizontalAccuracy: 8,   // metros: gobierna el anillo de precision
    altitude: 1600,
    timestamp: DateTime.now(),
  ),
);
```

> **Utilidad para pruebas.** En modo manual el SDK no consulta el dispositivo, asi que **no requiere
> permiso** y el puck es reproducible: se puede empujar una ruta prefijada y el mapa se comporta como si el
> tecnico la caminara. Es la forma de probar el comportamiento de la ubicacion sin salir a campo.

## Coordenadas fiables: GPS frente al reloj del dispositivo {#sec-geolocalizacion-fiabilidad}

El puck sirve para mostrarse, pero la marca de tiempo y la precision que sostienen una lectura deben venir
del motor de posicion, no del reloj del telefono, que puede derivar (R-T6):

```dart
final pos = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
// pos.latitude, pos.longitude  -> redondear a 5 cifras (WGS84)
// pos.accuracy                 -> decidir si el punto es fiable
// pos.timestamp                -> marca de tiempo del satelite
```

> **Limite de precision.** En un cultivo con arboles la precision puede degradarse; el campo `accuracy` es
> la unica forma de saber si un punto marcado es confiable o si conviene registrar por celda de reticula
> (que es, precisamente, la razon por la que X-05 permite el MVP sin puntos precisos).

# Mapa sin conexion {#sec-offline}

Este es el requisito que define la viabilidad del proyecto en campo. MapLibre descarga una region y luego
sirve los mosaicos desde el almacenamiento local **sin escribir una linea de codigo adicional** para leerlos.

> **Alcance.** El modo sin conexion existe **solo en Android e iOS**. No hay API de descarga en web, asi que
> todo el codigo de esta seccion se protege con `if (!kIsWeb)` (irrelevante para este proyecto, que es movil,
> pero conviene por si se reutiliza el codigo).

## Descargar la region del predio {#sec-offline-descargar}

```dart
import 'package:flutter/foundation.dart'; // para kIsWeb

Future<void> downloadPredioRegion() async {
  if (kIsWeb) return;

  final definition = OfflineRegionDefinition(
    bounds: LatLngBounds(
      southwest: const LatLng(5.020, -75.470),
      northeast: const LatLng(5.040, -75.450),
    ),
    minZoom: 13.0,
    maxZoom: 17.0,
    mapStyleUrl: 'https://servidor/estilos/ica.json',
    includeIdeographs: false,
  );

  final region = await downloadOfflineRegion(
    definition,
    metadata: {'predio': 'P-0142', 'nombre': 'La Esperanza'},
    onEvent: (DownloadRegionStatus status) {
      if (status is InProgress) {
        final progress = status.requiredResourceCount > 0
            ? status.completedResourceCount / status.requiredResourceCount
            : 0.0;
        // actualizar barra de progreso
      } else if (status is Success) {
        // guardar region.id para consultar o borrar despues
      } else if (status is Error) {
        // status.cause.message -> reintentar
      }
    },
  );
}
```

**Reglas de una descarga sana:**

- **Limitar la ventana de zoom.** El numero de teselas crece de forma exponencial. Una region guarda
  **6.000 teselas** por defecto (se puede ampliar con `setOfflineTileCountLimit`). Un area de 10 x 10 km
  entre zoom 10 y 16 puede superar ese limite facilmente: conservar `bounds` ajustados y rango de zoom corto.
- **No bajar de zoom 17** de forma indiscriminada: es zoom de calle y multiplica las teselas.
- **Versionar el estilo.** La descarga incluye teselas, fuentes y sprites. Si despues cambia la URL del
  estilo, las regiones ya descargadas pueden no verse bien.

## Consultar y mantener las regiones {#sec-offline-mantener}

```dart
final List<OfflineRegion> regiones = await getListOfRegions();

final status = await getOfflineRegionStatus(regiones.first.id);
// status.completedResourceCount, requiredResourceCount
// status.completedResourceSize (bytes), downloadProgress (0-100), isComplete

await deleteOfflineRegion(regionId);   // liberar espacio
```

Campos de `OfflineRegionStatus`:

| Campo | Significado |
|---|---|
| `completedResourceCount` | Teselas y recursos descargados |
| `requiredResourceCount` | Teselas y recursos necesarios |
| `completedResourceSize` | Bytes descargados |
| `downloadProgress` | Porcentaje, de 0 a 100 |
| `isComplete` | Si la region termino de descargar |

## Verificar antes de cada visita (obligatorio en iOS) {#sec-offline-verificar}

En iOS las teselas descargadas viven en `Library/Caches`, que el sistema puede **borrar** cuando falta
espacio. Una region descargada es una **cache**, no un dato garantizado: antes de confiar en el mapa sin
conexion, comprobar que sigue completa.

```dart
final status = await getOfflineRegionStatus(regionId);
if (!status.isComplete) {
  // advertir al tecnico o permitir el modo degradado (fondo vectorial minimo)
}
```

## Mover regiones entre dispositivos {#sec-offline-mover}

La base offline es un unico archivo SQLite. Se puede copiar y fusionar, de modo que una region descargada
una vez se reutilice en otro dispositivo sin volver a bajarla. Esto es util para preparar varios telefonos
del ICA.

```dart
// Exportar (con no_write_progress pendiente, sin descargas en curso)
final savedPath = await exportOfflineDatabase('${(await getTemporaryDirectory()).path}/offline.db');

// Importar en otro equipo
final List<OfflineRegion> merged = await mergeOfflineRegions(savedPath);
```

> **Solo base completa.** Los SDK no exponen exportacion por region: el archivo contiene **todas** las
> regiones mas la cache ambiental. Copiar el archivo cuando no haya una descarga en curso.

# Anotaciones y marcadores {#sec-anotaciones}

Ademas de las capas, MapLibre ofrece una API de **anotaciones** para objetos individuales e interactivos.

```dart
// Registrar un icono propio (el estilo no trae todos los nombres de icono)
final bytes = await rootBundle.load('assets/markers/trampa.png');
await controller.addImage('trampa-pin', bytes.buffer.asUint8List());

final symbol = await controller.addSymbol(
  const SymbolOptions(
    geometry: LatLng(5.031, -75.462),
    iconImage: 'trampa-pin',
    textField: 'R-05-1-013',
    textAnchor: 'top',
  ),
);

controller.onSymbolTapped.add((Symbol s) {
  // abrir el formulario de la trampa tocada
});
```

## Anotaciones frente a capas: cuando usar cada una {#sec-anotaciones-decision}

| Capacidad | Anotaciones | Capas de estilo |
|---|---|---|
| API | `addSymbol`, `addCircle`, `addLine`, `addFill` | `addGeoJsonSource` + `add*Layer` |
| Maximo practico | decenas (~50) | 100.000+ |
| Estilo segun datos | No | Si (expresiones) |
| Callback de toque | Si (objeto tipado) | Si (id + id de capa) |
| Arrastrable | Si | Con condicion |
| Agrupacion (*clustering*) | No | Si |
| **Uso recomendado** | Pocos pines interactivos | Datasets grandes: lotes, trampas, recorridos |

**Regla practica del proyecto.** Los **lotes**, la **reticula** y el conjunto de **trampas** usan capas de
estilo, porque son muchos y necesitan estilo por atributos. Las **pocas marcas interactivas** de una visita
(por ejemplo, los hallazgos destacados) pueden usar anotaciones. Ambos enfoques conviven sin problema.

## Configuracion de las anotaciones {#sec-anotaciones-config}

- `annotationOrder` decide que tipos de anotacion existen y su orden de apilado (de abajo hacia arriba). Con
  una lista vacia se desactivan por completo y cualquier `addSymbol`/`addCircle` lanza excepcion. Se lee una
  sola vez al crear el mapa.
- `annotationConsumeTapEvents` decide que anotaciones reciben los toques. Un tipo que no este ahi nunca
  dispara `onSymbolTapped` (ni se puede arrastrar).
- `iconImage` debe resolver a una imagen que el mapa tenga (del sprite del estilo o registrada con
  `addImage`). Un nombre desconocido **no dibuja nada y solo registra una advertencia**.

# Interaccion con las capas y consultas {#sec-consultas}

Las capas de estilo tambien reciben toques. El callback entrega el **id del feature** y el **id de la capa**,
no las propiedades:

```dart
controller.onFeatureTapped.add((id, annotation, point, coordinates) {
  // id: id del feature GeoJSON (los features sin id no se pueden distinguir)
  // coordinates: donde se toco
});
```

Para obtener las **propiedades** (por ejemplo, el codigo de la trampa) hay que consultar el propio dato, o
llamar a `queryRenderedFeatures()`. Las capas interactivas se habilitan con `enableInteraction: true` (por
defecto).

# Desempeno y ciclo de vida {#sec-desempeno}

| Tecnica | API | Cuando |
|---|---|---|
| Adelantar el motor | `MapLibreMap.preWarm()` | La primera pantalla es un mapa |
| Pausar un mapa fuera de pantalla | `controller.pauseMap()` / `resumeMap()` | Mapa en una pestana inactiva o detras de una ruta |
| Actualizacion de datos en segundo plano | automatico para GeoJSON grande | Lineas con decenas de miles de puntos |
| Restyling sin reenviar datos | `controller.setFeatureState(...)` | Cambia el color de un feature, no sus datos |
| Incrustacion del mapa en Android | `MapLibreMap.useHybridComposition = true` | Se necesita dibujar Flutter **encima** del mapa |

- `preWarm()` ahorra aproximadamente 170 a 480 ms en Android, 45 a 165 ms en iOS (orden de magnitud;
  perfilar siempre en el dispositivo objetivo). Llamarlo mas de una vez es inofensivo.
- `useHybridComposition = true` hace que el mapa se comporte como un widget normal (Flutter puede pintar
  encima, transformarlo o recortarlo), a costa de mas costo de render en Android. Se fija antes de construir
  el primer mapa.
- En Android los mapas son *platform views*; existe ademas el modo experimental *Hybrid Composition++*
  (Android 14+, Impeller y Vulkan) que se activa desde el manifiesto con
  `io.flutter.embedding.android.EnableHcpp`.

# Casos de uso del proyecto, resueltos {#sec-casos}

## Orientar al tecnico en el predio (RF-005 a RF-007) {#sec-casos-orientar}

1. Al abrir el predio, leer los poligonos de lote y la reticula de la base local espacial.
2. Agregarlos como fuentes GeoJSON y capas de relleno y linea en `onStyleLoadedCallback`.
3. Encajonar el predio con `CameraUpdate.newLatLngBounds`.
4. Encender el puck con `myLocationEnabled: true` y `MyLocationTrackingMode.tracking`.

Todos los datos vienen de la base local, por lo que funciona sin red.

## Marcar un hallazgo (RF-010, v0.4) {#sec-casos-hallazgo}

`onMapLongClick` -> redondear a 5 cifras -> resolver lote y celda -> dibujar la marca -> guardar con sus
marcas temporales. Ver seccion\nobreakspace\ref{sec-interaccion}.

## Registrar el recorrido (RF-009, v0.4) {#sec-casos-recorrido}

1. Suscribirse a `onUserLocationUpdated` o a `Geolocator.getPositionStream`.
2. Acumular puntos `(lat, lng, t)` en memoria y en la base local.
3. Dibujarlos como `LineString`: `controller.addLine(LineOptions(geometry: puntos, ...))` o una fuente
   GeoJSON con capa de linea.
4. Actualizar con `setGeoJsonSource` en lote, no punto por punto.

## Visita completa sin conexion (RF-060) {#sec-casos-offline}

1. **Antes de salir:** descargar la region del predio (seccion\nobreakspace\ref{sec-offline-descargar}) y
   verificar `isComplete`.
2. **En campo:** el mapa sirve las teselas del dispositivo; la captura no depende de la red.
3. **Antes de confiar en el mapa:** verificar de nuevo la region, sobre todo en iOS
   (seccion\nobreakspace\ref{sec-offline-verificar}).

## «Dame el lote que contiene este punto» {#sec-casos-lote}

Se resuelve con la base local espacial (consulta por geometria), no con el mapa. El mapa solo dibuja el
resultado. Cuando se necesita identificar lo tocado, `onFeatureTapped` + `queryRenderedFeatures` dan el id y
la capa.

# Trampas conocidas y como evitarlas {#sec-trampas}

| Sintoma | Causa | Solucion |
|---|---|---|
| El mapa aparece en blanco | `styleString` con un valor que no es URL, ruta absoluta, clave de asset ni JSON | Usar una de las cuatro formas validas |
| Nada de lo que agrego aparece | Se agrego desde `onMapCreated` en vez de `onStyleLoadedCallback` | Mover la carga a `onStyleLoadedCallback` |
| Todo desaparece tras cambiar el estilo | `setStyle()` borra fuentes y capas | Volver a agregarlas en `onStyleLoadedCallback` |
| El icono del simbolo no se ve | `iconImage` no existe en el sprite del estilo | Registrarlo con `addImage` desde `onStyleLoadedCallback` |
| Una capa queda invisible sin error | Expresion mal formada | Revisar los registros nativos; las expresiones fallan en silencio |
| `addSymbol` lanza excepcion | `annotationOrder` vacio desactiva las anotaciones | No vaciar `annotationOrder` |
| El simbolo no recibe toques | El tipo no esta en `annotationConsumeTapEvents` | Incluirlo alli |
| El mapa sale en el oceano Indico | Coordenadas `[lat, lng]` en GeoJSON | GeoJSON es `[lng, lat]`; `LatLng` es `(lat, lng)` |
| Falla la compilacion Android | JDK distinto de 21 | Compilar con JDK 21; `minSdk` 21 o mayor |
| El mapa no funciona sin conexion | No se descargo la region, o la descargo otro estilo | Descargar por predio y verificar `isComplete` |
| Los mosaicos desaparecieron en iOS | El sistema purgo `Library/Caches` | Tratarlos como cache y verificar antes de la visita |

# Pruebas y verificacion {#sec-pruebas}

El mapa tiene una propiedad que facilita su prueba: **la fuente de ubicacion es sustituible**. Con
`ManualLocationSource` se empuja una ruta prefijada y el mapa se comporta como si el tecnico la recorriera,
sin necesidad de salir a campo ni de permisos.

| Que probar | Como |
|---|---|
| El puck sigue la posicion | Modo manual con una ruta simulada; verificar `onUserLocationUpdated` |
| Se resuelve el lote y la celda | Punto de prueba conocido dentro de un poligono de lote |
| El recorrido se dibuja | Empujar varios puntos y verificar la `LineString` |
| El mapa funciona sin conexion | Activar modo avion tras descargar la region; verificar `isComplete` |
| Un predio nuevo no requiere codigo | Cargar solo configuracion y comprobar que el mapa lo dibuja (A-10) |

> **Coherencia con la arquitectura.** Estas pruebas son las que el hito **H2** exige: una visita completa
> debe ejecutarse **sin ninguna llamada de red**. El mapa sin conexion es parte de ese criterio.

# Anexo: resumen de API usadas {#sec-anexo-api}

| API | Para que |
|---|---|
| `MapLibreMap(...)` | Widget del mapa |
| `MapLibreMap.preWarm()` | Adelantar la inicializacion del motor |
| `MapLibreMapController` | Controlador entregado en `onMapCreated` |
| `controller.animateCamera` / `moveCamera` / `easeCamera` | Mover la camara |
| `CameraUpdate.*` | Construir movimientos de camara |
| `controller.setPadding` | Centrar bajo un panel |
| `controller.addGeoJsonSource` / `addSource` | Agregar datos |
| `controller.addFillLayer` / `addLineLayer` / `addCircleLayer` / `addSymbolLayer` | Dibujar datos |
| `controller.setGeoJsonSource` / `setGeoJsonFeature` / `setFeatureState` | Actualizar datos |
| `controller.queryRenderedFeatures` / `onFeatureTapped` | Consultar lo tocado |
| `controller.addSymbol` / `addCircle` / `addLine` / `addFill` | Anotaciones individuales |
| `controller.addImage` | Registrar un icono propio |
| `myLocationEnabled` / `myLocationTrackingMode` | Puck y seguimiento |
| `controller.setTrackingCameraOptions` | Inclinar sin cortar el seguimiento |
| `controller.updateManualLocation` | Empujar una posicion (fuente manual) |
| `locationEnginePlatforms` | Afinar el motor (intervalos, pulsos iOS) |
| `downloadOfflineRegion` / `getOfflineRegionStatus` | Descargar y verificar regiones |
| `getListOfRegions` / `deleteOfflineRegion` | Listar y borrar regiones |
| `exportOfflineDatabase` / `mergeOfflineRegions` | Mover regiones entre dispositivos |
| `controller.pauseMap` / `resumeMap` | Pausar un mapa fuera de pantalla |

\vfill
\begin{center}
\small\itshape
Fin del documento. Esta guia implementa la decision de motor de mapas de la Arquitectura tecnologica y
resuelve las necesidades de RF-005 a RF-007, RF-009, RF-010 y RF-060. Las versiones citadas corresponden al
paquete maplibre\_gl 0.27.1; verificar la guia de migracion antes de actualizar.
\end{center}
