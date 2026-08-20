import 'package:flutter_test/flutter_test.dart';

import 'package:hmgs_arena/question_bank.dart';
import 'package:hmgs_arena/question_difficulty.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed bank has 50 questions and 10 per difficulty', () async {
    final bank = await QuestionBank.load();

    expect(bank.total, 50);
    for (final level in QuestionDifficulty.values) {
      expect(bank.countByDifficulty[level], 10);
    }
  });
}
