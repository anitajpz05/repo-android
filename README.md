# El Pistón · Garage 

Aplicación móvil Flutter para el taller automotriz **"El Pistón"**: clientes, vehículos, órdenes de servicio, trabajos, repuestos, inventario, pagos parciales y reportes. Funciona **sin conexión**: los datos se guardan en una base SQLite local (Drift).

 "Pistón Garage"**, pensada para **el mecánico dentro del taller**: tema oscuro de estética industrial, textos y números grandes, botones de 56 px para manos con grasa, y las órdenes organizadas como un **tablero Kanban**, como la pizarra de un taller.

> Asignatura: Programación para Dispositivos Móviles · Actividad "Taller automotriz El Pistón".

## Enfoque de UX/UI

### Idea central
- **Tema oscuro** (`Brightness.dark`): el taller tiene poca luz, el fondo oscuro cansa menos la vista y la pantalla se lee mejor de lejos.
- **La matrícula es el dato estrella**: se dibuja como una chapa real (widget `PlacaMatricula`) en Kanban, listas y detalle.
- **Pensada para manos con grasa o guantes**: botones de mínimo 56 px de alto, áreas táctiles de 48 px, selectores de cantidad −/+ y atajos para teclear lo menos posible.

### Paleta

| Rol | Hex | Uso |
|---|---|---|
| Fondo | `#121214` | Fondo de todas las pantallas |
| Superficie | `#1E1E22` | Tarjetas, hojas inferiores, menú, AppBar |
| Borde | `#2C2C33` | Bordes, divisores, segmentos apagados |
| Primario (amarillo señal) | `#FACC15` | Botones, FAB, foco de campos, números destacados |
| Texto sobre primario | `#18181B` | Texto sobre amarillo y colores vivos |
| Secundario (cian) | `#22D3EE` | Mecánico asignado, acciones secundarias |
| Peligro | `#F87171` | Deudas, stock bajo, errores, cancelar |
| Éxito | `#4ADE80` | Pagado, en stock, botón ENTREGAR |
| Texto | `#F4F4F5` | Texto principal y fondo de la chapa |
| Texto secundario | `#A1A1AA` | Subtítulos y datos auxiliares |

Colores por estado de la orden (siempre acompañados de icono y texto):

| Estado | Hex |
|---|---|
| Recibida | `#A1A1AA` |
| En diagnóstico | `#22D3EE` |
| En reparación | `#FACC15` |
| Lista para entregar | `#4ADE80` |
| Entregada | `#71717A` |
| Cancelada | `#F87171` |

### Tipografía (incluida en `assets/fonts`, no se descarga)
- **Rajdhani** (500/600/700): títulos del AppBar, números grandes, matrículas, encabezados de columna y botones, en MAYÚSCULAS con separación entre letras. Aspecto técnico e industrial, muy legible de lejos.
- **TitilliumWeb** (400/600/700): fuente base del tema (`fontFamily` del `ThemeData`) para todo el texto corrido.

### Navegación
- **Menú lateral** (`NavigationDrawer` de Material 3) + `AppBar`. Secciones: **Tablero, Órdenes, Clientes, Inventario, Reportes, Mecánicos** y, al final, **Cargar datos de ejemplo**.
- Las fichas (orden, cliente, vehículo) se abren encima con `Navigator.push`. La **nueva orden** se abre a pantalla completa como `fullscreenDialog` y al guardarla se reemplaza por el detalle de la orden creada.
- **Formularios en hojas inferiores** (`showModalBottomSheet` con `isScrollControlled` y padding del teclado) en lugar de diálogos: quedan al alcance del pulgar y el teclado no tapa los campos.

### Flujo principal
1. **Tablero**: medidores grandes (abiertas, en reparación, listas, por cobrar), alertas de stock en rojo y carga por mecánico con barras. Tocar un medidor lleva a su sección.
2. **Órdenes (Kanban)**: columnas Recibida / Diagnóstico / Reparación / Lista que se recorren deslizando (cada columna ocupa ~86 % del ancho y asoma la siguiente). Arriba, el selector de columnas con el conteo por estado y los chips **"Mis órdenes"** por mecánico; búsqueda en el AppBar y botón **Histórico** (entregadas/canceladas). Cada tarjeta muestra matrícula grande, vehículo, mecánico y **días en taller**, y un botón grande **"→ siguiente estado"**.
3. **Nueva orden**: buscar el vehículo por matrícula; si no existe, **"Registrar cliente y vehículo"** abre una hoja inferior sin salir del flujo. Se elige el mecánico con **tarjetas que muestran su carga actual** (marca "MENOR CARGA") y se escribe el problema y el kilometraje (precargado).
4. **Detalle de orden**: cabecera con matrícula enorme y **barra segmentada de estados**; botones de avanzar/retroceder; pestañas **Trabajos | Repuestos | Pagos | Info**. El **botón flotante cambia según la pestaña** (añadir trabajo / usar repuesto / registrar pago) y desaparece si la orden ya está cerrada.
5. **Reportes** en pestañas: **Carga | Deudores | Stock | Facturación** (Hoy / Esta semana / Este mes / Personalizado).

### Accesibilidad y decisiones de interfaz
- Cada estado tiene **color + icono + texto**: no depende solo de percibir colores.
- Alto contraste: texto `#F4F4F5` sobre `#121214`; el amarillo `#FACC15` siempre lleva texto oscuro `#18181B`.
- Confirmación antes de **cancelar** órdenes, **eliminar** trabajos/pagos y **quitar** repuestos; al **entregar** se avisa si queda saldo.
- Al usar un repuesto que queda en su mínimo aparece un aviso rojo: **"Quedan N de X: hay que comprar"**.
- Los errores de reglas de negocio se muestran en la propia hoja (recuadro rojo) o en un SnackBar rojo; los éxitos en verde.
- Listas vacías con icono y explicación; todo se actualiza solo gracias a los `Stream` de Drift.
- Atajos para teclear menos: chips de trabajos frecuentes, botón **"Saldo completo"** al cobrar, cantidades −/+, atajos 5/10/20 al reabastecer.

## Estructura de carpetas

```
lib/
├── main.dart                 # arranque: BD, repositorio, TallerScope y MaterialApp
├── data/                     # núcleo común (Drift, reglas de negocio) — igual en las 3 soluciones
├── utils/formato.dart        # dinero, fechas y números sin paquetes externos
└── ui/
    ├── tema.dart             # Paleta, colorEstado/iconoEstado, rajdhani(), ThemeData oscuro
    ├── widgets/
    │   ├── basicos.dart          # TarjetaGarage, VistaStream, EstadoVacio, BotonGrande…
    │   ├── hojas.dart            # mostrarHoja, CuerpoHoja, AccionHojaMixin, confirmar, SnackBars
    │   ├── estado_orden.dart     # PlacaMatricula, ChipEstado, BarraEstados, diasEnTaller
    │   ├── medidores.dart        # TarjetaMedidor (tablero) y BarraCarga (FractionallySizedBox)
    │   ├── acciones_orden.dart   # avanzar / retroceder / cancelar (con confirmación)
    │   ├── tarjetas_orden.dart   # TarjetaKanban y FilaOrden
    │   ├── totales_orden.dart    # mano de obra, repuestos, total, pagado, saldo
    │   ├── selector_mecanico.dart# tarjetas de mecánico con su carga
    │   ├── menu_lateral.dart     # NavigationDrawer y secciones
    │   ├── formularios.dart      # hojas: cliente, vehículo, cliente+vehículo, repuesto, mecánico…
    │   ├── hojas_orden.dart      # hojas: trabajo, usar repuesto, pago, cambiar mecánico
    │   └── pestanas_orden.dart   # pestañas Trabajos | Repuestos | Pagos | Info
    └── pantallas/
        ├── principal.dart        # sección activa del menú
        ├── tablero.dart
        ├── ordenes_kanban.dart   # pantalla estrella
        ├── historial_ordenes.dart
        ├── detalle_orden.dart
        ├── nueva_orden.dart
        ├── clientes.dart
        ├── detalle_cliente.dart
        ├── detalle_vehiculo.dart
        ├── inventario.dart
        ├── reportes.dart
        └── mecanicos.dart
test/reglas_negocio_test.dart # pruebas de las reglas de negocio (BD en memoria)
assets/fonts/                 # Rajdhani y TitilliumWeb (licencia OFL)
capturas/                     # capturas de la app en uso
```

## Capturas

Las capturas de la aplicación en uso están en la carpeta [`capturas/`](capturas/). Para generarlas: menú lateral → **Cargar datos de ejemplo**, recorrer cada pantalla y capturar desde el emulador (ver `capturas/LEEME.md`).

## Cómo ejecutar el proyecto

1. Abrir la carpeta del proyecto en **Android Studio** (con los plugins *Flutter* y *Dart* instalados): `File > Open` y elegir la carpeta que contiene `pubspec.yaml`.
2. Descargar dependencias: `flutter pub get` (o el botón *Pub get* que aparece arriba del `pubspec.yaml`).
3. **Generar el código de Drift** (obligatorio la primera vez y cada vez que se cambie `tablas.dart` o `base_datos.dart`):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   Esto crea `lib/data/base_datos.g.dart` (clases `Cliente`, `ClientesCompanion`, `$ClientesTable`, etc.).
4. Elegir un emulador o teléfono Android y pulsar **Run** (`flutter run`).
5. Pruebas de reglas de negocio: `flutter test`.

> Si Android Studio no reconoce la carpeta `android/` (versión de Flutter muy distinta), ejecute `flutter create --platforms=android .` dentro del proyecto: regenera solo los archivos de plataforma que falten y no toca `lib/`.

Primer uso: en el menú de la app está **Cargar datos de ejemplo**, que crea 3 clientes, 4 vehículos y 4 órdenes en distintos estados para probar todas las pantallas.

## Decisiones de diseño comunes (modelo de datos y reglas)

**Tecnología.** Flutter + Dart, persistencia con **Drift** sobre SQLite (paquete `drift_flutter`). La base de datos es un archivo local (`el_piston.sqlite`), así que la app funciona **sin internet** y conserva todo aunque se cierre. No se usa ningún servicio en la nube. Las fuentes tipográficas están incluidas en `assets/fonts` (no se descargan), por la misma razón.

**Arquitectura en capas.**
- `lib/data/tablas.dart`: esquema (8 tablas).
- `lib/data/base_datos.dart`: clase `AppDatabase` (Drift), migración y datos iniciales.
- `lib/data/repositorio_taller.dart`: todas las consultas y **reglas de negocio**. La interfaz nunca escribe SQL.
- `lib/data/modelos.dart`: clases de vista (`OrdenResumen`, `Deudor`, `CargaMecanico`…) y la excepción `ReglaNegocioException`.
- `lib/data/taller_scope.dart`: `InheritedWidget` que entrega el repositorio a todas las pantallas.
- `lib/ui/...`: pantallas y widgets (lo que cambia entre las tres soluciones).

**Reactividad.** Las consultas `watch...()` devuelven `Stream`. Las pantallas usan `StreamBuilder`; al guardar un pago, por ejemplo, el total, el saldo, la lista de deudores y el tablero se actualizan solos sin recargar manualmente.

**Modelo de datos.**

| Tabla | Campos principales | Relación |
|---|---|---|
| clientes | nombre, teléfono, dirección (opcional) | 1 cliente → N vehículos |
| vehiculos | matrícula (única), marca, modelo, año, kilometraje | 1 vehículo → N órdenes |
| mecanicos | nombre, activo | 1 mecánico → N órdenes |
| ordenes | vehículo, mecánico, fecha de entrada, problema, estado, km de entrada, fecha de entrega | |
| trabajos | orden, descripción, precio de mano de obra | 1 orden → N trabajos |
| repuestos | código (único), nombre, precio de venta, existencias, stock mínimo | |
| orden_repuestos | orden, repuesto, cantidad, precio unitario del momento | N:M órdenes–repuestos |
| pagos | orden, monto, fecha, método | 1 orden → N pagos |

**Decisiones tomadas donde el enunciado deja puntos abiertos.**
1. *Estados*: recibida → en diagnóstico → en reparación → lista para entregar → entregada; desde cualquier estado abierto se puede **cancelar**. Se permite retroceder un paso para corregir errores. Al pasar a *entregada* se guarda la fecha de entrega.
2. Las órdenes **entregadas o canceladas no se pueden editar** (trabajos, repuestos, mecánico).
3. Un vehículo **no puede tener dos órdenes abiertas** a la vez.
4. Al crear la orden se registra el **kilometraje de entrada** y se actualiza el "último kilometraje" del vehículo.
5. Al usar un repuesto se valida que haya existencias y se **descuentan en una transacción**. Si se quita de la orden, las unidades vuelven al inventario. Se guarda el **precio del momento** para que el historial no cambie si luego sube el precio.
6. *Stock bajo*: cada repuesto tiene su **stock mínimo** configurable. Si `existencias <= mínimo` aparece en la alerta del inicio y en el reporte; además, al usar un repuesto que cae a ese nivel se muestra un aviso inmediato.
7. *Cancelar*: devuelve los repuestos al inventario. No se permite cancelar una orden con pagos (habría que devolver dinero); primero se eliminan los pagos.
8. *Pagos*: se admiten **pagos parciales** (abonos) en cualquier estado no cancelado; no se puede pagar más que el saldo. Total = mano de obra + repuestos; saldo = total − pagado.
9. *Deuda del cliente*: se cuenta el saldo de las órdenes **terminadas** (lista para entregar o entregada); en las órdenes en proceso el total todavía puede cambiar. Se puede entregar el carro con saldo pendiente (el cliente paga en dos partes).
10. *Facturación de un período*: suma de los totales de las órdenes **entregadas** en el período (desglosado en mano de obra y repuestos), y aparte lo **cobrado** (pagos recibidos) en ese período.
11. Matrículas y códigos de repuesto se guardan en mayúsculas y son únicos. No se borra un cliente con vehículos ni un vehículo con historial.
12. Moneda: CUP. Dos mecánicos precargados (editables) y cinco repuestos de ejemplo.
