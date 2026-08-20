import '../models/portfolio_transaction.dart';

class HoldingPosition {
  const HoldingPosition({
    required this.ticker,
    required this.quantity,
    required this.averageCost,
    required this.realizedPnl,
    required this.netDividends,
  });

  final String ticker;
  final double quantity;
  final double averageCost;
  final double realizedPnl;
  final double netDividends;

  double get costBasis => quantity * averageCost;
}

class PortfolioLedger {
  const PortfolioLedger();

  Map<String, HoldingPosition> calculate(List<PortfolioTransaction> source) {
    final transactions = [...source]..sort((a, b) => a.date.compareTo(b.date));
    final states = <String, _MutableHolding>{};

    for (final tx in transactions) {
      final ticker = tx.ticker.toUpperCase();
      final state = states.putIfAbsent(ticker, () => _MutableHolding(ticker));

      switch (tx.type) {
        case PortfolioTransactionType.buy:
          if (tx.quantity <= 0 || tx.unitPrice < 0) continue;
          final oldCost = state.quantity * state.averageCost;
          final incomingCost = (tx.quantity * tx.unitPrice) + tx.fee;
          final newQuantity = state.quantity + tx.quantity;
          state.averageCost = newQuantity == 0 ? 0 : (oldCost + incomingCost) / newQuantity;
          state.quantity = newQuantity;
          break;
        case PortfolioTransactionType.sell:
          if (tx.quantity <= 0 || tx.quantity > state.quantity) continue;
          final proceeds = (tx.quantity * tx.unitPrice) - tx.fee;
          final removedCost = tx.quantity * state.averageCost;
          state.realizedPnl += proceeds - removedCost;
          state.quantity -= tx.quantity;
          if (state.quantity.abs() < 0.0000001) {
            state.quantity = 0;
            state.averageCost = 0;
          }
          break;
        case PortfolioTransactionType.dividend:
          state.netDividends += tx.netDividend;
          break;
      }
    }

    return {
      for (final entry in states.entries)
        entry.key: HoldingPosition(
          ticker: entry.key,
          quantity: entry.value.quantity,
          averageCost: entry.value.averageCost,
          realizedPnl: entry.value.realizedPnl,
          netDividends: entry.value.netDividends,
        ),
    };
  }
}

class _MutableHolding {
  _MutableHolding(this.ticker);

  final String ticker;
  double quantity = 0;
  double averageCost = 0;
  double realizedPnl = 0;
  double netDividends = 0;
}
