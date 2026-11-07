// =============================================================================
// selector_mecanico.dart
// Selector de mecánico con TARJETAS que muestran la carga actual de cada uno
// (órdenes abiertas y desglose). Se usa al crear una orden y al reasignarla.
// La tarjeta del mecánico con menos trabajo lleva la marca "MENOR CARGA" para
// ayudar a repartir el trabajo.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../tema.dart';
import 'basicos.dart';
import 'medidores.dart';

class SelectorMecanico extends StatefulWidget {
  final int? seleccionado;
  final ValueChanged<int> alSeleccionar;

  const SelectorMecanico(
      {super.key, required this.seleccionado, required this.alSeleccionar});

  @override
  State<SelectorMecanico> createState() => _SelectorMecanicoState();
}

class _SelectorMecanicoState extends State<SelectorMecanico> {
  // `late final`: se evalúa la primera vez que se usa (en build), cuando el
  // context ya puede buscar el TallerScope. El Stream se crea UNA sola vez.
  late final Stream<List<CargaMecanico>> _carga =
      TallerScope.of(context).watchCargaMecanicos();

  @override
  Widget build(BuildContext context) {
    return VistaStream<List<CargaMecanico>>(
      stream: _carga,
      builder: (context, todas) {
        // Solo mecánicos activos pueden recibir órdenes.
        final activos = todas.where((c) => c.mecanico.activo).toList();
        if (activos.isEmpty) {
          return const EstadoVacio(
              icono: Icons.engineering_outlined,
              titulo: 'No hay mecánicos activos',
              detalle: 'Actívalos en la sección Mecánicos.');
        }
        final maximo = activos.fold<int>(1, (m, c) => c.abiertas > m ? c.abiertas : m);
        final menor = activos.reduce((a, b) => b.abiertas < a.abiertas ? b : a);

        return Column(
          children: [
            for (final c in activos)
              _TarjetaMecanico(
                carga: c,
                maximo: maximo,
                elegido: c.mecanico.id == widget.seleccionado,
                menorCarga: c.mecanico.id == menor.mecanico.id && activos.length > 1,
                alTocar: () => widget.alSeleccionar(c.mecanico.id),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaMecanico extends StatelessWidget {
  final CargaMecanico carga;
  final int maximo;
  final bool elegido;
  final bool menorCarga;
  final VoidCallback alTocar;

  const _TarjetaMecanico({
    required this.carga,
    required this.maximo,
    required this.elegido,
    required this.menorCarga,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final c = carga;
    return TarjetaGarage(
      alTocar: alTocar,
      margin: const EdgeInsets.only(bottom: 10),
      // La tarjeta elegida se reconoce por el borde amarillo y el check.
      colorBorde: elegido ? Paleta.primario : Paleta.borde,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(elegido ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: elegido ? Paleta.primario : Paleta.textoSecundario),
              const SizedBox(width: 10),
              Expanded(
                child: Text(c.mecanico.nombre.toUpperCase(),
                    style: rajdhani(size: 18)),
              ),
              if (menorCarga)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Paleta.exito.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('MENOR CARGA',
                      style: rajdhani(size: 11, color: Paleta.exito)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          BarraCarga(
            fraccion: c.abiertas / maximo,
            color: elegido ? Paleta.primario : Paleta.secundario,
            alto: 10,
          ),
          const SizedBox(height: 6),
          Text(
            '${c.abiertas} abiertas · ${c.enDiagnostico} por diagnosticar · '
            '${c.enReparacion} en reparación · ${c.listas} listas',
            style: const TextStyle(color: Paleta.textoSecundario, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
