import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/franja.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import '../viewmodels/salon_view_model.dart';
import '../viewmodels/turno_form_view_model.dart';
import 'clientes_screen.dart'; // Para reutilizar la hoja de crear cliente

class TurnoFormScreen extends StatefulWidget {
  const TurnoFormScreen({
    super.key,
    required this.salon,
    this.turnoEditar,
    this.iniciales,
  });

  final SalonViewModel salon;
  final Turno? turnoEditar;
  final DatosInicialesTurno? iniciales;

  @override
  State<TurnoFormScreen> createState() => _TurnoFormScreenState();
}

class _TurnoFormScreenState extends State<TurnoFormScreen> {
  late final TurnoFormViewModel _vm;
  final _formKey = GlobalKey<FormState>();
  final _notasCtrl = TextEditingController();

  // FocusNodes para mover el foco (Requisito RF3)
  final _clienteFocus = FocusNode();
  final _notasFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _vm = TurnoFormViewModel(
      widget.salon,
      turnoEditado: widget.turnoEditar,
      iniciales: widget.iniciales,
    );
    _notasCtrl.text = _vm.notas;

    // Escuchamos avisos del ViewModel (ej. si se limpió el estilista)
    _vm.addListener(_mostrarAvisos);
  }

  void _mostrarAvisos() {
    final aviso = _vm.consumirAviso();
    if (aviso != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_mostrarAvisos);
    _vm.dispose();
    _notasCtrl.dispose();
    _clienteFocus.dispose();
    _notasFocus.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Validamos los campos con el Form (C3)
    if (!_formKey.currentState!.validate()) {
      // Si falla, mandamos el foco al primer campo (C3)
      _clienteFocus.requestFocus();
      return;
    }

    try {
      final t = _vm.guardar();
      // RF1: Devolvemos la fecha del turno guardado con context.pop(valor)
      if (mounted) context.pop(t.inicio);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _vm.fechaReferencia,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday, // No domingos
    );
    if (f != null) _vm.seleccionarFecha(f);
  }

  void _abrirCrearCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ClienteFormSheet(salon: widget.salon),     ).then((_) {
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return PopScope(
          // Requisito RF3: Aviso si intenta salir con cambios sin guardar
          canPop: !_vm.tieneCambios,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final salir = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Descartar los cambios?'),
                content: const Text('Tienes cambios sin guardar en este turno. Si sales ahora se perderán.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir editando')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            ) ?? false;
            if (salir && context.mounted) context.pop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(_vm.esEdicion ? 'Editar turno' : 'Nuevo turno'),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCliente(theme),
                    const SizedBox(height: 16),
                    _buildServicios(theme),
                    const SizedBox(height: 16),
                    _buildEstilista(theme),
                    const SizedBox(height: 16),
                    _buildFechaHora(theme),
                    const SizedBox(height: 16),
                    _buildNotas(theme),
                    const SizedBox(height: 100), // Espacio para el resumen inferior
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomBar(theme),
          ),
        );
      },
    );
  }

  // --- SECCIONES DE LA PANTALLA ---

  Widget _buildCliente(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          focusNode: _clienteFocus,
          value: _vm.clienteId,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person),
            hintText: 'Selecciona un cliente',
          ),
          items: widget.salon.clientes.map((c) {
            return DropdownMenuItem(value: c.id, child: Text(c.nombre));
          }).toList(),
          onChanged: (id) {
            if (id != null) _vm.seleccionarCliente(id);
          },
          validator: (_) => _vm.validarCliente(),
        ),
        TextButton.icon(
          onPressed: _abrirCrearCliente,
          icon: const Icon(Icons.person_add),
          label: const Text('Crear cliente nuevo'),
        ),
      ],
    );
  }

  Widget _buildServicios(ThemeData theme) {
    final porCategoria = _vm.serviciosPorCategoria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Filtro de Público
        SegmentedButton<FiltroPublico>(
          segments: const [
            ButtonSegment(value: FiltroPublico.todos, label: Text('Todos')),
            ButtonSegment(value: FiltroPublico.mujeres, label: Text('Mujeres')),
            ButtonSegment(value: FiltroPublico.hombres, label: Text('Hombres')),
          ],
          selected: {_vm.filtroPublico},
          onSelectionChanged: (Set<FiltroPublico> newSelection) {
            _vm.cambiarFiltroPublico(newSelection.first);
          },
        ),
        const SizedBox(height: 12),

        // Lista de servicios por categoría
        ...porCategoria.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key.etiqueta.toUpperCase(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entry.value.map((s) {
                  final seleccionado = _vm.servicioIds.contains(s.id);
                  return FilterChip(
                    label: Text(s.nombre),
                    selected: seleccionado,
                    onSelected: (_) => _vm.alternarServicio(s.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
        if (_vm.validarServicios() != null)
          Text(_vm.validarServicios()!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
      ],
    );
  }

  Widget _buildEstilista(ThemeData theme) {
    final hayServicios = _vm.servicioIds.isNotEmpty;
    final hayEstilistas = _vm.estilistasDisponibles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estilista', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          isExpanded: true, // <--- ESTO EVITA EL OVERFLOW
          value: _vm.estilistaId,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.content_cut),
            // Textos más cortos para que quepan
            hintText: !hayServicios
                ? 'Elige servicios primero'
                : !hayEstilistas
                ? 'No hay estilista disponible'
                : 'Selecciona un estilista',
          ),
          items: _vm.estilistasDisponibles.map((e) {
            return DropdownMenuItem(
              value: e.id,
              child: Text(e.nombreCorto, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: !hayEstilistas ? null : (id) {
            if (id != null) _vm.seleccionarEstilista(id);
          },
          validator: (_) => _vm.validarEstilista(),
        ),
        // Mensaje de ayuda extra
        if (hayServicios && !hayEstilistas)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ninguno de nuestros profesionales realiza todos los servicios elegidos. Cambia la selección.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFechaHora(ThemeData theme) {
    final franjas = _vm.franjas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _elegirFecha,
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_month),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _vm.fecha != null ? fechaLarga(_vm.fecha!) : 'Selecciona una fecha',
              style: TextStyle(color: _vm.fecha == null ? theme.hintColor : null),
            ),
          ),
        ),
        if (_vm.validarFecha() != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_vm.validarFecha()!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
        const SizedBox(height: 16),

        const Text('Hora de inicio', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Cuadrícula de horas (RF3)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Para que no haya conflicto con el scroll padre
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: franjas.length,
          itemBuilder: (context, index) {
            final f = franjas[index];
            final seleccionada = _vm.hora == f.inicio;
            final disponible = f.disponible;

            return InkWell(
              onTap: disponible ? () => _vm.seleccionarHora(f.inicio) : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: seleccionada
                      ? theme.colorScheme.primary
                      : disponible
                      ? Colors.transparent
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: Border.all(
                    color: seleccionada
                        ? theme.colorScheme.primary
                        : disponible
                        ? theme.colorScheme.outline
                        : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  horaTexto(f.inicio),
                  style: TextStyle(
                    color: seleccionada
                        ? theme.colorScheme.onPrimary
                        : disponible
                        ? theme.colorScheme.onSurface
                        : theme.disabledColor,
                  ),
                ),
              ),
            );
          },
        ),
        if (_vm.validarHora() != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_vm.validarHora()!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildNotas(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notas (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notasCtrl,
          focusNode: _notasFocus,
          maxLines: 4,
          maxLength: SalonViewModel.maxNotas,
          decoration: const InputDecoration(
            hintText: 'Ej. Prefiere la máquina en el número 2 a los lados.',
            alignLabelWithHint: true,
          ),
          onChanged: _vm.actualizarNotas,
          // FocusNode para pasar al siguiente campo o cerrar teclado
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _notasFocus.unfocus(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resumen visible (Duración, Fin, Precio)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _datoResumen(Icons.access_time, duracionTexto(_vm.duracionMinutos)),
                  _datoResumen(Icons.flag, _vm.fin != null ? 'Fin ${horaTexto(_vm.fin!)}' : 'Fin --:--'),
                  _datoResumen(Icons.attach_money, precioTexto(_vm.precioTotal)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _guardar,
                    child: const Text('Guardar turno'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoResumen(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}