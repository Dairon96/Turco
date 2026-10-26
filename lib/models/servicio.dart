import 'enums.dart';

/// Servicio del catálogo (solo lectura).
class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.duracionMinutos,
    required this.precio,
    required this.publico,
  });

  final int id;
  final String nombre;
  final CategoriaServicio categoria;
  final int duracionMinutos;
  final int precio;
  final Publico publico;

  /// Mujeres incluye los unisex; Hombres incluye los unisex.
  bool coincideConPublico(FiltroPublico filtro) {
    switch (filtro) {
      case FiltroPublico.todos:
        return true;
      case FiltroPublico.mujeres:
        return publico != Publico.hombres;
      case FiltroPublico.hombres:
        return publico != Publico.mujeres;
    }
  }
}
