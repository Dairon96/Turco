import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'viewmodels/salon_view_model.dart';
import 'viewmodels/tema_view_model.dart';
import 'viewmodels/turno_form_view_model.dart';

import 'views/agenda_screen.dart';
import 'views/clientes_screen.dart';
import 'views/servicios_screen.dart';
import 'views/estilistas_screen.dart';
import 'views/turno_detalle_screen.dart';
import 'views/turno_form_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter crearRouter(SalonViewModel salon, TemaViewModel temaVM) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/agenda',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell, salon: salon);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) {
                  final estilistaStr = state.uri.queryParameters['estilista'];
                  final estilistaId = estilistaStr != null ? int.tryParse(estilistaStr) : null;
                  return AgendaScreen(salon: salon, temaVM: temaVM, estilistaIdInicial: estilistaId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clientes',
                builder: (context, state) => ClientesScreen(salon: salon),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servicios',
                builder: (context, state) => ServiciosScreen(salon: salon),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/estilistas',
                builder: (context, state) => EstilistasScreen(salon: salon),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/turno/nuevo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final iniciales = state.extra as DatosInicialesTurno?;
          return TurnoFormScreen(salon: salon, iniciales: iniciales);
        },
      ),
      GoRoute(
        path: '/turno/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id']!) ?? -1;
          return TurnoDetalleScreen(salon: salon, turnoId: id);
        },
      ),
      GoRoute(
        path: '/turno/:id/editar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id']!) ?? -1;
          final turno = salon.turnoPorId(id);
          return TurnoFormScreen(salon: salon, turnoEditar: turno);
        },
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.salon,
  });

  final StatefulNavigationShell navigationShell;
  final SalonViewModel salon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.content_cut_outlined), selectedIcon: Icon(Icons.content_cut), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Estilistas'),
        ],
      ),
    );
  }
}