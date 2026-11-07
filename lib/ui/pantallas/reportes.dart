// =============================================================================
// reportes.dart
// Reportes del dueño en 4 pestañas (TabBar en el AppBar):
//   CARGA        trabajo asignado a cada mecánico
//   DEUDORES     clientes con saldo pendiente (con teléfono para llamar)
//   STOCK        repuestos por agotarse y cuánto comprar
//   FACTURACIÓN  facturado y cobrado en un período (Hoy / Semana / Mes /
//                Personalizado con showDateRangePicker)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import '../widgets/medidores.dart';
import '../widgets/tarjetas_orden.dart';
import 'detalle_cliente.dart';
import 'detalle_orden.dart';

class PantallaReportes extends StatelessWidget {
  final Widget menu;
  const PantallaReportes({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController crea y comparte el TabController entre el TabBar y
    // el TabBarView sin tener que declararlo en un State.
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        drawer: menu,
        appBar: AppBar(
          title: const Text('REPORTES'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Paleta.primario,
            unselectedLabelColor: Paleta.textoSecundario,
            indicatorColor: Paleta.primario,
            indicatorWeight: 3,
            dividerColor: Paleta.borde,
            labelStyle: rajdhani(size: 15),
            tabs: const [
              Tab(icon: Icon(Icons.engineering_outlined), text: 'CARGA'),
              Tab(icon: Icon(Icons.person_search_outlined), text: 'DEUDORES'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'STOCK'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'FACTURACIÓN'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TabCarga(),
            _TabDeudores(),
            _TabStock(),
            _TabFacturacion(),
          ],
        ),
      ),
    );
  }
}

const _padding = EdgeInsets.fromLTRB(16, 12, 16, 24);

// =============================================================================
// CARGA POR MECÁNICO
// =============================================================================
class _TabCarga extends StatefulWidget {
  const _TabCarga();
  @override
  State<_TabCarga> createState() => _TabCargaState();
}

class _TabCargaState extends State<_TabCarga> {
  late final Stream<List<CargaMecanico>> _carga =
      TallerScope.of(context).watchCargaMecanicos();

  @override
  Widget build(BuildContext context) {
    return VistaStream<List<CargaMecanico>>(
      stream: _carga,
      builder: (context, cargas) {
        if (cargas.isEmpty) {
          return const EstadoVacio(icono: Icons.engineering_outlined,
              titulo: 'Sin mecánicos');
        }
        final maximo = cargas.fold<int>(1, (m, c) => c.abiertas > m ? c.abiertas : m);
        final total = cargas.fold<int>(0, (s, c) => s + c.abiertas);
        return ListView(
          padding: _padding,
          children: [
            Text('$total orden(es) abiertas en el taller',
                style: const TextStyle(color: Paleta.textoSecundario)),
            const SizedBox(height: 8),
            for (final c in cargas)
              TarjetaGarage(
                key: ValueKey(c.mecanico.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.mecanico.nombre.toUpperCase(),
                              style: rajdhani(
                                  size: 20,
                                  color: c.mecanico.activo
                                      ? Paleta.texto
                                      : Paleta.textoSecundario)),
                        ),
                        if (!c.mecanico.activo)
                          Text('INACTIVO',
                              style: rajdhani(size: 12, color: Paleta.textoSecundario)),
                        const SizedBox(width: 8),
                        Text('${c.abiertas}',
                            style: rajdhani(size: 32, color: Paleta.primario,
                                altura: 1)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BarraCarga(fraccion: c.abiertas / maximo),
                    const SizedBox(height: 12),
                    // Desglose por estado con mini barras de color.
                    _desglose('Recibidas / diagnóstico', c.enDiagnostico, c.abiertas,
                        Paleta.diagnostico),
                    _desglose('En reparación', c.enReparacion, c.abiertas,
                        Paleta.reparacion),
                    _desglose('Listas para entregar', c.listas, c.abiertas,
                        Paleta.lista),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _desglose(String etiqueta, int n, int total, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(etiqueta,
                  style: const TextStyle(color: Paleta.textoSecundario, fontSize: 13)),
            ),
            Expanded(
              child: BarraCarga(
                  fraccion: total == 0 ? 0.0 : n / total, color: color, alto: 8),
            ),
            SizedBox(
              width: 32,
              child: Text('$n', textAlign: TextAlign.right, style: rajdhani(size: 16)),
            ),
          ],
        ),
      );
}

// =============================================================================
// DEUDORES
// =============================================================================
class _TabDeudores extends StatefulWidget {
  const _TabDeudores();
  @override
  State<_TabDeudores> createState() => _TabDeudoresState();
}

class _TabDeudoresState extends State<_TabDeudores> {
  late final Stream<List<Deudor>> _deudores = TallerScope.of(context).watchDeudores();

  Future<void> _copiar(Deudor d) async {
    // Clipboard (flutter/services): copia el teléfono para pegarlo al llamar
    // o escribir por mensajería.
    await Clipboard.setData(ClipboardData(text: d.telefono));
    if (!mounted) return;
    mostrarMensaje(context, 'Teléfono de ${d.nombre} copiado');
  }

  @override
  Widget build(BuildContext context) {
    return VistaStream<List<Deudor>>(
      stream: _deudores,
      builder: (context, deudores) {
        if (deudores.isEmpty) {
          return const EstadoVacio(
              icono: Icons.verified_outlined,
              titulo: 'Nadie debe',
              detalle: 'Todas las órdenes terminadas están pagadas.');
        }
        final total = deudores.fold<double>(0, (s, d) => s + d.saldo);
        return ListView(
          padding: _padding,
          children: [
            TarjetaGarage(
              colorAcento: Paleta.peligro,
              child: Row(
                children: [
                  Expanded(
                    child: Text('TOTAL POR COBRAR',
                        style: rajdhani(size: 14, color: Paleta.textoSecundario,
                            espaciado: 2)),
                  ),
                  Text(dinero(total), style: rajdhani(size: 26, color: Paleta.peligro)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                  'Saldo de órdenes terminadas (lista para entregar o entregada).',
                  style: TextStyle(color: Paleta.textoSecundario, fontSize: 12.5)),
            ),
            for (final d in deudores)
              TarjetaGarage(
                key: ValueKey(d.clienteId),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                alTocar: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PantallaDetalleCliente(clienteId: d.clienteId))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.nombre,
                              style: const TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text('${d.telefono} · ${d.ordenesConSaldo} orden(es) con saldo',
                              style: const TextStyle(
                                  color: Paleta.textoSecundario, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(dinero(d.saldo), style: rajdhani(size: 17,
                        color: Paleta.peligro)),
                    IconButton(
                      tooltip: 'Copiar teléfono',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copiar(d),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// STOCK (repuestos por agotarse)
// =============================================================================
class _TabStock extends StatefulWidget {
  const _TabStock();
  @override
  State<_TabStock> createState() => _TabStockState();
}

class _TabStockState extends State<_TabStock> {
  late final Stream<List<Repuesto>> _bajos = TallerScope.of(context).watchRepuestosBajos();

  @override
  Widget build(BuildContext context) {
    return VistaStream<List<Repuesto>>(
      stream: _bajos,
      builder: (context, bajos) {
        if (bajos.isEmpty) {
          return const EstadoVacio(
              icono: Icons.inventory_2_outlined,
              titulo: 'Stock en orden',
              detalle: 'Ningún repuesto está en su mínimo o por debajo.');
        }
        return ListView(
          padding: _padding,
          children: [
            Text('${bajos.length} repuesto(s) por agotarse',
                style: const TextStyle(color: Paleta.peligro,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final r in bajos)
              TarjetaGarage(
                key: ValueKey(r.id),
                colorAcento: Paleta.peligro,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.nombre,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${r.codigo} · hay ${r.existencias}, mínimo ${r.stockMinimo}',
                            style: const TextStyle(color: Paleta.textoSecundario,
                                fontSize: 13),
                          ),
                          // Sugerencia: reponer hasta el doble del mínimo.
                          Text('Sugerido comprar: ${_sugerido(r)}',
                              style: const TextStyle(
                                  color: Paleta.primario, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text('${r.existencias}', style: rajdhani(size: 28,
                        color: Paleta.peligro)),
                    IconButton(
                      tooltip: 'Reabastecer',
                      iconSize: 30,
                      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                      color: Paleta.primario,
                      icon: const Icon(Icons.add_box_outlined),
                      onPressed: () =>
                          mostrarHoja<bool>(context, HojaReabastecer(repuesto: r)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _sugerido(Repuesto r) {
    final objetivo = r.stockMinimo <= 0 ? 1 : r.stockMinimo * 2;
    final n = objetivo - r.existencias;
    return n < 1 ? 1 : n;
  }
}

// =============================================================================
// FACTURACIÓN POR PERÍODO
// =============================================================================
enum _Periodo { hoy, semana, mes, personalizado }

class _TabFacturacion extends StatefulWidget {
  const _TabFacturacion();
  @override
  State<_TabFacturacion> createState() => _TabFacturacionState();
}

/// AutomaticKeepAliveClientMixin: TabBarView destruye las pestañas que no se
/// ven; con este mixin la pestaña se conserva y no se pierde el período
/// elegido al ir a otra pestaña y volver.
class _TabFacturacionState extends State<_TabFacturacion>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _Periodo _periodo = _Periodo.mes;
  late DateTimeRange _rango = _rangoDe(_Periodo.mes);
  Stream<ReporteFacturacion>? _reporte;

  Stream<ReporteFacturacion> _stream() => _reporte ??=
      TallerScope.of(context).watchFacturacion(_rango.start, _rango.end);

  /// Calcula el rango de fechas de cada atajo (días completos).
  static DateTimeRange _rangoDe(_Periodo p) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    return switch (p) {
      _Periodo.hoy => DateTimeRange(start: hoy, end: hoy),
      // weekday: lunes = 1 ... domingo = 7 -> la semana empieza el lunes
      _Periodo.semana =>
        DateTimeRange(start: hoy.subtract(Duration(days: hoy.weekday - 1)), end: hoy),
      _Periodo.mes => DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: hoy),
      _Periodo.personalizado => DateTimeRange(start: hoy, end: hoy),
    };
  }

  Future<void> _elegir(_Periodo p) async {
    if (p != _Periodo.personalizado) {
      setState(() {
        _periodo = p;
        _rango = _rangoDe(p);
        _reporte = null; // nuevo Stream para el nuevo rango
      });
      return;
    }
    // Calendario de rango de Material (usa el idioma de la app: español).
    final ahora = DateTime.now();
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(ahora.year + 1, 12, 31),
      initialDateRange: _rango,
      helpText: 'PERÍODO A FACTURAR',
      saveText: 'APLICAR',
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _periodo = _Periodo.personalizado;
      _rango = elegido;
      _reporte = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // obligatorio con AutomaticKeepAliveClientMixin
    const etiquetas = {
      _Periodo.hoy: 'Hoy',
      _Periodo.semana: 'Esta semana',
      _Periodo.mes: 'Este mes',
      _Periodo.personalizado: 'Personalizado',
    };
    return ListView(
      padding: _padding,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in _Periodo.values)
              ChoiceChip(
                label: Text(etiquetas[p]!),
                avatar: p == _Periodo.personalizado
                    ? const Icon(Icons.date_range, size: 18)
                    : null,
                selected: _periodo == p,
                onSelected: (_) => _elegir(p),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Del ${fecha(_rango.start)} al ${fecha(_rango.end)}',
            style: rajdhani(size: 16, color: Paleta.textoSecundario)),
        const SizedBox(height: 8),
        VistaStream<ReporteFacturacion>(
          stream: _stream(),
          builder: (context, r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarjetaMedidor(
                rotulo: 'Facturado (órdenes entregadas)',
                valor: dinero(r.facturado, conMoneda: false),
                icono: Icons.receipt_long,
                color: Paleta.primario,
                pie: '$kMoneda · ${r.cantidad} orden(es) entregada(s)',
              ),
              const SizedBox(height: 12),
              TarjetaGarage(
                child: Column(
                  children: [
                    FilaDato('Mano de obra', dinero(r.manoObra),
                        icono: Icons.build_outlined),
                    FilaDato('Repuestos', dinero(r.repuestos),
                        icono: Icons.settings_outlined),
                    FilaDato('Órdenes', '${r.cantidad}',
                        icono: Icons.assignment_outlined),
                    const Divider(height: 16),
                    FilaDato('Cobrado', dinero(r.cobrado),
                        icono: Icons.payments_outlined,
                        estiloValor: rajdhani(size: 20, color: Paleta.exito)),
                    const Text(
                      'Cobrado = pagos recibidos en el período (de cualquier orden '
                      'no cancelada).',
                      style: TextStyle(color: Paleta.textoSecundario, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TituloSeccion('Órdenes entregadas (${r.cantidad})'),
              if (r.ordenes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No se entregaron órdenes en este período.',
                      style: TextStyle(color: Paleta.textoSecundario)),
                ),
              for (final o in r.ordenes)
                FilaOrden(
                  key: ValueKey(o.id),
                  orden: o,
                  alTocar: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PantallaDetalleOrden(ordenId: o.id))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
