// =============================================================================
// tema.dart
// Identidad visual de la solución B "Pistón Garage": tema OSCURO de estética
// industrial pensado para usarse dentro del taller (poca luz, pantallas con
// grasa, lectura rápida a distancia).
//
// Contiene:
//  - Paleta: todos los colores de la app en un solo lugar (constantes).
//  - colorEstado / iconoEstado: color e icono de cada estado de una orden.
//  - rajdhani(): atajo para el estilo de títulos, números y matrículas.
//  - decoracionCampo(): estilo común de los campos de texto.
//  - temaGarage(): el ThemeData que se pasa a MaterialApp.
// =============================================================================
import 'package:flutter/material.dart';

import '../data/base_datos.dart';

/// Colores de la solución. Se usan como `Paleta.primario`, `Paleta.fondo`...
/// Tenerlos centralizados permite cambiar el aspecto de toda la app aquí.
class Paleta {
  Paleta._(); // no se instancia: solo contiene constantes

  static const Color fondo = Color(0xFF121214);
  static const Color superficie = Color(0xFF1E1E22); // tarjetas, hojas
  static const Color superficieAlta = Color(0xFF26262B); // campos, chips
  static const Color borde = Color(0xFF2C2C33);

  static const Color primario = Color(0xFFFACC15); // amarillo señal
  static const Color sobrePrimario = Color(0xFF18181B); // texto sobre amarillo
  static const Color secundario = Color(0xFF22D3EE); // cian
  static const Color peligro = Color(0xFFF87171);
  static const Color exito = Color(0xFF4ADE80);

  static const Color texto = Color(0xFFF4F4F5);
  static const Color textoSecundario = Color(0xFFA1A1AA);

  // Colores por estado de la orden
  static const Color recibida = Color(0xFFA1A1AA);
  static const Color diagnostico = Color(0xFF22D3EE);
  static const Color reparacion = Color(0xFFFACC15);
  static const Color lista = Color(0xFF4ADE80);
  static const Color entregada = Color(0xFF71717A);
  static const Color cancelada = Color(0xFFF87171);
}

/// Color asociado a cada estado (columnas del Kanban, chips, barra).
Color colorEstado(EstadoOrden estado) => switch (estado) {
      EstadoOrden.recibida => Paleta.recibida,
      EstadoOrden.diagnostico => Paleta.diagnostico,
      EstadoOrden.reparacion => Paleta.reparacion,
      EstadoOrden.lista => Paleta.lista,
      EstadoOrden.entregada => Paleta.entregada,
      EstadoOrden.cancelada => Paleta.cancelada,
    };

/// Icono que acompaña al estado (no depender solo del color: accesibilidad).
IconData iconoEstado(EstadoOrden estado) => switch (estado) {
      EstadoOrden.recibida => Icons.move_to_inbox_outlined,
      EstadoOrden.diagnostico => Icons.search,
      EstadoOrden.reparacion => Icons.build_outlined,
      EstadoOrden.lista => Icons.check_circle_outline,
      EstadoOrden.entregada => Icons.directions_car_outlined,
      EstadoOrden.cancelada => Icons.block,
    };

/// Etiqueta corta en MAYÚSCULAS para encabezados de columna y botones.
String etiquetaCorta(EstadoOrden estado) => switch (estado) {
      EstadoOrden.recibida => 'RECIBIDA',
      EstadoOrden.diagnostico => 'DIAGNÓSTICO',
      EstadoOrden.reparacion => 'REPARACIÓN',
      EstadoOrden.lista => 'LISTA',
      EstadoOrden.entregada => 'ENTREGADA',
      EstadoOrden.cancelada => 'CANCELADA',
    };

/// Estilo con la fuente Rajdhani (títulos, números grandes, matrículas,
/// botones). Por defecto en negrita y con separación entre letras.
TextStyle rajdhani({
  double size = 16,
  FontWeight weight = FontWeight.w700,
  Color color = Paleta.texto,
  double espaciado = 1.2,
  double? altura,
}) =>
    TextStyle(
      fontFamily: 'Rajdhani',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: espaciado,
      height: altura,
    );

/// Decoración común de los TextField/TextFormField: relleno oscuro, borde
/// redondeado y borde amarillo cuando el campo tiene el foco.
/// (Se usa una función en lugar de `inputDecorationTheme` para no depender
/// de cambios de tipo entre versiones de Flutter.)
InputDecoration decoracionCampo(
  String etiqueta, {
  IconData? icono,
  String? ayuda,
  String? sufijo,
  String? pista,
}) {
  OutlineInputBorder borde(Color c, [double ancho = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: ancho),
      );
  return InputDecoration(
    labelText: etiqueta,
    hintText: pista,
    helperText: ayuda,
    suffixText: sufijo,
    prefixIcon: icono == null ? null : Icon(icono),
    filled: true,
    fillColor: Paleta.superficieAlta,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: borde(Paleta.borde),
    enabledBorder: borde(Paleta.borde),
    focusedBorder: borde(Paleta.primario, 2),
    errorBorder: borde(Paleta.peligro),
    focusedErrorBorder: borde(Paleta.peligro, 2),
  );
}

/// ThemeData de la app. Material 3, brillo oscuro y TitilliumWeb como fuente
/// base de todo el texto; los títulos usan Rajdhani.
ThemeData temaGarage() {
  const esquema = ColorScheme.dark(
    primary: Paleta.primario,
    onPrimary: Paleta.sobrePrimario,
    secondary: Paleta.secundario,
    onSecondary: Paleta.sobrePrimario,
    // "contenedor secundario": indicador del menú lateral y chips elegidos
    secondaryContainer: Color(0xFF3A3412),
    onSecondaryContainer: Paleta.primario,
    error: Paleta.peligro,
    onError: Paleta.sobrePrimario,
    surface: Paleta.superficie,
    onSurface: Paleta.texto,
    onSurfaceVariant: Paleta.textoSecundario,
    outline: Paleta.borde,
    outlineVariant: Paleta.borde,
    surfaceTint: Colors.transparent, // sin tinte al hacer scroll (M3)
  );

  // Estilo de los botones: grandes (56 px) y con texto Rajdhani en mayúsculas.
  final estiloTextoBoton = rajdhani(size: 17, espaciado: 1.4);
  const tamMinimo = Size(64, 56);
  final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: esquema,
    fontFamily: 'TitilliumWeb',
    scaffoldBackgroundColor: Paleta.fondo,
    canvasColor: Paleta.fondo,
    dividerColor: Paleta.borde,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.primario,
        foregroundColor: Paleta.sobrePrimario,
        minimumSize: tamMinimo,
        textStyle: estiloTextoBoton,
        shape: forma,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.texto,
        minimumSize: tamMinimo,
        textStyle: estiloTextoBoton,
        side: const BorderSide(color: Paleta.borde, width: 1.5),
        shape: forma,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Paleta.primario,
        textStyle: rajdhani(size: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Paleta.primario,
      foregroundColor: Paleta.sobrePrimario,
      extendedTextStyle: rajdhani(size: 17, espaciado: 1.4),
      shape: forma,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Paleta.superficieAlta,
      contentTextStyle: TextStyle(
          fontFamily: 'TitilliumWeb', color: Paleta.texto, fontSize: 15),
      actionTextColor: Paleta.primario,
    ),
    dividerTheme: const DividerThemeData(color: Paleta.borde, space: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: Paleta.textoSecundario,
      textColor: Paleta.texto,
    ),
  );

  // ThemeData aplica `fontFamily` a TODOS los estilos; por eso Rajdhani se
  // pone DESPUÉS con copyWith. El AppBar de M3 toma su título de titleLarge.
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      titleLarge: rajdhani(size: 22, espaciado: 1.5),
      labelLarge: rajdhani(size: 16),
    ),
  );
}
