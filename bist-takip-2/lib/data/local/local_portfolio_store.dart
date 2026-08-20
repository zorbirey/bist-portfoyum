import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/portfolio_snapshot.dart';
import '../../domain/models/portfolio_transaction.dart';

class LocalPortfolioSnapshot {
  const LocalPortfolioSnapshot({
    required this.transactions,
    required this.snapshots,
    required this.annualTarget,
    required this.monthlyTarget,
    required this.portfolioStartDate,
  });

  final List<PortfolioTransaction> transactions;
  final List<PortfolioSnapshot> snapshots;
  final double annualTarget;
  final double monthlyTarget;
  final DateTime? portfolioStartDate;
}

class LocalPortfolioStore {
  static const _transactionsKey = 'v2.transactions';
  static const _snapshotsKey = 'v2.snapshots';
  static const _annualTargetKey = 'v2.annualTarget';
  static const _monthlyTargetKey = 'v2.monthlyTarget';
  static const _portfolioStartDateKey = 'v2.portfolioStartDate';

  Future<LocalPortfolioSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = _decodeTransactions(
      prefs.getString(_transactionsKey),
    );
    final snapshots = _decodeSnapshots(
      prefs.getString(_snapshotsKey),
    );
    final rawStartDate = prefs.getString(_portfolioStartDateKey);

    return LocalPortfolioSnapshot(
      transactions: transactions,
      snapshots: snapshots,
      annualTarget: prefs.getDouble(_annualTargetKey) ?? 0,
      monthlyTarget: prefs.getDouble(_monthlyTargetKey) ?? 0,
      portfolioStartDate:
          rawStartDate == null ? null : DateTime.tryParse(rawStartDate),
    );
  }

  List<PortfolioTransaction> _decodeTransactions(String? raw) {
    final result = <PortfolioTransaction>[];
    if (raw == null || raw.trim().isEmpty) return result;

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          result.add(
            PortfolioTransaction.fromJson(
              Map<String, Object?>.from(item),
            ),
          );
        }
      }
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<PortfolioSnapshot> _decodeSnapshots(String? raw) {
    final result = <PortfolioSnapshot>[];
    if (raw == null || raw.trim().isEmpty) return result;

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          result.add(
            PortfolioSnapshot.fromJson(
              Map<String, Object?>.from(item),
            ),
          );
        }
      }
    }

    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  Future<void> save({
    required List<PortfolioTransaction> transactions,
    required List<PortfolioSnapshot> snapshots,
    required double annualTarget,
    required double monthlyTarget,
    required DateTime? portfolioStartDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((tx) => tx.toJson()).toList()),
    );
    await prefs.setString(
      _snapshotsKey,
      jsonEncode(snapshots.map((item) => item.toJson()).toList()),
    );
    await prefs.setDouble(_annualTargetKey, annualTarget);
    await prefs.setDouble(_monthlyTargetKey, monthlyTarget);

    if (portfolioStartDate == null) {
      await prefs.remove(_portfolioStartDateKey);
    } else {
      await prefs.setString(
        _portfolioStartDateKey,
        portfolioStartDate.toIso8601String(),
      );
    }
  }
}
