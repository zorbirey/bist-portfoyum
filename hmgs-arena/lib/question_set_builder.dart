import 'dart:math';

import 'question.dart';
import 'question_difficulty.dart';

enum QuestionSelectionMode { balancedRandom, fixedDifficulty }

class QuestionSetBuilder {
  QuestionSetBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<Question> build({
    required List<Question> bank,
    required int totalCount,
    QuestionSelectionMode mode = QuestionSelectionMode.balancedRandom,
    QuestionDifficulty? difficulty,
    String? subject,
    String? topic,
    Set<String> excludedIds = const {},
  }) {
    if (totalCount <= 0) {
      throw const ArgumentError('Soru sayısı sıfırdan büyük olmalı.');
    }

    var filtered = bank.where((q) => !excludedIds.contains(q.id));
    if (subject != null) filtered = filtered.where((q) => q.subject == subject);
    if (topic != null) filtered = filtered.where((q) => q.topic == topic);
    final pool = filtered.toList();

    if (mode == QuestionSelectionMode.fixedDifficulty) {
      if (difficulty == null) {
        throw const ArgumentError('Sabit zorluk modunda zorluk seçilmeli.');
      }
      final candidates = pool.where((q) => q.difficulty == difficulty).toList();
      _ensureEnough(candidates.length, totalCount, difficulty.label);
      candidates.shuffle(_random);
      return candidates.take(totalCount).toList();
    }

    if (totalCount % QuestionDifficulty.values.length != 0) {
      throw ArgumentError(
        'Rastgele dengeli modda soru sayısı 5’in katı olmalı. '
        'Önerilen seçenekler: 10, 20, 30, 50.',
      );
    }

    final perDifficulty = totalCount ~/ QuestionDifficulty.values.length;
    final selected = <Question>[];

    for (final level in QuestionDifficulty.values) {
      final candidates = pool.where((q) => q.difficulty == level).toList();
      _ensureEnough(candidates.length, perDifficulty, level.label);
      candidates.shuffle(_random);
      selected.addAll(candidates.take(perDifficulty));
    }

    selected.shuffle(_random);
    return selected;
  }

  void _ensureEnough(int available, int needed, String label) {
    if (available < needed) {
      throw StateError(
        '$label seviyesinde yeterli soru yok. Gereken: $needed, mevcut: $available.',
      );
    }
  }
}
