import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:hmgs_arena/question.dart';
import 'package:hmgs_arena/question_difficulty.dart';
import 'package:hmgs_arena/question_set_builder.dart';

Question makeQuestion(int index, QuestionDifficulty difficulty) => Question(
      id: '${difficulty.code}-$index',
      subject: 'Anayasa Hukuku',
      topic: 'Temel Haklar',
      difficulty: difficulty,
      question: 'Soru $index',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
      explanation: 'Açıklama',
      sourceLabel: 'Anayasa',
      sourceRef: 'm.10',
    );

void main() {
  test('20 soruluk rastgele testte her seviyeden 4 soru gelir', () {
    final bank = <Question>[];
    for (final level in QuestionDifficulty.values) {
      for (var i = 0; i < 10; i++) {
        bank.add(makeQuestion(i, level));
      }
    }

    final builder = QuestionSetBuilder(random: Random(7));
    final set = builder.build(bank: bank, totalCount: 20);

    expect(set, hasLength(20));
    for (final level in QuestionDifficulty.values) {
      expect(set.where((q) => q.difficulty == level), hasLength(4));
    }
  });

  test('rastgele dengeli test soru sayısı 5in katı olmalıdır', () {
    final builder = QuestionSetBuilder(random: Random(1));
    expect(
      () => builder.build(bank: const [], totalCount: 12),
      throwsArgumentError,
    );
  });
}
