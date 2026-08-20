import 'dart:convert';

import 'package:http/http.dart' as http;

class MarketQuote {
  const MarketQuote({
    required this.ticker,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.marketTime,
  });

  final String ticker;
  final String name;
  final double price;
  final double changePercent;
  final String marketTime;
}

class MarketSnapshot {
  const MarketSnapshot({
    required this.updatedAt,
    required this.source,
    required this.quotes,
  });

  final DateTime? updatedAt;
  final String source;
  final Map<String, MarketQuote> quotes;
}

abstract class MarketFeed {
  Future<MarketSnapshot> fetch();
}

class GithubJsonMarketFeed implements MarketFeed {
  const GithubJsonMarketFeed({
    this.url =
        'https://raw.githubusercontent.com/zorbirey/bist-portfoyum/main/prices.json',
  });

  final String url;

  @override
  Future<MarketSnapshot> fetch() async {
    final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 12),
        );

    if (response.statusCode != 200) {
      throw StateError('Fiyat verisi alınamadı (${response.statusCode}).');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const FormatException('Fiyat dosyası geçersiz.');
    }

    final rawPrices = decoded['prices'];
    if (rawPrices is! Map) {
      throw const FormatException('Fiyat listesi bulunamadı.');
    }

    final quotes = <String, MarketQuote>{};
    rawPrices.forEach((rawTicker, rawValue) {
      if (rawValue is! Map) return;
      final ticker = rawTicker.toString().trim().toUpperCase();
      if (ticker.isEmpty) return;
      quotes[ticker] = MarketQuote(
        ticker: ticker,
        name: (rawValue['name'] ?? ticker).toString(),
        price: _asDouble(rawValue['price']),
        changePercent: _asDouble(rawValue['changePct']),
        marketTime: (rawValue['marketTime'] ?? '').toString(),
      );
    });

    return MarketSnapshot(
      updatedAt: DateTime.tryParse((decoded['updatedAt'] ?? '').toString()),
      source: (decoded['source'] ?? 'Piyasa verisi').toString(),
      quotes: quotes,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
