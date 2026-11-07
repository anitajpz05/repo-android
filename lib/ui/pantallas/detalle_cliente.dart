// =============================================================================
// detalle_cliente.dart
// Ficha de un cliente:
//  - Datos de contacto (editar / eliminar desde el AppBar).
//  - Saldo pendiente (órdenes terminadas con dinero por cobrar).
//  - Sus vehículos: crear, editar, eliminar, ver historial y abrir una nueva
//    orden directamente para ese vehículo.
//  - Historial de todas sus órdenes.
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
import 'detalle_orden.dart';
import 'detalle_vehiculo.dart';
import 'nueva_orden.dart';

class PantallaDetalleCliente extends StatefulWidget {
  final int clienteId;
  const PantallaDetalleCliente({super.key, required this.clienteId});

  @override
  State<PantallaDetalleCliente> createState() => _PantallaDetalleClienteState();
}

class _PantallaDetalleClienteState extends State<PantallaDetalleCliente> {
  late final repo = TallerScope.of(context);
  late final Stream<Cliente?> _cliente = repo.watchCliente(widget.clienteId);
  late final Stream<List<Vehiculo>> _vehiculos =
      repo.watchVehiculosDeCliente(widget.clienteId);
  late final Stream<List<OrdenResumen>> _ordenes =
      repo.watchOrdenes(clienteId: widget.clienteId);

  Future<void> _editar(Cliente c) =>
      mostrarHoja<int>(context, HojaCliente(cliente: c));

  Future<void> _eliminar(Cliente c) async {
    final navegador = Navigator.of(context); // se guarda antes del await
    final ok = await confirmar(context,
        titulo: 'Eliminar cliente',
        mensaje: '¿Eliminar a ${c.nombre}? Solo es posible si no tiene vehículos.',
        textoAccion: 'Eliminar',
        icono: Icons.delete_outline);
    if (!ok || !mounted) return;
    final hecho = await ejecutarAccion(context, () => repo.eliminarCliente(c.id),
        exito: 'Cliente eliminado');
    if (hecho) navegador.pop();
  }

  Future<void> _nuevoVehiculo() =>
      mostrarHoja<int>(context, HojaVehiculo(clienteId: widget.clienteId));

  Future<void> _eliminarVehiculo(Vehiculo v) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar vehículo',
        mensaje: '¿Eliminar ${v.matricula} (${v.marca} ${v.modelo})? Solo es '
            'posible si nunca ha tenido órdenes.',
        textoAccion: 'Eliminar',
        icono: Icons.delete_outline);
    if (!ok || !mounted) return;
    await ejecutarAccion(context, () => repo.eliminarVehiculo(v.id),
        exito: 'Vehículo eliminado');
  }

  @override
  Widget build(BuildContext context) {
    return VistaStream<Cliente?>(
      stream: _cliente,
      builder: (context, c) {
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('CLIENTE')),
            body: const EstadoVacio(
                icono: Icons.person_off_outlined, titulo: 'El cliente no existe'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('CLIENTE'),
            actions: [
              IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editar(c)),
              IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _eliminar(c)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _nuevoVehiculo,
            icon: const Icon(Icons.directions_car),
            label: const Text('AÑADIR VEHÍCULO'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _datos(c),
              _resumenYHistorial(),
            ],
          ),
        );
      },
    );
  }

  Widget _datos(Cliente c) {
    return TarjetaGarage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.nombre.toUpperCase(), style: rajdhani(size: 26)),
          const SizedBox(height: 6),
          FilaDato('Teléfono', c.telefono, icono: Icons.phone_outlined),
          FilaDato('Dirección', c.direccion ?? '—', icono: Icons.home_outlined),
          FilaDato('Cliente desde', fecha(c.creadoEn), icono: Icons.event_outlined),
        ],
      ),
    );
  }

  /// Saldo, vehículos e historial. El saldo se calcula con la misma regla del
  /// núcleo: solo órdenes terminadas (lista para entregar o entregada).
  Widget _resumenYHistorial() {
    return VistaStream<List<OrdenResumen>>(
      stream: _ordenes,
      builder: (context, ordenes) {
        final saldo = ordenes
            .where((o) =>
                o.estado == EstadoOrden.lista || o.estado == EstadoOrden.entregada)
            .fold<double>(0, (s, o) => s + (o.saldo > 0 ? o.saldo : 0));
        final abiertas = ordenes.where((o) => o.estado.abierta).length;
        final debe = saldo > 0.009;
        final color = debe ? Paleta.peligro : Paleta.exito;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TarjetaGarage(
              colorAcento: color,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SALDO PENDIENTE',
                            style: rajdhani(size: 13, color: Paleta.textoSecundario,
                                espaciado: 2)),
                        Text(dinero(saldo), style: rajdhani(size: 30, color: color)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${ordenes.length} orden(es)',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('$abiertas abierta(s)',
                          style: const TextStyle(color: Paleta.textoSecundario)),
                    ],
                  ),
                ],
              ),
            ),
            const TituloSeccion('Vehículos'),
            _vehiculosLista(ordenes),
            TituloSeccion('Historial de órdenes (${ordenes.length})'),
            if (ordenes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Este cliente todavía no tiene órdenes.',
                    style: TextStyle(color: Paleta.textoSecundario)),
              ),
            for (final o in ordenes)
              FilaOrden(
                key: ValueKey(o.id),
                orden: o,
                alTocar: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PantallaDetalleOrden(ordenId: o.id))),
              ),
          ],
        );
      },
    );
  }

  /// Vehículos del cliente. Recibe las órdenes para saber si un vehículo ya
  /// tiene una orden abierta (entonces se ofrece "VER ORDEN" en lugar de
  /// "NUEVA ORDEN", porque no puede tener dos abiertas).
  Widget _vehiculosLista(List<OrdenResumen> ordenes) {
    return VistaStream<List<Vehiculo>>(
      stream: _vehiculos,
      builder: (context, vehiculos) {
        if (vehiculos.isEmpty) {
          return const TarjetaGarage(
            child: Text('Sin vehículos. Pulsa AÑADIR VEHÍCULO.',
                style: TextStyle(color: Paleta.textoSecundario)),
          );
        }
        return Column(
          children: [
            for (final v in vehiculos)
              _tarjetaVehiculo(
                v,
                ordenes
                    .where((o) => o.vehiculoId == v.id && o.estado.abierta)
                    .firstOrNull,
              ),
          ],
        );
      },
    );
  }

  Widget _tarjetaVehiculo(Vehiculo v, OrdenResumen? abierta) {
    return TarjetaGarage(
      key: ValueKey(v.id),
      alTocar: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PantallaDetalleVehiculo(vehiculoId: v.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlacaMatricula(v.matricula, tamano: 22),
              const Spacer(),
              IconButton(
                tooltip: 'Editar vehículo',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => mostrarHoja<int>(
                    context, HojaVehiculo(clienteId: v.clienteId, vehiculo: v)),
              ),
              IconButton(
                tooltip: 'Eliminar vehículo',
                icon: const Icon(Icons.delete_outline, color: Paleta.peligro),
                onPressed: () => _eliminarVehiculo(v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${v.marca} ${v.modelo} (${v.anio})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Último kilometraje: ${numero(v.kilometraje)} km',
              style: const TextStyle(color: Paleta.textoSecundario)),
          const SizedBox(height: 10),
          if (abierta != null)
            BotonGrande(
              texto: 'Ver orden #${abierta.id} · ${etiquetaCorta(abierta.estado)}',
              icono: iconoEstado(abierta.estado),
              contorno: true,
              color: colorEstado(abierta.estado),
              alPulsar: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PantallaDetalleOrden(ordenId: abierta.id))),
            )
          else
            BotonGrande(
              texto: 'Nueva orden',
              icono: Icons.add,
              alPulsar: () => abrirNuevaOrden(context, vehiculoId: v.id),
            ),
        ],
      ),
    );
  }
}
