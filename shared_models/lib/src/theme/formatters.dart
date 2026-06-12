import 'dart:math' as math;

const _monthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// "R$ 1.234,56"
String formatBRL(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'R\$ $buffer,${parts[1]}';
}

/// "11/06/2026"
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// "09:57"
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// "11/06/2026 09:57"
String formatDateTime(DateTime d) => '${formatDate(d)} ${formatTime(d)}';

/// "2026-05" → "Maio de 2026"
String monthLabel(String referenceMonth) {
  final year = referenceMonth.substring(0, 4);
  final month = int.parse(referenceMonth.substring(5, 7));
  return '${_monthNames[month - 1]} de $year';
}

/// "2026-05" → "Mai/2026" (rótulo curto para tabelas)
String monthLabelShort(String referenceMonth) {
  final year = referenceMonth.substring(0, 4);
  final month = int.parse(referenceMonth.substring(5, 7));
  return '${_monthNames[month - 1].substring(0, 3)}/$year';
}

/// Distância haversine em km (geolocalização mockada no POC).
double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;
