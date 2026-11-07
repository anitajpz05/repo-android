// =============================================================================
// tarjetas_orden.dart
// Dos formas de mostrar una orden en una lista:
//  - TarjetaKanban: tarjeta grande del tablero Kanban, con la MATRÍCULA en
//    grande y un botón "→ siguiente estado" de 56 px.
//  - FilaOrden: versión compacta para historiales y reportes.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'acciones_orden.dart';
import 'basicos.dart';
import 'estado_orden.dart';

class TarjetaKanban extends StatelessWidget {
  final OrdenResumen orden;
  final VoidCallback alTocar; // abre el detalle
  final VoidCallback? alAvanzar; // botón "→ siguiente estado"

  const TarjetaKanban({
    super.key,
    required this.orden,
    required this.alTocar,
    this.alAvanzar,
  });

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final color = colorEstado(o.estado);
    final dias = diasEnTaller(o);
    final siguiente = textoAvanzar(o.estado);

    return TarjetaGarage(
      alTocar: alTocar,
      colorAcento: color,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlacaMatricula(o.matricula, tamano: 26),
              const Spacer(),
              // Días en el taller: se resalta en rojo a partir de 5 días.
              _Dias(dias),
            ],
          ),
          const SizedBox(height: 10),
          Text(o.vehiculoTexto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(o.problema,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Paleta.textoSecundario)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.engineering_outlined,
                  size: 18, color: Paleta.secundario),
              const SizedBox(width: 4),
              Expanded(
                child: Text(o.mecanicoNombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Paleta.secundario, fontWeight: FontWeight.w600)),
              ),
              Text('#${o.id}', style: rajdhani(size: 14,
                  color: Paleta.textoSecundario)),
            ],
          ),
          if (siguiente != null && alAvanzar != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: BotonGrande(
                texto: '→  $siguiente',
                icono: iconoEstado(o.estado.siguiente!),
                color: colorAvanzar(o.estado),
                alPulsar: alAvanzar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dias extends StatelessWidget {
  final int dias;
  const _Dias(this.dias);

  @override
  Widget build(BuildContext context) {
    final alerta = dias >= 5;
    final c = alerta ? Paleta.peligro : Paleta.textoSecundario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(dias == 0 ? 'HOY' : '$dias', style: rajdhani(size: 24, color: c,
            altura: 1)),
        Text(dias == 0 ? 'ENTRÓ' : (dias == 1 ? 'DÍA' : 'DÍAS'),
            style: rajdhani(size: 11, color: c, espaciado: 1.5)),
      ],
    );
  }
}

/// Fila compacta de una orden: matrícula, vehículo, cliente, estado, fecha y
/// total/saldo. Se usa en historiales (cliente, vehículo, órdenes cerradas)
/// y en el reporte de facturación.
class FilaOrden extends StatelessWidget {
  final OrdenResumen orden;
  final VoidCallback? alTocar;
  final bool mostrarKm; // en el historial del vehículo interesa el km

  const FilaOrden(
      {super.key, required this.orden, this.alTocar, this.mostrarKm = false});

  @override
  Widget build(BuildContext context) {
    final o = orden;
    final fechaTexto = o.fechaEntrega != null
        ? 'Entregada ${fecha(o.fechaEntrega!)}'
        : 'Entró ${fecha(o.fechaEntrada)}';
    return TarjetaGarage(
      alTocar: alTocar,
      colorAcento: colorEstado(o.estado),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlacaMatricula(o.matricula, tamano: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text('#${o.id} · ${o.marca} ${o.modelo}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              ChipEstado(o.estado, compacto: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.problema,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Paleta.textoSecundario)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${o.clienteNombre} · $fechaTexto'
                  '${mostrarKm ? ' · ${numero(o.kilometrajeEntrada)} km' : ''}',
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12.5, color: Paleta.textoSecundario),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dinero(o.total), style: rajdhani(size: 16)),
                  if (o.saldo > 0.009 && o.estado != EstadoOrden.cancelada)
                    Text('debe ${dinero(o.saldo)}',
                        style: const TextStyle(color: Paleta.peligro, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
