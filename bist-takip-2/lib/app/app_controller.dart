import 'package:flutter/foundation.dart';

import '../data/benchmarks/benchmark_feed.dart';
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
    required this.benchmarkFeed,
  });

  final LocalPortfolioStore store;
  final MarketFeed marketFeed;
  final DividendFeed dividendFeed;
  final BenchmarkFeed benchmarkFeed;
  final PortfolioLedger _ledger = const PortfolioLedger();

  List<PortfolioTransaction> _transactions = const [];
  List<PortfolioSnapshot> _snapshots = const [];
  Map<String, MarketQuote> _quotes = const {};
  List<DividendEvent> _dividendEvents = const [];
  Map<BenchmarkKind, BenchmarkPoint> _benchmarkPoints = const {};

  double _annualTarget = 0;
  double _monthlyTarget = 0;
  DateTime? _portfolioStartDate;

  bool _refreshingMarket = false;
  bool _refreshingDividends = false;
  bool _refreshingBenchmarks = false;

  String? _marketError;
  String? _dividendError;
  String? _benchmarkError;

  DateTime? _marketUpdatedAt;
  DateTime? _dividendUpdatedAt;
  DateTime? _benchmarkUpdatedAt;

  String _marketSource = '';
  String _dividendSource = '';
  String _benchmarkSource = '';

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
  DateTime? get portfolioStartDate => _portfolioStartDate;

  bool get refreshingMarket => _refreshingMarket;
  bool get refreshingDividends => _refreshingDividends;
  bool get refreshingBenchmarks => _refreshingBenchmarks;

  String? get marketError => _marketError;
  String? get dividendError => _dividendError;
  String? get benchmarkError => _benchmarkError;

  DateTime? get marketUpdatedAt => _marketUpdatedAt;
  DateTime? get dividendUpdatedAt => _dividendUpdatedAt;
  DateTime? get benchmarkUpdatedAt => _benchmarkUpdatedAt;

  String get marketSource => _marketSource;
  String get dividendSource => _dividendSource;
  String get benchmarkSource => _benchmarkSource;

  MarketQuote? quoteFor(String ticker) => _quotes[ticker.toUpperCase()];

  BenchmarkPoint? benchmarkFor(BenchmarkKind kind) =>
      _benchmarkPoints[kind];

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
      if (quote == null ||
          quote.price <= 0 ||
          quote.changePercent == -100) {
        continue;
      }
      final previous = quote.price / (1 + (quote.changePercent / 100));
      if (previous > 0) {
        total += (quote.price - previous) * holding.quantity;
      }
    }
    return total;
  }

  double? get portfolioReturnPercent {
    final start = _portfolioStartDate;
    if (start == null) return null;

    final end = DateTime.now();
    final totalSeconds = end.difference(start).inSeconds;
    if (totalSeconds <= 0) return null;

    double netFlow = 0;
    double weightedFlow = 0;
    var hasFlow = false;

    for (final tx in _transactions) {
      if (tx.date.isBefore(start)) continue;

      double flow;
      switch (tx.type) {
        case PortfolioTransactionType.opening:
        case PortfolioTransactionType.buy:
          flow = tx.grossAmount + tx.fee;
          break;
        case PortfolioTransactionType.sell:
          flow = -((tx.grossAmount) - tx.fee);
          break;
        case PortfolioTransactionType.dividend:
          flow = -tx.netDividend;
          break;
      }

      if (flow.abs() < 0.000001) continue;
      hasFlow = true;

      final elapsed = tx.date
          .difference(start)
          .inSeconds
          .clamp(0, totalSeconds)
          .toDouble();
      final weight = 1 - (elapsed / totalSeconds);

      netFlow += flow;
      weightedFlow += weight * flow;
    }

    if (!hasFlow || weightedFlow.abs() < 0.000001) {
      if (activeCostBasis <= 0) return null;
      return (totalPnl / activeCostBasis) * 100;
    }

    return ((portfolioValue - netFlow) / weightedFlow) * 100;
  }

  double dividendsForYear(int year) => _transactions
      .where(
        (tx) =>
            tx.type == PortfolioTransactionType.dividend &&
            tx.date.year == year,
      )
      .fold<double>(0, (sum, tx) => sum + tx.netDividend);

  double? recordedDividendForEvent(String ticker, DateTime date) {
    final id = _calendarDividendId(ticker, date);
    for (final tx in _transactions) {
      if (tx.id == id &&
          tx.type == PortfolioTransactionType.dividend) {
        return tx.netDividend;
      }
    }
    return null;
  }

  Future<void> load() async {
    final snapshot = await store.load();
    _transactions = snapshot.transactions;
    _snapshots = snapshot.snapshots;
    _annualTarget = snapshot.annualTarget;
    _monthlyTarget = snapshot.monthlyTarget;
    _portfolioStartDate =
        snapshot.portfolioStartDate ?? _inferStartDate(_transactions);
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

  Future<void> refreshBenchmarks() async {
    final start = _portfolioStartDate;
    if (start == null || _refreshingBenchmarks) return;

    _refreshingBenchmarks = true;
    _benchmarkError = null;
    notifyListeners();

    try {
      final snapshot = await benchmarkFeed.fetch(start);
      _benchmarkPoints = snapshot.points;
      _benchmarkUpdatedAt = snapshot.updatedAt;
      _benchmarkSource = snapshot.source;
    } catch (error) {
      _benchmarkError =
          error.toString().replaceFirst('Exception: ', '');
    } finally {
      _refreshingBenchmarks = false;
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

    if (transaction.type != PortfolioTransactionType.dividend) {
      final normalized = _dateOnly(transaction.date);
      if (_portfolioStartDate == null ||
          normalized.isBefore(_portfolioStartDate!)) {
        _portfolioStartDate = normalized;
      }
    }

    await _recordTodaySnapshot();
    await _persist();
    notifyListeners();
  }

  Future<void> recordDividend({
    required String ticker,
    required DateTime date,
    required double netAmount,
  }) async {
    if (netAmount <= 0) return;

    final id = _calendarDividendId(ticker, date);
    final next = PortfolioTransaction(
      id: id,
      ticker: ticker.toUpperCase(),
      type: PortfolioTransactionType.dividend,
      date: _dateOnly(date),
      netDividend: netAmount,
      note: 'Temettü takviminden kaydedildi',
    );

    _transactions = [
      ..._transactions.where((tx) => tx.id != id),
      next,
    ]..sort((a, b) => b.date.compareTo(a.date));

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
    _portfolioStartDate = _inferStartDate(_transactions);
    _snapshots = const [];
    _benchmarkPoints = const {};
    await _recordTodaySnapshot();
    await _persist();
    notifyListeners();
    await refreshMarket();
    await refreshBenchmarks();
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

  Future<void> updatePortfolioStartDate(DateTime date) async {
    final normalized = _dateOnly(date);
    _portfolioStartDate = normalized;

    _transactions = _transactions.map((tx) {
      final isLegacyOpening =
          tx.type == PortfolioTransactionType.opening ||
          tx.note == '1.1.5 yedeğinden açılış bakiyesi';
      return isLegacyOpening ? tx.copyWith(date: normalized) : tx;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    _benchmarkPoints = const {};
    await _persist();
    notifyListeners();
    await refreshBenchmarks();
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

  DateTime? _inferStartDate(List<PortfolioTransaction> source) {
    final relevant = source
        .where((tx) => tx.type != PortfolioTransactionType.dividend)
        .toList();
    if (relevant.isEmpty) return null;
    relevant.sort((a, b) => a.date.compareTo(b.date));
    return _dateOnly(relevant.first.date);
  }

  String _calendarDividendId(String ticker, DateTime date) {
    final day = _dateOnly(date);
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return 'div-calendar-${ticker.toUpperCase()}-$y$m$d';
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _persist() => store.save(
        transactions: _transactions,
        snapshots: _snapshots,
        annualTarget: _annualTarget,
        monthlyTarget: _monthlyTarget,
        portfolioStartDate: _portfolioStartDate,
      );
}
