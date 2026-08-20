import 'dart:convert';

import 'package:bist_takip_2/data/legacy/legacy_backup_migrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.1.5 localStorage yedeğini açılış pozisyonlarına çevirir', () {
    final raw = jsonEncode({
      'app': 'BIST TAKİP',
      'version': 2,
      'storage': {
        'stocks': jsonEncode([
          {'code': 'tuprs', 'qty': 500, 'cost': 175.40},
          {'code': 'froto', 'qty': 20, 'cost': 910},
        ]),
        'annualTarget': '60000',
        'monthlyTarget': '5000',
      },
    });

    final result = const LegacyBackupMigrator().migrate(
      raw,
      importedAt: DateTime(2026, 8, 20),
    );

    expect(result.transactions.length, 2);
    expect(result.transactions.first.ticker, 'TUPRS');
    expect(result.transactions.first.quantity, 500);
    expect(result.transactions.first.unitPrice, 175.40);
    expect(result.annualTarget, 60000);
    expect(result.monthlyTarget, 5000);
    expect(result.warnings, isNotEmpty);
  });
}
