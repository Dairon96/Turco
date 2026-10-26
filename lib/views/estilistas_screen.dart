import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../viewmodels/salon_view_model.dart';

class EstilistasScreen extends StatelessWidget {
  const EstilistasScreen({super.key, required this.salon});

  final SalonViewModel salon;

  @override
  Widget build(BuildContext context) {
    // Escuchamos al salon para que si se crea un turno hoy, el contador se actualice
    return ListenableBuilder(
      listenable: salon,
      builder: (context, _) {
        final theme = Theme.of(context);
        final totalProfesionales = salon.estilistas.length;
        final totalTurnosHoy = salon.totalProgramadosHoy;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // 1. SliverAppBar plegable (Requisito RF6)
              SliverAppBar(
                pinned: true,
                expandedHeight: 220.0,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Estilistas',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 80, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.badge, size: 40, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(height: 8),
                        Text(
                          '$totalProfesionales profesionales · $totalTurnosHoy turnos programados hoy',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. SliverList para los estilistas
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final estilista = salon.estilistas[index];
                      final programados = salon.programadosHoy(estilista.id);

                      // Extraemos las categorías únicas de los servicios del estilista
                      final categorias = estilista.servicios
                          .map((s) => s.categoria)
                          .toSet()
                          .toList();

                      return _TarjetaEstilista(
                        estilista: estilista,
                        programadosHoy: programados,
                        categorias: categorias,
                        onTap: () {
                          // Navegar a la Agenda con el filtro del estilista por Query Param
                          context.go('/agenda?estilista=${estilista.id}');
                        },
                      );
                    },
                    childCount: salon.estilistas.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaEstilista extends StatelessWidget {
  const _TarjetaEstilista({
    required this.estilista,
    required this.programadosHoy,
    required this.categorias,
    required this.onTap,
  });

  final Estilista estilista;
  final int programadosHoy;
  final List<CategoriaServicio> categorias;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con la inicial
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  inicial(estilista.nombre),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estilista.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Uso de Wrap (Requisito de la conferencia C6)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categorias.map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat.etiqueta,
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Turnos hoy
                    Text(
                      programadosHoy == 0
                          ? 'Sin turnos hoy'
                          : programadosHoy == 1
                          ? '1 turno hoy'
                          : '$programadosHoy turnos hoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: programadosHoy > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}