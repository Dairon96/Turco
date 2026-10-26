import 'package:flutter/foundation.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/franja.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'salon_view_model.dart';

/// Datos con los que se puede abrir el formulario desde otras pantallas.
class DatosInicialesTurno {
  const DatosInicialesTurno({this.clienteId, this.servicioId, this.fecha});

  final int? clienteId;
  final int? servicioId;
  final DateTime? fecha;
}

/// Estado y reglas del formulario de turno (crear y editar).
/// Se crea al abrir la pantalla y se destruye al cerrarla.
class TurnoFormViewModel extends ChangeNotifier {
  TurnoFormViewModel(
    this.salon, {
    this.turnoEditado,
    DatosInicialesTurno? iniciales,
  }) {
    final t = turnoEditado;
    if (t != null) {
      _clienteId = t.clienteId;
      _servicioIds.addAll(t.servicios.map((s) => s.id));
      _estilistaId = t.estilistaId;
      _fecha = soloFecha(t.inicio);
      _hora = t.inicio;
      _notas = t.notas ?? '';
      final cliente = salon.clientePorId(t.clienteId);
      if (cliente != null) _filtroPublico = cliente.genero.filtroPublico;
    } else if (iniciales != null) {
      _clienteId = iniciales.clienteId;
      final cliente =
          _clienteId == null ? null : salon.clientePorId(_clienteId!);
      if (cliente != null) _filtroPublico = cliente.genero.filtroPublico;
      final servicio = iniciales.servicioId == null
          ? null
          : salon.servicioPorId(iniciales.servicioId!);
      if (servicio != null) {
        _servicioIds.add(servicio.id);
        if (cliente == null) {
          _filtroPublico = switch (servicio.publico) {
            Publico.mujeres => FiltroPublico.mujeres,
            Publico.hombres => FiltroPublico.hombres,
            Publico.unisex => FiltroPublico.todos,
          };
        }
      }
      final f = iniciales.fecha;
      if (f != null &&
          salon.esDiaLaborable(f) &&
          !soloFecha(f).isBefore(soloFecha(salon.ahora))) {
        _fecha = soloFecha(f);
      }
    }
    _snapshotInicial = _snapshot();
  }

  final SalonViewModel salon;

  /// null = se está creando un turno nuevo.
  final Turno? turnoEditado;
  bool get esEdicion => turnoEditado != null;

  int? _clienteId;
  final Set<int> _servicioIds = {};
  int? _estilistaId;
  DateTime? _fecha;
  DateTime? _hora;
  String _notas = '';
  FiltroPublico _filtroPublico = FiltroPublico.todos;
  String? _aviso;
  late final String _snapshotInicial;

  int? get clienteId => _clienteId;
  int? get estilistaId => _estilistaId;
  DateTime? get fecha => _fecha;
  DateTime? get hora => _hora;
  String get notas => _notas;
  FiltroPublico get filtroPublico => _filtroPublico;
  Set<int> get servicioIds => Set.unmodifiable(_servicioIds);

  // ------------------------------------------------------------ acciones

  /// Elegir cliente ajusta por defecto el filtro de público a su género.
  void seleccionarCliente(int id) {
    _clienteId = id;
    final cliente = salon.clientePorId(id);
    if (cliente != null) _filtroPublico = cliente.genero.filtroPublico;
    _revalidar();
    notifyListeners();
  }

  void cambiarFiltroPublico(FiltroPublico f) {
    if (f == _filtroPublico) return;
    _filtroPublico = f;
    notifyListeners();
  }

  void alternarServicio(int id) {
    if (!_servicioIds.remove(id)) _servicioIds.add(id);
    _revalidar();
    notifyListeners();
  }

  void seleccionarEstilista(int id) {
    _estilistaId = id;
    _revalidar();
    notifyListeners();
  }

  void seleccionarFecha(DateTime d) {
    _fecha = soloFecha(d);
    _revalidar();
    notifyListeners();
  }

  void seleccionarHora(DateTime inicio) {
    _fecha ??= soloFecha(inicio);
    _hora = inicio;
    notifyListeners();
  }

  /// Las notas viven en un TextEditingController de la vista; aquí solo se
  /// guarda el último valor para detectar cambios y guardar.
  void actualizarNotas(String texto) => _notas = texto;

  /// Mensaje pendiente (p. ej. "se limpió el estilista"); la vista lo muestra
  /// una vez y lo consume.
  String? consumirAviso() {
    final a = _aviso;
    _aviso = null;
    return a;
  }

  /// Si cambian servicios, cliente o fecha, el estilista y la hora elegidos
  /// pueden dejar de ser válidos: se limpian y se avisa.
  void _revalidar() {
    final id = _estilistaId;
    if (id != null && !estilistasDisponibles.any((e) => e.id == id)) {
      _estilistaId = null;
      _hora = null;
      _aviso = 'Se quitó el estilista porque ya no realiza todos los '
          'servicios elegidos. Elige otro.';
    }
    final h = _hora;
    if (h != null) {
      final sigueLibre = franjas.any((f) => f.inicio == h && f.disponible);
      if (!sigueLibre) _hora = null;
    }
  }

  // ------------------------------------------------------------- derivados

  List<Servicio> get serviciosSeleccionados => salon.servicios
      .where((s) => _servicioIds.contains(s.id))
      .toList();

  /// Servicios visibles según el filtro de público, agrupados por categoría.
  Map<CategoriaServicio, List<Servicio>> get serviciosPorCategoria {
    final mapa = <CategoriaServicio, List<Servicio>>{};
    for (final c in CategoriaServicio.values) {
      final lista = salon.servicios
          .where((s) =>
              s.categoria == c && s.coincideConPublico(_filtroPublico))
          .toList();
      if (lista.isNotEmpty) mapa[c] = lista;
    }
    return mapa;
  }

  /// Solo estilistas que realizan todos los servicios elegidos.
  List<Estilista> get estilistasDisponibles =>
      salon.estilistasPara(serviciosSeleccionados);

  int get duracionMinutos =>
      serviciosSeleccionados.fold(0, (s, x) => s + x.duracionMinutos);

  int get precioTotal =>
      serviciosSeleccionados.fold(0, (s, x) => s + x.precio);

  DateTime? get fin {
    final h = _hora;
    if (h == null) return null;
    return DateTime(h.year, h.month, h.day, h.hour, h.minute + duracionMinutos);
  }

  /// Día que usa la cuadrícula cuando todavía no hay fecha elegida:
  /// hoy o, si es domingo, el siguiente día laborable.
  DateTime get fechaReferencia {
    if (_fecha != null) return _fecha!;
    var d = soloFecha(salon.ahora);
    while (!salon.esDiaLaborable(d)) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  List<Franja> get franjas => salon.franjas(
        fecha: fechaReferencia,
        duracionMinutos: duracionMinutos,
        estilistaId: _estilistaId,
        clienteId: _clienteId,
        excluirTurnoId: turnoEditado?.id,
        inicioPermitido: turnoEditado?.inicio,
      );

  bool get hayFranjaLibre => franjas.any((f) => f.disponible);

  // ----------------------------------------------------------- validación

  String? validarCliente() =>
      _clienteId == null ? 'Selecciona un cliente' : null;

  String? validarServicios() =>
      _servicioIds.isEmpty ? 'Elige al menos un servicio' : null;

  String? validarEstilista() =>
      _estilistaId == null ? 'Selecciona un estilista' : null;

  String? validarFecha() {
    final f = _fecha;
    if (f == null || !salon.esDiaLaborable(f)) {
      return 'Elige una fecha válida (no domingos)';
    }
    return null;
  }

  String? validarHora() =>
      _hora == null ? 'Elige una hora para el turno' : null;

  bool get esValido =>
      validarCliente() == null &&
      validarServicios() == null &&
      validarEstilista() == null &&
      validarFecha() == null &&
      validarHora() == null;

  // --------------------------------------------------------------- cambios

  String _snapshot() {
    final ids = _servicioIds.toList()..sort();
    return [
      _clienteId,
      ids.join(','),
      _estilistaId,
      _fecha?.toIso8601String(),
      _hora?.toIso8601String(),
      _notas.trim(),
    ].join('|');
  }

  /// Hay cambios sin guardar respecto al estado con que se abrió el formulario.
  bool get tieneCambios => _snapshot() != _snapshotInicial;

  // --------------------------------------------------------------- guardar

  /// Crea o edita el turno. Lanza [ReglaNegocioException] si alguna regla
  /// no se cumple (solape, domingo, pasado, después de las 19:00...).
  Turno guardar() {
    if (!esValido) {
      throw ReglaNegocioException('Revisa los campos del formulario');
    }
    final t = turnoEditado;
    if (t == null) {
      return salon.crearTurno(
        clienteId: _clienteId,
        servicios: serviciosSeleccionados,
        estilistaId: _estilistaId,
        inicio: _hora,
        notas: _notas,
      );
    }
    return salon.editarTurno(
      id: t.id,
      clienteId: _clienteId,
      servicios: serviciosSeleccionados,
      estilistaId: _estilistaId,
      inicio: _hora,
      notas: _notas,
    );
  }
}
