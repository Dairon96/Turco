/// Franja de 30 minutos de la cuadrícula de horas.
enum MotivoNoDisponible {
  cerrado,
  pasada,
  terminaTarde,
  estilistaOcupado,
  clienteOcupado,
}

class Franja {
  const Franja({required this.inicio, this.motivo});

  final DateTime inicio;

  /// null = disponible.
  final MotivoNoDisponible? motivo;

  bool get disponible => motivo == null;
}
