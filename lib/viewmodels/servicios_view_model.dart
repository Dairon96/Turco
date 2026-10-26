import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/servicio.dart';
import 'salon_view_model.dart';

/// Estado de la pantalla Servicios: filtros por categoría y público.
class ServiciosViewModel extends ChangeNotifier {
  ServiciosViewModel(this.salon);

  final SalonViewModel salon;

  CategoriaServicio? _categoria;
  FiltroPublico _publico = FiltroPublico.todos;

  CategoriaServicio? get categoria => _categoria;
  FiltroPublico get publico => _publico;

  void filtrarCategoria(CategoriaServicio? c) {
    if (c == _categoria) return;
    _categoria = c;
    notifyListeners();
  }

  void filtrarPublico(FiltroPublico p) {
    if (p == _publico) return;
    _publico = p;
    notifyListeners();
  }

  List<Servicio> get filtrados => salon.servicios.where((s) {
        if (_categoria != null && s.categoria != _categoria) return false;
        return s.coincideConPublico(_publico);
      }).toList();
}
