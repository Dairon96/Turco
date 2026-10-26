import 'servicio.dart';

/// Estilista del salón (solo lectura).
class Estilista {
  const Estilista({
    required this.id,
    required this.nombre,
    required this.avatar,
    required this.servicios,
  });

  final int id;
  final String nombre;

  /// Ruta del asset del avatar (si no existe, la vista muestra la inicial).
  final String avatar;
  final List<Servicio> servicios;

  /// Nombre de pila, para chips y tarjetas compactas.
  String get nombreCorto => nombre.split(' ').first;

  bool realiza(Servicio s) => servicios.any((x) => x.id == s.id);

  bool realizaTodos(List<Servicio> lista) =>
      lista.isNotEmpty && lista.every(realiza);
}
