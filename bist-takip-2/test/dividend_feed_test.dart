import 'package:bist_takip_2/data/dividends/dividend_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temettü satırını Türkçe tarihle çözer', () {
    final event = DividendEvent.fromJson({
      'code': 'tuprs',
      'name': 'Tüpraş',
      'date': '16.03.2026',
      'grossPerShare': 10.376471,
      'netPerShare': 8.82,
      'withholdingRate': 15,
      'source': 'test',
    });

    expect(event.ticker, 'TUPRS');
    expect(event.date, DateTime(2026, 3, 16));
    expect(event.netPerShare, 8.82);
    expect(event.withholdingRate, 15);
  });
}
