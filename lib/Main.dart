import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'viewmodels/salon_view_model.dart';
import 'viewmodels/tema_view_model.dart';

void main() {
  runApp(const TurcoApp());
}

class TurcoApp extends StatefulWidget {
  const TurcoApp({super.key});

  @override
  State<TurcoApp> createState() => _TurcoAppState();
}

class _TurcoAppState extends State<TurcoApp> {
  late final TemaViewModel _temaVM;
  late final SalonViewModel _salonVM;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _temaVM = TemaViewModel();
    _salonVM = SalonViewModel();
    _router = crearRouter(_salonVM, _temaVM);
  }

  @override
  void dispose() {
    _temaVM.dispose();
    _salonVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _temaVM,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Turco',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: _temaVM.modo,
          routerConfig: _router,
        );
      },
    );
  }
}