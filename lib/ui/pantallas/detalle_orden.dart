// =============================================================================
// detalle_orden.dart
// Detalle de UNA orden de servicio.
//  - Cabecera: matrícula ENORME, vehículo y cliente, barra segmentada de
//    estados y botones grandes para avanzar / retroceder el estado.
//  - TabBar con 4 pestañas: Trabajos | Repuestos | Pagos | Info.
//  - FAB CONTEXTUAL: cambia según la pestaña (añadir trabajo, usar repuesto,
//    registrar pago) y desaparece si la orden ya no se puede editar.
//  - Menú ⋮: cambiar mecánico, editar problema, retroceder, cancelar.
// Toda la pantalla escucha watchOrden(): cualquier cambio (un pago, un
// repuesto…) actualiza totales y cabecera al instante.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../tema.dart';
import '../widgets/acciones_orden.dart';
import '../widgets/basicos.dart';
import '../widgets/estado_orden.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import '../widgets/hojas_orden.dart';
import '../widgets/pestanas_orden.dart';
import 'detalle_cliente.dart';
import 'detalle_vehiculo.dart';

class PantallaDetalleOrden extends StatefulWidget {
  final int ordenId;
  const PantallaDetalleOrden({super.key, required this.ordenId});

  @override
  State<PantallaDetalleOrden> createState() => _PantallaDetalleOrdenState();
}

/// SingleTickerProviderStateMixin aporta el "reloj" (vsync) que necesita el
/// TabController para animar el indicador de las pestañas.
class _PantallaDetalleOrdenState extends State<PantallaDetalleOrden>
    with SingleTickerProviderStateMixin {
  late final repo = TallerScope.of(context);
  late final Stream<OrdenResumen?> _orden = repo.watchOrden(widget.ordenId);
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    // Al cambiar de pestaña se reconstruye para actualizar el FAB contextual.
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------
  Future<void> _anadirTrabajo(OrdenResumen o) async {
    final ok = await mostrarHoja<bool>(context, HojaTrabajo(ordenId: o.id));
    if (ok == true && mounted) {
      mostrarMensaje(context, 'Trabajo añadido', tipo: TipoMensaje.exito);
    }
  }

  Future<void> _usarRepuesto(OrdenResumen o) async {
    final r = await mostrarHoja<ResultadoUsoRepuesto>(
        context, HojaUsarRepuesto(ordenId: o.id));
    if (r == null || !mounted) return;
    if (r.quedoBajo) {
      avisoStockBajo(context, r); // "Quedan N de X: hay que comprar"
    } else {
      mostrarMensaje(context, '${r.repuesto.nombre} añadido a la orden',
          tipo: TipoMensaje.exito);
    }
  }

  Future<void> _registrarPago(OrdenResumen o) async {
    final ok = await mostrarHoja<bool>(context, HojaPago(orden: o));
    if (ok == true && mounted) {
      mostrarMensaje(context, 'Pago registrado', tipo: TipoMensaje.exito);
    }
  }

  Future<void> _cambiarMecanico(OrdenResumen o) async {
    final ok = await mostrarHoja<bool>(context, HojaCambiarMecanico(orden: o));
    if (ok == true && mounted) {
      mostrarMensaje(context, 'Mecánico reasignado', tipo: TipoMensaje.exito);
    }
  }

  Future<void> _editarProblema(OrdenResumen o) async {
    await mostrarHoja<bool>(
      context,
      HojaTexto(
        titulo: 'Problema reportado',
        etiqueta: 'Descripción del problema',
        inicial: o.problema,
        alGuardar: (t) => repo.actualizarOrden(o.id, problema: t),
      ),
    );
  }

  void _verCliente(OrdenResumen o) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PantallaDetalleCliente(clienteId: o.clienteId)));

  void _verVehiculo(OrdenResumen o) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PantallaDetalleVehiculo(vehiculoId: o.vehiculoId)));

  // ---------------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return VistaStream<OrdenResumen?>(
      stream: _orden,
      builder: (context, o) {
        if (o == null) {
          return Scaffold(
            appBar: AppBar(title: Text('ORDEN #${widget.ordenId}')),
            body: const EstadoVacio(
                icono: Icons.search_off, titulo: 'La orden no existe'),
          );
        }
        return Scaffold(
          // Esta pantalla no tiene campos de texto propios: el teclado solo
          // sale en las hojas. Sin esto, la cabecera fija + TabBar desbordan
          // la columna (bajo la hoja) cuando el teclado reduce el alto.
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text('ORDEN #${o.id}'),
            actions: [_menu(o)],
          ),
          floatingActionButton: _fab(o),
          body: Column(
            children: [
              _Cabecera(orden: o),
              TabBar(
                controller: _tabs,
                labelColor: Paleta.primario,
                unselectedLabelColor: Paleta.textoSecundario,
                indicatorColor: Paleta.primario,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Paleta.borde,
                labelStyle: rajdhani(size: 15),
                unselectedLabelStyle: rajdhani(size: 15, weight: FontWeight.w600),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'TRABAJOS'),
                  Tab(text: 'REPUESTOS'),
                  Tab(text: 'PAGOS'),
                  Tab(text: 'INFO'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    PestanaTrabajos(orden: o),
                    PestanaRepuestos(orden: o),
                    PestanaPagos(orden: o),
                    PestanaInfo(
                      orden: o,
                      alVerCliente: () => _verCliente(o),
                      alVerVehiculo: () => _verVehiculo(o),
                      alCambiarMecanico: () => _cambiarMecanico(o),
                      alEditarProblema: () => _editarProblema(o),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// FAB contextual según la pestaña activa. Devuelve null (sin FAB) si la
  /// acción no tiene sentido: orden cerrada, saldo cero o pestaña Info.
  Widget? _fab(OrdenResumen o) {
    final editable = o.estado.editable;
    final String texto;
    final IconData icono;
    final VoidCallback accion;
    if (_tabs.index == 0 && editable) {
      texto = 'AÑADIR TRABAJO';
      icono = Icons.add;
      accion = () => _anadirTrabajo(o);
    } else if (_tabs.index == 1 && editable) {
      texto = 'USAR REPUESTO';
      icono = Icons.add_shopping_cart;
      accion = () => _usarRepuesto(o);
    } else if (_tabs.index == 2 &&
        o.estado != EstadoOrden.cancelada &&
        o.saldo > 0.009) {
      texto = 'REGISTRAR PAGO';
      icono = Icons.payments_outlined;
      accion = () => _registrarPago(o);
    } else {
      return null; // pestaña Info, orden cerrada o nada que cobrar
    }
    return FloatingActionButton.extended(
      // Una key distinta por pestaña hace que el FAB se anime al cambiar.
      key: ValueKey(_tabs.index),
      onPressed: accion,
      icon: Icon(icono),
      label: Text(texto),
    );
  }

  /// Menú ⋮ del AppBar con las acciones menos frecuentes.
  Widget _menu(OrdenResumen o) {
    final editable = o.estado.editable;
    return PopupMenuButton<String>(
      tooltip: 'Más acciones',
      color: Paleta.superficieAlta,
      onSelected: (v) {
        switch (v) {
          case 'mecanico':
            _cambiarMecanico(o);
          case 'problema':
            _editarProblema(o);
          case 'retroceder':
            retrocederOrden(context, o);
          case 'cancelar':
            cancelarOrden(context, o);
          case 'cliente':
            _verCliente(o);
          case 'vehiculo':
            _verVehiculo(o);
        }
      },
      itemBuilder: (_) => [
        if (editable)
          const PopupMenuItem(
              value: 'mecanico',
              child: ListTile(leading: Icon(Icons.engineering),
                  title: Text('Cambiar mecánico'))),
        if (editable)
          const PopupMenuItem(
              value: 'problema',
              child: ListTile(leading: Icon(Icons.edit_outlined),
                  title: Text('Editar problema'))),
        if (o.estado.anterior != null)
          PopupMenuItem(
              value: 'retroceder',
              child: ListTile(
                  leading: const Icon(Icons.undo),
                  title: Text('Volver a "${o.estado.anterior!.etiqueta}"'))),
        const PopupMenuItem(
            value: 'cliente',
            child: ListTile(leading: Icon(Icons.person_outline),
                title: Text('Ver cliente'))),
        const PopupMenuItem(
            value: 'vehiculo',
            child: ListTile(
                leading: Icon(Icons.directions_car_outlined),
                title: Text('Ver vehículo'))),
        if (o.estado.abierta)
          const PopupMenuItem(
              value: 'cancelar',
              child: ListTile(
                  leading: Icon(Icons.block, color: Paleta.peligro),
                  title: Text('Cancelar orden',
                      style: TextStyle(color: Paleta.peligro)))),
      ],
    );
  }
}

/// Cabecera del detalle: matrícula, vehículo/cliente, barra de estados y
/// botones de cambio de estado.
class _Cabecera extends StatelessWidget {
  final OrdenResumen orden;
  const _Cabecera({required this.orden});

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final siguiente = textoAvanzar(o.estado);
    final puedeVolver = o.estado.anterior != null;

    return Container(
      color: Paleta.superficie,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // FittedBox: si la matrícula es muy larga se reduce en vez de
              // desbordar la fila.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PlacaMatricula(o.matricula, tamano: 38),
                ),
              ),
              const SizedBox(width: 12),
              ChipEstado(o.estado),
            ],
          ),
          const SizedBox(height: 8),
          Text('${o.vehiculoTexto} · ${o.clienteNombre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          BarraEstados(o.estado),
          if (siguiente != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (puedeVolver) ...[
                  // Botón cuadrado de 56×56 para retroceder (corregir error).
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => retrocederOrden(context, o),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Tooltip(
                        message: 'Volver al estado anterior',
                        child: Icon(Icons.undo),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: BotonGrande(
                    texto: '→  $siguiente',
                    icono: iconoEstado(o.estado.siguiente!),
                    color: colorAvanzar(o.estado),
                    alPulsar: () => avanzarOrden(context, o),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
