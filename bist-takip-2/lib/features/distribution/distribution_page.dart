import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../shared/page_widgets.dart';

enum _DistributionMode { currentValue, cost }

class DistributionPage extends StatefulWidget {
  const DistributionPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<DistributionPage> createState() => _DistributionPageState();
}

class _DistributionPageState extends State<DistributionPage> {
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
        final total = rows.fold<double>(0, (sum, item) => sum + item.value);
        final equalPercent = rows.isEmpty ? 0.0 : 100 / rows.length;
        final equalAmount = rows.isEmpty ? 0.0 : total / rows.length;
        final largestPercent = rows.isEmpty || total <= 0
            ? 0.0
            : rows.first.value / total * 100;
        final concentrationDifference = largestPercent - equalPercent;

        String balanceLabel;
        if (rows.length <= 1) {
          balanceLabel = 'Tek hisse portföyü';
        } else if (largestPercent <= equalPercent * 1.25) {
          balanceLabel = 'Eşit portföye yakın';
        } else {
          balanceLabel = 'Tek hisse ağırlığı yüksek';
        }

        return PageFrame(
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
                const InfoCard(
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEK HİSSE Mİ, EŞİT PORTFÖY MÜ?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _BalanceMetric(
                                label: 'EŞİT PAY',
                                value:
                                    '%${equalPercent.toStringAsFixed(1).replaceAll('.', ',')}',
                                subtitle: '${money.format(equalAmount)} ₺',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BalanceMetric(
                                label: 'EN AĞIR HİSSE',
                                value:
                                    '${rows.first.ticker} %${largestPercent.toStringAsFixed(1).replaceAll('.', ',')}',
                                subtitle:
                                    '${concentrationDifference >= 0 ? '+' : ''}${concentrationDifference.toStringAsFixed(1).replaceAll('.', ',')} puan',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            balanceLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final percent = total > 0 ? row.value / total * 100 : 0.0;
                  final deviationPercent = percent - equalPercent;
                  final deviationAmount = row.value - equalAmount;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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
                                  const SizedBox(height: 3),
                                  Text(
                                    'Eşit paya göre ${deviationPercent >= 0 ? '+' : ''}${deviationPercent.toStringAsFixed(1).replaceAll('.', ',')} puan · ${deviationAmount >= 0 ? '+' : ''}${money.format(deviationAmount)} ₺',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
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

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
