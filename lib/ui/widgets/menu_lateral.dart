// =============================================================================
// menu_lateral.dart
// Menú lateral (NavigationDrawer de Material 3) con las secciones de la app.
// La lista `secciones` define el orden; su índice es el que guarda la
// pantalla principal. Al final del menú está "Cargar datos de ejemplo".
// =============================================================================
import 'package:flutter/material.dart';

import '../tema.dart';

/// Datos de una sección del menú.
class Seccion {
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  const Seccion(this.titulo, this.icono, this.iconoActivo);
}

/// Índices de las secciones (evita "números mágicos" al navegar).
class Secciones {
  Secciones._();
  static const int tablero = 0;
  static const int ordenes = 1;
  static const int clientes = 2;
  static const int inventario = 3;
  static const int reportes = 4;
  static const int mecanicos = 5;

  static const List<Seccion> todas = [
    Seccion('Tablero', Icons.speed_outlined, Icons.speed),
    Seccion('Órdenes', Icons.view_column_outlined, Icons.view_column),
    Seccion('Clientes', Icons.people_outline, Icons.people),
    Seccion('Inventario', Icons.inventory_2_outlined, Icons.inventory_2),
    Seccion('Reportes', Icons.bar_chart_outlined, Icons.bar_chart),
    Seccion('Mecánicos', Icons.engineering_outlined, Icons.engineering),
  ];
}

class MenuLateral extends StatelessWidget {
  final int seleccionada;
  final ValueChanged<int> alElegir;
  final VoidCallback alCargarDemo;

  const MenuLateral({
    super.key,
    required this.seleccionada,
    required this.alElegir,
    required this.alCargarDemo,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Paleta.superficie,
      selectedIndex: seleccionada,
      // NavigationDrawer cuenta SOLO los NavigationDrawerDestination para el
      // índice; el encabezado y el botón final no alteran la numeración.
      onDestinationSelected: (i) {
        Navigator.of(context).pop(); // cierra el menú
        alElegir(i);
      },
      children: [
        const _Cabecera(),
        const SizedBox(height: 8),
        for (final s in Secciones.todas)
          NavigationDrawerDestination(
            icon: Icon(s.icono),
            selectedIcon: Icon(s.iconoActivo),
            label: Text(s.titulo.toUpperCase(),
                style: rajdhani(size: 16, espaciado: 1.5, color: Paleta.texto)),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            leading: const Icon(Icons.playlist_add),
            title: const Text('Cargar datos de ejemplo'),
            subtitle: const Text('Clientes, vehículos y órdenes de prueba'),
            onTap: () {
              Navigator.of(context).pop();
              alCargarDemo();
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Encabezado del menú con el "logo" del taller.
class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Paleta.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Paleta.primario,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build, color: Paleta.sobrePrimario, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EL PISTÓN', style: rajdhani(size: 26, espaciado: 3, altura: 1)),
                Text('GARAGE · TALLER',
                    style: rajdhani(size: 13, color: Paleta.primario, espaciado: 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
