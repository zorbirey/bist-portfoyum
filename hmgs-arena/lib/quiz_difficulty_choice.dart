import 'question_difficulty.dart';

enum QuizDifficultyChoice {
  random('Rastgele', null),
  veryEasy('Çok Kolay', QuestionDifficulty.veryEasy),
  easy('Kolay', QuestionDifficulty.easy),
  medium('Orta', QuestionDifficulty.medium),
  hard('Zor', QuestionDifficulty.hard),
  veryHard('Çok Zor', QuestionDifficulty.veryHard);

  const QuizDifficultyChoice(this.label, this.difficulty);

  final String label;
  final QuestionDifficulty? difficulty;

  bool get isBalancedRandom => this == QuizDifficultyChoice.random;
}
