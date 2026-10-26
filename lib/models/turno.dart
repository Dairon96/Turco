import 'enums.dart';
import 'servicio.dart';

/// Turno. La hora de fin y el precio total se calculan, no se guardan.
class Turno {
  const Turno({
    required this.id,
    required this.clienteId,
    required this.estilistaId,
    required this.servicios,
    required this.inicio,
    this.notas,
    required this.estado,
    required this.creado,
    required this.modificado,
  });

  final int id;
  final int clienteId;
  final int estilistaId;
  final List<Servicio> servicios;
  final DateTime inicio;
  final String? notas;
  final EstadoTurno estado;
  final DateTime creado;
  final DateTime modificado;

  int get duracionMinutos =>
      servicios.fold(0, (suma, s) => suma + s.duracionMinutos);

  int get precioTotal => servicios.fold(0, (suma, s) => suma + s.precio);

  DateTime get fin => DateTime(
        inicio.year,
        inicio.month,
        inicio.day,
        inicio.hour,
        inicio.minute + duracionMinutos,
      );

  bool get estaProgramado => estado == EstadoTurno.programado;

  /// Un turno que termina a las 10:00 no se solapa con otro que empieza a las 10:00.
  bool solapaCon(DateTime otroInicio, DateTime otroFin) =>
      inicio.isBefore(otroFin) && otroInicio.isBefore(fin);

  /// Nombres de servicios unidos con " + ".
  String get serviciosTexto => servicios.map((s) => s.nombre).join(' + ');

  Turno copyWith({EstadoTurno? estado, DateTime? modificado}) {
    return Turno(
      id: id,
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicios: servicios,
      inicio: inicio,
      notas: notas,
      estado: estado ?? this.estado,
      creado: creado,
      modificado: modificado ?? this.modificado,
    );
  }
}
