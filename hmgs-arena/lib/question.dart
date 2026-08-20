import 'question_difficulty.dart';

class Question {
  const Question({
    required this.id,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.sourceLabel,
    required this.sourceRef,
  });

  final String id;
  final String subject;
  final String topic;
  final QuestionDifficulty difficulty;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String sourceLabel;
  final String sourceRef;

  factory Question.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>).cast<String>();
    final correctIndex = json['correctIndex'] as int;
    if (options.length != 5) {
      throw const FormatException('HMGS ARENA sorularında tam 5 seçenek olmalı.');
    }
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw const FormatException('Doğru cevap indeksi geçersiz.');
    }

    return Question(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      difficulty: QuestionDifficulty.fromCode(json['difficulty'] as String),
      question: json['question'] as String,
      options: options,
      correctIndex: correctIndex,
      explanation: json['explanation'] as String,
      sourceLabel: json['sourceLabel'] as String,
      sourceRef: json['sourceRef'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'topic': topic,
        'difficulty': difficulty.code,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'sourceLabel': sourceLabel,
        'sourceRef': sourceRef,
      };
}
