import 'package:flutter/foundation.dart';

import '../data/dividends/dividend_feed.dart';
import '../data/legacy/legacy_backup_migrator.dart';
import '../data/local/local_portfolio_store.dart';
import '../data/market/market_feed.dart';
import '../domain/models/portfolio_snapshot.dart';
import '../domain/models/portfolio_transaction.dart';
import '../domain/services/portfolio_ledger.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.store,
    required this.marketFeed,
    required this.dividendFeed,
  });

  final LocalPortfolioStore store;
  final MarketFeed marketFeed;
  final DividendFeed dividendFeed;
  final PortfolioLedger _ledger = const PortfolioLedger();

  List<PortfolioTransaction> _transactions = const [];
  List<PortfolioSnapshot> _snapshots = const [];
  Map<String, MarketQuote> _quotes = const {};
  List<DividendEvent> _dividendEvents = const [];
  double _annualTarget = 0;
  double _monthlyTarget = 0;
  bool _refreshingMarket = false;
  bool _refreshingDividends = false;
  String? _marketError;
  String? _dividendError;
  DateTime? _marketUpdatedAt;
  DateTime? _dividendUpdatedAt;
  String _marketSource = '';
  String _dividendSource = '';

  List<PortfolioTransaction> get transactions =>
      List.unmodifiable(_transactions);
  List<PortfolioSnapshot> get snapshots => List.unmodifiable(_snapshots);
  Map<String, HoldingPosition> get holdings =>
      _ledger.calculate(_transactions);
  Map<String, MarketQuote> get quotes => Map.unmodifiable(_quotes);
  List<DividendEvent> get dividendEvents =>
      List.unmodifiable(_dividendEvents);
  double get annualTarget => _annualTarget;
  double get monthlyTarget => _monthlyTarget;
  bool get refreshingMarket => _refreshingMarket;
  bool get refreshingDividends => _refreshingDividends;
  String? get marketError => _marketError;
  String? get dividendError => _dividendError;
  DateTime? get marketUpdatedAt => _marketUpdatedAt;
  DateTime? get dividendUpdatedAt => _dividendUpdatedAt;
  String get marketSource => _marketSource;
  String get dividendSource => _dividendSource;

  MarketQuote? quoteFor(String ticker) => _quotes[ticker.toUpperCase()];

  double get portfolioValue {
    double total = 0;
    for (final holding in holdings.values) {
      if (holding.quantity <= 0) continue;
      final quote = quoteFor(holding.ticker);
      if (quote == null || quote.price <= 0) continue;
      total += holding.quantity * quote.price;
    }
    return total;
  }

  double get activeCostBasis => holdings.values
      .where((holding) => holding.quantity > 0)
      .fold<double>(0, (sum, holding) => sum + holding.costBasis);

  double get totalPnl {
    double total = holdings.values.fold<double>(
      0,
      (sum, holding) =>
          sum + holding.realizedPnl + holding.netDividends,
    );

    for (final holding in holdings.values) {
      if (holding.quantity <= 0) continue;
      final quote = quoteFor(holding.ticker);
      if (quote == null || quote.price <= 0) continue;
      total += (quote.price - holding.averageCost) * holding.quantity;
    }
    return total;
  }

  double get dailyPnl {
    double total = 0;
    for (final holding in holdings.values) {
      if (holding.quantity <= 0) continue;
      final quote = quoteFor(holding.ticker);
      if (quote == null || quote.price <= 0 || quote.changePercent == -100) {
        continue;
      }
      final previous = quote.price / (1 + (quote.changePercent / 100));
      if (previous > 0) {
        total += (quote.price - previous) * holding.quantity;
      }
    }
    return total;
  }

  double dividendsForYear(int year) => _transactions
      .where(
        (tx) =>
            tx.type == PortfolioTransactionType.dividend &&
            tx.date.year == year,
      )
      .fold<double>(0, (sum, tx) => sum + tx.netDividend);

  Future<void> load() async {
    final snapshot = await store.load();
    _transactions = snapshot.transactions;
    _snapshots = snapshot.snapshots;
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
      await _recordTodaySnapshot();
      await _persist();
    } catch (error) {
      _marketError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _refreshingMarket = false;
      notifyListeners();
    }
  }

  Future<void> refreshDividends() async {
    if (_refreshingDividends) return;
    _refreshingDividends = true;
    _dividendError = null;
    notifyListeners();

    try {
      final snapshot = await dividendFeed.fetch();
      _dividendEvents = snapshot.events;
      _dividendUpdatedAt = snapshot.updatedAt;
      _dividendSource = snapshot.source;
    } catch (error) {
      _dividendError =
          error.toString().replaceFirst('Exception: ', '');
    } finally {
      _refreshingDividends = false;
      notifyListeners();
    }
  }

  List<DividendEvent> dividendEventsForPortfolio({int? year}) {
    final activeCodes = holdings.values
        .where((holding) => holding.quantity > 0)
        .map((holding) => holding.ticker)
        .toSet();

    return _dividendEvents
        .where(
          (event) =>
              activeCodes.contains(event.ticker) &&
              (year == null || event.date.year == year),
        )
        .toList();
  }

  Future<void> addTransaction(PortfolioTransaction transaction) async {
    _transactions = [..._transactions, transaction]
      ..sort((a, b) => b.date.compareTo(a.date));
    await _recordTodaySnapshot();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions = _transactions.where((tx) => tx.id != id).toList();
    await _recordTodaySnapshot();
    await _persist();
    notifyListeners();
  }

  Future<void> importLegacy(LegacyMigrationResult migration) async {
    _transactions = [...migration.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    _annualTarget = migration.annualTarget;
    _monthlyTarget = migration.monthlyTarget;
    _snapshots = const [];
    await _recordTodaySnapshot();
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

  Future<void> _recordTodaySnapshot() async {
    if (_quotes.isEmpty || holdings.isEmpty) return;

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final next = PortfolioSnapshot(
      day: day,
      portfolioValue: portfolioValue,
      totalPnl: totalPnl,
      dailyPnl: dailyPnl,
    );

    final updated = [..._snapshots];
    final index = updated.indexWhere((item) => item.dayKey == next.dayKey);
    if (index >= 0) {
      updated[index] = next;
    } else {
      updated.add(next);
    }

    updated.sort((a, b) => a.day.compareTo(b.day));
    if (updated.length > 730) {
      updated.removeRange(0, updated.length - 730);
    }
    _snapshots = updated;
  }

  Future<void> _persist() => store.save(
        transactions: _transactions,
        snapshots: _snapshots,
        annualTarget: _annualTarget,
        monthlyTarget: _monthlyTarget,
      );
}
