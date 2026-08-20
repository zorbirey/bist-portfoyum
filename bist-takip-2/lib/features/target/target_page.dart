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
  Future<void> _editTargets({_TargetPeriod initial = _TargetPeriod.annual}) async {
    final result = await showDialog<_TargetEditResult>(
      context: context,
      builder: (_) => _TargetAmountDialog(
        initialPeriod: initial,
        annualTarget: widget.controller.annualTarget,
        monthlyTarget: widget.controller.monthlyTarget,
      ),
    );

    if (result == null || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    if (result.period == _TargetPeriod.annual) {
      await widget.controller.updateTargets(
        annualTarget: result.amount,
        monthlyTarget: widget.controller.monthlyTarget,
      );
    } else {
      await widget.controller.updateTargets(
        annualTarget: widget.controller.annualTarget,
        monthlyTarget: result.amount,
      );
    }
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
              tooltip: 'Hedef tutarını düzenle',
              onPressed: () => _editTargets(),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_outlined),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Hedef Tutarım',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactTargetCard(
                              label: 'YILLIK HEDEFİM',
                              value: annualTarget > 0
                                  ? '${money.format(annualTarget)} ₺'
                                  : 'Belirlenmedi',
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _CompactTargetCard(
                              label: 'AYLIK HEDEFİM',
                              value: monthlyTarget > 0
                                  ? '${money.format(monthlyTarget)} ₺'
                                  : 'Belirlenmedi',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _editTargets(),
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('HEDEF TUTARIMI BELİRLE'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editTargets(
                                initial: _TargetPeriod.annual,
                              ),
                              child: const Text('YILLIK HEDEF'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editTargets(
                                initial: _TargetPeriod.monthly,
                              ),
                              child: const Text('AYLIK HEDEF'),
                            ),
                          ),
                        ],
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
                    'Hedef ilerlemesinde takvim tahmini değil, Temettü ekranında kaydettiğin GERÇEK net ödemeler kullanılır. Aylık hedef hesabında yıl içinde gerçekten alınan net temettü toplamı 12’ye bölünür.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactTargetCard extends StatelessWidget {
  const _CompactTargetCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TargetPeriod { annual, monthly }

class _TargetEditResult {
  const _TargetEditResult({required this.period, required this.amount});

  final _TargetPeriod period;
  final double amount;
}

class _TargetAmountDialog extends StatefulWidget {
  const _TargetAmountDialog({
    required this.initialPeriod,
    required this.annualTarget,
    required this.monthlyTarget,
  });

  final _TargetPeriod initialPeriod;
  final double annualTarget;
  final double monthlyTarget;

  @override
  State<_TargetAmountDialog> createState() => _TargetAmountDialogState();
}

class _TargetAmountDialogState extends State<_TargetAmountDialog> {
  late _TargetPeriod _period;
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _controller = TextEditingController(text: _valueFor(_period));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _valueFor(_TargetPeriod period) {
    final value = period == _TargetPeriod.annual
        ? widget.annualTarget
        : widget.monthlyTarget;
    return value > 0 ? value.toStringAsFixed(0) : '';
  }

  double _parse(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.isEmpty) return 0;

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(text) ?? 0;
    }

    final dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) {
      text = text.replaceAll('.', '');
    } else if (dotCount == 1) {
      final dot = text.indexOf('.');
      final decimalDigits = text.length - dot - 1;
      if (decimalDigits == 3) {
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text) ?? 0;
  }

  void _changePeriod(_TargetPeriod period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _error = null;
      _controller.text = _valueFor(period);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _save() {
    final amount = _parse(_controller.text);
    if (amount <= 0) {
      setState(() => _error = 'Sıfırdan büyük bir hedef tutarı gir.');
      return;
    }
    Navigator.of(context).pop(
      _TargetEditResult(period: _period, amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hedef tutarımı belirle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_TargetPeriod>(
              segments: const [
                ButtonSegment(
                  value: _TargetPeriod.annual,
                  icon: Icon(Icons.calendar_today_outlined),
                  label: Text('Yıllık'),
                ),
                ButtonSegment(
                  value: _TargetPeriod.monthly,
                  icon: Icon(Icons.date_range_outlined),
                  label: Text('Aylık'),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (selection) =>
                  _changePeriod(selection.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _period == _TargetPeriod.annual
                    ? 'Yıllık net temettü hedefi'
                    : 'Aylık net temettü hedefi',
                hintText: _period == _TargetPeriod.annual
                    ? 'Örnek: 120.000'
                    : 'Örnek: 10.000',
                suffixText: '₺',
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Text(
              _period == _TargetPeriod.annual
                  ? 'Bu tutar ÇEYREK, YARIM, 3/4 ve HEDEF kademelerinde kullanılır.'
                  : 'Aylık ilerleme, yıl içinde gerçekten aldığın net temettü toplamı ÷ 12 ile karşılaştırılır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
