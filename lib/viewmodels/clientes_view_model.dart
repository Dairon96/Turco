import 'package:flutter/foundation.dart';

import '../core/formato.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import 'salon_view_model.dart';

/// Estado de la pantalla Clientes: búsqueda y filtro por género.
class ClientesViewModel extends ChangeNotifier {
  ClientesViewModel(this.salon) {
    salon.addListener(notifyListeners);
  }

  final SalonViewModel salon;

  String _busqueda = '';
  Genero? _genero;

  String get busqueda => _busqueda;
  Genero? get genero => _genero;

  void buscar(String texto) {
    if (texto == _busqueda) return;
    _busqueda = texto;
    notifyListeners();
  }

  void filtrarGenero(Genero? g) {
    if (g == _genero) return;
    _genero = g;
    notifyListeners();
  }

  int get total => salon.clientes.length;
  int get totalMujeres =>
      salon.clientes.where((c) => c.genero == Genero.mujer).length;
  int get totalHombres =>
      salon.clientes.where((c) => c.genero == Genero.hombre).length;

  /// Búsqueda por nombre o teléfono (sin mayúsculas ni acentos) combinada
  /// con el filtro de género.
  List<Cliente> get filtrados {
    final texto = normalizar(_busqueda);
    final digitos = _busqueda.replaceAll(RegExp(r'\D'), '');
    return salon.clientes.where((c) {
      if (_genero != null && c.genero != _genero) return false;
      if (texto.isEmpty) return true;
      final porNombre = normalizar(c.nombre).contains(texto);
      final porTelefono = digitos.isNotEmpty && c.telefono.contains(digitos);
      return porNombre || porTelefono;
    }).toList();
  }

  @override
  void dispose() {
    salon.removeListener(notifyListeners);
    super.dispose();
  }
}
