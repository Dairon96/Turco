import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../viewmodels/clientes_view_model.dart';
import '../viewmodels/salon_view_model.dart';
import '../viewmodels/turno_form_view_model.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.salon});
  final SalonViewModel salon;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late final ClientesViewModel _vm;
  final _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ClientesViewModel(widget.salon);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _abrirFormulario({Cliente? clienteEditar}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ClienteFormSheet(
        salon: widget.salon,
        clienteEditar: clienteEditar,
      ),
    );
  }

  void _abrirDetalle(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClienteDetalleSheet(
        salon: widget.salon,
        cliente: cliente,
        onEditar: () {
          Navigator.pop(ctx);
          _abrirFormulario(clienteEditar: cliente);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _abrirFormulario(),
            tooltip: 'Nuevo cliente',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final clientes = _vm.filtrados;

          return Column(
            children: [
              // 1. Buscador
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _busquedaCtrl,
                  onChanged: _vm.buscar,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busquedaCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        _vm.buscar('');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),

              // 2. Filtro por género
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<Genero?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Todos'), icon: Icon(Icons.check)),
                    ButtonSegment(value: Genero.mujer, label: Text('Mujeres')),
                    ButtonSegment(value: Genero.hombre, label: Text('Hombres')),
                  ],
                  selected: {_vm.genero},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (Set<Genero?> newSelection) {
                    _vm.filtrarGenero(newSelection.isEmpty ? null : newSelection.first);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // 3. Totales
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${_vm.total} clientes · ${_vm.totalMujeres} mujeres · ${_vm.totalHombres} hombres',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // 4. Lista (ListView.separated como pide el RF4)
              Expanded(
                child: clientes.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('No se encontraron clientes.'),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
                  itemCount: clientes.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = clientes[index];
                    final turnos = widget.salon.cantidadTurnosCliente(c.id);

                    return ListTile(
                      onTap: () => _abrirDetalle(c),
                      leading: CircleAvatar(
                        backgroundColor: c.genero == Genero.mujer
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.tertiaryContainer,
                        child: Text(
                          inicial(c.nombre),
                          style: TextStyle(
                            color: c.genero == Genero.mujer
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${telefonoTexto(c.telefono)} · ${c.genero.etiqueta}'),
                      trailing: Text(
                        turnos == 1 ? '1 turno' : '$turnos turnos',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
      ),
    );
  }
}

class _ClienteDetalleSheet extends StatelessWidget {
  const _ClienteDetalleSheet({
    required this.salon,
    required this.cliente,
    required this.onEditar,
  });

  final SalonViewModel salon;
  final Cliente cliente;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historial = salon.historialCliente(cliente.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Info Cliente
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      inicial(cliente.nombre),
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente.nombre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${telefonoTexto(cliente.telefono)}', style: theme.textTheme.bodyLarge),
                        if (cliente.correo != null) Text(cliente.correo!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Historial de turnos · ${historial.length}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Historial (con scroll)
              Expanded(
                child: historial.isEmpty
                    ? const Center(child: Text('No tiene turnos registrados.'))
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final t = historial[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${fechaCorta(t.inicio)} · ${t.serviciosTexto}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t.estado.etiqueta, style: theme.textTheme.labelSmall),
                      ),
                    );
                  },
                ),
              ),

              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/turno/nuevo', extra: DatosInicialesTurno(clienteId: cliente.id));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo turno'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onEditar,
                    child: const Icon(Icons.edit),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('¿Eliminar a ${cliente.nombre}?'),
                          content: const Text('Se eliminará el cliente junto con su historial de turnos completados y cancelados.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirmar) {
                        try {
                          salon.eliminarCliente(cliente.id);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    },
                    child: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ClienteFormSheet extends StatefulWidget {
  const ClienteFormSheet({super.key, required this.salon, this.clienteEditar});
  final SalonViewModel salon;
  final Cliente? clienteEditar;

  @override
  State<ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _correoCtrl;
  Genero? _genero;

  @override
  void initState() {
    super.initState();
    final c = widget.clienteEditar;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _correoCtrl = TextEditingController(text: c?.correo ?? '');
    _genero = c?.genero;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_genero == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un género')));
      return;
    }

    try {
      if (widget.clienteEditar == null) {
        widget.salon.crearCliente(
          nombre: _nombreCtrl.text,
          telefono: _telefonoCtrl.text,
          genero: _genero,
          correo: _correoCtrl.text,
        );
      } else {
        widget.salon.actualizarCliente(
          id: widget.clienteEditar!.id,
          nombre: _nombreCtrl.text,
          telefono: _telefonoCtrl.text,
          genero: _genero,
          correo: _correoCtrl.text,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ajuste para que el teclado no tape los campos (C5 y C6)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.clienteEditar == null ? 'Nuevo cliente' : 'Editar cliente',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: widget.salon.validarNombreCliente,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Teléfono
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => widget.salon.validarTelefonoCliente(v, excluirClienteId: widget.clienteEditar?.id),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Género
              Text('Género', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Genero>(
                segments: const [
                  ButtonSegment(value: Genero.mujer, label: Text('Mujer')),
                  ButtonSegment(value: Genero.hombre, label: Text('Hombre')),
                ],
                selected: _genero != null ? {_genero!} : {},
                emptySelectionAllowed: true,
                onSelectionChanged: (Set<Genero> newSelection) {
                  setState(() => _genero = newSelection.isEmpty ? null : newSelection.first);
                },
              ),
              if (_genero == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text('Selecciona un género', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 16),

              // Correo
              TextFormField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                keyboardType: TextInputType.emailAddress,
                validator: widget.salon.validarCorreoCliente,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardar,
                      child: const Text('Guardar cliente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}