// =============================================================================
// detalle_vehiculo.dart
// Ficha de un vehículo: matrícula, datos, dueño, último kilometraje y el
// HISTORIAL DE SERVICIOS (todas sus órdenes, con el km de cada visita).
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/estado_orden.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import '../widgets/tarjetas_orden.dart';
import 'detalle_cliente.dart';
import 'detalle_orden.dart';
import 'nueva_orden.dart';

class PantallaDetalleVehiculo extends StatefulWidget {
  final int vehiculoId;
  const PantallaDetalleVehiculo({super.key, required this.vehiculoId});

  @override
  State<PantallaDetalleVehiculo> createState() => _PantallaDetalleVehiculoState();
}

class _PantallaDetalleVehiculoState extends State<PantallaDetalleVehiculo> {
  late final repo = TallerScope.of(context);
  late final Stream<Vehiculo?> _vehiculo = repo.watchVehiculo(widget.vehiculoId);
  late final Stream<List<OrdenResumen>> _historial =
      repo.watchOrdenes(vehiculoId: widget.vehiculoId);

  // El dueño se consulta cuando se conoce el clienteId del vehículo. Se
  // guarda para no recrear el Stream en cada build.
  Stream<Cliente?>? _duenio;
  int? _duenioId;

  Stream<Cliente?> _streamDuenio(int clienteId) {
    if (_duenio == null || _duenioId != clienteId) {
      _duenioId = clienteId;
      _duenio = repo.watchCliente(clienteId);
    }
    return _duenio!;
  }

  @override
  Widget build(BuildContext context) {
    return VistaStream<Vehiculo?>(
      stream: _vehiculo,
      builder: (context, v) {
        if (v == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('VEHÍCULO')),
            body: const EstadoVacio(icono: Icons.directions_car_outlined,
                titulo: 'El vehículo no existe'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('VEHÍCULO'),
            actions: [
              IconButton(
                tooltip: 'Editar vehículo',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => mostrarHoja<int>(
                    context, HojaVehiculo(clienteId: v.clienteId, vehiculo: v)),
              ),
            ],
          ),
          body: VistaStream<List<OrdenResumen>>(
            stream: _historial,
            builder: (context, ordenes) {
              final abierta = ordenes.where((o) => o.estado.abierta).firstOrNull;
              final facturado = ordenes
                  .where((o) => o.estado == EstadoOrden.entregada)
                  .fold<double>(0, (s, o) => s + o.total);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ficha(v),
                  const SizedBox(height: 4),
                  if (abierta != null)
                    BotonGrande(
                      texto: 'En taller: orden #${abierta.id} · ${etiquetaCorta(abierta.estado)}',
                      icono: iconoEstado(abierta.estado),
                      contorno: true,
                      color: colorEstado(abierta.estado),
                      alPulsar: () => _abrirOrden(abierta.id),
                    )
                  else
                    BotonGrande(
                      texto: 'Nueva orden para ${v.matricula}',
                      icono: Icons.add,
                      alPulsar: () => abrirNuevaOrden(context, vehiculoId: v.id),
                    ),
                  TituloSeccion('Historial de servicios (${ordenes.length})'),
                  if (ordenes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('Total facturado en entregas: ${dinero(facturado)}',
                          style: const TextStyle(color: Paleta.textoSecundario)),
                    ),
                  if (ordenes.isEmpty)
                    const EstadoVacio(
                        icono: Icons.history, titulo: 'Sin servicios todavía'),
                  for (final o in ordenes)
                    FilaOrden(
                      key: ValueKey(o.id),
                      orden: o,
                      mostrarKm: true,
                      alTocar: () => _abrirOrden(o.id),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _abrirOrden(int id) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantallaDetalleOrden(ordenId: id)));

  Widget _ficha(Vehiculo v) {
    return TarjetaGarage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: PlacaMatricula(v.matricula, tamano: 40)),
          const SizedBox(height: 12),
          Center(
            child: Text('${v.marca} ${v.modelo}'.toUpperCase(),
                style: rajdhani(size: 22)),
          ),
          const SizedBox(height: 8),
          FilaDato('Año', '${v.anio}', icono: Icons.calendar_today_outlined),
          FilaDato('Último km', '${numero(v.kilometraje)} km', icono: Icons.speed),
          // Dueño: segundo Stream, porque el vehículo solo guarda clienteId.
          StreamBuilder<Cliente?>(
            stream: _streamDuenio(v.clienteId),
            builder: (context, snap) {
              final c = snap.data;
              return InkWell(
                onTap: c == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PantallaDetalleCliente(clienteId: c.id))),
                child: FilaDato('Dueño',
                    c == null ? '…' : '${c.nombre} · ${c.telefono}',
                    icono: Icons.person_outline),
              );
            },
          ),
        ],
      ),
    );
  }
}
