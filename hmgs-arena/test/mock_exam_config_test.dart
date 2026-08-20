import 'package:flutter_test/flutter_test.dart';
import 'package:hmgs_arena/mock_exam_screen.dart';

void main() {
  test('HMGS tam deneme 120 soru ve 155 dakikadır', () {
    expect(HmgsMockExamConfig.totalQuestions, 120);
    expect(HmgsMockExamConfig.totalDuration, const Duration(minutes: 155));
    expect(HmgsMockExamConfig.halfTime, const Duration(minutes: 77, seconds: 30));
    expect(HmgsMockExamConfig.targetSecondsPerQuestion, 77.5);
  });
}
