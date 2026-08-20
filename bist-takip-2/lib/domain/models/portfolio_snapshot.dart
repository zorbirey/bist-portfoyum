class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.day,
    required this.portfolioValue,
    required this.totalPnl,
    required this.dailyPnl,
  });

  final DateTime day;
  final double portfolioValue;
  final double totalPnl;
  final double dailyPnl;

  String get dayKey =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
        'day': day.toIso8601String(),
        'portfolioValue': portfolioValue,
        'totalPnl': totalPnl,
        'dailyPnl': dailyPnl,
      };

  factory PortfolioSnapshot.fromJson(Map<String, Object?> json) {
    return PortfolioSnapshot(
      day: DateTime.parse(json['day'] as String),
      portfolioValue: (json['portfolioValue'] as num?)?.toDouble() ?? 0,
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0,
      dailyPnl: (json['dailyPnl'] as num?)?.toDouble() ?? 0,
    );
  }
}
