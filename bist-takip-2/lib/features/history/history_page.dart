import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../shared/page_widgets.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshots = controller.snapshots;
        final money = NumberFormat('#,##0.00', 'tr_TR');

        return PageFrame(
          title: 'Geçmiş',
          subtitle: 'Portföy değerinin günlük gelişimini takip et',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshots.isEmpty)
                const InfoCard(
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
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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
                ),
              ],
              const SizedBox(height: 8),
              const InfoCard(
                text:
                    'BIST 100, Dolar ve Gram Altın başlangıçtan bugüne karşılaştırması Portföy ekranında gösterilir.',
              ),
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
      final y = size.height -
          (normalized * size.height * .82) -
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
