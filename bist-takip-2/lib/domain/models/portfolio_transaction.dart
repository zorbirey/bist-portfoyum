enum PortfolioTransactionType { buy, sell, dividend }

class PortfolioTransaction {
  const PortfolioTransaction({
    required this.id,
    required this.ticker,
    required this.type,
    required this.date,
    this.quantity = 0,
    this.unitPrice = 0,
    this.fee = 0,
    this.netDividend = 0,
    this.note,
  });

  final String id;
  final String ticker;
  final PortfolioTransactionType type;
  final DateTime date;
  final double quantity;
  final double unitPrice;
  final double fee;
  final double netDividend;
  final String? note;

  double get grossAmount => quantity * unitPrice;

  Map<String, Object?> toJson() => {
        'id': id,
        'ticker': ticker,
        'type': type.name,
        'date': date.toIso8601String(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'fee': fee,
        'netDividend': netDividend,
        'note': note,
      };

  factory PortfolioTransaction.fromJson(Map<String, Object?> json) {
    return PortfolioTransaction(
      id: json['id'] as String,
      ticker: (json['ticker'] as String).toUpperCase(),
      type: PortfolioTransactionType.values.byName(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      netDividend: (json['netDividend'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
    );
  }
}
