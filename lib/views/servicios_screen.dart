import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/servicio.dart';
import '../viewmodels/salon_view_model.dart';
import '../viewmodels/servicios_view_model.dart';
import '../viewmodels/turno_form_view_model.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key, required this.salon});
  final SalonViewModel salon;

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  late final ServiciosViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ServiciosViewModel(widget.salon);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Toca un servicio para reservar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final servicios = _vm.filtrados;

          return Column(
            children: [
              // 1. Filtro por Categoría (Chips horizontal)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todas'),
                        selected: _vm.categoria == null,
                        onSelected: (_) => _vm.filtrarCategoria(null),
                      ),
                    ),
                    ...CategoriaServicio.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.etiqueta),
                        selected: _vm.categoria == cat,
                        onSelected: (_) => _vm.filtrarCategoria(cat),
                      ),
                    )),
                  ],
                ),
              ),

              // 2. Filtro por Público (SegmentedButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<FiltroPublico>(
                  segments: const [
                    ButtonSegment(value: FiltroPublico.todos, label: Text('Todos'), icon: Icon(Icons.check)),
                    ButtonSegment(value: FiltroPublico.mujeres, label: Text('Mujeres')),
                    ButtonSegment(value: FiltroPublico.hombres, label: Text('Hombres')),
                  ],
                  selected: {_vm.publico},
                  onSelectionChanged: (Set<FiltroPublico> newSelection) {
                    _vm.filtrarPublico(newSelection.first);
                  },
                ),
              ),

              // 3. Cuadrícula de servicios
              Expanded(
                child: servicios.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('No hay servicios que coincidan con los filtros.'),
                    ],
                  ),
                )
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    // RF5: Número de columnas según el ancho
                    int columnas = 2;
                    if (constraints.maxWidth >= 600 && constraints.maxWidth <= 840) {
                      columnas = 3;
                    } else if (constraints.maxWidth > 840) {
                      columnas = 4;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.80, // Ajusta la proporción de la tarjeta
                      ),
                      itemCount: servicios.length,
                      itemBuilder: (context, index) {
                        return _TarjetaServicio(
                          servicio: servicios[index],
                          onTap: () {
                            // Navegar al formulario pasando el ID del servicio
                            context.push(
                              '/turno/nuevo',
                              extra: DatosInicialesTurno(servicioId: servicios[index].id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio, required this.onTap});
  final Servicio servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen / Icono de la categoría
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                child: Icon(
                  _iconoCategoria(servicio.categoria),
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            // Detalles
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicio.nombre,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('${servicio.duracionMinutos} min', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(servicio.publico.etiqueta, style: theme.textTheme.labelSmall),
                        ),
                        Text(
                          precioTexto(servicio.precio),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconoCategoria(CategoriaServicio cat) {
    switch (cat) {
      case CategoriaServicio.corte:
        return Icons.content_cut;
      case CategoriaServicio.color:
        return Icons.palette;
      case CategoriaServicio.barba:
        return Icons.face_retouching_natural;
      case CategoriaServicio.peinado:
        return Icons.auto_awesome;
      case CategoriaServicio.tratamiento:
        return Icons.spa;
    }
  }
}