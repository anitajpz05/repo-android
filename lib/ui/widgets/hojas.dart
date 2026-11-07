// =============================================================================
// hojas.dart
// Todo lo relacionado con mensajes y "hojas" inferiores (bottom sheets).
// En esta solución los formularios y confirmaciones NO usan diálogos: suben
// desde abajo, quedan al alcance del pulgar y tienen botones grandes.
//
//  - mostrarHoja(): abre un showModalBottomSheet que se adapta al teclado.
//  - CuerpoHoja: estructura común (asa, título, campos, error, botón).
//  - AccionHojaMixin: lógica de "guardando…" + captura de errores dentro de
//    la hoja (el error se muestra DENTRO de la hoja, porque un SnackBar
//    quedaría tapado por ella).
//  - confirmar(): hoja de confirmación Sí/No que devuelve un bool.
//  - mostrarMensaje(), ejecutarAccion(), avisoStockBajo(): avisos SnackBar.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../tema.dart';
import 'basicos.dart';

/// Abre [hoja] como bottom sheet modal.
/// - isScrollControlled: true -> puede ocupar más de media pantalla.
/// - El Padding con viewInsets.bottom empuja el contenido por encima del
///   teclado, así los campos nunca quedan tapados.
Future<T?> mostrarHoja<T>(BuildContext context, Widget hoja) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Paleta.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: hoja,
    ),
  );
}

/// Estructura visual común de las hojas con formulario.
class CuerpoHoja extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final String? error; // mensaje de error de la última acción
  final Widget? boton; // botón principal al final

  const CuerpoHoja({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
    this.error,
    this.boton,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo.toUpperCase(), style: rajdhani(size: 24)),
          if (subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitulo!,
                  style: const TextStyle(color: Paleta.textoSecundario)),
            ),
          const SizedBox(height: 16),
          ...children,
          if (error != null) ...[
            const SizedBox(height: 8),
            CajaError(error!),
          ],
          if (boton != null) ...[
            const SizedBox(height: 16),
            boton!,
          ],
        ],
      ),
    );
  }
}

/// Recuadro rojo con el mensaje de una regla de negocio incumplida.
class CajaError extends StatelessWidget {
  final String mensaje;
  const CajaError(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Paleta.peligro.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Paleta.peligro.withAlpha(120)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Paleta.peligro),
          const SizedBox(width: 10),
          Expanded(
              child: Text(mensaje,
                  style: const TextStyle(color: Paleta.peligro))),
        ],
      ),
    );
  }
}

/// Mixin para los State de las hojas con formulario. Aporta:
///  - [ocupado]: true mientras se guarda (el botón muestra un indicador).
///  - [error]: último mensaje de error, que la hoja pinta con CajaError.
///  - [guardar]: ejecuta la acción, captura ReglaNegocioException y, si todo
///    va bien, cierra la hoja devolviendo el resultado al que la abrió.
///    OJO: el valor devuelto debe ser del tipo con que se abrió la hoja
///    (mostrarHoja<int> -> int, mostrarHoja<bool> -> true); si no, la ruta
///    lanzaría un error de tipos al cerrarse.
mixin AccionHojaMixin<T extends StatefulWidget> on State<T> {
  bool ocupado = false;
  String? error;

  Future<void> guardar(Future<Object?> Function() accion) async {
    if (ocupado) return; // evita doble pulsación
    setState(() {
      ocupado = true;
      error = null;
    });
    try {
      final resultado = await accion();
      // Tras un await el widget pudo cerrarse: se comprueba `mounted`.
      if (!mounted) return;
      Navigator.of(context).pop(resultado ?? true);
    } on ReglaNegocioException catch (e) {
      if (mounted) setState(() => error = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }
}

/// Hoja de confirmación. Devuelve true solo si se pulsa el botón de acción.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoAccion = 'Confirmar',
  bool peligro = true,
  IconData icono = Icons.check,
}) async {
  final r = await mostrarHoja<bool>(
    context,
    Builder(
      builder: (ctx) => CuerpoHoja(
        titulo: titulo,
        children: [
          Text(mensaje, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BotonGrande(
                  texto: 'Volver',
                  icono: Icons.close,
                  contorno: true,
                  alPulsar: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BotonGrande(
                  texto: textoAccion,
                  icono: icono,
                  peligro: peligro,
                  alPulsar: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return r ?? false; // cerrar deslizando = no confirmar
}

/// Muestra un SnackBar. [tipo] cambia color e icono.
enum TipoMensaje { info, exito, error }

void mostrarMensaje(BuildContext context, String texto,
    {TipoMensaje tipo = TipoMensaje.info}) {
  final (color, icono) = switch (tipo) {
    TipoMensaje.info => (Paleta.superficieAlta, Icons.info_outline),
    TipoMensaje.exito => (const Color(0xFF14361F), Icons.check_circle_outline),
    TipoMensaje.error => (const Color(0xFF4A1C1C), Icons.error_outline),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: color,
      content: Row(
        children: [
          Icon(icono, color: Paleta.texto),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    ));
}

/// Ejecuta una acción del repositorio desde una pantalla: si falla una regla
/// de negocio, se muestra su mensaje; si sale bien y hay [exito], se avisa.
/// Devuelve true si la acción terminó sin errores.
Future<bool> ejecutarAccion(
  BuildContext context,
  Future<void> Function() accion, {
  String? exito,
}) async {
  try {
    await accion();
    if (!context.mounted) return true;
    if (exito != null) mostrarMensaje(context, exito, tipo: TipoMensaje.exito);
    return true;
  } on ReglaNegocioException catch (e) {
    if (context.mounted) {
      mostrarMensaje(context, e.mensaje, tipo: TipoMensaje.error);
    }
  } catch (e) {
    if (context.mounted) {
      mostrarMensaje(context, 'Error: $e', tipo: TipoMensaje.error);
    }
  }
  return false;
}

/// Aviso inmediato cuando, tras usar un repuesto, quedan pocas unidades.
void avisoStockBajo(BuildContext context, ResultadoUsoRepuesto r) {
  if (!r.quedoBajo) return;
  final rep = r.repuesto;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: Paleta.peligro,
      duration: const Duration(seconds: 6),
      content: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Paleta.sobrePrimario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Quedan ${rep.existencias} de ${rep.nombre}: hay que comprar '
              '(mínimo ${rep.stockMinimo}).',
              style: const TextStyle(
                  color: Paleta.sobrePrimario, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ));
}
