/// Enumeraciones del dominio de Turco.

enum CategoriaServicio {
  corte('Corte'),
  color('Color'),
  barba('Barba'),
  peinado('Peinado'),
  tratamiento('Tratamiento');

  const CategoriaServicio(this.etiqueta);
  final String etiqueta;
}

/// Público al que se dirige un servicio.
enum Publico {
  mujeres('Mujeres'),
  hombres('Hombres'),
  unisex('Unisex');

  const Publico(this.etiqueta);
  final String etiqueta;
}

enum Genero {
  mujer('Mujer'),
  hombre('Hombre');

  const Genero(this.etiqueta);
  final String etiqueta;

  /// Filtro de público que se aplica por defecto a este género.
  FiltroPublico get filtroPublico =>
      this == Genero.mujer ? FiltroPublico.mujeres : FiltroPublico.hombres;
}

/// Filtro "Todos / Mujeres / Hombres" para servicios.
enum FiltroPublico {
  todos('Todos'),
  mujeres('Mujeres'),
  hombres('Hombres');

  const FiltroPublico(this.etiqueta);
  final String etiqueta;
}

enum EstadoTurno {
  programado('Programado'),
  completado('Completado'),
  cancelado('Cancelado');

  const EstadoTurno(this.etiqueta);
  final String etiqueta;
}
