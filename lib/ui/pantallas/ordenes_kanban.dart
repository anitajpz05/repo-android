// =============================================================================
// ordenes_kanban.dart
// PANTALLA ESTRELLA: las órdenes abiertas como un TABLERO KANBAN.
//  - 4 columnas (Recibida / Diagnóstico / Reparación / Lista) que se
//    recorren deslizando a los lados (PageView con viewportFraction 0.86:
//    se ve un trozo de la columna siguiente, invitando a deslizar).
//  - Selector superior de columnas con el conteo de cada estado: un toque
//    salta a esa columna (filtro por estado) y además indica dónde estás.
//  - Filtro "Mis órdenes" por mecánico (chips) y búsqueda en el AppBar.
//  - Cada tarjeta tiene un botón grande "→ siguiente estado".
//  - Botón "Histórico" para ver entregadas/canceladas en lista.
// =============================================================================
import 'package:flutter/material.dart';

import '../../data/base_datos.dart';
import '../../data/modelos.dart';
import '../../data/taller_scope.dart';
import '../tema.dart';
import '../widgets/acciones_orden.dart';
import '../widgets/basicos.dart';
import '../widgets/tarjetas_orden.dart';
import 'detalle_orden.dart';
import 'historial_ordenes.dart';
import 'nueva_orden.dart';

class PantallaOrdenes extends StatefulWidget {
  final Widget menu;
  const PantallaOrdenes({super.key, required this.menu});

  @override
  State<PantallaOrdenes> createState() => _PantallaOrdenesState();
}

class _PantallaOrdenesState extends State<PantallaOrdenes> {
  late final repo = TallerScope.of(context);
  late final Stream<List<Mecanico>> _mecanicos = repo.watchMecanicos(soloActivos: true);

  // Controla qué columna (página) se ve. viewportFraction < 1 deja asomar la
  // columna siguiente.
  final _paginas = PageController(viewportFraction: 0.86);
  final _busquedaCtrl = TextEditingController();

  int _columna = 0; // columna visible (para resaltar el selector)
  int? _mecanicoId; // null = todos los mecánicos
  bool _buscando = false; // el AppBar muestra el campo de búsqueda

  // Stream de órdenes abiertas con los filtros actuales. Se pone a null cuando
  // cambia un filtro y se vuelve a crear en el siguiente build.
  Stream<List<OrdenResumen>>? _ordenes;

  Stream<List<OrdenResumen>> _stream() => _ordenes ??= repo.watchOrdenes(
        estados: EstadoOrdenX.abiertos,
        mecanicoId: _mecanicoId,
        busqueda: _busquedaCtrl.text,
      );

  @override
  void dispose() {
    _paginas.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _filtrarMecanico(int? id) => setState(() {
        _mecanicoId = id;
        _ordenes = null; // fuerza a recrear el Stream con el nuevo filtro
      });

  void _alternarBusqueda() => setState(() {
        _buscando = !_buscando;
        if (!_buscando && _busquedaCtrl.text.isNotEmpty) {
          _busquedaCtrl.clear();
          _ordenes = null;
        }
      });

  void _irAColumna(int i) => _paginas.animateToPage(i,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  void _abrirDetalle(OrdenResumen o) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantallaDetalleOrden(ordenId: o.id)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.menu,
      appBar: AppBar(
        title: _buscando
            ? TextField(
                controller: _busquedaCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 17),
                decoration: const InputDecoration(
                  hintText: 'Matrícula, cliente o problema…',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() => _ordenes = null),
              )
            : const Text('ÓRDENES'),
        actions: [
          IconButton(
            tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
            icon: Icon(_buscando ? Icons.close : Icons.search),
            onPressed: _alternarBusqueda,
          ),
          IconButton(
            tooltip: 'Histórico (entregadas y canceladas)',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PantallaHistorialOrdenes())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirNuevaOrden(context),
        icon: const Icon(Icons.add),
        label: const Text('NUEVA ORDEN'),
      ),
      body: Column(
        children: [
          _filtroMecanicos(),
          Expanded(
            child: VistaStream<List<OrdenResumen>>(
              stream: _stream(),
              builder: (context, ordenes) => _tablero(ordenes),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de chips: TODOS + un chip por mecánico activo ("Mis órdenes").
  Widget _filtroMecanicos() {
    return SizedBox(
      height: 52,
      child: VistaStream<List<Mecanico>>(
        stream: _mecanicos,
        builder: (context, mecanicos) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8, left: 4),
                child: Text('MIS ÓRDENES',
                    style: rajdhani(size: 12, color: Paleta.textoSecundario,
                        espaciado: 2)),
              ),
            ),
            _chip('Todos', _mecanicoId == null, () => _filtrarMecanico(null)),
            for (final m in mecanicos)
              _chip(m.nombre, _mecanicoId == m.id, () => _filtrarMecanico(m.id)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String texto, bool elegido, VoidCallback alTocar) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(texto),
          selected: elegido,
          onSelected: (_) => alTocar(),
        ),
      );

  /// Selector de columnas + PageView con las 4 columnas.
  Widget _tablero(List<OrdenResumen> ordenes) {
    final estados = EstadoOrdenX.abiertos;
    // Agrupa las órdenes por estado en un solo recorrido.
    final porEstado = {for (final e in estados) e: <OrdenResumen>[]};
    for (final o in ordenes) {
      porEstado[o.estado]?.add(o);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              for (var i = 0; i < estados.length; i++)
                Expanded(
                  child: _PestanaColumna(
                    estado: estados[i],
                    cantidad: porEstado[estados[i]]!.length,
                    activa: i == _columna,
                    alTocar: () => _irAColumna(i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _paginas,
            padEnds: false, // la primera columna pegada a la izquierda
            onPageChanged: (i) => setState(() => _columna = i),
            children: [
              for (final e in estados)
                _ColumnaKanban(
                  estado: e,
                  ordenes: porEstado[e]!,
                  alAbrir: _abrirDetalle,
                  alAvanzar: (o) => avanzarOrden(context, o),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botón del selector superior: nombre corto del estado + conteo.
class _PestanaColumna extends StatelessWidget {
  final EstadoOrden estado;
  final int cantidad;
  final bool activa;
  final VoidCallback alTocar;

  const _PestanaColumna({
    required this.estado,
    required this.cantidad,
    required this.activa,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: activa ? c.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(bottom: BorderSide(color: activa ? c : Paleta.borde,
              width: 3)),
        ),
        child: Column(
          children: [
            Text('$cantidad', style: rajdhani(size: 22, color: c, altura: 1)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(etiquetaCorta(estado),
                  style: rajdhani(size: 11,
                      color: activa ? c : Paleta.textoSecundario)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una columna del Kanban: encabezado de color y lista de tarjetas.
class _ColumnaKanban extends StatelessWidget {
  final EstadoOrden estado;
  final List<OrdenResumen> ordenes;
  final ValueChanged<OrdenResumen> alAbrir;
  final ValueChanged<OrdenResumen> alAvanzar;

  const _ColumnaKanban({
    required this.estado,
    required this.ordenes,
    required this.alAbrir,
    required this.alAvanzar,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Container(
      margin: const EdgeInsets.only(left: 12, bottom: 12),
      clipBehavior: Clip.antiAlias, // recorta la franja superior a las esquinas
      decoration: BoxDecoration(
        color: const Color(0xFF17171A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.borde),
      ),
      child: Column(
        children: [
          // Encabezado de la columna
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c, width: 4)),
            ),
            child: Row(
              children: [
                Icon(iconoEstado(estado), color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(estado.etiqueta.toUpperCase(),
                      style: rajdhani(size: 18, color: c)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(12)),
                  child: Text('${ordenes.length}',
                      style: rajdhani(size: 16, color: Paleta.sobrePrimario)),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ordenes.isEmpty
                ? EstadoVacio(
                    icono: iconoEstado(estado),
                    titulo: 'Sin órdenes',
                    detalle: estado == EstadoOrden.recibida
                        ? 'Pulsa NUEVA ORDEN para registrar un vehículo'
                        : null,
                  )
                : ListView.builder(
                    // Espacio inferior para que el FAB no tape la última tarjeta
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 88),
                    itemCount: ordenes.length,
                    itemBuilder: (context, i) {
                      final o = ordenes[i];
                      return TarjetaKanban(
                        // La key por id ayuda a Flutter a conservar cada
                        // tarjeta cuando la lista cambia de orden.
                        key: ValueKey(o.id),
                        orden: o,
                        alTocar: () => alAbrir(o),
                        alAvanzar: () => alAvanzar(o),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
