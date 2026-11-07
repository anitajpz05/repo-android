// =============================================================================
// mecanicos.dart
// Gestión de mecánicos: listar, añadir, renombrar y activar/desactivar.
// Un mecánico inactivo no aparece al asignar órdenes nuevas, pero conserva su
// historial. Usa watchCargaMecanicos(), que ya incluye a todos los mecánicos
// con su número de órdenes abiertas.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';

class PantallaMecanicos extends StatefulWidget {
  final Widget menu;
  const PantallaMecanicos({super.key, required this.menu});

  @override
  State<PantallaMecanicos> createState() => _PantallaMecanicosState();
}

class _PantallaMecanicosState extends State<PantallaMecanicos> {
  late final repo = TallerScope.of(context);
  late final Stream<List<CargaMecanico>> _mecanicos = repo.watchCargaMecanicos();

  Future<void> _activar(CargaMecanico c, bool activo) async {
    final m = c.mecanico;
    if (!activo && c.abiertas > 0) {
      // Se permite, pero se avisa: sus órdenes abiertas siguen a su nombre.
      final ok = await confirmar(context,
          titulo: 'Desactivar a ${m.nombre}',
          mensaje: 'Tiene ${c.abiertas} orden(es) abiertas, que seguirán '
              'asignadas a él. Puedes reasignarlas desde el detalle de cada orden.',
          textoAccion: 'Desactivar',
          icono: Icons.person_off_outlined);
      if (!ok || !mounted) return;
    }
    await ejecutarAccion(
      context,
      () => repo.guardarMecanico(id: m.id, nombre: m.nombre, activo: activo),
      exito: activo ? '${m.nombre} activado' : '${m.nombre} desactivado',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.menu,
      appBar: AppBar(title: const Text('MECÁNICOS')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarHoja<bool>(context, const HojaMecanico()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NUEVO MECÁNICO'),
      ),
      body: VistaStream<List<CargaMecanico>>(
        stream: _mecanicos,
        builder: (context, lista) {
          if (lista.isEmpty) {
            return const EstadoVacio(
                icono: Icons.engineering_outlined, titulo: 'Sin mecánicos');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              for (final c in lista)
                TarjetaGarage(
                  key: ValueKey(c.mecanico.id),
                  colorAcento: c.mecanico.activo ? Paleta.secundario : Paleta.entregada,
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.mecanico.nombre.toUpperCase(),
                                style: rajdhani(
                                    size: 20,
                                    color: c.mecanico.activo
                                        ? Paleta.texto
                                        : Paleta.textoSecundario)),
                            Text(
                              '${c.mecanico.activo ? 'Activo' : 'Inactivo'} · '
                              '${c.abiertas} orden(es) abiertas',
                              style: const TextStyle(color: Paleta.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Renombrar',
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => mostrarHoja<bool>(
                            context, HojaMecanico(mecanico: c.mecanico)),
                      ),
                      // Switch: activa o desactiva al mecánico.
                      Switch(
                        value: c.mecanico.activo,
                        onChanged: (v) => _activar(c, v),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
