// =============================================================================
// pestanas_orden.dart
// Contenido de las 4 pestañas del detalle de una orden:
//   Trabajos | Repuestos | Pagos | Info
// Cada pestaña es un StatefulWidget que crea SU Stream una sola vez y
// se redibuja sola cuando cambian los datos. Las acciones de añadir están en
// el FAB del detalle; aquí solo están las de eliminar/devolver (con
// confirmación) y, en Info, las de editar datos de la orden.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'basicos.dart';
import 'estado_orden.dart';
import 'hojas.dart';
import 'totales_orden.dart';

/// Espacio inferior para que el FAB no tape el último elemento.
const _paddingLista = EdgeInsets.fromLTRB(16, 12, 16, 96);

/// Pie con un subtotal, alineado a la derecha.
class _Subtotal extends StatelessWidget {
  final String etiqueta;
  final double valor;
  const _Subtotal(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(etiqueta.toUpperCase(),
                  style: rajdhani(size: 14, color: Paleta.textoSecundario,
                      espaciado: 2)),
            ),
            Text(dinero(valor), style: rajdhani(size: 22, color: Paleta.primario)),
          ],
        ),
      );
}

/// Botón de papelera grande (48×48) para eliminar una línea.
Widget _botonQuitar(VoidCallback alPulsar, String tooltip) => IconButton(
      tooltip: tooltip,
      iconSize: 26,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      color: Paleta.peligro,
      icon: const Icon(Icons.delete_outline),
      onPressed: alPulsar,
    );

// =============================================================================
// TRABAJOS
// =============================================================================
class PestanaTrabajos extends StatefulWidget {
  final OrdenResumen orden;
  const PestanaTrabajos({super.key, required this.orden});

  @override
  State<PestanaTrabajos> createState() => _PestanaTrabajosState();
}

class _PestanaTrabajosState extends State<PestanaTrabajos> {
  late final repo = TallerScope.of(context);
  late final Stream<List<Trabajo>> _trabajos = repo.watchTrabajos(widget.orden.id);

  Future<void> _eliminar(Trabajo t) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar trabajo',
        mensaje: '¿Quitar "${t.descripcion}" (${dinero(t.precio)}) de la orden?',
        textoAccion: 'Eliminar',
        icono: Icons.delete_outline);
    if (!ok || !mounted) return;
    await ejecutarAccion(context, () => repo.eliminarTrabajo(t),
        exito: 'Trabajo eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.orden.estado.editable;
    return VistaStream<List<Trabajo>>(
      stream: _trabajos,
      builder: (context, trabajos) {
        if (trabajos.isEmpty) {
          return EstadoVacio(
            icono: Icons.build_outlined,
            titulo: 'Sin trabajos',
            detalle: editable ? 'Pulsa AÑADIR TRABAJO para anotar la mano de obra' : null,
          );
        }
        return ListView(
          padding: _paddingLista,
          children: [
            for (final t in trabajos)
              TarjetaGarage(
                key: ValueKey(t.id),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                child: Row(
                  children: [
                    const Icon(Icons.build_outlined, color: Paleta.secundario),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t.descripcion,
                          style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text(dinero(t.precio), style: rajdhani(size: 17)),
                    // Si la orden ya está cerrada no se muestra el botón.
                    if (editable) _botonQuitar(() => _eliminar(t), 'Eliminar trabajo')
                    else const SizedBox(width: 12),
                  ],
                ),
              ),
            _Subtotal('Mano de obra', widget.orden.manoObra),
          ],
        );
      },
    );
  }
}

// =============================================================================
// REPUESTOS
// =============================================================================
class PestanaRepuestos extends StatefulWidget {
  final OrdenResumen orden;
  const PestanaRepuestos({super.key, required this.orden});

  @override
  State<PestanaRepuestos> createState() => _PestanaRepuestosState();
}

class _PestanaRepuestosState extends State<PestanaRepuestos> {
  late final repo = TallerScope.of(context);
  late final Stream<List<RepuestoUsadoDetalle>> _lineas =
      repo.watchRepuestosDeOrden(widget.orden.id);

  Future<void> _devolver(RepuestoUsadoDetalle l) async {
    final ok = await confirmar(context,
        titulo: 'Quitar repuesto',
        mensaje: '¿Quitar ${l.cantidad} × ${l.nombre}? Las unidades volverán '
            'al inventario.',
        textoAccion: 'Quitar',
        icono: Icons.undo);
    if (!ok || !mounted) return;
    await ejecutarAccion(context, () => repo.devolverRepuesto(l, widget.orden.id),
        exito: '${l.cantidad} × ${l.nombre} devuelto(s) al inventario');
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.orden.estado.editable;
    return VistaStream<List<RepuestoUsadoDetalle>>(
      stream: _lineas,
      builder: (context, lineas) {
        if (lineas.isEmpty) {
          return EstadoVacio(
            icono: Icons.settings_outlined,
            titulo: 'Sin repuestos',
            detalle: editable ? 'Pulsa USAR REPUESTO para sacarlo del inventario' : null,
          );
        }
        return ListView(
          padding: _paddingLista,
          children: [
            for (final l in lineas)
              TarjetaGarage(
                key: ValueKey(l.id),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                child: Row(
                  children: [
                    // Cantidad grande a la izquierda: se lee de un vistazo.
                    SizedBox(
                      width: 44,
                      child: Text('${l.cantidad}×',
                          style: rajdhani(size: 22, color: Paleta.secundario)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.nombre,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${l.codigo} · ${dinero(l.precioUnitario)} c/u',
                              style: const TextStyle(
                                  color: Paleta.textoSecundario, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Text(dinero(l.subtotal), style: rajdhani(size: 17)),
                    if (editable) _botonQuitar(() => _devolver(l), 'Quitar repuesto')
                    else const SizedBox(width: 12),
                  ],
                ),
              ),
            _Subtotal('Repuestos', widget.orden.totalRepuestos),
          ],
        );
      },
    );
  }
}

// =============================================================================
// PAGOS (con el resumen de totales arriba)
// =============================================================================
class PestanaPagos extends StatefulWidget {
  final OrdenResumen orden;
  const PestanaPagos({super.key, required this.orden});

  @override
  State<PestanaPagos> createState() => _PestanaPagosState();
}

class _PestanaPagosState extends State<PestanaPagos> {
  late final repo = TallerScope.of(context);
  late final Stream<List<Pago>> _pagos = repo.watchPagos(widget.orden.id);

  Future<void> _eliminar(Pago p) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar pago',
        mensaje: '¿Eliminar el pago de ${dinero(p.monto)} (${p.metodo}) del '
            '${fechaHora(p.fecha)}? El saldo volverá a aumentar.',
        textoAccion: 'Eliminar',
        icono: Icons.delete_outline);
    if (!ok || !mounted) return;
    await ejecutarAccion(context, () => repo.eliminarPago(p), exito: 'Pago eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.orden;
    final puedeEliminar = o.estado != EstadoOrden.cancelada;
    return VistaStream<List<Pago>>(
      stream: _pagos,
      builder: (context, pagos) => ListView(
        padding: _paddingLista,
        children: [
          TotalesOrden(o),
          TituloSeccion('Pagos recibidos (${pagos.length})'),
          if (pagos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Todavía no hay pagos. Se admiten abonos parciales.',
                  style: TextStyle(color: Paleta.textoSecundario)),
            ),
          for (final p in pagos)
            TarjetaGarage(
              key: ValueKey(p.id),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Row(
                children: [
                  Icon(
                    p.metodo == 'Efectivo'
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined,
                    color: Paleta.exito,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.metodo,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(fechaHora(p.fecha),
                            style: const TextStyle(
                                color: Paleta.textoSecundario, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Text(dinero(p.monto), style: rajdhani(size: 18, color: Paleta.exito)),
                  if (puedeEliminar) _botonQuitar(() => _eliminar(p), 'Eliminar pago')
                  else const SizedBox(width: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// INFO: datos del vehículo, cliente, mecánico, problema, km y fechas
// =============================================================================
class PestanaInfo extends StatelessWidget {
  final OrdenResumen orden;
  final VoidCallback alVerCliente;
  final VoidCallback alVerVehiculo;
  final VoidCallback alCambiarMecanico;
  final VoidCallback alEditarProblema;

  const PestanaInfo({
    super.key,
    required this.orden,
    required this.alVerCliente,
    required this.alVerVehiculo,
    required this.alCambiarMecanico,
    required this.alEditarProblema,
  });

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final editable = o.estado.editable;
    final dias = diasEnTaller(o);

    return ListView(
      padding: _paddingLista,
      children: [
        TituloSeccion('Problema reportado',
            accion: editable
                ? TextButton.icon(
                    onPressed: alEditarProblema,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('EDITAR'))
                : null),
        TarjetaGarage(
          child: Text(o.problema, style: const TextStyle(fontSize: 16)),
        ),
        TituloSeccion('Mecánico asignado'),
        TarjetaGarage(
          alTocar: editable ? alCambiarMecanico : null,
          child: Row(
            children: [
              const Icon(Icons.engineering, color: Paleta.secundario, size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(o.mecanicoNombre.toUpperCase(),
                      style: rajdhani(size: 20))),
              if (editable)
                const Text('CAMBIAR',
                    style: TextStyle(color: Paleta.primario,
                        fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        TituloSeccion('Vehículo'),
        TarjetaGarage(
          alTocar: alVerVehiculo,
          child: Column(
            children: [
              FilaDato('Vehículo', o.vehiculoTexto,
                  icono: Icons.directions_car_outlined),
              FilaDato('Matrícula', o.matricula, icono: Icons.confirmation_number_outlined),
              FilaDato('Km de entrada', '${numero(o.kilometrajeEntrada)} km',
                  icono: Icons.speed),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('VER HISTORIAL →',
                    style: TextStyle(color: Paleta.primario,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        TituloSeccion('Cliente'),
        TarjetaGarage(
          alTocar: alVerCliente,
          child: Column(
            children: [
              FilaDato('Nombre', o.clienteNombre, icono: Icons.person_outline),
              FilaDato('Teléfono', o.clienteTelefono, icono: Icons.phone_outlined),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('VER CLIENTE →',
                    style: TextStyle(color: Paleta.primario,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        TituloSeccion('Fechas'),
        TarjetaGarage(
          child: Column(
            children: [
              FilaDato('Entrada',
                  '${fechaHora(o.fechaEntrada)} (${haceCuanto(o.fechaEntrada)})',
                  icono: Icons.login),
              FilaDato('Entrega',
                  o.fechaEntrega == null ? 'Pendiente' : fechaHora(o.fechaEntrega!),
                  icono: Icons.logout),
              FilaDato('En taller', textoDias(dias).toLowerCase(),
                  icono: Icons.timer_outlined),
              FilaDato('Estado', o.estado.etiqueta, icono: iconoEstado(o.estado)),
            ],
          ),
        ),
      ],
    );
  }
}
