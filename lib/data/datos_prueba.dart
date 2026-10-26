import '../core/formato.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Conjunto de datos de prueba que se carga en memoria al iniciar la app.
class DatosPrueba {
  const DatosPrueba({
    required this.servicios,
    required this.estilistas,
    required this.clientes,
    required this.turnos,
  });

  final List<Servicio> servicios;
  final List<Estilista> estilistas;
  final List<Cliente> clientes;
  final List<Turno> turnos;
}

class _Plantilla {
  const _Plantilla(
    this.id,
    this.dia,
    this.hora,
    this.minuto,
    this.cliente,
    this.estilista,
    this.servicios, {
    this.notas,
    this.pasado = EstadoTurno.completado,
  });

  final int id;

  /// Índice 0..6 dentro de los siete días laborables (el 3 es "hoy").
  final int dia;
  final int hora;
  final int minuto;
  final int cliente;
  final int estilista;
  final List<int> servicios;
  final String? notas;

  /// Estado que toma el turno si su hora ya pasó.
  final EstadoTurno pasado;
}

const _notasLargas =
    'La clienta pide un cambio de imagen importante para una boda familiar. '
    'Quiere conservar el largo, aclarar el tono hasta un castaño miel y '
    'terminar con un peinado suave con ondas. Es alérgica a los productos con '
    'amoníaco, así que hay que usar solo tintes sin amoníaco y hacer antes una '
    'prueba de sensibilidad en la piel. Prefiere que no se use secador a '
    'temperatura alta porque tiene el cuero cabelludo delicado. Llega con '
    'fotos de referencia en el teléfono y quiere revisarlas antes de empezar.';

/// Siete días laborables (lunes a sábado) alrededor de hoy: tres antes,
/// el de referencia (hoy) y tres después. Si hoy es domingo (salón cerrado),
/// la referencia es el sábado anterior.
List<DateTime> _diasAlrededor(DateTime ahora) {
  final hoy = soloFecha(ahora);
  final ref = hoy.weekday == DateTime.sunday
      ? DateTime(hoy.year, hoy.month, hoy.day - 1)
      : hoy;

  final antes = <DateTime>[];
  var k = 1;
  while (antes.length < 3) {
    final d = DateTime(ref.year, ref.month, ref.day - k);
    if (d.weekday != DateTime.sunday) antes.insert(0, d);
    k++;
  }
  final despues = <DateTime>[];
  k = 1;
  while (despues.length < 3) {
    final d = DateTime(ref.year, ref.month, ref.day + k);
    if (d.weekday != DateTime.sunday) despues.add(d);
    k++;
  }
  return [...antes, ref, ...despues];
}

/// Los turnos se calculan a partir de [ahora] para que nunca queden vencidos.
DatosPrueba cargarDatosPrueba(DateTime ahora) {
  const servicios = <Servicio>[
    Servicio(id: 1, nombre: 'Corte mujer', categoria: CategoriaServicio.corte, duracionMinutos: 60, precio: 30, publico: Publico.mujeres),
    Servicio(id: 2, nombre: 'Corte caballero', categoria: CategoriaServicio.corte, duracionMinutos: 45, precio: 25, publico: Publico.hombres),
    Servicio(id: 3, nombre: 'Corte clásico', categoria: CategoriaServicio.corte, duracionMinutos: 30, precio: 18, publico: Publico.hombres),
    Servicio(id: 4, nombre: 'Color completo', categoria: CategoriaServicio.color, duracionMinutos: 120, precio: 70, publico: Publico.mujeres),
    Servicio(id: 5, nombre: 'Mechas', categoria: CategoriaServicio.color, duracionMinutos: 150, precio: 85, publico: Publico.mujeres),
    Servicio(id: 6, nombre: 'Barba', categoria: CategoriaServicio.barba, duracionMinutos: 45, precio: 20, publico: Publico.hombres),
    Servicio(id: 7, nombre: 'Afeitado', categoria: CategoriaServicio.barba, duracionMinutos: 30, precio: 15, publico: Publico.hombres),
    Servicio(id: 8, nombre: 'Peinado evento', categoria: CategoriaServicio.peinado, duracionMinutos: 60, precio: 40, publico: Publico.unisex),
    Servicio(id: 9, nombre: 'Brushing', categoria: CategoriaServicio.peinado, duracionMinutos: 45, precio: 25, publico: Publico.mujeres),
    Servicio(id: 10, nombre: 'Hidratación', categoria: CategoriaServicio.tratamiento, duracionMinutos: 45, precio: 28, publico: Publico.unisex),
    Servicio(id: 11, nombre: 'Keratina', categoria: CategoriaServicio.tratamiento, duracionMinutos: 90, precio: 60, publico: Publico.unisex),
    Servicio(id: 12, nombre: 'Retoque de color', categoria: CategoriaServicio.color, duracionMinutos: 60, precio: 35, publico: Publico.unisex),
  ];

  Servicio s(int id) => servicios.firstWhere((x) => x.id == id);
  List<Servicio> varios(List<int> ids) => ids.map(s).toList();

  final estilistas = <Estilista>[
    // Solo mujeres (+ unisex)
    Estilista(id: 1, nombre: 'Marta Salazar', avatar: 'assets/images/avatares/marta.png', servicios: varios([1, 4, 5, 9, 12, 8])),
    // Solo hombres (+ unisex)
    Estilista(id: 2, nombre: 'Pedro Vega', avatar: 'assets/images/avatares/pedro.png', servicios: varios([2, 3, 6, 7, 10])),
    // Ambos públicos
    Estilista(id: 3, nombre: 'Lucía Torres', avatar: 'assets/images/avatares/lucia.png', servicios: varios([1, 2, 3, 10, 11, 8])),
    // Solo hombres (+ unisex)
    Estilista(id: 4, nombre: 'Rafael Núñez', avatar: 'assets/images/avatares/rafael.png', servicios: varios([2, 3, 6, 7])),
    // Solo mujeres (+ unisex)
    Estilista(id: 5, nombre: 'Camila Ortega', avatar: 'assets/images/avatares/camila.png', servicios: varios([4, 5, 9, 8, 11, 10, 12])),
  ];

  Cliente c(int id, String nombre, String tel, Genero g, int diasAtras, [String? correo]) => Cliente(
        id: id,
        nombre: nombre,
        telefono: tel,
        genero: g,
        correo: correo,
        registro: soloFecha(ahora).subtract(Duration(days: diasAtras)),
      );

  final clientes = <Cliente>[
    c(1, 'Laura Gómez', '52111222', Genero.mujer, 120, 'laura.gomez@correo.com'),
    c(2, 'Carlos Ruiz', '52345678', Genero.hombre, 95, 'carlos.ruiz@correo.com'),
    c(3, 'Ana Martín', '53220140', Genero.mujer, 80),
    c(4, 'Diego Pérez', '55908771', Genero.hombre, 60),
    c(5, 'Sofía Díaz', '54667310', Genero.mujer, 50, 'sofia.diaz@correo.com'),
    c(6, 'Javier Soto', '52774009', Genero.hombre, 40), // sin turnos
    c(7, 'Marta Peña', '53441902', Genero.mujer, 30),
    c(8, 'Elena Castro', '55123456', Genero.mujer, 25, 'elena.castro@correo.com'),
    c(9, 'Andrés Molina', '54890123', Genero.hombre, 20),
    c(10, 'Pablo Herrera', '53765432', Genero.hombre, 10),
  ];

  final dias = _diasAlrededor(ahora);

  // No hay solapes entre turnos programados del mismo estilista ni cliente.
  const plantillas = <_Plantilla>[
    // Día 0 (pasado)
    _Plantilla(1, 0, 9, 0, 1, 1, [1], notas: 'Quiere un corte con capas.'),
    _Plantilla(2, 0, 10, 0, 2, 2, [2, 6], notas: 'Prefiere la máquina en el número 2 a los lados. Llega siempre diez minutos antes y pide agua.'),
    // Día 1 (pasado): turno con 3 servicios y notas largas
    _Plantilla(3, 1, 9, 0, 3, 1, [1, 4, 9], notas: _notasLargas),
    _Plantilla(4, 1, 11, 0, 4, 4, [2], pasado: EstadoTurno.cancelado),
    // Día 2 (pasado)
    _Plantilla(5, 2, 10, 0, 5, 5, [5], notas: 'Canceló por viaje.', pasado: EstadoTurno.cancelado),
    _Plantilla(6, 2, 15, 0, 8, 3, [10, 8]), // sin notas
    // Día 3 (hoy)
    _Plantilla(7, 3, 9, 0, 1, 1, [1]),
    _Plantilla(8, 3, 10, 0, 2, 2, [2, 6], notas: 'Prefiere la máquina en el número 2 a los lados. Llega siempre diez minutos antes y pide agua.'),
    _Plantilla(9, 3, 10, 30, 3, 1, [12, 8], notas: 'Quiere el mismo tono de la última vez.'),
    _Plantilla(10, 3, 12, 0, 4, 2, [7]),
    _Plantilla(11, 3, 14, 0, 9, 3, [3]),
    // Día 4 (futuro): uno termina exactamente a las 19:00
    _Plantilla(12, 4, 9, 0, 10, 4, [2, 6]),
    _Plantilla(13, 4, 17, 30, 5, 5, [11], notas: 'Trae el cabello muy maltratado.'),
    // Día 5 (futuro)
    _Plantilla(14, 5, 10, 0, 2, 2, [3, 7]),
    _Plantilla(15, 5, 11, 0, 7, 1, [5], notas: 'Mechas rubias, tono ceniza.'),
    // Día 6 (futuro)
    _Plantilla(16, 6, 9, 30, 8, 3, [1]),
  ];

  final turnos = plantillas.map((p) {
    final d = dias[p.dia];
    final inicio = DateTime(d.year, d.month, d.day, p.hora, p.minuto);
    final estado = inicio.isBefore(ahora) ? p.pasado : EstadoTurno.programado;
    final base = soloFecha(ahora);
    final creado = DateTime(base.year, base.month, base.day - 5 - (p.id % 4), 10);
    final modificado = DateTime(creado.year, creado.month, creado.day + 1, 12);
    return Turno(
      id: p.id,
      clienteId: p.cliente,
      estilistaId: p.estilista,
      servicios: varios(p.servicios),
      inicio: inicio,
      notas: p.notas,
      estado: estado,
      creado: creado,
      modificado: modificado,
    );
  }).toList();

  return DatosPrueba(
    servicios: servicios,
    estilistas: estilistas,
    clientes: clientes,
    turnos: turnos,
  );
}
