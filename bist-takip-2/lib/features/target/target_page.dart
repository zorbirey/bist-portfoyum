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

enum _TargetPeriod { annual, monthly }
enum _TargetMode { single, equal }

class _TargetPageState extends State<TargetPage> {
  _TargetPeriod _period = _TargetPeriod.annual;
  _TargetMode _mode = _TargetMode.single;
  double _milestone = 1.0;

  late final TextEditingController _amountController;
  late final FocusNode _amountFocus;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatInput(widget.controller.annualTarget),
    );
    _amountFocus = FocusNode()..addListener(_onAmountFocusChanged);
  }

  @override
  void dispose() {
    _amountFocus.removeListener(_onAmountFocusChanged);
    _amountFocus.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountFocusChanged() {
    if (!_amountFocus.hasFocus) _saveTargetAmount();
  }

  String _formatInput(double value) =>
      NumberFormat('#,##0', 'tr_TR').format(math.max(0.0, value));

  double _parseMoney(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.isEmpty) return 0.0;

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(text) ?? 0.0;
    }

    final dots = '.'.allMatches(text).length;
    if (dots > 1) {
      text = text.replaceAll('.', '');
    } else if (dots == 1) {
      final index = text.indexOf('.');
      if (text.length - index - 1 == 3) text = text.replaceAll('.', '');
    }
    return double.tryParse(text) ?? 0.0;
  }

  Future<void> _saveTargetAmount() async {
    final amount = math.max(0.0, _parseMoney(_amountController.text)).toDouble();
    if (_period == _TargetPeriod.annual) {
      if ((widget.controller.annualTarget - amount).abs() > 0.001) {
        await widget.controller.updateTargets(
          annualTarget: amount,
          monthlyTarget: widget.controller.monthlyTarget,
        );
      }
    } else if ((widget.controller.monthlyTarget - amount).abs() > 0.001) {
      await widget.controller.updateTargets(
        annualTarget: widget.controller.annualTarget,
        monthlyTarget: amount,
      );
    }

    if (!mounted) return;
    _amountController.text = _formatInput(amount);
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
    setState(() {});
  }

  Future<void> _setPeriod(_TargetPeriod next) async {
    if (next == _period) return;
    await _saveTargetAmount();
    if (!mounted) return;
    setState(() {
      _period = next;
      final value = next == _TargetPeriod.annual
          ? widget.controller.annualTarget
          : widget.controller.monthlyTarget;
      _amountController.text = _formatInput(value);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final money = NumberFormat('#,##0.00', 'tr_TR');
        final money0 = NumberFormat('#,##0', 'tr_TR');
        final year = DateTime.now().year;
        final rawTarget = _period == _TargetPeriod.annual
            ? widget.controller.annualTarget
            : widget.controller.monthlyTarget;
        final annualTarget =
            (_period == _TargetPeriod.monthly ? rawTarget * 12 : rawTarget)
                .toDouble();

        final netPerShare = <String, double>{};
        for (final event
            in widget.controller.dividendEventsForPortfolio(year: year)) {
          final ticker = event.ticker.toUpperCase();
          netPerShare[ticker] =
              (netPerShare[ticker] ?? 0.0) + event.netPerShare;
        }

        double forecast = 0.0;
        final eligible = <_EligibleStock>[];
        for (final holding in widget.controller.holdings.values) {
          if (holding.quantity <= 0) continue;
          final ticker = holding.ticker.toUpperCase();
          final dps = netPerShare[ticker] ?? 0.0;
          final quote = widget.controller.quoteFor(ticker);
          final price = quote?.price ?? 0.0;

          if (dps > 0) forecast += holding.quantity * dps;
          if (dps > 0 && price > 0) {
            eligible.add(
              _EligibleStock(
                ticker: ticker,
                name: quote?.name ?? '',
                price: price,
                netYearPerShare: dps,
              ),
            );
          }
        }

        final selectedGoal = annualTarget * _milestone;
        final remaining = math.max(0.0, selectedGoal - forecast).toDouble();
        final plan = _makePlan(eligible, remaining);
        final planCost =
            plan.fold<double>(0.0, (sum, item) => sum + item.cost);
        final planDividend = plan.fold<double>(
          0.0,
          (sum, item) => sum + item.addedDividend,
        );

        const milestones = <_Milestone>[
          _Milestone(.25, '25%'),
          _Milestone(.50, '50%'),
          _Milestone(.75, '75%'),
          _Milestone(1.0, 'HEDEF'),
        ];

        return PageFrame(
          title: 'Hedef',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TargetHeader(),
              const SizedBox(height: 12),
              _WarningCard(),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('HEDEF TÜRÜ',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<_TargetPeriod>(
                        segments: const [
                          ButtonSegment(
                              value: _TargetPeriod.annual,
                              label: Text('YILLIK')),
                          ButtonSegment(
                              value: _TargetPeriod.monthly,
                              label: Text('AYLIK')),
                        ],
                        selected: {_period},
                        onSelectionChanged: (selection) {
                          _setPeriod(selection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _period == _TargetPeriod.annual
                            ? 'YILLIK NET TEMETTÜ HEDEFİ'
                            : 'AYLIK NET TEMETTÜ HEDEFİ',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(suffixText: '₺'),
                        onSubmitted: (_) {
                          _saveTargetAmount();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yıllık karşılığı: ${money.format(annualTarget)} ₺',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Bu yıl öngörülen net temettü: ${money.format(forecast)} ₺',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hedef Kademeleri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.55,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                children: milestones.map((item) {
                  final goal = annualTarget * item.factor;
                  final ratio = (goal > 0
                          ? math.min(100.0, forecast / goal * 100)
                          : 0.0)
                      .toDouble();
                  return _MilestoneCard(
                    item: item,
                    goal: goal,
                    ratio: ratio,
                    selected: _milestone == item.factor,
                    money: money0,
                    onTap: () => setState(() => _milestone = item.factor),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('HEDEF KADEMESİNE KALAN TUTAR',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${money.format(remaining)} ₺',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: remaining > 0
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      Text(
                        'Seçili kademe: %${(_milestone * 100).toStringAsFixed(0)} · ${money.format(selectedGoal)} ₺',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tek hisseden mi portföye eşit dağılımla mı ilerlemek istersiniz?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 9),
                      SegmentedButton<_TargetMode>(
                        segments: const [
                          ButtonSegment(
                              value: _TargetMode.single,
                              label: Text('TEK HİSSE')),
                          ButtonSegment(
                              value: _TargetMode.equal,
                              label: Text('EŞİT DAĞILIM')),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) {
                          setState(() => _mode = selection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_mode == _TargetMode.equal && plan.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _Summary(
                                'PLAN TOPLAM MALİYETİ',
                                '${money.format(planCost)} ₺',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Summary(
                                'EK NET TEMETTÜ GELİRİ',
                                '+${money.format(planDividend)} ₺',
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (plan.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Plan oluşturmak için portföyde fiyatı ve $year net temettü verisi bulunan hisse gerekli.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...plan.asMap().entries.map(
                              (entry) => _PlanRow(
                                plan: entry.value,
                                cheapest: _mode == _TargetMode.single &&
                                    entry.key == 0,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_TargetPlan> _makePlan(
    List<_EligibleStock> eligible,
    double remaining,
  ) {
    final result = <_TargetPlan>[];
    if (_mode == _TargetMode.single) {
      for (final stock in eligible) {
        final qty = (remaining / stock.netYearPerShare).ceil();
        result.add(_TargetPlan(stock, qty));
      }
      result.sort((a, b) => a.cost.compareTo(b.cost));
      return result;
    }

    if (eligible.isEmpty) return result;
    final share = remaining / eligible.length;
    for (final stock in eligible) {
      result.add(_TargetPlan(stock, (share / stock.netYearPerShare).ceil()));
    }
    return result;
  }
}

class _TargetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            'NET TEMETTÜ HEDEFİ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'HEDEFE GİDEN YOLDA ÇEKİLEN BÜTÜN ÇİLELER KUTSALDIR',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      );
}

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          'UYARI\nBU HESAPLAMALAR SADECE BU SENEYE GÖRE YAPILMIŞTIR. SENEYE HİSSENİN TEMETTÜ VERMESİ GARANTİ DEĞİLDİR. SADECE FİKİR AMAÇLIDIR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red.shade800,
            fontWeight: FontWeight.w900,
            height: 1.45,
          ),
        ),
      );
}

class _Milestone {
  const _Milestone(this.factor, this.label);
  final double factor;
  final String label;
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.item,
    required this.goal,
    required this.ratio,
    required this.selected,
    required this.money,
    required this.onTap,
  });

  final _Milestone item;
  final double goal;
  final double ratio;
  final bool selected;
  final NumberFormat money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.green.shade500
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${money.format(goal)} ₺',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: (ratio / 100).clamp(0.0, 1.0).toDouble(),
                minHeight: 9,
              ),
              const SizedBox(height: 5),
              Text(
                ratio >= 100 ? 'Ulaşıldı' : '%${ratio.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

class _EligibleStock {
  const _EligibleStock({
    required this.ticker,
    required this.name,
    required this.price,
    required this.netYearPerShare,
  });

  final String ticker;
  final String name;
  final double price;
  final double netYearPerShare;
}

class _TargetPlan {
  const _TargetPlan(this.stock, this.quantity);

  final _EligibleStock stock;
  final int quantity;
  double get cost => quantity * stock.price;
  double get addedDividend => quantity * stock.netYearPerShare;
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      );
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.cheapest});
  final _TargetPlan plan;
  final bool cheapest;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.00', 'tr_TR');
    final integer = NumberFormat('#,##0', 'tr_TR');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cheapest ? '★ EN DÜŞÜK MALİYET · ' : ''}${plan.stock.ticker}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (plan.stock.name.isNotEmpty)
                  Text(plan.stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text(
                  'Yıllık net temettü / hisse: ${money.format(plan.stock.netYearPerShare)} ₺ · Güncel fiyat: ${money.format(plan.stock.price)} ₺',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Alınması gereken: ${integer.format(plan.quantity)} adet · Ek net temettü: ${money.format(plan.addedDividend)} ₺',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('MALİYET',
                    style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${money.format(plan.cost)} ₺',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
