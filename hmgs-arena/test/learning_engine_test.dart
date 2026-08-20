import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hmgs_arena/learning_engine.dart';
import 'package:hmgs_arena/question.dart';
import 'package:hmgs_arena/question_difficulty.dart';

Question q(String id, String topic) => Question(
      id: id,
      subject: 'Borçlar Hukuku',
      topic: topic,
      difficulty: QuestionDifficulty.medium,
      question: 'Soru $id',
      options: const ['A', 'B', 'C', 'D', 'E'],
      correctIndex: 0,
      explanation: 'Açıklama',
      sourceLabel: 'TBK',
      sourceRef: 'm.1',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('yanlıştan sonra aynı konudan farklı soru seçilir', () async {
    final engine = await LearningEngine.create();
    final wrong = q('sozlesme-001', 'Sözleşmeler');
    final alternative = q('sozlesme-002', 'Sözleşmeler');
    final other = q('haksiz-001', 'Haksız Fiil');

    await engine.recordAnswer(wrong, false);
    final next = engine.pickNext(
      [wrong, alternative, other],
      previous: wrong,
    );

    expect(next, isNotNull);
    expect(next!.id, alternative.id);
    expect(next.id, isNot(wrong.id));
    expect(next.topic, wrong.topic);
  });

  test('5 denemede yüzde 70 altı konu zayıf olarak işaretlenir', () async {
    final engine = await LearningEngine.create();
    final question = q('haksiz-001', 'Haksız Fiil');

    await engine.recordAnswer(question, true);
    await engine.recordAnswer(question, false);
    await engine.recordAnswer(question, false);
    await engine.recordAnswer(question, true);
    await engine.recordAnswer(question, false);

    final weak = engine.weakTopics;
    expect(weak, hasLength(1));
    expect(weak.first.topic, 'Haksız Fiil');
    expect(weak.first.accuracyPercent, 40);
    expect(engine.weakTopicMessage, contains('Haksız Fiil'));
  });
}
