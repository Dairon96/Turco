import 'package:flutter/foundation.dart';

import '../core/formato.dart';
import '../models/enums.dart';
import '../models/turno.dart';
import 'salon_view_model.dart';

/// Resumen del día para las tarjetas de la Agenda.
class ResumenDia {
  const ResumenDia({
    required this.programados,
    required this.completados,
    required this.ingreso,
  });

  final int programados;
  final int completados;
  final int ingreso;
}

/// Estado de la pantalla Agenda: fecha seleccionada y filtros.
/// Vive mientras la app esté abierta, así cada pestaña conserva su estado.
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel(this.salon) {
    _fecha = soloFecha(salon.ahora);
    salon.addListener(notifyListeners);
  }

  final SalonViewModel salon;

  late DateTime _fecha;
  int? _estilistaId;
  EstadoTurno? _estado;

  DateTime get fecha => _fecha;
  int? get estilistaId => _estilistaId;
  EstadoTurno? get estado => _estado;

  /// Los siete días (lunes a domingo) de la semana de la fecha seleccionada.
  List<DateTime> get diasSemana {
    final lunes = DateTime(_fecha.year, _fecha.month, _fecha.day - (_fecha.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(lunes.year, lunes.month, lunes.day + i),
    );
  }

  bool esDomingo(DateTime d) => d.weekday == DateTime.sunday;

  void seleccionarFecha(DateTime d) {
    final nueva = soloFecha(d);
    if (mismoDia(nueva, _fecha)) return;
    _fecha = nueva;
    notifyListeners();
  }

  /// Semana anterior (-1) o siguiente (+1), manteniendo el día de la semana.
  void cambiarSemana(int delta) {
    _fecha = DateTime(_fecha.year, _fecha.month, _fecha.day + 7 * delta);
    notifyListeners();
  }

  void filtrarEstilista(int? id) {
    if (id == _estilistaId) return;
    _estilistaId = id;
    notifyListeners();
  }

  void filtrarEstado(EstadoTurno? estado) {
    if (estado == _estado) return;
    _estado = estado;
    notifyListeners();
  }

  /// Todos los turnos del día, sin filtros.
  List<Turno> get turnosDelDia => salon.turnosDelDia(_fecha);

  bool get diaTieneTurnos => turnosDelDia.isNotEmpty;

  /// Turnos del día con los filtros de estilista y estado aplicados.
  List<Turno> get turnosFiltrados => turnosDelDia.where((t) {
        if (_estilistaId != null && t.estilistaId != _estilistaId) return false;
        if (_estado != null && t.estado != _estado) return false;
        return true;
      }).toList();

  /// Programados, completados e ingreso estimado (programados + completados).
  ResumenDia get resumen {
    var programados = 0;
    var completados = 0;
    var ingreso = 0;
    for (final t in turnosDelDia) {
      switch (t.estado) {
        case EstadoTurno.programado:
          programados++;
          ingreso += t.precioTotal;
        case EstadoTurno.completado:
          completados++;
          ingreso += t.precioTotal;
        case EstadoTurno.cancelado:
          break;
      }
    }
    return ResumenDia(
      programados: programados,
      completados: completados,
      ingreso: ingreso,
    );
  }

  @override
  void dispose() {
    salon.removeListener(notifyListeners);
    super.dispose();
  }
}
