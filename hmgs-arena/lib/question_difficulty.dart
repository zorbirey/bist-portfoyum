enum QuestionDifficulty {
  veryEasy('cok_kolay', 'Çok Kolay', 1),
  easy('kolay', 'Kolay', 2),
  medium('orta', 'Orta', 3),
  hard('zor', 'Zor', 4),
  veryHard('cok_zor', 'Çok Zor', 5);

  const QuestionDifficulty(this.code, this.label, this.weight);

  final String code;
  final String label;
  final int weight;

  static QuestionDifficulty fromCode(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('ğ', 'g')
        .replaceAll(' ', '_');

    return switch (normalized) {
      'cok_kolay' || 'very_easy' => QuestionDifficulty.veryEasy,
      'kolay' || 'easy' => QuestionDifficulty.easy,
      'orta' || 'medium' => QuestionDifficulty.medium,
      'zor' || 'hard' => QuestionDifficulty.hard,
      'cok_zor' || 'very_hard' => QuestionDifficulty.veryHard,
      _ => throw FormatException('Bilinmeyen zorluk seviyesi: $value'),
    };
  }
}
