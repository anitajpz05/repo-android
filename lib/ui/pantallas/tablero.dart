// =============================================================================
// tablero.dart
// Pantalla de inicio "TABLERO": lo que el dueño mira primero.
//  - 4 medidores grandes: abiertas, en reparación, listas y por cobrar.
//  - Alertas de stock (repuestos por agotarse) en rojo.
//  - Carga por mecánico con barras horizontales.
// Cada bloque escucha su propio Stream: al registrar un pago, avanzar una
// orden o usar un repuesto, el tablero se actualiza solo.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/medidores.dart';
import '../widgets/menu_lateral.dart';
import 'nueva_orden.dart';

class PantallaTablero extends StatefulWidget {
  final Widget menu;
  final ValueChanged<int> irA; // para saltar a otra sección del menú

  const PantallaTablero({super.key, required this.menu, required this.irA});

  @override
  State<PantallaTablero> createState() => _PantallaTableroState();
}

class _PantallaTableroState extends State<PantallaTablero> {
  // Streams creados UNA vez (campos `late final`: se inicializan en el primer
  // build, cuando ya se puede leer el TallerScope del context).
  late final repo = TallerScope.of(context);
  late final Stream<Map<EstadoOrden, int>> _conteo = repo.watchConteoPorEstado();
  late final Stream<List<Deudor>> _deudores = repo.watchDeudores();
  late final Stream<List<Repuesto>> _bajos = repo.watchRepuestosBajos();
  late final Stream<List<CargaMecanico>> _carga = repo.watchCargaMecanicos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.menu,
      appBar: AppBar(title: const Text('TABLERO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirNuevaOrden(context),
        icon: const Icon(Icons.add),
        label: const Text('NUEVA ORDEN'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // espacio para el FAB
        children: [
          _medidores(),
          _alertasStock(),
          _cargaMecanicos(),
        ],
      ),
    );
  }

  /// Rejilla 2×2 de medidores.
  Widget _medidores() {
    return VistaStream<Map<EstadoOrden, int>>(
      stream: _conteo,
      builder: (context, c) {
        int n(EstadoOrden e) => c[e] ?? 0; // conteo de un estado (0 si no hay)
        final abiertas = EstadoOrdenX.abiertos.fold<int>(0, (s, e) => s + n(e));
        final enRep = n(EstadoOrden.reparacion);
        final listas = n(EstadoOrden.lista);
        final porRevisar = n(EstadoOrden.recibida) + n(EstadoOrden.diagnostico);
        double prop(int n) => abiertas == 0 ? 0.0 : n / abiertas;
        void irOrdenes() => widget.irA(Secciones.ordenes);

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TarjetaMedidor(
                    rotulo: 'Abiertas',
                    valor: '$abiertas',
                    icono: Icons.assignment_outlined,
                    color: Paleta.texto,
                    fraccion: abiertas == 0 ? 0.0 : 1.0,
                    pie: '$porRevisar por revisar',
                    alTocar: irOrdenes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TarjetaMedidor(
                    rotulo: 'En reparación',
                    valor: '$enRep',
                    icono: Icons.build,
                    color: Paleta.reparacion,
                    fraccion: prop(enRep),
                    pie: 'de $abiertas abiertas',
                    alTocar: irOrdenes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TarjetaMedidor(
                    rotulo: 'Listas',
                    valor: '$listas',
                    icono: Icons.check_circle_outline,
                    color: Paleta.lista,
                    fraccion: prop(listas),
                    pie: 'para entregar',
                    alTocar: irOrdenes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _medidorPorCobrar()),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Total por cobrar = suma de los saldos de todos los deudores.
  Widget _medidorPorCobrar() {
    return VistaStream<List<Deudor>>(
      stream: _deudores,
      builder: (context, deudores) {
        final total = deudores.fold<double>(0, (s, d) => s + d.saldo);
        return TarjetaMedidor(
          rotulo: 'Por cobrar',
          valor: dinero(total, conMoneda: false),
          icono: Icons.payments_outlined,
          color: total > 0 ? Paleta.peligro : Paleta.exito,
          pie: '$kMoneda · ${deudores.length} cliente(s)',
          alTocar: () => widget.irA(Secciones.reportes),
        );
      },
    );
  }

  Widget _alertasStock() {
    return VistaStream<List<Repuesto>>(
      stream: _bajos,
      builder: (context, bajos) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TituloSeccion(
              'Alertas de stock (${bajos.length})',
              color: bajos.isEmpty ? Paleta.textoSecundario : Paleta.peligro,
              accion: TextButton(
                onPressed: () => widget.irA(Secciones.inventario),
                child: const Text('INVENTARIO'),
              ),
            ),
            if (bajos.isEmpty)
              const TarjetaGarage(
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Paleta.exito),
                    SizedBox(width: 10),
                    Expanded(child: Text('Todo el inventario está por encima del mínimo')),
                  ],
                ),
              )
            else
              for (final r in bajos)
                TarjetaGarage(
                  colorAcento: Paleta.peligro,
                  colorBorde: Paleta.peligro.withAlpha(90),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 8),
                  alTocar: () => widget.irA(Secciones.inventario),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Paleta.peligro),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${r.codigo} · mínimo ${r.stockMinimo}',
                                style: const TextStyle(
                                    color: Paleta.textoSecundario, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text('${r.existencias}',
                              style: rajdhani(size: 26, color: Paleta.peligro,
                                  altura: 1)),
                          Text('QUEDAN', style: rajdhani(size: 10,
                              color: Paleta.peligro)),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _cargaMecanicos() {
    return VistaStream<List<CargaMecanico>>(
      stream: _carga,
      builder: (context, cargas) {
        // Se muestran los activos y los inactivos que aún tengan órdenes.
        final visibles =
            cargas.where((c) => c.mecanico.activo || c.abiertas > 0).toList();
        final maximo = visibles.fold<int>(1, (m, c) => c.abiertas > m ? c.abiertas : m);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TituloSeccion('Carga por mecánico',
                accion: TextButton(
                  onPressed: () => widget.irA(Secciones.mecanicos),
                  child: const Text('MECÁNICOS'),
                )),
            TarjetaGarage(
              child: visibles.isEmpty
                  ? const Text('No hay mecánicos registrados')
                  : Column(
                      children: [
                        for (final c in visibles) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(c.mecanico.nombre.toUpperCase(),
                                    style: rajdhani(size: 16)),
                              ),
                              Text('${c.abiertas}',
                                  style: rajdhani(size: 22, color: Paleta.primario)),
                              const SizedBox(width: 4),
                              const Text('abiertas',
                                  style: TextStyle(color: Paleta.textoSecundario)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          BarraCarga(fraccion: c.abiertas / maximo),
                          const SizedBox(height: 4),
                          Text(
                            'Revisión ${c.enDiagnostico} · Reparación ${c.enReparacion}'
                            ' · Listas ${c.listas}',
                            style: const TextStyle(
                                color: Paleta.textoSecundario, fontSize: 12.5),
                          ),
                          if (c != visibles.last) const SizedBox(height: 14),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
