import 'package:flutter_test/flutter_test.dart';
import 'package:bist_takip_2/domain/models/portfolio_transaction.dart';
import 'package:bist_takip_2/domain/services/portfolio_ledger.dart';

void main() {
  test('ağırlıklı maliyet ve satış kârını hesaplar', () {
    final ledger = PortfolioLedger();
    final rows = [
      PortfolioTransaction(
        id: '1', ticker: 'TUPRS', type: PortfolioTransactionType.buy,
        date: DateTime(2026, 1, 1), quantity: 100, unitPrice: 100,
      ),
      PortfolioTransaction(
        id: '2', ticker: 'TUPRS', type: PortfolioTransactionType.buy,
        date: DateTime(2026, 2, 1), quantity: 100, unitPrice: 120,
      ),
      PortfolioTransaction(
        id: '3', ticker: 'TUPRS', type: PortfolioTransactionType.sell,
        date: DateTime(2026, 3, 1), quantity: 50, unitPrice: 140,
      ),
    ];

    final position = ledger.calculate(rows)['TUPRS']!;
    expect(position.quantity, 150);
    expect(position.averageCost, 110);
    expect(position.realizedPnl, 1500);
  });

  test('net temettüyü pozisyona ekler', () {
    final ledger = PortfolioLedger();
    final rows = [
      PortfolioTransaction(
        id: '1', ticker: 'FROTO', type: PortfolioTransactionType.dividend,
        date: DateTime(2026, 4, 1), netDividend: 2500,
      ),
    ];

    expect(ledger.calculate(rows)['FROTO']!.netDividends, 2500);
  });
}
