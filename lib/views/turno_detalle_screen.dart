import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/turno.dart';
import '../viewmodels/salon_view_model.dart';

class TurnoDetalleScreen extends StatelessWidget {
  const TurnoDetalleScreen({
    super.key,
    required this.salon,
    required this.turnoId,
  });

  final SalonViewModel salon;
  final int turnoId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Escuchamos al salón para que si el turno cambia de estado, la UI se actualice
    return ListenableBuilder(
      listenable: salon,
      builder: (context, _) {
        final turno = salon.turnoPorId(turnoId);

        // Manejo de ruta con ID que no existe (RF4)
        if (turno == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del turno')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('No encontramos este turno', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('El turno no existe o ya no está disponible.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/agenda'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver a la agenda'),
                  ),
                ],
              ),
            ),
          );
        }

        final cliente = salon.clientePorId(turno.clienteId);
        final estilista = salon.estilistaPorId(turno.estilistaId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del turno'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tarjeta del Cliente y Estado
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                inicial(cliente?.nombre ?? '?'),
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cliente?.nombre ?? 'Cliente', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  if (cliente?.telefono != null)
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(telefonoTexto(cliente!.telefono), style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            _EstadoBadge(estado: turno.estado),
                          ],
                        ),
                        const Divider(height: 32),

                        // Fecha
                        _FilaInfo(
                          icono: Icons.calendar_month,
                          titulo: 'Fecha',
                          valor: fechaLarga(turno.inicio),
                        ),
                        const SizedBox(height: 12),

                        // Hora
                        _FilaInfo(
                          icono: Icons.access_time,
                          titulo: 'Hora',
                          valor: '${horaTexto(turno.inicio)} a ${horaTexto(turno.fin)} (${duracionTexto(turno.duracionMinutos)})',
                        ),
                        const SizedBox(height: 12),

                        // Estilista
                        _FilaInfo(
                          icono: Icons.person,
                          titulo: 'Estilista',
                          valor: estilista?.nombre ?? 'Estilista',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tarjeta de Servicios
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Servicios', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...turno.servicios.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.nombre, style: theme.textTheme.bodyLarge),
                                    Text(duracionTexto(s.duracionMinutos), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Text(precioTexto(s.precio), style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              precioTexto(turno.precioTotal),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Tarjeta de Notas
                if (turno.notas != null && turno.notas!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Área con scroll propio por si las notas son largas
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: Text(
                                turno.notas!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Fechas de auditoría
                Center(
                  child: Text(
                    'Creado el ${fechaCorta(turno.creado)} · Modificado el ${fechaCorta(turno.modificado)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 80), // Espacio para la barra inferior
              ],
            ),
          ),

          // 5. Botones de acción (solo si está programado)
          bottomNavigationBar: turno.estaProgramado
              ? _BarraAcciones(salon: salon, turno: turno)
              : _BarraSoloLectura(estado: turno.estado),
        );
      },
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _FilaInfo extends StatelessWidget {
  const _FilaInfo({required this.icono, required this.titulo, required this.valor});
  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: theme.textTheme.labelSmall),
              Text(valor, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});
  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (estado) {
      case EstadoTurno.programado:
        color = theme.colorScheme.tertiary;
      case EstadoTurno.completado:
        color = theme.colorScheme.primary;
      case EstadoTurno.cancelado:
        color = theme.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({required this.salon, required this.turno});
  final SalonViewModel salon;
  final Turno turno;

  Future<void> _confirmarAccion(BuildContext context, String titulo, String mensaje, VoidCallback accion, {bool esPeligro = false}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: esPeligro ? Theme.of(ctx).colorScheme.error : null),
            child: Text(esPeligro ? 'Cancelar turno' : 'Aceptar'),
          ),
        ],
      ),
    );
    if (res == true) accion();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/turno/${turno.id}/editar'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _confirmarAccion(
                  context,
                  'Completar turno',
                  '¿Marcar este turno como completado?',
                      () => salon.completarTurno(turno.id),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Completar'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => _confirmarAccion(
                context,
                '¿Cancelar este turno?',
                'El horario quedará libre. Esta acción no se puede deshacer.',
                    () => salon.cancelarTurno(turno.id),
                esPeligro: true,
              ),
              child: const Icon(Icons.cancel_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraSoloLectura extends StatelessWidget {
  const _BarraSoloLectura({required this.estado});
  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        color: theme.colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Turno ${estado.etiqueta.toLowerCase()}: solo lectura',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}