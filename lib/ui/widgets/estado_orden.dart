// =============================================================================
// estado_orden.dart
// Widgets que representan visualmente una orden y su estado:
//  - PlacaMatricula: la matrícula dibujada como una chapa (dato estrella del
//    taller: es lo primero que el mecánico mira en el carro).
//  - ChipEstado: pastilla de color + icono + texto del estado.
//  - BarraEstados: barra de progreso segmentada Recibida → Entregada.
//  - diasEnTaller(): cuántos días lleva (o llevó) el vehículo en el taller.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../tema.dart';

/// Días que el vehículo estuvo/está en el taller. Si ya se entregó se cuenta
/// hasta la fecha de entrega; si no, hasta hoy.
int diasEnTaller(OrdenResumen o) {
  final fin = o.fechaEntrega ?? DateTime.now();
  final a = DateTime(o.fechaEntrada.year, o.fechaEntrada.month, o.fechaEntrada.day);
  final b = DateTime(fin.year, fin.month, fin.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d;
}

/// Texto "HOY", "1 DÍA", "5 DÍAS".
String textoDias(int dias) =>
    dias == 0 ? 'HOY' : (dias == 1 ? '1 DÍA' : '$dias DÍAS');

/// Matrícula estilo chapa: fondo claro, letras oscuras Rajdhani y separación
/// amplia. Alto contraste para leerla de lejos.
class PlacaMatricula extends StatelessWidget {
  final String matricula;
  final double tamano; // tamaño de letra

  const PlacaMatricula(this.matricula, {super.key, this.tamano = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tamano * 0.45, vertical: tamano * 0.08),
      decoration: BoxDecoration(
        color: Paleta.texto,
        borderRadius: BorderRadius.circular(tamano * 0.22),
        border: Border.all(color: Paleta.sobrePrimario, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        matricula.toUpperCase(),
        style: rajdhani(
          size: tamano,
          color: Paleta.sobrePrimario,
          espaciado: tamano * 0.12,
          altura: 1.15,
        ),
      ),
    );
  }
}

/// Pastilla con el estado de la orden. Usa color + icono + texto para que se
/// distinga también sin percibir colores.
class ChipEstado extends StatelessWidget {
  final EstadoOrden estado;
  final bool compacto;

  const ChipEstado(this.estado, {super.key, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compacto ? 8 : 10, vertical: compacto ? 2 : 4),
      decoration: BoxDecoration(
        color: c.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoEstado(estado), size: compacto ? 14 : 16, color: c),
          const SizedBox(width: 4),
          Text(etiquetaCorta(estado),
              style: rajdhani(size: compacto ? 12 : 14, color: c)),
        ],
      ),
    );
  }
}

/// Barra de progreso segmentada con los 5 estados del flujo normal.
/// Los segmentos alcanzados se pintan con el color del estado actual; el
/// actual lleva además su nombre resaltado. Si la orden está cancelada, toda
/// la barra se pinta en rojo apagado con la leyenda CANCELADA.
class BarraEstados extends StatelessWidget {
  final EstadoOrden estado;

  const BarraEstados(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final cancelada = estado == EstadoOrden.cancelada;
    final pasos = EstadoOrdenX.flujo;
    final actual = pasos.indexOf(estado); // -1 si está cancelada
    final colorActual = colorEstado(estado);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < pasos.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: cancelada
                        ? Paleta.cancelada.withAlpha(70)
                        : (i <= actual ? colorActual : Paleta.borde),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (cancelada)
          Text('ORDEN CANCELADA',
              textAlign: TextAlign.center,
              style: rajdhani(size: 13, color: Paleta.cancelada, espaciado: 2))
        else
          Row(
            children: [
              for (var i = 0; i < pasos.length; i++)
                Expanded(
                  child: Text(
                    etiquetaCorta(pasos[i]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: rajdhani(
                      size: 10.5,
                      espaciado: 0.4,
                      color: i == actual
                          ? colorActual
                          : (i < actual
                              ? Paleta.textoSecundario
                              : Paleta.entregada),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
