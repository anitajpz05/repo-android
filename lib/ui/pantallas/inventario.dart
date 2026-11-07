// =============================================================================
// inventario.dart
// Inventario de repuestos:
//  - Búsqueda por nombre o código y filtro "Solo por agotarse".
//  - Cada repuesto muestra existencias en grande y una barra respecto al
//    stock mínimo (ROJA si existencias <= mínimo).
//  - Tocar = editar. Botón "+" = reabastecer (entrada de mercancía).
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import '../widgets/medidores.dart';

class PantallaInventario extends StatefulWidget {
  final Widget menu;
  const PantallaInventario({super.key, required this.menu});

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  final _busqueda = TextEditingController();
  bool _soloBajos = false;
  Stream<List<Repuesto>>? _repuestos;

  Stream<List<Repuesto>> _stream() => _repuestos ??= TallerScope.of(context)
      .watchRepuestos(busqueda: _busqueda.text, soloBajos: _soloBajos);

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _editar([Repuesto? r]) async {
    final ok = await mostrarHoja<bool>(context, HojaRepuesto(repuesto: r));
    if (ok == true && mounted) {
      mostrarMensaje(context, r == null ? 'Repuesto creado' : 'Repuesto actualizado',
          tipo: TipoMensaje.exito);
    }
  }

  Future<void> _reabastecer(Repuesto r) async {
    final ok = await mostrarHoja<bool>(context, HojaReabastecer(repuesto: r));
    if (ok == true && mounted) {
      mostrarMensaje(context, 'Existencias de ${r.nombre} actualizadas',
          tipo: TipoMensaje.exito);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.menu,
      appBar: AppBar(title: const Text('INVENTARIO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('NUEVO REPUESTO'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() => _repuestos = null),
              decoration: decoracionCampo('Buscar nombre o código',
                  icono: Icons.search),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo por agotarse'),
                  avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                  selected: _soloBajos,
                  onSelected: (v) => setState(() {
                    _soloBajos = v;
                    _repuestos = null;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: VistaStream<List<Repuesto>>(
              stream: _stream(),
              builder: (context, lista) {
                if (lista.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.inventory_2_outlined,
                    titulo: _soloBajos ? 'Nada por agotarse' : 'Sin repuestos',
                  );
                }
                final bajos = lista.where((r) => r.existencias <= r.stockMinimo).length;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: lista.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          '${lista.length} repuesto(s) · $bajos por agotarse',
                          style: TextStyle(
                              color: bajos > 0 ? Paleta.peligro : Paleta.textoSecundario),
                        ),
                      );
                    }
                    final r = lista[i - 1];
                    return _FilaRepuesto(
                      key: ValueKey(r.id),
                      repuesto: r,
                      alEditar: () => _editar(r),
                      alReabastecer: () => _reabastecer(r),
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

class _FilaRepuesto extends StatelessWidget {
  final Repuesto repuesto;
  final VoidCallback alEditar;
  final VoidCallback alReabastecer;

  const _FilaRepuesto({
    super.key,
    required this.repuesto,
    required this.alEditar,
    required this.alReabastecer,
  });

  @override
  Widget build(BuildContext context) {
    final r = repuesto;
    final bajo = r.existencias <= r.stockMinimo;
    final color = bajo ? Paleta.peligro : Paleta.exito;
    // Barra: existencias frente al doble del mínimo (el mínimo queda a la
    // mitad, así se ve de un vistazo cuánto margen hay).
    final referencia = r.stockMinimo <= 0 ? 1 : r.stockMinimo * 2;

    return TarjetaGarage(
      alTocar: alEditar,
      colorAcento: bajo ? Paleta.peligro : null,
      colorBorde: bajo ? Paleta.peligro.withAlpha(90) : Paleta.borde,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nombre,
                        style: const TextStyle(fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
                    Text('${r.codigo} · ${dinero(r.precioVenta)}',
                        style: const TextStyle(color: Paleta.textoSecundario,
                            fontSize: 13)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${r.existencias}', style: rajdhani(size: 28, color: color,
                      altura: 1)),
                  Text(bajo ? 'COMPRAR' : 'EN STOCK',
                      style: rajdhani(size: 10, color: color)),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Reabastecer',
                iconSize: 30,
                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                color: Paleta.primario,
                icon: const Icon(Icons.add_box_outlined),
                onPressed: alReabastecer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BarraCarga(fraccion: r.existencias / referencia, color: color,
                alto: 8),
          ),
          const SizedBox(height: 4),
          Text('Mínimo: ${r.stockMinimo}',
              style: const TextStyle(color: Paleta.textoSecundario, fontSize: 12)),
        ],
      ),
    );
  }
}
