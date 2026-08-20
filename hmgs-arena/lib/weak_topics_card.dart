import 'package:flutter/material.dart';

import 'learning_engine.dart';

class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({
    super.key,
    required this.engine,
    this.maxItems = 4,
  });

  final LearningEngine engine;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final weak = engine.weakTopics.take(maxItems).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'ZAYIF KONULARIN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              weak.isEmpty
                  ? 'Henüz yeterli çözüm verisi yok. En az 5 soru çözdüğün konular analiz edilir.'
                  : 'Arena performansına göre daha fazla çalışman önerilen alanlar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (weak.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...weak.map((item) {
                final percent = item.accuracyPercent.clamp(0, 100).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  item.topic,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '%${percent.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.correct} doğru · ${item.wrong} yanlış · ${item.attempts} soru',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
