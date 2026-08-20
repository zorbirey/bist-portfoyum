import 'dart:convert';

import 'package:flutter/services.dart';

import 'question.dart';
import 'question_difficulty.dart';

class QuestionBank {
  const QuestionBank(this.questions);

  final List<Question> questions;

  int get total => questions.length;

  Map<QuestionDifficulty, int> get countByDifficulty {
    return {
      for (final level in QuestionDifficulty.values)
        level: questions.where((q) => q.difficulty == level).length,
    };
  }

  Set<String> get subjects => questions.map((q) => q.subject).toSet();

  static Future<QuestionBank> load({
    String manifestAsset = 'assets/question_manifest.json',
  }) async {
    final manifestRaw = await rootBundle.loadString(manifestAsset);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final files = (manifest['files'] as List<dynamic>).cast<String>();

    final questions = <Question>[];
    final ids = <String>{};

    for (final file in files) {
      final raw = await rootBundle.loadString(file);
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final question = Question.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        if (!ids.add(question.id)) {
          throw FormatException('Tekrarlanan soru ID: ${question.id}');
        }
        questions.add(question);
      }
    }

    return QuestionBank(List.unmodifiable(questions));
  }
}
