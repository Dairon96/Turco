import 'package:flutter/foundation.dart';

import '../core/formato.dart';
import '../data/datos_prueba.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/franja.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Error de una regla de negocio; el mensaje se puede mostrar al usuario.
class ReglaNegocioException implements Exception {
  ReglaNegocioException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Estado compartido del salón: catálogo, estilistas, clientes y turnos,
/// más todas las reglas de negocio (horarios, solapes, duración, precio).
class SalonViewModel extends ChangeNotifier {
  SalonViewModel({DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now {
    final datos = cargarDatosPrueba(_reloj());
    _servicios = datos.servicios;
    _estilistas = datos.estilistas;
    _clientes = List.of(datos.clientes);
    _turnos = List.of(datos.turnos);
    _siguienteClienteId = _clientes.fold(0, (m, c) => c.id > m ? c.id : m) + 1;
    _siguienteTurnoId = _turnos.fold(0, (m, t) => t.id > m ? t.id : m) + 1;
  }

  static const int horaApertura = 9;
  static const int horaCierre = 19;
  static const int pasoMinutos = 30;
  static const int maxNotas = 500;

  final DateTime Function() _reloj;
  late final List<Servicio> _servicios;
  late final List<Estilista> _estilistas;
  late List<Cliente> _clientes;
  late List<Turno> _turnos;
  late int _siguienteClienteId;
  late int _siguienteTurnoId;

  DateTime get ahora => _reloj();

  // ---------------------------------------------------------------- lectura

  List<Servicio> get servicios => List.unmodifiable(_servicios);
  List<Estilista> get estilistas => List.unmodifiable(_estilistas);
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Turno> get turnos => List.unmodifiable(_turnos);

  Servicio? servicioPorId(int id) =>
      _servicios.where((s) => s.id == id).firstOrNull;
  Estilista? estilistaPorId(int id) =>
      _estilistas.where((e) => e.id == id).firstOrNull;
  Cliente? clientePorId(int id) =>
      _clientes.where((c) => c.id == id).firstOrNull;
  Turno? turnoPorId(int id) => _turnos.where((t) => t.id == id).firstOrNull;

  /// Turnos del día ordenados por hora de inicio.
  List<Turno> turnosDelDia(DateTime dia) {
    final lista = _turnos.where((t) => mismoDia(t.inicio, dia)).toList();
    lista.sort((a, b) => a.inicio.compareTo(b.inicio));
    return lista;
  }

  /// Cantidad total de turnos (de cualquier estado) del cliente.
  int cantidadTurnosCliente(int clienteId) =>
      _turnos.where((t) => t.clienteId == clienteId).length;

  int programadosDeCliente(int clienteId) => _turnos
      .where((t) => t.clienteId == clienteId && t.estaProgramado)
      .length;

  /// Historial del cliente, del más reciente al más antiguo.
  List<Turno> historialCliente(int clienteId) {
    final lista = _turnos.where((t) => t.clienteId == clienteId).toList();
    lista.sort((a, b) => b.inicio.compareTo(a.inicio));
    return lista;
  }

  /// Turnos programados que tiene hoy un estilista.
  int programadosHoy(int estilistaId) {
    final hoy = ahora;
    return _turnos
        .where((t) =>
            t.estaProgramado &&
            t.estilistaId == estilistaId &&
            mismoDia(t.inicio, hoy))
        .length;
  }

  int get totalProgramadosHoy => _estilistas.fold(
        0,
        (suma, e) => suma + programadosHoy(e.id),
      );

  /// Estilistas que realizan TODOS los servicios indicados.
  List<Estilista> estilistasPara(List<Servicio> servicios) =>
      _estilistas.where((e) => e.realizaTodos(servicios)).toList();

  // --------------------------------------------------------------- horarios

  bool esDiaLaborable(DateTime d) => d.weekday != DateTime.sunday;

  DateTime _a(DateTime dia, int minutosDesdeMedianoche) => DateTime(
        dia.year,
        dia.month,
        dia.day,
        0,
        minutosDesdeMedianoche,
      );

  bool estilistaOcupado(
    int estilistaId,
    DateTime inicio,
    DateTime fin, {
    int? excluirTurnoId,
  }) =>
      _turnos.any((t) =>
          t.estaProgramado &&
          t.estilistaId == estilistaId &&
          t.id != excluirTurnoId &&
          t.solapaCon(inicio, fin));

  bool clienteOcupado(
    int clienteId,
    DateTime inicio,
    DateTime fin, {
    int? excluirTurnoId,
  }) =>
      _turnos.any((t) =>
          t.estaProgramado &&
          t.clienteId == clienteId &&
          t.id != excluirTurnoId &&
          t.solapaCon(inicio, fin));

  /// Franjas de 30 minutos del día. Una franja no está disponible si el
  /// salón está cerrado, ya pasó, el turno terminaría después de las 19:00 o
  /// el estilista o el cliente ya tienen un turno programado que se solapa.
  List<Franja> franjas({
    required DateTime fecha,
    required int duracionMinutos,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
    DateTime? inicioPermitido,
  }) {
    final dia = soloFecha(fecha);
    final duracion = duracionMinutos <= 0 ? pasoMinutos : duracionMinutos;
    final cierre = _a(dia, horaCierre * 60);
    final ahoraMismo = ahora;
    final resultado = <Franja>[];

    for (var min = horaApertura * 60; min < horaCierre * 60; min += pasoMinutos) {
      final inicio = _a(dia, min);
      final fin = _a(dia, min + duracion);
      MotivoNoDisponible? motivo;

      if (!esDiaLaborable(dia)) {
        motivo = MotivoNoDisponible.cerrado;
      } else if (inicio.isBefore(ahoraMismo) && inicio != inicioPermitido) {
        motivo = MotivoNoDisponible.pasada;
      } else if (fin.isAfter(cierre)) {
        motivo = MotivoNoDisponible.terminaTarde;
      } else if (estilistaId != null &&
          estilistaOcupado(estilistaId, inicio, fin,
              excluirTurnoId: excluirTurnoId)) {
        motivo = MotivoNoDisponible.estilistaOcupado;
      } else if (clienteId != null &&
          clienteOcupado(clienteId, inicio, fin,
              excluirTurnoId: excluirTurnoId)) {
        motivo = MotivoNoDisponible.clienteOcupado;
      }
      resultado.add(Franja(inicio: inicio, motivo: motivo));
    }
    return resultado;
  }

  // ----------------------------------------------------------------- turnos

  String? _validarTurno({
    required int? clienteId,
    required List<Servicio> servicios,
    required int? estilistaId,
    required DateTime? inicio,
    int? excluirTurnoId,
    DateTime? inicioOriginal,
  }) {
    if (clienteId == null || clientePorId(clienteId) == null) {
      return 'Selecciona un cliente';
    }
    if (servicios.isEmpty) return 'Elige al menos un servicio';
    final estilista = estilistaId == null ? null : estilistaPorId(estilistaId);
    if (estilista == null) return 'Selecciona un estilista';
    if (!estilista.realizaTodos(servicios)) {
      return 'El estilista no realiza todos los servicios elegidos';
    }
    if (inicio == null) return 'Elige una hora para el turno';
    if (!esDiaLaborable(inicio)) return 'El salón está cerrado los domingos';

    final minutos = inicio.hour * 60 + inicio.minute;
    if (minutos < horaApertura * 60 ||
        minutos >= horaCierre * 60 ||
        minutos % pasoMinutos != 0) {
      return 'La hora debe ser una franja de 30 minutos entre las 9:00 y las 19:00';
    }

    final duracion = servicios.fold(0, (s, x) => s + x.duracionMinutos);
    final fin = _a(soloFecha(inicio), minutos + duracion);
    if (fin.isAfter(_a(soloFecha(inicio), horaCierre * 60))) {
      return 'El turno terminaría después de las 19:00';
    }
    if (inicio != inicioOriginal && inicio.isBefore(ahora)) {
      return 'No se pueden agendar turnos en una fecha y hora pasadas';
    }
    if (estilistaOcupado(estilista.id, inicio, fin,
        excluirTurnoId: excluirTurnoId)) {
      return 'El estilista ya tiene un turno que se solapa con ese horario';
    }
    if (clienteOcupado(clienteId, inicio, fin, excluirTurnoId: excluirTurnoId)) {
      return 'El cliente ya tiene un turno que se solapa con ese horario';
    }
    return null;
  }

  String? _limpiarNotas(String? notas) {
    final t = notas?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length > maxNotas) {
      throw ReglaNegocioException('Las notas admiten hasta $maxNotas caracteres');
    }
    return t;
  }

  Turno crearTurno({
    required int? clienteId,
    required List<Servicio> servicios,
    required int? estilistaId,
    required DateTime? inicio,
    String? notas,
  }) {
    final error = _validarTurno(
      clienteId: clienteId,
      servicios: servicios,
      estilistaId: estilistaId,
      inicio: inicio,
    );
    if (error != null) throw ReglaNegocioException(error);
    final notasLimpias = _limpiarNotas(notas);

    final ahoraMismo = ahora;
    final turno = Turno(
      id: _siguienteTurnoId++,
      clienteId: clienteId!,
      estilistaId: estilistaId!,
      servicios: List.of(servicios),
      inicio: inicio!,
      notas: notasLimpias,
      estado: EstadoTurno.programado,
      creado: ahoraMismo,
      modificado: ahoraMismo,
    );
    _turnos.add(turno);
    notifyListeners();
    return turno;
  }

  Turno editarTurno({
    required int id,
    required int? clienteId,
    required List<Servicio> servicios,
    required int? estilistaId,
    required DateTime? inicio,
    String? notas,
  }) {
    final actual = turnoPorId(id);
    if (actual == null) throw ReglaNegocioException('El turno no existe');
    if (!actual.estaProgramado) {
      throw ReglaNegocioException('Solo se pueden editar turnos programados');
    }
    final error = _validarTurno(
      clienteId: clienteId,
      servicios: servicios,
      estilistaId: estilistaId,
      inicio: inicio,
      excluirTurnoId: id,
      inicioOriginal: actual.inicio,
    );
    if (error != null) throw ReglaNegocioException(error);
    final notasLimpias = _limpiarNotas(notas);

    final nuevo = Turno(
      id: id,
      clienteId: clienteId!,
      estilistaId: estilistaId!,
      servicios: List.of(servicios),
      inicio: inicio!,
      notas: notasLimpias,
      estado: EstadoTurno.programado,
      creado: actual.creado,
      modificado: ahora,
    );
    _turnos[_turnos.indexWhere((t) => t.id == id)] = nuevo;
    notifyListeners();
    return nuevo;
  }

  void _cambiarEstado(int id, EstadoTurno estado) {
    final actual = turnoPorId(id);
    if (actual == null) throw ReglaNegocioException('El turno no existe');
    if (!actual.estaProgramado) {
      throw ReglaNegocioException('Solo los turnos programados se pueden modificar');
    }
    _turnos[_turnos.indexWhere((t) => t.id == id)] =
        actual.copyWith(estado: estado, modificado: ahora);
    notifyListeners();
  }

  void completarTurno(int id) => _cambiarEstado(id, EstadoTurno.completado);

  /// Cancelar libera el horario: los turnos cancelados no ocupan agenda.
  void cancelarTurno(int id) => _cambiarEstado(id, EstadoTurno.cancelado);

  // --------------------------------------------------------------- clientes

  static final RegExp _regexTelefono = RegExp(r'^\d{8}$');
  static final RegExp _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validarNombreCliente(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length < 3 || v.length > 60) return 'Escribe entre 3 y 60 caracteres';
    return null;
  }

  bool telefonoRepetido(String telefono, {int? excluirClienteId}) =>
      _clientes.any((c) => c.telefono == telefono && c.id != excluirClienteId);

  String? validarTelefonoCliente(String? valor, {int? excluirClienteId}) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'El teléfono es obligatorio';
    if (!_regexTelefono.hasMatch(v)) return 'Debe tener exactamente 8 dígitos';
    if (telefonoRepetido(v, excluirClienteId: excluirClienteId)) {
      return 'Ese teléfono ya está registrado';
    }
    return null;
  }

  String? validarCorreoCliente(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return null; // opcional
    return _regexCorreo.hasMatch(v) ? null : 'Escribe un correo válido';
  }

  String? validarGeneroCliente(Genero? genero) =>
      genero == null ? 'Selecciona un género' : null;

  void _validarCliente(
    String nombre,
    String telefono,
    Genero? genero,
    String? correo, {
    int? excluirId,
  }) {
    final error = validarNombreCliente(nombre) ??
        validarTelefonoCliente(telefono, excluirClienteId: excluirId) ??
        validarGeneroCliente(genero) ??
        validarCorreoCliente(correo);
    if (error != null) throw ReglaNegocioException(error);
  }

  Cliente crearCliente({
    required String nombre,
    required String telefono,
    required Genero? genero,
    String? correo,
  }) {
    _validarCliente(nombre, telefono, genero, correo);
    final c = correo?.trim() ?? '';
    final cliente = Cliente(
      id: _siguienteClienteId++,
      nombre: nombre.trim(),
      telefono: telefono.trim(),
      genero: genero!,
      correo: c.isEmpty ? null : c,
      registro: soloFecha(ahora),
    );
    _clientes.add(cliente);
    notifyListeners();
    return cliente;
  }

  Cliente actualizarCliente({
    required int id,
    required String nombre,
    required String telefono,
    required Genero? genero,
    String? correo,
  }) {
    final actual = clientePorId(id);
    if (actual == null) throw ReglaNegocioException('El cliente no existe');
    _validarCliente(nombre, telefono, genero, correo, excluirId: id);
    final c = correo?.trim() ?? '';
    final nuevo = Cliente(
      id: id,
      nombre: nombre.trim(),
      telefono: telefono.trim(),
      genero: genero!,
      correo: c.isEmpty ? null : c,
      registro: actual.registro,
    );
    _clientes[_clientes.indexWhere((x) => x.id == id)] = nuevo;
    notifyListeners();
    return nuevo;
  }

  /// No se puede eliminar un cliente con turnos programados. Si no los tiene,
  /// se elimina junto con su historial de turnos completados y cancelados.
  void eliminarCliente(int id) {
    final cliente = clientePorId(id);
    if (cliente == null) throw ReglaNegocioException('El cliente no existe');
    final programados = programadosDeCliente(id);
    if (programados > 0) {
      final texto = programados == 1
          ? '1 turno programado'
          : '$programados turnos programados';
      throw ReglaNegocioException(
        'No se puede eliminar: ${cliente.nombre} tiene $texto.',
      );
    }
    _turnos.removeWhere((t) => t.clienteId == id);
    _clientes.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
