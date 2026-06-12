import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  test('formatBRL formata moeda no padrão brasileiro', () {
    expect(formatBRL(8), 'R\$ 8,00');
    expect(formatBRL(139.9), 'R\$ 139,90');
    expect(formatBRL(1234.56), 'R\$ 1.234,56');
  });

  test('monthLabel converte YYYY-MM para nome do mês', () {
    expect(monthLabel('2026-05'), 'Maio de 2026');
    expect(monthLabelShort('2026-12'), 'Dez/2026');
  });

  test('distanceInKm calcula distância plausível Campinas-Americana', () {
    final d = distanceInKm(-22.9056, -47.0608, -22.7392, -47.3313);
    expect(d, greaterThan(25));
    expect(d, lessThan(45));
  });
}
