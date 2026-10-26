import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/turno.dart';
import '../viewmodels/agenda_view_model.dart';
import '../viewmodels/salon_view_model.dart';
import '../viewmodels/tema_view_model.dart';
import '../viewmodels/turno_form_view_model.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    required this.salon,
    required this.temaVM,
    this.estilistaIdInicial,
  });

  final SalonViewModel salon;
  final TemaViewModel temaVM;
  final int? estilistaIdInicial;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late final AgendaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AgendaViewModel(widget.salon);
    if (widget.estilistaIdInicial != null) {
      _vm.filtrarEstilista(widget.estilistaIdInicial);
    }
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si venimos de la pestaña Estilistas con un ID, aplicamos el filtro
    if (widget.estilistaIdInicial != oldWidget.estilistaIdInicial) {
      _vm.filtrarEstilista(widget.estilistaIdInicial);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _abrirNuevoTurno() async {
    // Navegamos pasando la fecha actual seleccionada como dato inicial
    final resultado = await context.push<DateTime>(
      '/turno/nuevo',
      extra: DatosInicialesTurno(fecha: _vm.fecha),
    );

    // RF1: Si volvemos con un resultado (fecha del turno), mostramos SnackBar
    if (resultado != null && mounted) {
      _vm.seleccionarFecha(resultado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Turno guardado para el ${fechaParaAviso(resultado)}'),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () {
              // Podríamos navegar al detalle del turno recién creado
            },
          ),
        ),
      );
    }
  }

  Future<void> _abrirMenuRapido(Turno turno) async {
    if (!turno.estaProgramado) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '${widget.salon.clientePorId(turno.clienteId)?.nombre} · ${horaTexto(turno.inicio)}',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                subtitle: Text('${turno.serviciosTexto} · ${widget.salon.estilistaPorId(turno.estilistaId)?.nombre}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Marcar como completado'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await _confirmarAccion('Completar turno', '¿Marcar este turno como completado?');
                  if (confirm) widget.salon.completarTurno(turno.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: Theme.of(ctx).colorScheme.error),
                title: Text('Cancelar turno', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await _confirmarAccion(
                      '¿Cancelar este turno?',
                      'El horario de ${widget.salon.clientePorId(turno.clienteId)?.nombre} (${horaTexto(turno.inicio)} a ${horaTexto(turno.fin)}) quedará libre. Esta acción no se puede deshacer.',
                      esPeligro: true
                  );
                  if (confirm) widget.salon.cancelarTurno(turno.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmarAccion(String titulo, String mensaje, {bool esPeligro = false}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: esPeligro ? Theme.of(ctx).colorScheme.error : null,
            ),
            child: Text(esPeligro ? 'Cancelar turno' : 'Aceptar'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _vm.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (f != null) _vm.seleccionarFecha(f);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Escuchamos tanto a la agenda como al tema (para el botón de modo oscuro)
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, widget.temaVM]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.content_cut, color: theme.colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Turco', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              PopupMenuButton<ThemeMode>(
                icon: Icon(
                  widget.temaVM.modo == ThemeMode.system
                      ? Icons.brightness_auto
                      : widget.temaVM.modo == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onSelected: widget.temaVM.cambiar,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                  const PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
                  const PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _CabeceraFechas(vm: _vm, onElegirFecha: _elegirFecha),
              _TiraDias(vm: _vm),
              _ResumenDia(vm: _vm),
              _Filtros(vm: _vm, salon: widget.salon),
              Expanded(
                child: _ListaTurnos(
                  vm: _vm,
                  salon: widget.salon,
                  onLongPress: _abrirMenuRapido,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _abrirNuevoTurno,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo turno'),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS DE LA PANTALLA
// -----------------------------------------------------------------------------

class _CabeceraFechas extends StatelessWidget {
  const _CabeceraFechas({required this.vm, required this.onElegirFecha});
  final AgendaViewModel vm;
  final VoidCallback onElegirFecha;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => vm.cambiarSemana(-1),
          ),
          Expanded(
            child: Text(
              mesAnio(vm.fecha),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => vm.cambiarSemana(1),
          ),
          TextButton.icon(
            onPressed: onElegirFecha,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Elegir fecha'),
          ),
        ],
      ),
    );
  }
}

class _TiraDias extends StatelessWidget {
  const _TiraDias({required this.vm});
  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final dias = vm.diasSemana;
    final theme = Theme.of(context);

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final d = dias[index];
          final esSel = mismoDia(d, vm.fecha);
          final esDom = vm.esDomingo(d);

          return GestureDetector(
            onTap: () => vm.seleccionarFecha(d),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: esSel ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: esDom ? Border.all(color: Colors.transparent) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    diaSemanaCorto(d),
                    style: TextStyle(
                      color: esSel ? theme.colorScheme.onPrimary : (esDom ? theme.disabledColor : theme.colorScheme.onSurfaceVariant),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: esSel ? theme.colorScheme.onPrimary : (esDom ? theme.disabledColor : theme.colorScheme.onSurface),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResumenDia extends StatelessWidget {
  const _ResumenDia({required this.vm});
  final AgendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final r = vm.resumen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TarjetaResumen(titulo: 'Programados', valor: '${r.programados}'),
          const SizedBox(width: 8),
          _TarjetaResumen(titulo: 'Completados', valor: '${r.completados}'),
          const SizedBox(width: 8),
          _TarjetaResumen(titulo: 'Ingreso est.', valor: '\$ ${r.ingreso}'),
        ],
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.titulo, required this.valor});
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(titulo, style: theme.textTheme.bodyMedium, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.vm, required this.salon});
  final AgendaViewModel vm;
  final SalonViewModel salon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chips de estilistas
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Todos'),
                  selected: vm.estilistaId == null,
                  onSelected: (_) => vm.filtrarEstilista(null),
                ),
              ),
              ...salon.estilistas.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(e.nombreCorto),
                  selected: vm.estilistaId == e.id,
                  onSelected: (_) => vm.filtrarEstilista(e.id),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // SegmentedButton de estados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            segments: const [
              // AQUI ESTA LA MAGIA DEL FITTEDBOX
              ButtonSegment(value: 0, label: FittedBox(fit: BoxFit.scaleDown, child: Text('Todos')), icon: Icon(Icons.check)),
              ButtonSegment(value: 1, label: FittedBox(fit: BoxFit.scaleDown, child: Text('Program.'))),
              ButtonSegment(value: 2, label: FittedBox(fit: BoxFit.scaleDown, child: Text('Complet.'))),
              ButtonSegment(value: 3, label: FittedBox(fit: BoxFit.scaleDown, child: Text('Cancel.'))),
            ],
            selected: {
              vm.estado == null
                  ? 0
                  : vm.estado == EstadoTurno.programado
                  ? 1
                  : vm.estado == EstadoTurno.completado
                  ? 2
                  : 3
            },
            onSelectionChanged: (Set<int> newSelection) {
              final val = newSelection.first;
              vm.filtrarEstado(
                val == 0
                    ? null
                    : val == 1
                    ? EstadoTurno.programado
                    : val == 2
                    ? EstadoTurno.completado
                    : EstadoTurno.cancelado,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ListaTurnos extends StatelessWidget {
  const _ListaTurnos({
    required this.vm,
    required this.salon,
    required this.onLongPress,
  });

  final AgendaViewModel vm;
  final SalonViewModel salon;
  final Function(Turno) onLongPress;

  @override
  Widget build(BuildContext context) {
    final turnos = vm.turnosFiltrados;

    if (turnos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No hay turnos para este día', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Crea el primer turno con el botón de abajo\no cambia los filtros.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
      itemCount: turnos.length,
      itemBuilder: (context, index) {
        final t = turnos[index];
        final cliente = salon.clientePorId(t.clienteId);
        final estilista = salon.estilistaPorId(t.estilistaId);

        Color colorEstado;
        switch (t.estado) {
          case EstadoTurno.programado:
            colorEstado = Theme.of(context).colorScheme.tertiary;
          case EstadoTurno.completado:
            colorEstado = Theme.of(context).colorScheme.primary;
          case EstadoTurno.cancelado:
            colorEstado = Theme.of(context).colorScheme.error;
        }

        return GestureDetector(
          onLongPress: () => onLongPress(t),
          onTap: () => context.push('/turno/${t.id}'),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Barra de color lateral
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Horas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(horaTexto(t.inicio), style: Theme.of(context).textTheme.titleMedium),
                      Text(horaTexto(t.fin), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Datos del turno
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente?.nombre ?? 'Cliente', style: Theme.of(context).textTheme.titleMedium),
                        Text(t.serviciosTexto, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(estilista?.nombreCorto ?? 'Estilista', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Estado badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.estado.etiqueta,
                      style: TextStyle(color: colorEstado, fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 1, // <--- AQUI ESTA LA MAGIA
                      softWrap: false, // <--- Y AQUI
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}