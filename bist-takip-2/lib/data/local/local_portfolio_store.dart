import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/portfolio_transaction.dart';

class LocalPortfolioSnapshot {
  const LocalPortfolioSnapshot({
    required this.transactions,
    required this.annualTarget,
    required this.monthlyTarget,
  });

  final List<PortfolioTransaction> transactions;
  final double annualTarget;
  final double monthlyTarget;
}

class LocalPortfolioStore {
  static const _transactionsKey = 'v2.transactions';
  static const _annualTargetKey = 'v2.annualTarget';
  static const _monthlyTargetKey = 'v2.monthlyTarget';

  Future<LocalPortfolioSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    final transactions = <PortfolioTransaction>[];

    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            transactions.add(
              PortfolioTransaction.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
        }
      }
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return LocalPortfolioSnapshot(
      transactions: transactions,
      annualTarget: prefs.getDouble(_annualTargetKey) ?? 0,
      monthlyTarget: prefs.getDouble(_monthlyTargetKey) ?? 0,
    );
  }

  Future<void> save({
    required List<PortfolioTransaction> transactions,
    required double annualTarget,
    required double monthlyTarget,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((tx) => tx.toJson()).toList()),
    );
    await prefs.setDouble(_annualTargetKey, annualTarget);
    await prefs.setDouble(_monthlyTargetKey, monthlyTarget);
  }
}
