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
      const _PlaceholderPage(
        title: 'Dağılım',
        message:
            'Maliyet, güncel değer ve sektör dağılımları burada gösterilecek.',
      ),
      _DividendPage(controller: widget.controller),
      _TargetPage(controller: widget.controller),
      const _PlaceholderPage(
        title: 'Geçmiş',
        message:
            'Günlük portföy değeri, BIST 100 kıyası ve gerçek getiri grafikleri burada olacak.',
      ),
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
        final allHoldings = controller.holdings.values.toList();
        final holdings = allHoldings
            .where((holding) => holding.quantity > 0)
            .toList()
          ..sort((a, b) => a.ticker.compareTo(b.ticker));

        double portfolioValue = 0;
        double totalPnl = allHoldings.fold<double>(
          0,
          (sum, holding) =>
              sum + holding.realizedPnl + holding.netDividends,
        );
        double dailyPnl = 0;

        for (final holding in holdings) {
          final quote = controller.quoteFor(holding.ticker);
          if (quote == null || quote.price <= 0) continue;
          final marketValue = holding.quantity * quote.price;
          final unrealized =
              (quote.price - holding.averageCost) * holding.quantity;
          portfolioValue += marketValue;
          totalPnl += unrealized;

          if (quote.changePercent != -100) {
            final previous =
                quote.price / (1 + (quote.changePercent / 100));
            dailyPnl += (quote.price - previous) * holding.quantity;
          }
        }

        final money = NumberFormat('#,##0.00', 'tr_TR');
        final marketStatus = controller.refreshingMarket
            ? 'Fiyatlar güncelleniyor'
            : controller.marketError != null
                ? controller.marketError!
                : controller.marketUpdatedAt == null
                    ? 'Fiyat verisi bekleniyor'
                    : '${controller.marketSource} · ${DateFormat('dd.MM HH:mm', 'tr_TR').format(controller.marketUpdatedAt!.toLocal())}';

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

class _DividendPage extends StatelessWidget {
  const _DividendPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final total = controller.holdings.values.fold<double>(
          0,
          (sum, holding) => sum + holding.netDividends,
        );
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final monthlyAverage = total / 12;
        final target = controller.monthlyTarget;
        final ratio = target > 0 ? (monthlyAverage / target) * 100 : 0;

        return _PageFrame(
          title: 'Temettü',
          subtitle: 'Pasif gelirini ve gelecek ödemelerini takip et',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'BU YIL NET',
                      value: '${money.format(total)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'AYLIK ORTALAMA',
                      value: '${money.format(monthlyAverage)} ₺',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetricCard(
                label: 'TEMETTÜ MAAŞI HEDEFİ',
                value: '%${ratio.clamp(0, 999).toStringAsFixed(0)}',
              ),
              const SizedBox(height: 16),
              const _InfoCard(
                text:
                    'Yaklaşan temettüler, gerçekleşen ödemeler ve yeniden yatırım senaryoları bu merkezde toplanacak.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TargetPage extends StatelessWidget {
  const _TargetPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00', 'tr_TR');
    return _PageFrame(
      title: 'Hedef',
      subtitle: 'Portföy ve temettü hedeflerini ayrı ayrı izle',
      child: Column(
        children: [
          _MetricCard(
            label: 'YILLIK NET TEMETTÜ HEDEFİ',
            value: '${money.format(controller.annualTarget)} ₺',
          ),
          const SizedBox(height: 10),
          const _MetricCard(label: 'HEDEFE ULAŞMA', value: '%0'),
          const SizedBox(height: 16),
          const _InfoCard(
            text:
                'Buradaki projeksiyonlar senaryo amaçlı olacak; gelecekteki getiri veya temettü garantisi olarak sunulmayacak.',
          ),
        ],
      ),
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
