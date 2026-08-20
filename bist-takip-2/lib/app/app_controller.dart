import 'package:flutter/foundation.dart';

import '../data/legacy/legacy_backup_migrator.dart';
import '../data/local/local_portfolio_store.dart';
import '../data/market/market_feed.dart';
import '../domain/models/portfolio_transaction.dart';
import '../domain/services/portfolio_ledger.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.store,
    required this.marketFeed,
  });

  final LocalPortfolioStore store;
  final MarketFeed marketFeed;
  final PortfolioLedger _ledger = const PortfolioLedger();

  List<PortfolioTransaction> _transactions = const [];
  Map<String, MarketQuote> _quotes = const {};
  double _annualTarget = 0;
  double _monthlyTarget = 0;
  bool _refreshingMarket = false;
  String? _marketError;
  DateTime? _marketUpdatedAt;
  String _marketSource = '';

  List<PortfolioTransaction> get transactions =>
      List.unmodifiable(_transactions);
  Map<String, HoldingPosition> get holdings =>
      _ledger.calculate(_transactions);
  Map<String, MarketQuote> get quotes => Map.unmodifiable(_quotes);
  double get annualTarget => _annualTarget;
  double get monthlyTarget => _monthlyTarget;
  bool get refreshingMarket => _refreshingMarket;
  String? get marketError => _marketError;
  DateTime? get marketUpdatedAt => _marketUpdatedAt;
  String get marketSource => _marketSource;

  MarketQuote? quoteFor(String ticker) => _quotes[ticker.toUpperCase()];

  Future<void> load() async {
    final snapshot = await store.load();
    _transactions = snapshot.transactions;
    _annualTarget = snapshot.annualTarget;
    _monthlyTarget = snapshot.monthlyTarget;
    notifyListeners();
  }

  Future<void> refreshMarket() async {
    if (_refreshingMarket) return;
    _refreshingMarket = true;
    _marketError = null;
    notifyListeners();

    try {
      final snapshot = await marketFeed.fetch();
      _quotes = snapshot.quotes;
      _marketUpdatedAt = snapshot.updatedAt;
      _marketSource = snapshot.source;
    } catch (error) {
      _marketError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _refreshingMarket = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(PortfolioTransaction transaction) async {
    _transactions = [..._transactions, transaction]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions = _transactions.where((tx) => tx.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> importLegacy(LegacyMigrationResult migration) async {
    _transactions = [...migration.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    _annualTarget = migration.annualTarget;
    _monthlyTarget = migration.monthlyTarget;
    await _persist();
    notifyListeners();
    await refreshMarket();
  }

  Future<void> updateTargets({
    required double annualTarget,
    required double monthlyTarget,
  }) async {
    _annualTarget = annualTarget;
    _monthlyTarget = monthlyTarget;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => store.save(
        transactions: _transactions,
        annualTarget: _annualTarget,
        monthlyTarget: _monthlyTarget,
      );
}
