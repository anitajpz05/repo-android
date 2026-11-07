// =============================================================================
// hojas_orden.dart
// Hojas inferiores que se abren desde el detalle de una orden (FAB
// contextual o menú):
//  - HojaTrabajo          añadir mano de obra            -> bool
//  - HojaUsarRepuesto     elegir repuesto del inventario -> ResultadoUsoRepuesto
//  - HojaPago             registrar un abono             -> bool
//  - HojaCambiarMecanico  reasignar la orden             -> bool
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'basicos.dart';
import 'formularios.dart';
import 'hojas.dart';
import 'selector_mecanico.dart';

// =============================================================================
// TRABAJO (mano de obra)
// =============================================================================
class HojaTrabajo extends StatefulWidget {
  final int ordenId;
  const HojaTrabajo({super.key, required this.ordenId});

  @override
  State<HojaTrabajo> createState() => _HojaTrabajoState();
}

class _HojaTrabajoState extends State<HojaTrabajo> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();

  /// Trabajos frecuentes: un toque rellena la descripción (menos tecleo).
  static const _frecuentes = [
    'Cambio de aceite',
    'Alineación',
    'Balanceo',
    'Diagnóstico',
    'Cambio de pastillas',
    'Revisión eléctrica',
  ];

  @override
  void dispose() {
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    guardar(() async {
      await repo.agregarTrabajo(
          widget.ordenId, _descripcion.text, leerDinero(_precio.text)!);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: 'Añadir trabajo',
        subtitulo: 'Orden #${widget.ordenId}',
        error: error,
        boton: BotonGrande(
            texto: 'Añadir trabajo', icono: Icons.add, ocupado: ocupado,
                alPulsar: _guardar),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in _frecuentes)
                ActionChip(
                  label: Text(t),
                  onPressed: () => setState(() => _descripcion.text = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcion,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoracionCampo('Descripción del trabajo',
                icono: Icons.build_outlined),
            validator: validarObligatorio,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: rajdhani(size: 22),
            decoration: decoracionCampo('Precio de mano de obra', sufijo: kMoneda),
            validator: validarDinero,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// USAR REPUESTO: buscador del inventario + cantidad
// =============================================================================
class HojaUsarRepuesto extends StatefulWidget {
  final int ordenId;
  const HojaUsarRepuesto({super.key, required this.ordenId});

  @override
  State<HojaUsarRepuesto> createState() => _HojaUsarRepuestoState();
}

class _HojaUsarRepuestoState extends State<HojaUsarRepuesto> with AccionHojaMixin {
  final _busqueda = TextEditingController();
  Stream<List<Repuesto>>? _repuestos; // se recrea al cambiar la búsqueda
  Repuesto? _elegido;
  int _cantidad = 1;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Crea (o recrea) el Stream filtrado. Se llama en build la primera vez y
  /// en onChanged del buscador.
  Stream<List<Repuesto>> _stream() =>
      _repuestos ??= TallerScope.of(context).watchRepuestos(busqueda: _busqueda.text);

  void _buscar(String _) => setState(() => _repuestos = null);

  void _elegir(Repuesto r) => setState(() {
        _elegido = r;
        _cantidad = 1;
        error = null;
      });

  void _usar() {
    final r = _elegido;
    if (r == null) return;
    final repo = TallerScope.of(context);
    // usarRepuesto devuelve ResultadoUsoRepuesto: la hoja lo devuelve a la
    // pantalla para que esta muestre el aviso de stock bajo si hace falta.
    guardar(() => repo.usarRepuesto(widget.ordenId, r.id, _cantidad));
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height;
    final r = _elegido;

    // Paso 2: ya se eligió el repuesto -> cantidad y confirmar.
    if (r != null) {
      final maximo = r.existencias;
      return CuerpoHoja(
        titulo: 'Usar repuesto',
        subtitulo: '${r.codigo} · ${r.nombre}',
        error: error,
        boton: BotonGrande(
          texto: 'Usar $_cantidad · ${dinero(r.precioVenta * _cantidad)}',
          icono: Icons.check,
          ocupado: ocupado,
          alPulsar: _usar,
        ),
        children: [
          Text('Disponibles: $maximo · Precio unitario: ${dinero(r.precioVenta)}',
              style: const TextStyle(color: Paleta.textoSecundario)),
          const SizedBox(height: 12),
          SelectorCantidad(
            cantidad: _cantidad,
            alRestar: () => setState(() => _cantidad = _cantidad > 1 ? _cantidad - 1 : 1),
            alSumar: () =>
                setState(() => _cantidad = _cantidad < maximo ? _cantidad + 1 : maximo),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _elegido = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('ELEGIR OTRO REPUESTO'),
          ),
        ],
      );
    }

    // Paso 1: buscador + lista del inventario.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ELEGIR REPUESTO', style: rajdhani(size: 24)),
          const SizedBox(height: 12),
          TextField(
            controller: _busqueda,
            onChanged: _buscar,
            decoration: decoracionCampo('Buscar por nombre o código',
                icono: Icons.search),
          ),
          const SizedBox(height: 12),
          // Altura acotada: la hoja no puede tener una lista de alto infinito.
          // Flexible: con el teclado abierto la lista se encoge en vez de
          // desbordar la hoja.
          Flexible(
            child: SizedBox(
              height: alto * 0.45,
              child: VistaStream<List<Repuesto>>(
                stream: _stream(),
                builder: (context, lista) {
                  if (lista.isEmpty) {
                    return const EstadoVacio(
                        icono: Icons.inventory_2_outlined, titulo: 'Sin resultados');
                  }
                  return ListView.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final rep = lista[i];
                      final agotado = rep.existencias <= 0;
                      final bajo = rep.existencias <= rep.stockMinimo;
                      return ListTile(
                        enabled: !agotado,
                        minVerticalPadding: 10,
                        onTap: agotado ? null : () => _elegir(rep),
                        title: Text(rep.nombre),
                        subtitle: Text('${rep.codigo} · ${dinero(rep.precioVenta)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${rep.existencias}',
                                style: rajdhani(
                                    size: 22,
                                    color: bajo ? Paleta.peligro : Paleta.exito)),
                            Text(agotado ? 'AGOTADO' : 'EN STOCK',
                                style: rajdhani(
                                    size: 10,
                                    color: bajo ? Paleta.peligro : Paleta.textoSecundario)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAGO (abono). Métodos: Efectivo / Transferencia. Botón "saldo completo".
// =============================================================================
class HojaPago extends StatefulWidget {
  final OrdenResumen orden;
  const HojaPago({super.key, required this.orden});

  @override
  State<HojaPago> createState() => _HojaPagoState();
}

class _HojaPagoState extends State<HojaPago> with AccionHojaMixin {
  static const _metodos = ['Efectivo', 'Transferencia'];
  final _form = GlobalKey<FormState>();
  final _monto = TextEditingController();
  String _metodo = _metodos.first;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    guardar(() async {
      await repo.registrarPago(widget.orden.id, leerDinero(_monto.text)!,
          metodo: _metodo);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final saldo = widget.orden.saldo;
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: 'Registrar pago',
        subtitulo: 'Orden #${widget.orden.id} · saldo ${dinero(saldo)}',
        error: error,
        boton: BotonGrande(
            texto: 'Registrar pago', icono: Icons.payments_outlined,
            ocupado: ocupado, alPulsar: _guardar),
        children: [
          TextFormField(
            controller: _monto,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: rajdhani(size: 28, color: Paleta.primario),
            decoration: decoracionCampo('Monto', sufijo: kMoneda),
            validator: (v) {
              final n = leerDinero(v ?? '');
              if (n == null || n <= 0) return 'Escribe un monto mayor que cero';
              if (n > saldo + 0.009) return 'Supera el saldo (${dinero(saldo)})';
              return null;
            },
          ),
          const SizedBox(height: 8),
          // Rellena el monto con todo lo que falta por pagar.
          OutlinedButton.icon(
            onPressed: () => setState(() => _monto.text = saldo.toStringAsFixed(2)),
            icon: const Icon(Icons.done_all),
            label: Text('SALDO COMPLETO · ${dinero(saldo)}'),
          ),
          const SizedBox(height: 16),
          TituloSeccion('Método'),
          Row(
            children: [
              for (final m in _metodos) ...[
                Expanded(
                  child: ChoiceChip(
                    label: Text(m),
                    avatar: Icon(m == 'Efectivo'
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined),
                    selected: _metodo == m,
                    onSelected: (_) => setState(() => _metodo = m),
                  ),
                ),
                if (m != _metodos.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CAMBIAR MECÁNICO
// =============================================================================
class HojaCambiarMecanico extends StatefulWidget {
  final OrdenResumen orden;
  const HojaCambiarMecanico({super.key, required this.orden});

  @override
  State<HojaCambiarMecanico> createState() => _HojaCambiarMecanicoState();
}

class _HojaCambiarMecanicoState extends State<HojaCambiarMecanico>
    with AccionHojaMixin {
  late int _mecanicoId = widget.orden.mecanicoId;

  @override
  Widget build(BuildContext context) {
    return CuerpoHoja(
      titulo: 'Asignar mecánico',
      subtitulo: 'Orden #${widget.orden.id} · ${widget.orden.matricula}',
      error: error,
      boton: BotonGrande(
        texto: 'Asignar',
        icono: Icons.engineering,
        ocupado: ocupado,
        alPulsar: _mecanicoId == widget.orden.mecanicoId
            ? null // no hay cambio que guardar
            : () {
                final repo = TallerScope.of(context);
                guardar(() async {
                  await repo.actualizarOrden(widget.orden.id, mecanicoId: _mecanicoId);
                  return true;
                });
              },
      ),
      children: [
        SelectorMecanico(
          seleccionado: _mecanicoId,
          alSeleccionar: (id) => setState(() => _mecanicoId = id),
        ),
      ],
    );
  }
}
