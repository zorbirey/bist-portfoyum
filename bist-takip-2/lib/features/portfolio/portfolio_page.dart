import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../../data/benchmarks/benchmark_feed.dart';
import '../../data/market/market_feed.dart';
import '../../domain/services/portfolio_ledger.dart';
import '../shared/page_widgets.dart';
import '../transactions/transaction_form_page.dart';
import '../transactions/transaction_history_page.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key, required this.controller});

  final AppController controller;

  Future<void> _openTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(controller: controller),
      ),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      controller.refreshMarket(),
      controller.refreshBenchmarks(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final holdings = controller.holdings.values
            .where((holding) => holding.quantity > 0)
            .toList()
          ..sort((a, b) => a.ticker.compareTo(b.ticker));

        final portfolioValue = controller.portfolioValue;
        final totalPnl = controller.totalPnl;
        final dailyPnl = controller.dailyPnl;
        final money = NumberFormat('#,##0.00', 'tr_TR');

        final marketStatus = controller.refreshingMarket
            ? 'Fiyatlar güncelleniyor'
            : controller.marketError != null
                ? controller.marketError!
                : controller.marketUpdatedAt == null
                    ? 'Fiyat verisi bekleniyor'
                    : '${controller.marketSource} · ${DateFormat('dd.MM HH:mm').format(controller.marketUpdatedAt!.toLocal())}';

        final start = controller.portfolioStartDate;
        final benchmarkStatus = start == null
            ? 'Benchmark kıyası için portföy başlangıç tarihi gerekli.'
            : controller.refreshingBenchmarks
                ? 'BIST 100, Dolar ve Altın karşılaştırması güncelleniyor'
                : controller.benchmarkError != null
                    ? controller.benchmarkError!
                    : controller.benchmarkUpdatedAt == null
                        ? 'Benchmark verisi bekleniyor'
                        : '${controller.benchmarkSource} · ${DateFormat('dd.MM HH:mm').format(controller.benchmarkUpdatedAt!.toLocal())}';

        final bist = controller.benchmarkFor(BenchmarkKind.bist100);
        final usd = controller.benchmarkFor(BenchmarkKind.usdTry);
        final gold = controller.benchmarkFor(BenchmarkKind.gramGold);

        return PageFrame(
          title: 'BIST TAKİP 2.0',
          subtitle:
              'Portföyün, gerçek getirilerin ve temettü gelirlerin tek yerde',
          actions: [
            IconButton(
              tooltip: 'Verileri yenile',
              onPressed: controller.refreshingMarket ||
                      controller.refreshingBenchmarks
                  ? null
                  : _refreshAll,
              icon: controller.refreshingMarket ||
                      controller.refreshingBenchmarks
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'PORTFÖY DEĞERİ',
                      value: '${money.format(portfolioValue)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'TOPLAM KÂR / ZARAR',
                      value:
                          '${totalPnl >= 0 ? '+' : ''}${money.format(totalPnl)} ₺',
                      valueColor: totalPnl > 0
                          ? Colors.green.shade700
                          : totalPnl < 0
                              ? Colors.red.shade700
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'BUGÜN',
                      value:
                          '${dailyPnl >= 0 ? '+' : ''}${money.format(dailyPnl)} ₺',
                      valueColor: dailyPnl > 0
                          ? Colors.green.shade700
                          : dailyPnl < 0
                              ? Colors.red.shade700
                              : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'TOPLAM MALİYET',
                      value: '${money.format(controller.activeCostBasis)} ₺',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(marketStatus, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 18),
              Text(
                'Başlangıçtan Bugüne Karşılaştırma',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                start == null
                    ? 'Başlangıç tarihi: Ayarlar bölümünden belirle'
                    : 'Başlangıç: ${DateFormat('dd.MM.yyyy').format(start)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.9,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  ReturnCard(
                    label: 'PORTFÖY',
                    value: controller.portfolioReturnPercent,
                    subtitle: 'Nakit akışı düzeltilmiş',
                  ),
                  ReturnCard(
                    label: 'BIST 100',
                    value: bist?.returnPercent,
                    subtitle: 'XU100',
                  ),
                  ReturnCard(
                    label: 'DOLAR',
                    value: usd?.returnPercent,
                    subtitle: 'USD/TRY',
                  ),
                  ReturnCard(
                    label: 'GRAM ALTIN',
                    value: gold?.returnPercent,
                    subtitle: 'Ons × USD/TRY',
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                benchmarkStatus,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Gram altın karşılaştırması geliştirici sürümünde ons altın ve USD/TRY referansından türetilir. Ticari sürümde lisanslı veri kaynağı kullanılacak.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Portföyüm',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionHistoryPage(controller: controller),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('İŞLEMLER'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (holdings.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Henüz 2.0 portföy kaydı yok. İlk alışını ekleyebilir veya 1.1.5 yedeğini Ayarlar bölümünden içe aktarabilirsin.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => _openTransaction(context),
                          icon: const Icon(Icons.add_chart),
                          label: const Text('İLK İŞLEMİ EKLE'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...holdings.map(
                  (holding) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PortfolioStockCard(
                      holding: holding,
                      quote: controller.quoteFor(holding.ticker),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _openTransaction(context),
                icon: const Icon(Icons.add),
                label: const Text('YENİ İŞLEM EKLE'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PortfolioStockCard extends StatelessWidget {
  const PortfolioStockCard({
    super.key,
    required this.holding,
    required this.quote,
  });

  final HoldingPosition holding;
  final MarketQuote? quote;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00', 'tr_TR');
    final number = NumberFormat('#,##0.##', 'tr_TR');
    final currentPrice = quote?.price ?? 0;
    final totalCost = holding.averageCost * holding.quantity;
    final currentValue = currentPrice * holding.quantity;
    final profitLoss =
        currentPrice > 0 ? currentValue - totalCost : 0;
    final profitPercent = totalCost > 0 && currentPrice > 0
        ? (profitLoss / totalCost) * 100
        : 0;

    final isProfit = profitLoss > 0;
    final isLoss = profitLoss < 0;
    final statusColor = isProfit
        ? Colors.green.shade700
        : isLoss
            ? Colors.red.shade700
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final priceBackground = isProfit
        ? Colors.green.shade50
        : isLoss
            ? Colors.red.shade50
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    final daily = quote?.changePercent ?? 0;
    final dailyColor = daily > 0
        ? Colors.green.shade700
        : daily < 0
            ? Colors.red.shade700
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;

            final nameBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.ticker,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  quote?.name ?? 'Şirket adı fiyat kaynağından gelecek',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  '${number.format(holding.quantity)} adet · Ort. maliyet ${money.format(holding.averageCost)} ₺',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Toplam maliyet: ${money.format(totalCost)} ₺',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            );

            final priceBlock = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: priceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: .25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'GÜNCEL FİYAT',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    currentPrice > 0
                        ? '${money.format(currentPrice)} ₺'
                        : '—',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (quote != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${daily >= 0 ? '+' : ''}${daily.toStringAsFixed(2).replaceAll('.', ',')}% ${quote!.marketTime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dailyColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            );

            final pnlBlock = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  'KÂR / ZARAR',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  currentPrice > 0
                      ? '${profitLoss >= 0 ? '+' : ''}${money.format(profitLoss)} ₺'
                      : '—',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (currentPrice > 0)
                  Text(
                    '${profitPercent >= 0 ? '+' : ''}${profitPercent.toStringAsFixed(2).replaceAll('.', ',')}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'GÜNCEL DEĞER',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  currentPrice > 0
                      ? '${money.format(currentValue)} ₺'
                      : '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameBlock,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: priceBlock),
                      const SizedBox(width: 10),
                      Expanded(child: pnlBlock),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 4, child: nameBlock),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: priceBlock),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: pnlBlock),
              ],
            );
          },
        ),
      ),
    );
  }
}
