// =============================================================================
// acciones_orden.dart
// Acciones de cambio de estado de una orden, compartidas por el tablero
// Kanban y por la pantalla de detalle (así la regla de "confirmar antes de
// entregar o cancelar" está escrita UNA sola vez).
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'hojas.dart';

/// Texto del botón "→ siguiente estado" (null si la orden ya terminó).
String? textoAvanzar(EstadoOrden estado) {
  final sig = estado.siguiente;
  if (sig == null) return null;
  if (sig == EstadoOrden.entregada) return 'ENTREGAR';
  return etiquetaCorta(sig);
}

/// Color del botón de avance: el del estado de destino, salvo ENTREGAR, que
/// usa verde (el gris de "entregada" tendría poco contraste).
Color colorAvanzar(EstadoOrden estado) {
  final sig = estado.siguiente;
  if (sig == null || sig == EstadoOrden.entregada) return Paleta.exito;
  return colorEstado(sig);
}

/// Avanza la orden al siguiente estado. Entregar el vehículo pide
/// confirmación y, si queda saldo, lo advierte (se permite entregar con
/// deuda: el cliente puede pagar en dos partes).
Future<void> avanzarOrden(BuildContext context, OrdenResumen o) async {
  final repo = TallerScope.of(context);
  final sig = o.estado.siguiente;
  if (sig == null) return;

  if (sig == EstadoOrden.entregada) {
    final deuda = o.saldo > 0.009;
    final ok = await confirmar(
      context,
      titulo: 'Entregar ${o.matricula}',
      mensaje: deuda
          ? 'El cliente ${o.clienteNombre} todavía debe ${dinero(o.saldo)}. '
              'La deuda quedará registrada. ¿Entregar el vehículo?'
          : '¿Confirmas que ${o.clienteNombre} recoge el vehículo?',
      textoAccion: 'Entregar',
      peligro: false,
      icono: Icons.directions_car,
    );
    if (!ok || !context.mounted) return;
  }

  await ejecutarAccion(
    context,
    () => repo.avanzarEstado(o.id),
    exito: '${o.matricula} → ${sig.etiqueta}',
  );
}

/// Retrocede un estado (para corregir un avance hecho por error).
Future<void> retrocederOrden(BuildContext context, OrdenResumen o) async {
  final ant = o.estado.anterior;
  if (ant == null) return;
  await ejecutarAccion(
    context,
    () => TallerScope.of(context).retrocederEstado(o.id),
    exito: '${o.matricula} volvió a "${ant.etiqueta}"',
  );
}

/// Cancela la orden tras confirmar. Los repuestos vuelven al inventario.
Future<void> cancelarOrden(BuildContext context, OrdenResumen o) async {
  final repo = TallerScope.of(context);
  final ok = await confirmar(
    context,
    titulo: 'Cancelar orden #${o.id}',
    mensaje: 'La orden de ${o.matricula} quedará CANCELADA y ya no se podrá '
        'modificar. Los repuestos usados volverán al inventario.',
    textoAccion: 'Cancelar orden',
    icono: Icons.block,
  );
  if (!ok || !context.mounted) return;
  await ejecutarAccion(context, () => repo.cancelarOrden(o.id),
      exito: 'Orden #${o.id} cancelada');
}
