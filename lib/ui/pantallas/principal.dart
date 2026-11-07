// =============================================================================
// principal.dart
// Pantalla "contenedora" de la app. Guarda qué sección del menú lateral está
// activa y construye esa sección. Cada sección tiene su propio Scaffold
// (AppBar, FAB, pestañas…) y recibe el MenuLateral como `drawer`, así el
// menú es el mismo en todas pero cada sección decide sus acciones.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/taller_scope.dart';
import '../widgets/hojas.dart';
import '../widgets/menu_lateral.dart';
import 'clientes.dart';
import 'inventario.dart';
import 'mecanicos.dart';
import 'ordenes_kanban.dart';
import 'reportes.dart';
import 'tablero.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _seccion = Secciones.tablero;

  /// Cambia de sección. setState hace que build se ejecute de nuevo y se
  /// muestre la sección elegida.
  void _irA(int seccion) => setState(() => _seccion = seccion);

  /// Opción del menú "Cargar datos de ejemplo".
  Future<void> _cargarDemo() async {
    final repo = TallerScope.of(context);
    final ok = await confirmar(
      context,
      titulo: 'Datos de ejemplo',
      mensaje: 'Se crearán 3 clientes, 4 vehículos y 4 órdenes en distintos '
          'estados para probar la app. Solo funciona si aún no hay clientes.',
      textoAccion: 'Cargar',
      peligro: false,
      icono: Icons.playlist_add,
    );
    if (!ok || !mounted) return;
    await ejecutarAccion(context, repo.cargarDatosDemo,
        exito: 'Datos de ejemplo cargados');
  }

  @override
  Widget build(BuildContext context) {
    final menu = MenuLateral(
      seleccionada: _seccion,
      alElegir: _irA,
      alCargarDemo: _cargarDemo,
    );

    // Una ValueKey distinta por sección: Flutter crea un State nuevo al
    // cambiar de sección en vez de reutilizar el de otra pantalla.
    return KeyedSubtree(
      key: ValueKey(_seccion),
      child: switch (_seccion) {
        Secciones.ordenes => PantallaOrdenes(menu: menu),
        Secciones.clientes => PantallaClientes(menu: menu),
        Secciones.inventario => PantallaInventario(menu: menu),
        Secciones.reportes => PantallaReportes(menu: menu),
        Secciones.mecanicos => PantallaMecanicos(menu: menu),
        _ => PantallaTablero(menu: menu, irA: _irA),
      },
    );
  }
}
