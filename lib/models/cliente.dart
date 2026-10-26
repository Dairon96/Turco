import 'enums.dart';

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.genero,
    this.correo,
    required this.registro,
  });

  final int id;
  final String nombre;

  /// Exactamente 8 dígitos, sin espacios.
  final String telefono;
  final Genero genero;
  final String? correo;
  final DateTime registro;

  Cliente copyWith({
    String? nombre,
    String? telefono,
    Genero? genero,
    String? correo,
    bool quitarCorreo = false,
  }) {
    return Cliente(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      genero: genero ?? this.genero,
      correo: quitarCorreo ? null : (correo ?? this.correo),
      registro: registro,
    );
  }
}
