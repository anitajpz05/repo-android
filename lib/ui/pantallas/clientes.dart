// =============================================================================
// clientes.dart
// Lista de clientes con búsqueda (nombre, teléfono o matrícula de alguno de
// sus vehículos). Cada fila muestra cuántos vehículos tiene y su saldo
// pendiente en rojo. FAB para crear un cliente; un toque abre su ficha.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import 'detalle_cliente.dart';

class PantallaClientes extends StatefulWidget {
  final Widget menu;
  const PantallaClientes({super.key, required this.menu});

  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  final _busqueda = TextEditingController();
  Stream<List<ClienteResumen>>? _clientes;

  // Se guarda el Stream en el estado y solo se recrea cuando cambia el texto
  // (si se recreara en cada build, la lista parpadearía al escribir).
  Stream<List<ClienteResumen>> _stream() =>
      _clientes ??= TallerScope.of(context).watchClientes(busqueda: _busqueda.text);

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _nuevo() async {
    final id = await mostrarHoja<int>(context, const HojaCliente());
    if (id == null || !mounted) return;
    // Tras crear el cliente se abre su ficha para añadirle vehículos.
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaDetalleCliente(clienteId: id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.menu,
      appBar: AppBar(title: const Text('CLIENTES')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NUEVO CLIENTE'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() => _clientes = null),
              decoration:
                  decoracionCampo('Buscar nombre, teléfono o matrícula',
                      icono: Icons.search),
            ),
          ),
          Expanded(
            child: VistaStream<List<ClienteResumen>>(
              stream: _stream(),
              builder: (context, lista) {
                if (lista.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.people_outline,
                    titulo: _busqueda.text.isEmpty ? 'Sin clientes' : 'Sin resultados',
                    detalle: _busqueda.text.isEmpty
                        ? 'Registra el primero con NUEVO CLIENTE'
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: lista.length,
                  itemBuilder: (context, i) => _FilaCliente(
                    key: ValueKey(lista[i].cliente.id),
                    resumen: lista[i],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  final ClienteResumen resumen;
  const _FilaCliente({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final c = resumen.cliente;
    final debe = resumen.saldoPendiente > 0.009;
    return TarjetaGarage(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      colorAcento: debe ? Paleta.peligro : null,
      alTocar: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PantallaDetalleCliente(clienteId: c.id))),
      child: Row(
        children: [
          // Inicial del cliente en un círculo (ayuda a ubicarlo rápido).
          CircleAvatar(
            radius: 22,
            backgroundColor: Paleta.superficieAlta,
            child: Text(c.nombre.isEmpty ? '?' : c.nombre[0].toUpperCase(),
                style: rajdhani(size: 20, color: Paleta.primario)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  '${c.telefono} · ${resumen.vehiculos} vehículo(s)',
                  style: const TextStyle(color: Paleta.textoSecundario, fontSize: 13),
                ),
              ],
            ),
          ),
          if (debe)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('DEBE', style: rajdhani(size: 11, color: Paleta.peligro)),
                Text(dinero(resumen.saldoPendiente),
                    style: rajdhani(size: 16, color: Paleta.peligro)),
              ],
            )
          else
            const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
