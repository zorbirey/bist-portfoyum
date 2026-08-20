import 'package:bist_takip_2/domain/models/portfolio_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gün anahtarı tarih bazında sabit üretilir', () {
    final snapshot = PortfolioSnapshot(
      day: DateTime(2026, 8, 20, 18, 45),
      portfolioValue: 100000,
      totalPnl: 5000,
      dailyPnl: 750,
    );

    expect(snapshot.dayKey, '2026-08-20');

    final restored = PortfolioSnapshot.fromJson(snapshot.toJson());
    expect(restored.portfolioValue, 100000);
    expect(restored.totalPnl, 5000);
    expect(restored.dailyPnl, 750);
  });
}
