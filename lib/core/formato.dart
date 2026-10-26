/// Utilidades de formato de fechas, horas, precios y texto (sin paquete intl).

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _diasLargos = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];
const _diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasMinusculas = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dos(int n) => n.toString().padLeft(2, '0');

String _capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// 09:30
String horaTexto(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

/// 1 h 30 min, 45 min, 2 h
String duracionTexto(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// Miércoles 21 de octubre de 2026
String fechaLarga(DateTime d) =>
    '${_capitalizar(_diasLargos[d.weekday - 1])} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// 21/10/2026
String fechaCorta(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

/// 21/10
String diaMesCorto(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

/// Octubre 2026
String mesAnio(DateTime d) => '${_capitalizar(_meses[d.month - 1])} ${d.year}';

/// mié 21 de octubre
String fechaParaAviso(DateTime d) =>
    '${_diasMinusculas[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

/// Lun, Mar, Mié...
String diaSemanaCorto(DateTime d) => _diasCortos[d.weekday - 1];

/// $ 45
String precioTexto(int precio) => '\$ $precio';

/// 52345678 -> 52 345 678
String telefonoTexto(String t) => t.length == 8
    ? '${t.substring(0, 2)} ${t.substring(2, 5)} ${t.substring(5)}'
    : t;

/// Quita acentos y la ñ (para comparar textos).
String quitarAcentos(String s) {
  const con = 'áàäâãéèëêíìïîóòöôõúùüûñÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑ';
  const sin = 'aaaaaeeeeiiiiooooouuuunAAAAAEEEEIIIIOOOOOUUUUN';
  final sb = StringBuffer();
  for (final c in s.split('')) {
    final i = con.indexOf(c);
    sb.write(i >= 0 ? sin[i] : c);
  }
  return sb.toString();
}

/// Minúsculas, sin acentos y sin espacios a los lados.
String normalizar(String s) => quitarAcentos(s.toLowerCase()).trim();

/// Inicial en mayúscula de un nombre (para avatares).
String inicial(String nombre) =>
    nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
