// =============================================================================
// basicos.dart
// Piezas visuales pequeñas que se repiten en todas las pantallas:
//  - TarjetaGarage: "placa" oscura con borde (sustituye a Card para no
//    depender de cardTheme).
//  - TituloSeccion: rótulo en Rajdhani mayúsculas.
//  - FilaDato: etiqueta + valor en una línea.
//  - VistaStream: StreamBuilder con carga y error ya resueltos.
//  - Cargando, EstadoVacio, ErrorVista: estados de la lista.
//  - BotonGrande: botón de 56 px de alto para manos con grasa.
// =============================================================================
import 'package:flutter/material.dart';

import '../tema.dart';

/// Contenedor tipo tarjeta: fondo superficie, borde fino y esquinas de 12 px.
/// Si se pasa [alTocar] se vuelve pulsable (InkWell con efecto de onda).
class TarjetaGarage extends StatelessWidget {
  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color colorBorde;
  final Color? colorAcento; // franja de color a la izquierda (opcional)

  const TarjetaGarage({
    super.key,
    required this.child,
    this.alTocar,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.colorBorde = Paleta.borde,
    this.colorAcento,
  });

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(12);
    Widget contenido = Padding(padding: padding, child: child);
    if (colorAcento != null) {
      // IntrinsicHeight permite que la franja ocupe todo el alto del contenido.
      contenido = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: colorAcento),
            Expanded(child: contenido),
          ],
        ),
      );
    }
    return Padding(
      padding: margin,
      child: Material(
        color: Paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: radio,
          side: BorderSide(color: colorBorde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: alTocar, child: contenido),
      ),
    );
  }
}

/// Rótulo de sección: texto pequeño en mayúsculas con separación amplia.
class TituloSeccion extends StatelessWidget {
  final String texto;
  final Widget? accion; // p. ej. un TextButton a la derecha
  final Color color;

  const TituloSeccion(this.texto,
      {super.key, this.accion, this.color = Paleta.textoSecundario});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(texto.toUpperCase(),
                style: rajdhani(size: 14, color: color, espaciado: 2)),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Una fila "Etiqueta ........ valor" para fichas de datos.
class FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData? icono;
  final TextStyle? estiloValor;

  const FilaDato(this.etiqueta, this.valor,
      {super.key, this.icono, this.estiloValor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 20, color: Paleta.textoSecundario),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 110,
            child: Text(etiqueta,
                style: const TextStyle(color: Paleta.textoSecundario)),
          ),
          Expanded(
            child: Text(valor,
                style: estiloValor ??
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

/// StreamBuilder "con todo resuelto": muestra un indicador mientras llega el
/// primer dato, un mensaje si hay error y, si no, llama a [builder].
/// Si el Stream cambia (p. ej. nuevo filtro) se siguen mostrando los datos
/// anteriores hasta que llegan los nuevos, así la lista no parpadea.
class VistaStream<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T datos) builder;

  const VistaStream({super.key, required this.stream, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return ErrorVista(snap.error.toString());
        if (snap.hasData) return builder(context, snap.data as T);
        if (snap.connectionState == ConnectionState.waiting ||
            snap.connectionState == ConnectionState.none) {
          return const Cargando();
        }
        // El Stream emitió null (p. ej. una orden que ya no existe).
        return builder(context, snap.data as T);
      },
    );
  }
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});
  @override
  // Tamaño fijo y pequeño: cabe incluso en barras de 48 px de alto.
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: Paleta.primario, strokeWidth: 3),
        ),
      );
}

/// Mensaje grande y centrado cuando una lista no tiene elementos.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;

  const EstadoVacio(
      {super.key, required this.icono, required this.titulo, this.detalle});

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView: si el alto disponible es poco (p. ej. con el
    // teclado abierto o en una columna del Kanban) se desplaza en vez de
    // desbordar. primary: false para no usar el PrimaryScrollController.
    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: Paleta.borde),
            const SizedBox(height: 12),
            Text(titulo.toUpperCase(),
                textAlign: TextAlign.center,
                style: rajdhani(size: 18, color: Paleta.textoSecundario)),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(detalle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Paleta.textoSecundario)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorVista extends StatelessWidget {
  final String mensaje;
  const ErrorVista(this.mensaje, {super.key});
  @override
  Widget build(BuildContext context) => EstadoVacio(
      icono: Icons.error_outline, titulo: 'Ocurrió un error', detalle: mensaje);
}

/// Botón principal de la app: alto mínimo de 56 px, ancho completo y texto en
/// MAYÚSCULAS. [peligro] lo pinta de rojo; [contorno] lo hace secundario.
/// Si [ocupado] es true muestra un indicador y queda deshabilitado (evita
/// pulsar dos veces mientras se guarda).
class BotonGrande extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final VoidCallback? alPulsar;
  final bool peligro;
  final bool contorno;
  final bool ocupado;
  final Color? color;

  const BotonGrande({
    super.key,
    required this.texto,
    this.icono,
    this.alPulsar,
    this.peligro = false,
    this.contorno = false,
    this.ocupado = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final etiqueta = Text(texto.toUpperCase(), textAlign: TextAlign.center);
    final Widget icon = ocupado
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5))
        : Icon(icono ?? Icons.check, size: 22);
    final accion = ocupado ? null : alPulsar;

    if (contorno) {
      final c = peligro ? Paleta.peligro : (color ?? Paleta.texto);
      return OutlinedButton.icon(
        onPressed: accion,
        icon: icon,
        label: etiqueta,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c.withAlpha(140), width: 1.5),
          minimumSize: const Size(64, 56),
        ),
      );
    }
    final fondo = peligro ? Paleta.peligro : (color ?? Paleta.primario);
    return FilledButton.icon(
      onPressed: accion,
      icon: icon,
      label: etiqueta,
      style: FilledButton.styleFrom(
        backgroundColor: fondo,
        foregroundColor: Paleta.sobrePrimario,
        minimumSize: const Size(64, 56),
      ),
    );
  }
}
