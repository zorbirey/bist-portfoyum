import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../../data/market/market_feed.dart';
import '../../domain/services/portfolio_ledger.dart';
import '../legacy/legacy_import_page.dart';
import '../transactions/transaction_form_page.dart';
import '../transactions/transaction_history_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PortfolioPage(controller: widget.controller),
      _DistributionPage(controller: widget.controller),
      _DividendPage(controller: widget.controller),
      _TargetPage(controller: widget.controller),
      _HistoryPage(controller: widget.controller),
      _SettingsPage(controller: widget.controller),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Portföy',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            label: 'Dağılım',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Temettü',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            label: 'Hedef',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            ...actions,
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _PortfolioPage extends StatelessWidget {
  const _PortfolioPage({required this.controller});

  final AppController controller;

  Future<void> _openTransaction(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(controller: controller),
      ),
    );
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

        return _PageFrame(
          title: 'BIST TAKİP 2.0',
          subtitle:
              'Portföyün, gerçek getirilerin ve temettü gelirlerin tek yerde',
          actions: [
            IconButton(
              tooltip: 'Fiyatları yenile',
              onPressed:
                  controller.refreshingMarket ? null : controller.refreshMarket,
              icon: controller.refreshingMarket
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
                    child: _MetricCard(
                      label: 'PORTFÖY DEĞERİ',
                      value: '${money.format(portfolioValue)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
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
                    child: _MetricCard(
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
                  const Expanded(
                    child:
                        _MetricCard(label: 'BIST 100 FARKI', value: '— %'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(marketStatus, style: Theme.of(context).textTheme.bodySmall),
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
                    child: _PortfolioStockCard(
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

class _PortfolioStockCard extends StatelessWidget {
  const _PortfolioStockCard({
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
    final profitLoss = currentPrice > 0
        ? (currentPrice - holding.averageCost) * holding.quantity
        : 0;
    final profitPercent = holding.averageCost > 0 && currentPrice > 0
        ? ((currentPrice / holding.averageCost) - 1) * 100
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
              ],
            );

            final priceBlock = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: priceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(.25)),
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

enum _DistributionMode { currentValue, cost }

class _DistributionPage extends StatefulWidget {
  const _DistributionPage({required this.controller});

  final AppController controller;

  @override
  State<_DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<_DistributionPage> {
  _DistributionMode mode = _DistributionMode.currentValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final rows = <_DistributionRow>[];

        for (final holding in widget.controller.holdings.values) {
          if (holding.quantity <= 0) continue;
          final quote = widget.controller.quoteFor(holding.ticker);
          final value = mode == _DistributionMode.currentValue
              ? (quote?.price ?? 0) * holding.quantity
              : holding.costBasis;
          if (value <= 0) continue;

          rows.add(
            _DistributionRow(
              ticker: holding.ticker,
              name: quote?.name ?? '',
              value: value,
            ),
          );
        }

        rows.sort((a, b) => b.value.compareTo(a.value));
        final total =
            rows.fold<double>(0, (sum, item) => sum + item.value);

        return _PageFrame(
          title: 'Dağılım',
          subtitle: 'Portföyünün hangi hisselerde yoğunlaştığını gör',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_DistributionMode>(
                segments: const [
                  ButtonSegment(
                    value: _DistributionMode.currentValue,
                    label: Text('Güncel Değer'),
                  ),
                  ButtonSegment(
                    value: _DistributionMode.cost,
                    label: Text('Maliyet'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) =>
                    setState(() => mode = value.first),
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const _InfoCard(
                  text:
                      'Dağılım göstermek için portföyde en az bir aktif hisse ve gerekli fiyat/maliyet verisi olmalı.',
                )
              else ...[
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    painter: _DistributionPiePainter(
                      rows: rows,
                      total: total,
                      colors: _distributionColors,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mode == _DistributionMode.currentValue
                                ? 'GÜNCEL DEĞER'
                                : 'TOPLAM MALİYET',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${money.format(total)} ₺',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final percent = total > 0 ? row.value / total * 100 : 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _distributionColors[
                                  index % _distributionColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.ticker,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (row.name.isNotEmpty)
                                  Text(
                                    row.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '%${percent.toStringAsFixed(1).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${money.format(row.value)} ₺',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DistributionRow {
  const _DistributionRow({
    required this.ticker,
    required this.name,
    required this.value,
  });

  final String ticker;
  final String name;
  final double value;
}

const _distributionColors = [
  Color(0xFF78A88F),
  Color(0xFF9AA8D6),
  Color(0xFFD2A67C),
  Color(0xFFB48CB8),
  Color(0xFF7FA8C9),
  Color(0xFFC79A9A),
  Color(0xFFA6B979),
  Color(0xFFB39B7D),
];

class _DistributionPiePainter extends CustomPainter {
  const _DistributionPiePainter({
    required this.rows,
    required this.total,
    required this.colors,
  });

  final List<_DistributionRow> rows;
  final double total;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .42;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .34
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    for (var i = 0; i < rows.length; i++) {
      final sweep = (rows[i].value / total) * math.pi * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionPiePainter oldDelegate) =>
      oldDelegate.rows != rows || oldDelegate.total != total;
}

class _DividendPage extends StatelessWidget {
  const _DividendPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final year = DateTime.now().year;
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final events = controller.dividendEventsForPortfolio(year: year);
        final holdings = controller.holdings;

        double calendarForecast = 0;
        double upcomingForecast = 0;
        for (final event in events) {
          final quantity = holdings[event.ticker]?.quantity ?? 0;
          final estimated = quantity * event.netPerShare;
          calendarForecast += estimated;
          if (!event.isPaid) upcomingForecast += estimated;
        }

        final recorded = controller.dividendsForYear(year);
        final monthlyForecast = calendarForecast / 12;
        final target = controller.monthlyTarget;
        final ratio =
            target > 0 ? (monthlyForecast / target) * 100 : 0;

        final ordered = [...events]
          ..sort((a, b) {
            if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
            return a.isPaid
                ? b.date.compareTo(a.date)
                : a.date.compareTo(b.date);
          });

        final status = controller.refreshingDividends
            ? 'Temettü takvimi güncelleniyor'
            : controller.dividendError != null
                ? controller.dividendError!
                : controller.dividendUpdatedAt == null
                    ? 'Temettü takvimi bekleniyor'
                    : '${controller.dividendSource} · ${DateFormat('dd.MM HH:mm').format(controller.dividendUpdatedAt!.toLocal())}';

        return _PageFrame(
          title: 'Temettü',
          subtitle: 'Pasif gelirini ve gelecek ödemelerini takip et',
          actions: [
            IconButton(
              tooltip: 'Temettü takvimini yenile',
              onPressed: controller.refreshingDividends
                  ? null
                  : controller.refreshDividends,
              icon: controller.refreshingDividends
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
                    child: _MetricCard(
                      label: '$year KAYITLI NET',
                      value: '${money.format(recorded)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'TAKVİM NET TAHMİNİ',
                      value: '${money.format(calendarForecast)} ₺',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'BEKLEYEN TAHMİN',
                      value: '${money.format(upcomingForecast)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'AYLIK HEDEF ORANI',
                      value: '%${ratio.clamp(0, 999).toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(status, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              const _InfoCard(
                text:
                    'Takvim tahminleri mevcut hisse adedin üzerinden hesaplanır. Geçmiş ödeme tarihinde farklı adet taşıdıysan gerçek aldığın net tutarı ayrıca Temettü işlemi olarak kaydet.',
              ),
              const SizedBox(height: 16),
              Text(
                'Temettü Takvimim',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (ordered.isEmpty)
                const _InfoCard(
                  text:
                      'Portföyündeki hisseler için bu takvim yılında açıklanmış temettü kaydı bulunamadı.',
                )
              else
                ...ordered.map((event) {
                  final quantity =
                      holdings[event.ticker]?.quantity ?? 0;
                  final estimated = quantity * event.netPerShare;
                  final statusColor = event.isPaid
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.primary;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.ticker,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    if (event.name.isNotEmpty)
                                      Text(
                                        event.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  event.isPaid ? 'ÖDENDİ' : 'BEKLEYEN',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ödeme: ${event.date.day.toString().padLeft(2, '0')}.${event.date.month.toString().padLeft(2, '0')}.${event.date.year}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Net / hisse: ${money.format(event.netPerShare)} ₺ · Mevcut adet: ${NumberFormat('#,##0.##', 'tr_TR').format(quantity)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tahmini net: ${money.format(estimated)} ₺',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TargetPage extends StatefulWidget {
  const _TargetPage({required this.controller});

  final AppController controller;

  @override
  State<_TargetPage> createState() => _TargetPageState();
}

class _TargetPageState extends State<_TargetPage> {
  double _number(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text) ?? 0;
  }

  Future<void> _editTargets() async {
    final annual = TextEditingController(
      text: widget.controller.annualTarget.toStringAsFixed(0),
    );
    final monthly = TextEditingController(
      text: widget.controller.monthlyTarget.toStringAsFixed(0),
    );

    final values = await showDialog<List<double>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temettü hedeflerini düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: annual,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Yıllık net temettü hedefi',
                suffixText: '₺',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthly,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Aylık net temettü hedefi',
                suffixText: '₺',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              [_number(annual.text), _number(monthly.text)],
            ),
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );

    annual.dispose();
    monthly.dispose();

    if (values == null) return;
    await widget.controller.updateTargets(
      annualTarget: values[0],
      monthlyTarget: values[1],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final year = DateTime.now().year;
        final paid = widget.controller.dividendsForYear(year);
        final annualTarget = widget.controller.annualTarget;
        final monthlyTarget = widget.controller.monthlyTarget;
        final annualRatio =
            annualTarget > 0 ? (paid / annualTarget) * 100 : 0;
        final monthlyAverage = paid / 12;
        final monthlyRatio =
            monthlyTarget > 0 ? (monthlyAverage / monthlyTarget) * 100 : 0;

        return _PageFrame(
          title: 'Hedef',
          subtitle: 'Portföy ve temettü hedeflerini ayrı ayrı izle',
          actions: [
            IconButton(
              tooltip: 'Hedefleri düzenle',
              onPressed: _editTargets,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetricCard(
                label: '$year NET TEMETTÜ',
                value: '${money.format(paid)} ₺',
              ),
              const SizedBox(height: 10),
              _MetricCard(
                label: 'YILLIK NET TEMETTÜ HEDEFİ',
                value: '${money.format(annualTarget)} ₺',
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YILLIK HEDEFE ULAŞMA',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (annualRatio / 100).clamp(0, 1),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '%${annualRatio.toStringAsFixed(1).replaceAll('.', ',')} · Kalan ${money.format(math.max(0, annualTarget - paid))} ₺',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _MetricCard(
                label: 'AYLIK TEMETTÜ HEDEFİ',
                value: '${money.format(monthlyTarget)} ₺',
              ),
              const SizedBox(height: 10),
              _MetricCard(
                label: 'AYLIK ORTALAMA / HEDEF',
                value:
                    '${money.format(monthlyAverage)} ₺ · %${monthlyRatio.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 16),
              const _InfoCard(
                text:
                    'Hedef ekranındaki projeksiyonlar senaryo amaçlıdır; gelecekteki getiri veya temettü garantisi değildir.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.controller});

  final AppController controller;

  Future<void> _importLegacy(BuildContext context) async {
    final imported = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LegacyImportPage(controller: controller),
      ),
    );
    if (imported == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1.1.5 yedeği 2.0 portföyüne aktarıldı.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Ayarlar',
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('1.1.5 yedeğini içe aktar'),
              subtitle: const Text(
                'Eski adet, maliyet ve hedefleri önce gösterir, onaydan sonra 2.0 açılış bakiyesine dönüştürür.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importLegacy(context),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('Bulut senkronizasyonu'),
              subtitle: Text('Ticari sürüm altyapısı aşamasında eklenecek.'),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: ListTile(
              leading: Icon(Icons.fingerprint),
              title: Text('PIN / biyometri'),
              subtitle: Text('Ticari sürüm güvenlik katmanında eklenecek.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshots = controller.snapshots;
        final money = NumberFormat('#,##0.00', 'tr_TR');

        return _PageFrame(
          title: 'Geçmiş',
          subtitle: 'Portföy değerinin günlük gelişimini takip et',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshots.isEmpty)
                const _InfoCard(
                  text:
                      'İlk fiyat güncellemesinden sonra günlük portföy kaydı burada oluşacak.',
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PORTFÖY DEĞERİ',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _HistoryLinePainter(
                              values: snapshots
                                  .map((item) => item.portfolioValue)
                                  .toList(),
                              color: Theme.of(context).colorScheme.primary,
                              gridColor:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _shortDate(snapshots.first.day),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              _shortDate(snapshots.last.day),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...snapshots.reversed.take(30).map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(
                        _fullDate(item.day),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Günlük K/Z ${item.dailyPnl >= 0 ? '+' : ''}${money.format(item.dailyPnl)} ₺ · Toplam K/Z ${item.totalPnl >= 0 ? '+' : ''}${money.format(item.totalPnl)} ₺',
                      ),
                      trailing: Text(
                        '${money.format(item.portfolioValue)} ₺',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  static String _fullDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class _HistoryLinePainter extends CustomPainter {
  const _HistoryLinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length == 1) {
      final dot = Paint()..color = color;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        4,
        dot,
      );
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final safeRange = range.abs() < .000001 ? 1.0 : range;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / safeRange;
      final y = size.height - (normalized * size.height * .82) -
          (size.height * .09);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryLinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) =>
      _PageFrame(title: title, child: _InfoCard(text: message));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 7),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
