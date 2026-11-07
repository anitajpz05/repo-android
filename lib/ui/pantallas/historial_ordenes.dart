// =============================================================================
// historial_ordenes.dart
// Lista de órdenes (vista "histórico"): por defecto las ya cerradas
// (entregadas o canceladas), con filtro por estado y búsqueda. Complementa
// al Kanban, que solo muestra las abiertas.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/tarjetas_orden.dart';
import 'detalle_orden.dart';

/// Opciones del filtro: etiqueta y estados que incluye (null = todos).
class _Filtro {
  final String etiqueta;
  final List<EstadoOrden>? estados;
  const _Filtro(this.etiqueta, this.estados);
}

class PantallaHistorialOrdenes extends StatefulWidget {
  const PantallaHistorialOrdenes({super.key});

  @override
  State<PantallaHistorialOrdenes> createState() => _PantallaHistorialOrdenesState();
}

class _PantallaHistorialOrdenesState extends State<PantallaHistorialOrdenes> {
  static const _filtros = [
    _Filtro('Cerradas', [EstadoOrden.entregada, EstadoOrden.cancelada]),
    _Filtro('Entregadas', [EstadoOrden.entregada]),
    _Filtro('Canceladas', [EstadoOrden.cancelada]),
    _Filtro('Abiertas', EstadoOrdenX.abiertos),
    _Filtro('Todas', null),
  ];

  final _busqueda = TextEditingController();
  _Filtro _filtro = _filtros.first;
  Stream<List<OrdenResumen>>? _ordenes;

  Stream<List<OrdenResumen>> _stream() => _ordenes ??= TallerScope.of(context)
      .watchOrdenes(estados: _filtro.estados, busqueda: _busqueda.text);

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HISTÓRICO DE ÓRDENES')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() => _ordenes = null),
              decoration: decoracionCampo('Buscar matrícula, cliente o problema',
                  icono: Icons.search),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final f in _filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.etiqueta),
                      selected: identical(f, _filtro),
                      onSelected: (_) => setState(() {
                        _filtro = f;
                        _ordenes = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: VistaStream<List<OrdenResumen>>(
              stream: _stream(),
              builder: (context, lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                      icono: Icons.history, titulo: 'No hay órdenes con este filtro');
                }
                final total = lista.fold<double>(0, (s, o) => s + o.total);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: lista.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                            '${lista.length} orden(es) · ${dinero(total)} en total',
                            style: const TextStyle(color: Paleta.textoSecundario)),
                      );
                    }
                    final o = lista[i - 1];
                    return FilaOrden(
                      key: ValueKey(o.id),
                      orden: o,
                      alTocar: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PantallaDetalleOrden(ordenId: o.id))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
