import 'dart:convert';

import 'package:http/http.dart' as http;

enum BenchmarkKind { bist100, usdTry, gramGold }

class BenchmarkPoint {
  const BenchmarkPoint({
    required this.kind,
    required this.label,
    required this.startValue,
    required this.endValue,
  });

  final BenchmarkKind kind;
  final String label;
  final double startValue;
  final double endValue;

  double get returnPercent =>
      startValue > 0 ? ((endValue / startValue) - 1) * 100 : 0;
}

class BenchmarkSnapshot {
  const BenchmarkSnapshot({
    required this.startDate,
    required this.points,
    required this.updatedAt,
    required this.source,
  });

  final DateTime startDate;
  final Map<BenchmarkKind, BenchmarkPoint> points;
  final DateTime updatedAt;
  final String source;
}

abstract class BenchmarkFeed {
  Future<BenchmarkSnapshot> fetch(DateTime startDate);
}

/// Prototype-only source. Commercial release should swap this implementation
/// for a licensed market-data provider without changing the UI/controller.
class YahooPrototypeBenchmarkFeed implements BenchmarkFeed {
  const YahooPrototypeBenchmarkFeed();

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 BIST-TAKIP/2.0';

  @override
  Future<BenchmarkSnapshot> fetch(DateTime startDate) async {
    final series = await Future.wait([
      _fetchSeries('XU100.IS', startDate),
      _fetchSeries('TRY=X', startDate),
      _fetchSeries('GC=F', startDate),
    ]);

    final bist = series[0];
    final usd = series[1];
    final goldUsdOunce = series[2];

    const gramsPerOunce = 31.1034768;
    final gramGoldStart =
        (goldUsdOunce.startValue * usd.startValue) / gramsPerOunce;
    final gramGoldEnd =
        (goldUsdOunce.endValue * usd.endValue) / gramsPerOunce;

    return BenchmarkSnapshot(
      startDate: startDate,
      updatedAt: DateTime.now(),
      source: 'Yahoo Finance prototip veri',
      points: {
        BenchmarkKind.bist100: BenchmarkPoint(
          kind: BenchmarkKind.bist100,
          label: 'BIST 100',
          startValue: bist.startValue,
          endValue: bist.endValue,
        ),
        BenchmarkKind.usdTry: BenchmarkPoint(
          kind: BenchmarkKind.usdTry,
          label: 'Dolar',
          startValue: usd.startValue,
          endValue: usd.endValue,
        ),
        BenchmarkKind.gramGold: BenchmarkPoint(
          kind: BenchmarkKind.gramGold,
          label: 'Gram Altın',
          startValue: gramGoldStart,
          endValue: gramGoldEnd,
        ),
      },
    );
  }

  Future<_SeriesRange> _fetchSeries(String symbol, DateTime startDate) async {
    final period1 = startDate
            .subtract(const Duration(days: 10))
            .toUtc()
            .millisecondsSinceEpoch ~/
        1000;
    final period2 = DateTime.now()
                .add(const Duration(days: 2))
                .toUtc()
                .millisecondsSinceEpoch ~/
            1000;

    final base = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(symbol)}',
    );
    final uri = base.replace(queryParameters: {
      'period1': '$period1',
      'period2': '$period2',
      'interval': '1d',
      'events': 'history',
      'includeAdjustedClose': 'true',
    });

    final response = await http.get(
      uri,
      headers: const {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      throw Exception('$symbol benchmark verisi alınamadı.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('$symbol benchmark yanıtı geçersiz.');
    }

    final chart = decoded['chart'];
    if (chart is! Map) {
      throw Exception('$symbol benchmark yanıtı eksik.');
    }

    if (chart['error'] != null) {
      throw Exception('$symbol benchmark kaynağı hata döndürdü.');
    }

    final results = chart['result'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      throw Exception('$symbol için tarihsel veri bulunamadı.');
    }

    final result = Map<String, dynamic>.from(results.first as Map);
    final timestamps = (result['timestamp'] as List?) ?? const [];
    final indicators = result['indicators'];
    if (indicators is! Map) {
      throw Exception('$symbol fiyat serisi bulunamadı.');
    }

    final quotes = indicators['quote'];
    if (quotes is! List || quotes.isEmpty || quotes.first is! Map) {
      throw Exception('$symbol kapanış serisi bulunamadı.');
    }

    final closes = (quotes.first as Map)['close'];
    if (closes is! List) {
      throw Exception('$symbol kapanış serisi geçersiz.');
    }

    final rows = <_SeriesRow>[];
    final length = timestamps.length < closes.length
        ? timestamps.length
        : closes.length;

    for (var i = 0; i < length; i++) {
      final timestamp = timestamps[i];
      final close = closes[i];
      if (timestamp is! num || close is! num || close <= 0) continue;
      rows.add(
        _SeriesRow(
          date: DateTime.fromMillisecondsSinceEpoch(
            timestamp.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          value: close.toDouble(),
        ),
      );
    }

    if (rows.isEmpty) {
      throw Exception('$symbol için kullanılabilir kapanış bulunamadı.');
    }

    rows.sort((a, b) => a.date.compareTo(b.date));
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);

    _SeriesRow? startRow;
    for (final row in rows) {
      final day = DateTime(row.date.year, row.date.month, row.date.day);
      if (!day.isBefore(startDay)) {
        startRow = row;
        break;
      }
    }

    startRow ??= rows.first;
    final endRow = rows.last;

    return _SeriesRange(
      startValue: startRow.value,
      endValue: endRow.value,
    );
  }
}

class _SeriesRow {
  const _SeriesRow({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class _SeriesRange {
  const _SeriesRange({
    required this.startValue,
    required this.endValue,
  });

  final double startValue;
  final double endValue;
}
