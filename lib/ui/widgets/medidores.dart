// =============================================================================
// medidores.dart
// Componentes del tablero con aspecto de instrumento:
//  - TarjetaMedidor: número grande (Rajdhani) con rótulo y una "regleta" de
//    10 LEDs que se encienden según la proporción indicada.
//  - BarraCarga: barra horizontal proporcional hecha con Container +
//    FractionallySizedBox (sin paquetes de gráficos).
// =============================================================================
import 'package:flutter/material.dart';

import '../tema.dart';

class TarjetaMedidor extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icono;
  final Color color;
  final double? fraccion; // 0..1; null = sin regleta
  final String? pie; // texto pequeño debajo del número
  final VoidCallback? alTocar;

  const TarjetaMedidor({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.fraccion,
    this.pie,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Paleta.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Paleta.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(rotulo.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rajdhani(
                            size: 13, color: Paleta.textoSecundario, espaciado: 1.5)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // FittedBox reduce el número si no cabe (p. ej. montos grandes).
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor,
                    style: rajdhani(size: 44, color: color, espaciado: 0.5,
                        altura: 1.1)),
              ),
              if (pie != null)
                Text(pie!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Paleta.textoSecundario, fontSize: 12.5)),
              if (fraccion != null) ...[
                const SizedBox(height: 8),
                _Regleta(fraccion: fraccion!, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 10 segmentos; se encienden round(fraccion * 10).
class _Regleta extends StatelessWidget {
  final double fraccion;
  final Color color;
  const _Regleta({required this.fraccion, required this.color});

  @override
  Widget build(BuildContext context) {
    final encendidos = (fraccion.clamp(0.0, 1.0) * 10).round();
    return Row(
      children: [
        for (var i = 0; i < 10; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < encendidos ? color : Paleta.borde,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Barra horizontal: el relleno ocupa [fraccion] del ancho disponible.
/// FractionallySizedBox calcula el ancho como porcentaje del padre.
class BarraCarga extends StatelessWidget {
  final double fraccion;
  final Color color;
  final double alto;

  const BarraCarga(
      {super.key, required this.fraccion, this.color = Paleta.primario,
          this.alto = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      decoration: BoxDecoration(
        color: Paleta.fondo,
        borderRadius: BorderRadius.circular(alto / 2),
        border: Border.all(color: Paleta.borde),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraccion.clamp(0.0, 1.0),
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(alto / 2),
          ),
        ),
      ),
    );
  }
}
