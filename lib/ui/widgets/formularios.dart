// =============================================================================
// formularios.dart
// Formularios de la app, todos como HOJAS inferiores (se abren con
// mostrarHoja). Cada uno es un StatefulWidget porque guarda sus
// TextEditingController, y usa AccionHojaMixin para el "guardando…" y los
// errores. Al guardar bien, la hoja se cierra devolviendo un resultado:
//  - HojaCliente           -> int (id del cliente)
//  - HojaVehiculo          -> int (id del vehículo)
//  - HojaClienteVehiculo   -> int (id del vehículo nuevo)  [nueva orden]
//  - HojaRepuesto, HojaReabastecer, HojaMecanico, HojaTexto -> bool
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import 'basicos.dart';
import 'hojas.dart';

// -----------------------------------------------------------------------------
// Validadores reutilizables (devuelven el texto del error o null si es válido)
// -----------------------------------------------------------------------------
String? validarObligatorio(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

String? validarTelefono(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Campo obligatorio';
  if (!RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(t)) {
    return 'Solo dígitos, mínimo 6';
  }
  return null;
}

String? validarEnteroNoNegativo(String? v) {
  final n = leerEntero(v ?? '');
  if (n == null) return 'Número inválido';
  if (n < 0) return 'No puede ser negativo';
  return null;
}

String? validarDinero(String? v) {
  final n = leerDinero(v ?? '');
  if (n == null) return 'Importe inválido';
  if (n < 0) return 'No puede ser negativo';
  return null;
}

String? validarAnio(String? v) {
  final n = int.tryParse(v?.trim() ?? '');
  final max = DateTime.now().year + 1;
  if (n == null || n < 1900 || n > max) return 'Entre 1900 y $max';
  return null;
}

/// Separación vertical estándar entre campos.
const _sep = SizedBox(height: 12);

// =============================================================================
// CLIENTE (crear / editar)
// =============================================================================
class HojaCliente extends StatefulWidget {
  final Cliente? cliente; // null = nuevo
  const HojaCliente({super.key, this.cliente});

  @override
  State<HojaCliente> createState() => _HojaClienteState();
}

class _HojaClienteState extends State<HojaCliente> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _direccion = TextEditingController(text: widget.cliente?.direccion);

  @override
  void dispose() {
    // Los controladores reservan recursos: se liberan al cerrar la hoja.
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    final c = widget.cliente;
    guardar(() async {
      if (c == null) {
        return repo.crearCliente(
            nombre: _nombre.text, telefono: _telefono.text, direccion: _direccion.text);
      }
      await repo.actualizarCliente(c.id,
          nombre: _nombre.text, telefono: _telefono.text, direccion: _direccion.text);
      return c.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
        error: error,
        boton: BotonGrande(
            texto: 'Guardar cliente', icono: Icons.save, ocupado: ocupado,
                alPulsar: _guardar),
        children: [
          TextFormField(
            controller: _nombre,
            autofocus: widget.cliente == null,
            textCapitalization: TextCapitalization.words,
            decoration: decoracionCampo('Nombre', icono: Icons.person_outline),
            validator: validarObligatorio,
          ),
          _sep,
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: decoracionCampo('Teléfono', icono: Icons.phone_outlined),
            validator: validarTelefono,
          ),
          _sep,
          TextFormField(
            controller: _direccion,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoracionCampo('Dirección (opcional)',
                icono: Icons.home_outlined),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Campos de vehículo reutilizables (HojaVehiculo y HojaClienteVehiculo)
// =============================================================================
class _ControlesVehiculo {
  final matricula = TextEditingController();
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final anio = TextEditingController();
  final km = TextEditingController(text: '0');

  void cargar(Vehiculo v) {
    matricula.text = v.matricula;
    marca.text = v.marca;
    modelo.text = v.modelo;
    anio.text = '${v.anio}';
    km.text = '${v.kilometraje}';
  }

  void dispose() {
    for (final c in [matricula, marca, modelo, anio, km]) {
      c.dispose();
    }
  }

  List<Widget> campos() => [
        TextFormField(
          controller: matricula,
          textCapitalization: TextCapitalization.characters,
          style: rajdhani(size: 22, espaciado: 3),
          decoration: decoracionCampo('Matrícula', icono: Icons.confirmation_number_outlined),
          validator: validarObligatorio,
        ),
        _sep,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: marca,
                textCapitalization: TextCapitalization.words,
                decoration: decoracionCampo('Marca'),
                validator: validarObligatorio,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: modelo,
                textCapitalization: TextCapitalization.words,
                decoration: decoracionCampo('Modelo'),
                validator: validarObligatorio,
              ),
            ),
          ],
        ),
        _sep,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: anio,
                keyboardType: TextInputType.number,
                decoration: decoracionCampo('Año'),
                validator: validarAnio,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: km,
                keyboardType: TextInputType.number,
                decoration: decoracionCampo('Kilometraje', sufijo: 'km'),
                validator: validarEnteroNoNegativo,
              ),
            ),
          ],
        ),
      ];
}

// =============================================================================
// VEHÍCULO (crear / editar) de un cliente concreto
// =============================================================================
class HojaVehiculo extends StatefulWidget {
  final int clienteId;
  final Vehiculo? vehiculo; // null = nuevo
  const HojaVehiculo({super.key, required this.clienteId, this.vehiculo});

  @override
  State<HojaVehiculo> createState() => _HojaVehiculoState();
}

class _HojaVehiculoState extends State<HojaVehiculo> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  final _c = _ControlesVehiculo();

  @override
  void initState() {
    super.initState();
    // initState es el lugar para inicializar estado que NO depende de
    // InheritedWidgets (aquí no se usa TallerScope).
    final v = widget.vehiculo;
    if (v != null) _c.cargar(v);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    final v = widget.vehiculo;
    final anio = int.parse(_c.anio.text.trim());
    final km = leerEntero(_c.km.text)!;
    guardar(() async {
      if (v == null) {
        return repo.crearVehiculo(
            clienteId: widget.clienteId,
            matricula: _c.matricula.text,
            marca: _c.marca.text,
            modelo: _c.modelo.text,
            anio: anio,
            kilometraje: km);
      }
      await repo.actualizarVehiculo(v.id,
          matricula: _c.matricula.text,
          marca: _c.marca.text,
          modelo: _c.modelo.text,
          anio: anio,
          kilometraje: km);
      return v.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: widget.vehiculo == null ? 'Nuevo vehículo' : 'Editar vehículo',
        error: error,
        boton: BotonGrande(
            texto: 'Guardar vehículo', icono: Icons.save, ocupado: ocupado,
                alPulsar: _guardar),
        children: _c.campos(),
      ),
    );
  }
}

// =============================================================================
// CLIENTE + VEHÍCULO en un solo paso (desde "Nueva orden")
// Permite elegir un cliente ya registrado o crear uno nuevo, y a la vez
// registrar el vehículo. Devuelve el id del vehículo creado.
// =============================================================================
class HojaClienteVehiculo extends StatefulWidget {
  final String matriculaInicial;
  const HojaClienteVehiculo({super.key, this.matriculaInicial = ''});

  @override
  State<HojaClienteVehiculo> createState() => _HojaClienteVehiculoState();
}

class _HojaClienteVehiculoState extends State<HojaClienteVehiculo>
    with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _v = _ControlesVehiculo();

  bool _clienteNuevo = true;
  int? _clienteExistente;

  // Lista de clientes para el modo "cliente existente" (se crea una vez).
  late final Stream<List<ClienteResumen>> _clientes =
      TallerScope.of(context).watchClientes();

  @override
  void initState() {
    super.initState();
    _v.matricula.text = widget.matriculaInicial.toUpperCase();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _v.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    if (!_clienteNuevo && _clienteExistente == null) {
      setState(() => error = 'Elige el cliente dueño del vehículo.');
      return;
    }
    final repo = TallerScope.of(context);
    final anio = int.parse(_v.anio.text.trim());
    final km = leerEntero(_v.km.text)!;

    guardar(() async {
      int? clienteCreado; // solo si se creó en ESTE intento
      final int clienteId;
      if (_clienteNuevo) {
        clienteCreado = await repo.crearCliente(
            nombre: _nombre.text, telefono: _telefono.text, direccion: _direccion.text);
        clienteId = clienteCreado;
      } else {
        clienteId = _clienteExistente!;
      }
      try {
        return await repo.crearVehiculo(
            clienteId: clienteId,
            matricula: _v.matricula.text,
            marca: _v.marca.text,
            modelo: _v.modelo.text,
            anio: anio,
            kilometraje: km);
      } catch (_) {
        // Si el vehículo falla (p. ej. matrícula repetida) se deshace el
        // cliente recién creado para no dejar un cliente "huérfano".
        if (clienteCreado != null) await repo.eliminarCliente(clienteCreado);
        rethrow;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: 'Registrar cliente y vehículo',
        subtitulo: 'Se usará en la nueva orden',
        error: error,
        boton: BotonGrande(
            texto: 'Registrar y usar', icono: Icons.save, ocupado: ocupado,
                alPulsar: _guardar),
        children: [
          TituloSeccion('Dueño'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Cliente nuevo'),
                selected: _clienteNuevo,
                onSelected: (_) => setState(() => _clienteNuevo = true),
              ),
              ChoiceChip(
                label: const Text('Cliente ya registrado'),
                selected: !_clienteNuevo,
                onSelected: (_) => setState(() => _clienteNuevo = false),
              ),
            ],
          ),
          _sep,
          if (_clienteNuevo) ...[
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: decoracionCampo('Nombre', icono: Icons.person_outline),
              validator: validarObligatorio,
            ),
            _sep,
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: decoracionCampo('Teléfono', icono: Icons.phone_outlined),
              validator: validarTelefono,
            ),
            _sep,
            TextFormField(
              controller: _direccion,
              decoration:
                  decoracionCampo('Dirección (opcional)', icono: Icons.home_outlined),
            ),
          ] else
            VistaStream<List<ClienteResumen>>(
              stream: _clientes,
              builder: (context, lista) => InputDecorator(
                decoration: decoracionCampo('Cliente', icono: Icons.person_search),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    isDense: true,
                    value: _clienteExistente,
                    hint: const Text('Elegir…'),
                    dropdownColor: Paleta.superficieAlta,
                    items: [
                      for (final c in lista)
                        DropdownMenuItem<int>(
                          value: c.cliente.id,
                          child: Text('${c.cliente.nombre} · ${c.cliente.telefono}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) => setState(() => _clienteExistente = id),
                  ),
                ),
              ),
            ),
          TituloSeccion('Vehículo'),
          ..._v.campos(),
        ],
      ),
    );
  }
}

// =============================================================================
// REPUESTO (crear / editar)
// =============================================================================
class HojaRepuesto extends StatefulWidget {
  final Repuesto? repuesto;
  const HojaRepuesto({super.key, this.repuesto});

  @override
  State<HojaRepuesto> createState() => _HojaRepuestoState();
}

class _HojaRepuestoState extends State<HojaRepuesto> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.repuesto?.codigo);
  late final _nombre = TextEditingController(text: widget.repuesto?.nombre);
  late final _precio = TextEditingController(
      text: widget.repuesto == null ? '' : widget.repuesto!.precioVenta.toStringAsFixed(2));
  late final _existencias =
      TextEditingController(text: '${widget.repuesto?.existencias ?? 0}');
  late final _minimo =
      TextEditingController(text: '${widget.repuesto?.stockMinimo ?? 3}');

  @override
  void dispose() {
    for (final c in [_codigo, _nombre, _precio, _existencias, _minimo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final repo = TallerScope.of(context);
    guardar(() async {
      await repo.guardarRepuesto(
        id: widget.repuesto?.id,
        codigo: _codigo.text,
        nombre: _nombre.text,
        precioVenta: leerDinero(_precio.text)!,
        existencias: leerEntero(_existencias.text)!,
        stockMinimo: leerEntero(_minimo.text)!,
      );
      return true; // la hoja se abrió con mostrarHoja<bool>
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: widget.repuesto == null ? 'Nuevo repuesto' : 'Editar repuesto',
        error: error,
        boton: BotonGrande(
            texto: 'Guardar repuesto', icono: Icons.save, ocupado: ocupado,
                alPulsar: _guardar),
        children: [
          TextFormField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            style: rajdhani(size: 18, espaciado: 2),
            decoration: decoracionCampo('Código', icono: Icons.qr_code),
            validator: validarObligatorio,
          ),
          _sep,
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoracionCampo('Nombre', icono: Icons.inventory_2_outlined),
            validator: validarObligatorio,
          ),
          _sep,
          TextFormField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoracionCampo('Precio de venta', sufijo: kMoneda),
            validator: validarDinero,
          ),
          _sep,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _existencias,
                  keyboardType: TextInputType.number,
                  decoration: decoracionCampo('Existencias'),
                  validator: validarEnteroNoNegativo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _minimo,
                  keyboardType: TextInputType.number,
                  decoration: decoracionCampo('Stock mínimo',
                      ayuda: 'Aviso al llegar aquí'),
                  validator: validarEnteroNoNegativo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REABASTECER (entrada de mercancía)
// =============================================================================
class HojaReabastecer extends StatefulWidget {
  final Repuesto repuesto;
  const HojaReabastecer({super.key, required this.repuesto});

  @override
  State<HojaReabastecer> createState() => _HojaReabastecerState();
}

class _HojaReabastecerState extends State<HojaReabastecer> with AccionHojaMixin {
  int _cantidad = 1;

  void _sumar(int d) => setState(() => _cantidad = (_cantidad + d).clamp(1, 9999));

  @override
  Widget build(BuildContext context) {
    final r = widget.repuesto;
    return CuerpoHoja(
      titulo: 'Reabastecer',
      subtitulo: '${r.codigo} · ${r.nombre}\nHay ${r.existencias} (mínimo ${r.stockMinimo})',
      error: error,
      boton: BotonGrande(
        texto: 'Añadir $_cantidad unidad(es)',
        icono: Icons.add_box_outlined,
        ocupado: ocupado,
        alPulsar: () {
          final repo = TallerScope.of(context);
          guardar(() async {
            await repo.reabastecer(r.id, _cantidad);
            return true;
          });
        },
      ),
      children: [
        SelectorCantidad(
          cantidad: _cantidad,
          alRestar: () => _sumar(-1),
          alSumar: () => _sumar(1),
          atajos: const [5, 10, 20],
          alAtajo: (n) => setState(() => _cantidad = n),
        ),
      ],
    );
  }
}

/// Selector de cantidad con botones − / + grandes (más cómodo que teclear con
/// guantes) y atajos opcionales.
class SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final VoidCallback alRestar;
  final VoidCallback alSumar;
  final List<int> atajos;
  final ValueChanged<int>? alAtajo;

  const SelectorCantidad({
    super.key,
    required this.cantidad,
    required this.alRestar,
    required this.alSumar,
    this.atajos = const [],
    this.alAtajo,
  });

  @override
  Widget build(BuildContext context) {
    Widget boton(IconData i, VoidCallback f) => SizedBox(
          width: 64,
          height: 64,
          child: OutlinedButton(
            onPressed: f,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Icon(i, size: 30),
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            boton(Icons.remove, alRestar),
            Expanded(
              child: Text('$cantidad',
                  textAlign: TextAlign.center,
                  style: rajdhani(size: 48, color: Paleta.primario)),
            ),
            boton(Icons.add, alSumar),
          ],
        ),
        if (atajos.isNotEmpty && alAtajo != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in atajos)
                ActionChip(label: Text('$n'), onPressed: () => alAtajo!(n)),
            ],
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// MECÁNICO (crear / renombrar)
// =============================================================================
class HojaMecanico extends StatefulWidget {
  final Mecanico? mecanico;
  const HojaMecanico({super.key, this.mecanico});

  @override
  State<HojaMecanico> createState() => _HojaMecanicoState();
}

class _HojaMecanicoState extends State<HojaMecanico> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.mecanico?.nombre);

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final m = widget.mecanico;
    final repo = TallerScope.of(context);
    guardar(() async {
      await repo.guardarMecanico(
          id: m?.id, nombre: _nombre.text, activo: m?.activo ?? true);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: widget.mecanico == null ? 'Nuevo mecánico' : 'Renombrar mecánico',
        error: error,
        boton: BotonGrande(
            texto: 'Guardar', icono: Icons.save, ocupado: ocupado, alPulsar: _guardar),
        children: [
          TextFormField(
            controller: _nombre,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: decoracionCampo('Nombre', icono: Icons.engineering_outlined),
            validator: validarObligatorio,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Hoja genérica de UN texto (p. ej. editar el problema de una orden)
// =============================================================================
class HojaTexto extends StatefulWidget {
  final String titulo;
  final String etiqueta;
  final String inicial;
  final Future<void> Function(String texto) alGuardar;

  const HojaTexto({
    super.key,
    required this.titulo,
    required this.etiqueta,
    required this.inicial,
    required this.alGuardar,
  });

  @override
  State<HojaTexto> createState() => _HojaTextoState();
}

class _HojaTextoState extends State<HojaTexto> with AccionHojaMixin {
  final _form = GlobalKey<FormState>();
  late final _texto = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: CuerpoHoja(
        titulo: widget.titulo,
        error: error,
        boton: BotonGrande(
          texto: 'Guardar',
          icono: Icons.save,
          ocupado: ocupado,
          alPulsar: () {
            if (!_form.currentState!.validate()) return;
            guardar(() async {
              await widget.alGuardar(_texto.text);
              return true;
            });
          },
        ),
        children: [
          TextFormField(
            controller: _texto,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoracionCampo(widget.etiqueta),
            validator: validarObligatorio,
          ),
        ],
      ),
    );
  }
}
