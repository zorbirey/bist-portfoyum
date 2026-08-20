import 'dart:convert';

import '../../domain/models/portfolio_transaction.dart';

class LegacyMigrationResult {
  const LegacyMigrationResult({
    required this.transactions,
    required this.annualTarget,
    required this.monthlyTarget,
    required this.warnings,
  });

  final List<PortfolioTransaction> transactions;
  final double annualTarget;
  final double monthlyTarget;
  final List<String> warnings;
}

class LegacyBackupMigrator {
  const LegacyBackupMigrator();

  LegacyMigrationResult migrate(String rawJson, {DateTime? importedAt}) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Geçersiz BIST TAKİP yedeği.');
    }

    final storage = <String, dynamic>{};
    if (decoded['storage'] is Map) {
      (decoded['storage'] as Map).forEach((key, value) {
        storage[key.toString()] = value;
      });
    } else {
      storage.addAll(decoded);
    }

    final warnings = <String>[];
    final stocks = _decodeList(storage['stocks']);
    final date = importedAt ?? DateTime.now();
    final transactions = <PortfolioTransaction>[];

    for (var i = 0; i < stocks.length; i++) {
      final item = stocks[i];
      if (item is! Map) continue;
      final ticker = (item['code'] ?? '').toString().trim().toUpperCase();
      final quantity = _asDouble(item['qty']);
      final averageCost = _asDouble(item['cost']);
      if (ticker.isEmpty || quantity <= 0) continue;

      transactions.add(
        PortfolioTransaction(
          id: 'legacy-${date.microsecondsSinceEpoch}-$i',
          ticker: ticker,
          type: PortfolioTransactionType.opening,
          date: date,
          quantity: quantity,
          unitPrice: averageCost,
          note: '1.1.5 yedeğinden açılış bakiyesi',
        ),
      );
    }

    if (transactions.isNotEmpty) {
      warnings.add(
        '1.1.5 eski alış/satış tarihlerini tutmadığı için pozisyonlar 2.0 açılış bakiyesi olarak aktarılır. Benchmark kıyası için başlangıç tarihini Ayarlar bölümünden kontrol et.',
      );
    }

    return LegacyMigrationResult(
      transactions: transactions,
      annualTarget: _asDouble(storage['annualTarget']),
      monthlyTarget: _asDouble(storage['monthlyTarget']),
      warnings: warnings,
    );
  }

  List<dynamic> _decodeList(dynamic value) {
    if (value is List) return value;
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is! String) return 0;

    var text = value.trim().replaceAll(' ', '');
    if (text.isEmpty) return 0;

    final comma = text.lastIndexOf(',');
    final dot = text.lastIndexOf('.');

    if (comma >= 0 && dot >= 0) {
      if (comma > dot) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (comma >= 0) {
      final decimals = text.length - comma - 1;
      text = decimals >= 1 && decimals <= 4
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (dot >= 0) {
      final decimals = text.length - dot - 1;
      if (decimals > 4) {
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text) ?? 0;
  }
}
