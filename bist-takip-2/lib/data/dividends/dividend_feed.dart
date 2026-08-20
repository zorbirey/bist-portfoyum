import 'dart:convert';

import 'package:http/http.dart' as http;

class DividendEvent {
  const DividendEvent({
    required this.ticker,
    required this.name,
    required this.date,
    required this.grossPerShare,
    required this.netPerShare,
    required this.withholdingRate,
    required this.source,
  });

  final String ticker;
  final String name;
  final DateTime date;
  final double grossPerShare;
  final double netPerShare;
  final double withholdingRate;
  final String source;

  bool get isPaid {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today) || date.isAtSameMomentAs(today);
  }

  factory DividendEvent.fromJson(Map<String, dynamic> json) {
    return DividendEvent(
      ticker: (json['code'] ?? '').toString().trim().toUpperCase(),
      name: (json['name'] ?? '').toString(),
      date: _parseTrDate((json['date'] ?? '').toString()),
      grossPerShare: _asDouble(json['grossPerShare']),
      netPerShare: _asDouble(json['netPerShare']),
      withholdingRate: _asDouble(json['withholdingRate']),
      source: (json['source'] ?? '').toString(),
    );
  }

  static DateTime _parseTrDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      throw FormatException('Geçersiz temettü tarihi: $value');
    }
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DividendSnapshot {
  const DividendSnapshot({
    required this.updatedAt,
    required this.source,
    required this.events,
  });

  final DateTime? updatedAt;
  final String source;
  final List<DividendEvent> events;
}

abstract class DividendFeed {
  Future<DividendSnapshot> fetch();
}

class GithubJsonDividendFeed implements DividendFeed {
  const GithubJsonDividendFeed({
    this.url =
        'https://raw.githubusercontent.com/zorbirey/bist-portfoyum/main/dividends.json',
  });

  final String url;

  @override
  Future<DividendSnapshot> fetch() async {
    final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 12),
        );
    if (response.statusCode != 200) {
      throw StateError(
        'Temettü verisi alınamadı (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const FormatException('Temettü dosyası geçersiz.');
    }

    final raw = decoded['dividends'];
    if (raw is! List) {
      throw const FormatException('Temettü listesi bulunamadı.');
    }

    final events = <DividendEvent>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        final event = DividendEvent.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (event.ticker.isNotEmpty) events.add(event);
      } catch (_) {
        // Tek bozuk satır tüm takvimi durdurmasın.
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return DividendSnapshot(
      updatedAt: DateTime.tryParse(
        (decoded['updatedAt'] ?? '').toString(),
      ),
      source: (decoded['source'] ?? 'Temettü takvimi').toString(),
      events: events,
    );
  }
}
