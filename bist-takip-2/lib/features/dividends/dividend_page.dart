import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../../data/dividends/dividend_feed.dart';
import '../../domain/models/portfolio_transaction.dart';
import '../shared/page_widgets.dart';
import '../transactions/transaction_form_page.dart';

class DividendPage extends StatelessWidget {
  const DividendPage({super.key, required this.controller});

  final AppController controller;

  Future<void> _recordEvent(
    BuildContext context,
    DividendEvent event,
    double estimated,
  ) async {
    final existing =
        controller.recordedDividendForEvent(event.ticker, event.date);

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _DividendAmountDialog(
        ticker: event.ticker,
        initialAmount: existing ?? estimated,
      ),
    );

    if (amount == null || amount <= 0 || !context.mounted) return;

    // Diyalog route'unun tamamen kapanmasını bekle. Böylece controller
    // notifyListeners çağrısı, kapanan dialog ağacının dispose süreciyle
    // çakışmaz.
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    await controller.recordDividend(
      ticker: event.ticker,
      date: event.date,
      netAmount: amount,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${event.ticker} için ${NumberFormat('#,##0.00', 'tr_TR').format(amount)} ₺ gerçek net temettü kaydedildi.',
        ),
      ),
    );
  }

  Future<void> _openManualDividend(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          controller: controller,
          initialType: PortfolioTransactionType.dividend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final year = DateTime.now().year;
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final quantityFormat = NumberFormat('#,##0.##', 'tr_TR');
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
        final monthlyActual = recorded / 12;
        final monthlyTarget = controller.monthlyTarget;
        final monthlyRatio = monthlyTarget > 0
            ? (monthlyActual / monthlyTarget) * 100
            : 0.0;

        final ordered = [...events]
          ..sort((a, b) {
            final aRecorded =
                controller.recordedDividendForEvent(a.ticker, a.date) != null;
            final bRecorded =
                controller.recordedDividendForEvent(b.ticker, b.date) != null;

            if (aRecorded != bRecorded) return aRecorded ? 1 : -1;
            if (a.isPaid != b.isPaid) return a.isPaid ? -1 : 1;
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

        return PageFrame(
          title: 'Temettü',
          subtitle: 'Tahmini ödemeyi ve gerçekten aldığın net tutarı ayrı izle',
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
                    child: MetricCard(
                      label: '$year KAYITLI NET',
                      value: '${money.format(recorded)} ₺',
                      subtitle: 'Gerçek alınan tutarlar',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'TAKVİM NET TAHMİNİ',
                      value: '${money.format(calendarForecast)} ₺',
                      subtitle: 'Mevcut adede göre',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'BEKLEYEN TAHMİN',
                      value: '${money.format(upcomingForecast)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'AYLIK GERÇEK ORT.',
                      value: '${money.format(monthlyActual)} ₺',
                      subtitle: '$year kayıtlı net ÷ 12',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MetricCard(
                label: 'AYLIK HEDEF ORANI (GERÇEK / 12)',
                value: monthlyTarget > 0
                    ? '%${monthlyRatio.toStringAsFixed(1).replaceAll('.', ',')}'
                    : 'Hedef girilmedi',
                valueColor:
                    monthlyRatio >= 100 ? Colors.green.shade700 : null,
                subtitle: monthlyTarget > 0
                    ? '${money.format(monthlyActual)} ₺ / ${money.format(monthlyTarget)} ₺'
                    : 'Hedef sekmesinden aylık hedefini belirle.',
              ),
              const SizedBox(height: 8),
              Text(status, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              const InfoCard(
                text:
                    'Ödeme tarihi geçmiş bir temettü otomatik olarak “gerçek alınan” sayılmaz. Banka hesabına geçen net rakamı kaydettiğinde KAYITLI NET ve hedef ilerlemesi güncellenir.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openManualDividend(context),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('GERÇEK TEMETTÜ TUTARI KAYDET'),
              ),
              const SizedBox(height: 18),
              Text(
                'Temettü Takvimim',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (ordered.isEmpty)
                const InfoCard(
                  text:
                      'Portföyündeki hisseler için bu takvim yılında açıklanmış temettü kaydı bulunamadı.',
                )
              else
                ...ordered.map((event) {
                  final quantity = holdings[event.ticker]?.quantity ?? 0;
                  final estimated = quantity * event.netPerShare;
                  final registered = controller.recordedDividendForEvent(
                    event.ticker,
                    event.date,
                  );

                  final Color statusColor;
                  final String statusLabel;
                  if (registered != null) {
                    statusColor = Colors.green.shade700;
                    statusLabel = 'KAYDEDİLDİ';
                  } else if (event.isPaid) {
                    statusColor = Colors.orange.shade800;
                    statusLabel = 'ÖDENDİ';
                  } else {
                    statusColor = Theme.of(context).colorScheme.primary;
                    statusLabel = 'BEKLEYEN';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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
                                    color: statusColor.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    statusLabel,
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
                              'Ödeme: ${DateFormat('dd.MM.yyyy').format(event.date)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Net / hisse: ${money.format(event.netPerShare)} ₺ · Mevcut adet: ${quantityFormat.format(quantity)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Takvim tahmini: ${money.format(estimated)} ₺',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (registered != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Gerçek kaydedilen net: ${money.format(registered)} ₺',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ] else if (event.isPaid) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Gerçek tutar henüz kaydedilmedi; $year KAYITLI NET toplamına dahil değil.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (event.isPaid) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _recordEvent(
                                    context,
                                    event,
                                    estimated,
                                  ),
                                  icon: Icon(
                                    registered == null
                                        ? Icons.add_card_outlined
                                        : Icons.edit_outlined,
                                  ),
                                  label: Text(
                                    registered == null
                                        ? 'ALDIĞIM TUTARI KAYDET'
                                        : 'GERÇEK TUTARI DÜZENLE',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _DividendAmountDialog extends StatefulWidget {
  const _DividendAmountDialog({
    required this.ticker,
    required this.initialAmount,
  });

  final String ticker;
  final double initialAmount;

  @override
  State<_DividendAmountDialog> createState() => _DividendAmountDialogState();
}

class _DividendAmountDialogState extends State<_DividendAmountDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _parseAmount(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text) ?? 0;
  }

  void _save() {
    final value = _parseAmount(_controller.text);
    if (value <= 0) {
      setState(() => _error = 'Sıfırdan büyük gerçek net tutarı gir.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.ticker} gerçek temettü'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banka hesabına gerçekten geçen NET tutarı gir. Takvim tahmini farklıysa burada gerçek rakamı kullan.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Gerçek alınan net tutar',
              suffixText: '₺',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('VAZGEÇ'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('KAYDET'),
        ),
      ],
    );
  }
}
