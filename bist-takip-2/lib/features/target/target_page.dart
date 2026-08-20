import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_controller.dart';
import '../shared/page_widgets.dart';

class TargetPage extends StatefulWidget {
  const TargetPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TargetPage> createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
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

        final actualPaid = widget.controller.dividendsForYear(year);
        final annualTarget = widget.controller.annualTarget;
        final monthlyTarget = widget.controller.monthlyTarget;

        final monthlyActual = actualPaid / 12;
        final monthlyRatio =
            monthlyTarget > 0 ? (monthlyActual / monthlyTarget) * 100 : 0.0;

        final annualRatio =
            annualTarget > 0 ? (actualPaid / annualTarget) * 100 : 0.0;

        final milestones = <_Milestone>[
          const _Milestone(factor: .25, label: 'ÇEYREK'),
          const _Milestone(factor: .50, label: 'YARIM'),
          const _Milestone(factor: .75, label: '3/4'),
          const _Milestone(factor: 1, label: 'HEDEF'),
        ];

        return PageFrame(
          title: 'Hedef',
          subtitle: 'Gerçek aldığın temettü ile hedefe ne kadar kaldığını gör',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'NET TEMETTÜ HEDEFİ',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.red.shade700,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'HEDEFE GİDEN YOLDA ÇEKİLEN BÜTÜN ÇİLELER KUTSALDIR',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: '$year GERÇEK ALINAN NET',
                      value: '${money.format(actualPaid)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'YILLIK HEDEF',
                      value: '${money.format(annualTarget)} ₺',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Hedef Kademeleri',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (annualTarget <= 0)
                const InfoCard(
                  text:
                      'Çeyrek, yarım, 3/4 ve hedef kademelerini görmek için yıllık temettü hedefini gir.',
                  icon: Icons.track_changes_outlined,
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.45,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  children: milestones.map((milestone) {
                    final goal = annualTarget * milestone.factor;
                    final ratio =
                        goal > 0 ? (actualPaid / goal) * 100 : 0.0;
                    final reached = actualPaid >= goal;

                    return _MilestoneCard(
                      label: milestone.label,
                      goal: goal,
                      ratio: ratio,
                      reached: reached,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),
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
                        value: (annualRatio / 100)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        annualTarget > 0
                            ? '%${annualRatio.toStringAsFixed(1).replaceAll('.', ',')} · Kalan ${money.format(math.max(0, annualTarget - actualPaid))} ₺'
                            : 'Yıllık hedef girilmedi.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Aylık Temettü Hedefi',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'AYLIK HEDEF',
                      value: '${money.format(monthlyTarget)} ₺',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'GERÇEK AYLIK ORT.',
                      value: '${money.format(monthlyActual)} ₺',
                      subtitle: '$year gerçek net ÷ 12',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AYLIK HEDEFE ULAŞMA',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (monthlyRatio / 100)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        monthlyTarget > 0
                            ? '%${monthlyRatio.toStringAsFixed(1).replaceAll('.', ',')} · ${money.format(monthlyActual)} ₺ / ${money.format(monthlyTarget)} ₺'
                            : 'Aylık hedef girilmedi.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const InfoCard(
                text:
                    'Hedef ilerlemesinde takvim tahmini değil, Temettü ekranında kaydettiğin GERÇEK net ödemeler kullanılır. Gelecekteki temettüler garanti değildir.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Milestone {
  const _Milestone({required this.factor, required this.label});

  final double factor;
  final String label;
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.label,
    required this.goal,
    required this.ratio,
    required this.reached,
  });

  final String label;
  final double goal;
  final double ratio;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0', 'tr_TR');
    final color = reached
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              '${money.format(goal)} ₺',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: (ratio / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
            ),
            const SizedBox(height: 6),
            Text(
              reached
                  ? 'Ulaşıldı'
                  : '%${ratio.toStringAsFixed(1).replaceAll('.', ',')}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
