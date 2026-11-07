// =============================================================================
// nueva_orden.dart
// Registro de la llegada de un vehículo (nueva orden de servicio). Se abre a
// pantalla completa como "diálogo" (fullscreenDialog: true -> aparece desde
// abajo y el AppBar muestra una X en vez de la flecha).
// Flujo en 3 pasos, de arriba abajo:
//   1. VEHÍCULO: buscar por matrícula. Si no existe, "Registrar cliente y
//      vehículo" abre una hoja inferior SIN salir de esta pantalla.
//   2. MECÁNICO: tarjetas con la carga actual de cada uno.
//   3. PROBLEMA y KILOMETRAJE (precargado con el último del vehículo).
// Al guardar se crea la orden y se REEMPLAZA esta pantalla por su detalle.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../../utils/formato.dart';
import '../tema.dart';
import '../widgets/basicos.dart';
import '../widgets/estado_orden.dart';
import '../widgets/formularios.dart';
import '../widgets/hojas.dart';
import '../widgets/selector_mecanico.dart';
import 'detalle_orden.dart';

/// Abre la pantalla de nueva orden. Si se pasa [vehiculoId] (desde la ficha
/// de un cliente o vehículo) ese vehículo ya viene elegido.
Future<void> abrirNuevaOrden(BuildContext context, {int? vehiculoId}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => PantallaNuevaOrden(vehiculoId: vehiculoId),
  ));
}

class PantallaNuevaOrden extends StatefulWidget {
  final int? vehiculoId;
  const PantallaNuevaOrden({super.key, this.vehiculoId});

  @override
  State<PantallaNuevaOrden> createState() => _PantallaNuevaOrdenState();
}

class _PantallaNuevaOrdenState extends State<PantallaNuevaOrden> {
  late final repo = TallerScope.of(context);

  final _form = GlobalKey<FormState>();
  final _busqueda = TextEditingController();
  final _problema = TextEditingController();
  final _km = TextEditingController();

  Stream<List<VehiculoConCliente>>? _vehiculos; // se recrea al buscar
  VehiculoConCliente? _elegido;
  int? _mecanicoId;
  bool _guardando = false;
  String? _error;
  bool _precargado = false;

  /// didChangeDependencies se ejecuta justo después de initState y SÍ
  /// permite leer InheritedWidgets (TallerScope). Se usa una bandera para
  /// precargar el vehículo solo la primera vez.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.vehiculoId;
    if (!_precargado && id != null) {
      _precargado = true;
      _cargarVehiculo(id);
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _problema.dispose();
    _km.dispose();
    super.dispose();
  }

  Stream<List<VehiculoConCliente>> _stream() =>
      _vehiculos ??= repo.watchVehiculos(busqueda: _busqueda.text);

  /// Busca el vehículo y el nombre de su dueño y lo deja elegido.
  Future<void> _cargarVehiculo(int id) async {
    final v = await repo.watchVehiculo(id).first;
    if (v == null) return;
    final c = await repo.watchCliente(v.clienteId).first;
    if (!mounted) return; // la pantalla pudo cerrarse mientras se esperaba
    _elegir(VehiculoConCliente(v, c?.nombre ?? ''));
  }

  void _elegir(VehiculoConCliente vc) => setState(() {
        _elegido = vc;
        _km.text = '${vc.vehiculo.kilometraje}'; // km precargado
        _error = null;
      });

  Future<void> _registrarNuevo() async {
    final vehiculoId = await mostrarHoja<int>(
        context, HojaClienteVehiculo(matriculaInicial: _busqueda.text.trim()));
    if (vehiculoId != null && mounted) await _cargarVehiculo(vehiculoId);
  }

  Future<void> _guardar() async {
    final v = _elegido;
    if (v == null) {
      setState(() => _error = 'Elige o registra el vehículo.');
      return;
    }
    if (_mecanicoId == null) {
      setState(() => _error = 'Asigna un mecánico.');
      return;
    }
    if (!_form.currentState!.validate()) return;
    final km = leerEntero(_km.text);
    if (km == null) return; // ya lo marca el validador del campo

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await repo.crearOrden(
        vehiculoId: v.vehiculo.id,
        mecanicoId: _mecanicoId!,
        problema: _problema.text,
        kilometraje: km,
      );
      if (!mounted) return;
      // pushReplacement: al volver desde el detalle no se regresa a este
      // formulario, sino a la pantalla desde la que se abrió.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => PantallaDetalleOrden(ordenId: id)));
    } on ReglaNegocioException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo crear la orden: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NUEVA ORDEN')),
      // El botón principal queda fijo abajo, siempre a mano.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BotonGrande(
            texto: 'Abrir orden',
            icono: Icons.assignment_turned_in_outlined,
            ocupado: _guardando,
            alPulsar: _guardar,
          ),
        ),
      ),
      // SingleChildScrollView + Column (y no ListView): ListView construye solo
      // lo visible, y Form.validate() ignoraría los campos no construidos.
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TituloSeccion('1 · Vehículo', color: Paleta.primario),
              if (_elegido != null) _vehiculoElegido(_elegido!) else ..._buscador(),
              const TituloSeccion('2 · Mecánico', color: Paleta.primario),
              SelectorMecanico(
                seleccionado: _mecanicoId,
                alSeleccionar: (id) => setState(() {
                  _mecanicoId = id;
                  _error = null;
                }),
              ),
              const TituloSeccion('3 · Problema y kilometraje', color: Paleta.primario),
              TextFormField(
                controller: _problema,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: decoracionCampo('Problema que reporta el cliente',
                    icono: Icons.report_problem_outlined),
                validator: validarObligatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _km,
                keyboardType: TextInputType.number,
                style: rajdhani(size: 22),
                decoration: decoracionCampo(
                  'Kilometraje de entrada',
                  icono: Icons.speed,
                  sufijo: 'km',
                  ayuda: _elegido == null
                      ? null
                      : 'Último registrado: ${numero(_elegido!.vehiculo.kilometraje)} km',
                ),
                validator: validarEnteroNoNegativo,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                CajaError(_error!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta del vehículo ya elegido, con botón para cambiarlo.
  Widget _vehiculoElegido(VehiculoConCliente vc) {
    final v = vc.vehiculo;
    return TarjetaGarage(
      colorBorde: Paleta.primario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible + FittedBox: una matrícula larga se reduce en vez de
              // desbordar la fila (pantallas estrechas).
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PlacaMatricula(v.matricula, tamano: 30),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _elegido = null),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('CAMBIAR'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${v.marca} ${v.modelo} (${v.anio})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text('Dueño: ${vc.clienteNombre}',
              style: const TextStyle(color: Paleta.textoSecundario)),
        ],
      ),
    );
  }

  /// Buscador por matrícula + resultados + botón de registrar.
  List<Widget> _buscador() {
    final texto = _busqueda.text.trim();
    return [
      TextField(
        controller: _busqueda,
        textCapitalization: TextCapitalization.characters,
        style: rajdhani(size: 22, espaciado: 3),
        decoration: decoracionCampo('Matrícula, marca o dueño', icono: Icons.search),
        onChanged: (_) => setState(() => _vehiculos = null),
      ),
      const SizedBox(height: 10),
      VistaStream<List<VehiculoConCliente>>(
        stream: _stream(),
        builder: (context, lista) {
          if (lista.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                texto.isEmpty
                    ? 'Todavía no hay vehículos registrados.'
                    : 'No existe ningún vehículo con «$texto».',
                style: const TextStyle(color: Paleta.textoSecundario),
              ),
            );
          }
          // Se muestran como máximo 6 resultados para no alargar el paso 1.
          final visibles = lista.take(6).toList();
          return Column(
            children: [
              for (final vc in visibles)
                TarjetaGarage(
                  key: ValueKey(vc.vehiculo.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  alTocar: () => _elegir(vc),
                  child: Row(
                    children: [
                      PlacaMatricula(vc.vehiculo.matricula, tamano: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${vc.vehiculo.marca} ${vc.vehiculo.modelo}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(vc.clienteNombre,
                                style: const TextStyle(
                                    color: Paleta.textoSecundario, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              if (lista.length > visibles.length)
                Text('… y ${lista.length - visibles.length} más: escribe más letras',
                    style: const TextStyle(color: Paleta.textoSecundario)),
            ],
          );
        },
      ),
      const SizedBox(height: 8),
      BotonGrande(
        texto: 'Registrar cliente y vehículo',
        icono: Icons.person_add_alt_1_outlined,
        contorno: true,
        color: Paleta.secundario,
        alPulsar: _registrarNuevo,
      ),
    ];
  }
}
