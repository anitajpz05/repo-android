// =============================================================================
// totales_orden.dart
// Resumen económico de una orden: mano de obra + repuestos = total,
// pagado y SALDO. El saldo se muestra grande, en rojo si falta dinero y en
// verde con "PAGADO" cuando está saldada.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'basicos.dart';

class TotalesOrden extends StatelessWidget {
  final OrdenResumen orden;
  const TotalesOrden(this.orden, {super.key});

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final debe = o.saldo > 0.009;
    final colorSaldo = debe ? Paleta.peligro : Paleta.exito;

    Widget linea(String etiqueta, double valor, {bool fuerte = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(etiqueta,
                    style: TextStyle(
                        color: fuerte ? Paleta.texto : Paleta.textoSecundario,
                        fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400)),
              ),
              Text(dinero(valor), style: rajdhani(size: fuerte ? 19 : 16)),
            ],
          ),
        );

    return TarjetaGarage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          linea('Mano de obra', o.manoObra),
          linea('Repuestos', o.totalRepuestos),
          const Divider(height: 16),
          linea('TOTAL', o.total, fuerte: true),
          linea('Pagado', o.pagado),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorSaldo.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorSaldo.withAlpha(120)),
            ),
            child: Row(
              children: [
                Text(debe ? 'SALDO' : 'PAGADO',
                    style: rajdhani(size: 16, color: colorSaldo, espaciado: 2)),
                const Spacer(),
                Text(dinero(debe ? o.saldo : o.pagado),
                    style: rajdhani(size: 26, color: colorSaldo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
