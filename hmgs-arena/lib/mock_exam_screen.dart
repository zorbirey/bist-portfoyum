import 'dart:async';

import 'package:flutter/material.dart';

import 'ad_service.dart';
import 'question.dart';
import 'question_bank.dart';
import 'question_set_builder.dart';

class HmgsMockExamConfig {
  const HmgsMockExamConfig._();

  static const int totalQuestions = 120;
  static const Duration totalDuration = Duration(minutes: 155);
  static const Duration halfTime = Duration(minutes: 77, seconds: 30);
  static const double targetSecondsPerQuestion =
      totalDuration.inSeconds / totalQuestions;
}

class MockExamHomeScreen extends StatefulWidget {
  const MockExamHomeScreen({super.key, required this.adService});

  final AdService adService;

  @override
  State<MockExamHomeScreen> createState() => _MockExamHomeScreenState();
}

class _MockExamHomeScreenState extends State<MockExamHomeScreen> {
  late Future<QuestionBank> _bankFuture;

  @override
  void initState() {
    super.initState();
    _bankFuture = QuestionBank.load();
    widget.adService.loadInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Sınavları')),
      body: FutureBuilder<QuestionBank>(
        future: _bankFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Soru bankası açılamadı: ${snapshot.error}'),
              ),
            );
          }

          final bank = snapshot.data!;
          final eligible = bank.questions
              .where((question) => question.isHmgsFiveOptionFormat)
              .toList();
          final ready = eligible.length >= HmgsMockExamConfig.totalQuestions;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HMGS Tam Deneme',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text('120 çoktan seçmeli soru'),
                      const Text('5 seçenek: A, B, C, D, E'),
                      const Text('Toplam süre: 155 dakika'),
                      const Text('Ortalama hedef: soru başına 77,5 saniye'),
                      const SizedBox(height: 16),
                      Text(
                        ready
                            ? 'Deneme havuzu hazır.'
                            : 'Tam deneme için en az 120 doğrulanmış, 5 seçenekli soru gerekir. Şu an uygun soru: ${eligible.length}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ready
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sınav psikolojisi modu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Sınav sırasında reklam gösterilmez.'),
                      Text('• Toplam süre bittiği anda deneme otomatik kapanır.'),
                      Text('• Soru hedef süresinin son 10 saniyesinde cevap yoksa ekran kırmızı yanıp söner.'),
                      Text('• 60. soruya gelindiğinde 77:30 aşılmışsa zaman uyarısı gösterilir.'),
                      Text('• Deneme bittikten sonra tek geçiş reklamı ve ardından sonuç ekranı açılır.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: ready ? () => _startExam(eligible) : null,
                icon: const Icon(Icons.timer_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('155 Dakikalık Denemeyi Başlat'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startExam(List<Question> eligible) {
    try {
      final questions = QuestionSetBuilder().build(
        bank: eligible,
        totalCount: HmgsMockExamConfig.totalQuestions,
        mode: QuestionSelectionMode.balancedRandom,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MockExamSessionScreen(
            questions: questions,
            adService: widget.adService,
          ),
        ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class MockExamSessionScreen extends StatefulWidget {
  const MockExamSessionScreen({
    super.key,
    required this.questions,
    required this.adService,
  });

  final List<Question> questions;
  final AdService adService;

  @override
  State<MockExamSessionScreen> createState() => _MockExamSessionScreenState();
}

class _MockExamSessionScreenState extends State<MockExamSessionScreen> {
  final Map<int, int> _answers = {};
  final Map<int, int> _spentSeconds = {};

  late final DateTime _examStartedAt;
  late DateTime _questionEnteredAt;
  Timer? _timer;
  int _currentIndex = 0;
  bool _blinkOn = false;
  bool _halfTimeWarningShown = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _examStartedAt = DateTime.now();
    _questionEnteredAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _elapsed => DateTime.now().difference(_examStartedAt);

  Duration get _remainingTotal {
    final remaining = HmgsMockExamConfig.totalDuration - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get _currentQuestionSpentSeconds {
    final saved = _spentSeconds[_currentIndex] ?? 0;
    return saved + DateTime.now().difference(_questionEnteredAt).inSeconds;
  }

  double get _questionTargetRemaining =>
      HmgsMockExamConfig.targetSecondsPerQuestion - _currentQuestionSpentSeconds;

  bool get _currentAnswered => _answers.containsKey(_currentIndex);

  bool get _urgentUnanswered {
    return !_currentAnswered &&
        _questionTargetRemaining > 0 &&
        _questionTargetRemaining <= 10;
  }

  void _tick() {
    if (!mounted || _finishing) return;
    if (_remainingTotal == Duration.zero) {
      _finishExam(timeExpired: true);
      return;
    }

    final reachedHalfQuestion = _currentIndex >= 59;
    if (!_halfTimeWarningShown &&
        reachedHalfQuestion &&
        _elapsed > HmgsMockExamConfig.halfTime) {
      _halfTimeWarningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showHalfTimeWarning();
      });
    }

    setState(() {
      _blinkOn = _urgentUnanswered ? !_blinkOn : false;
    });
  }

  Future<void> _showHalfTimeWarning() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zaman Uyarısı'),
        content: const Text(
          '60. soruya ulaştın ancak sınav süresinin yarısı olan 77 dakika 30 saniyeyi aştın. Kalan sorularda temponu artır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _commitQuestionTime() {
    final now = DateTime.now();
    final delta = now.difference(_questionEnteredAt).inSeconds;
    _spentSeconds[_currentIndex] = (_spentSeconds[_currentIndex] ?? 0) + delta;
    _questionEnteredAt = now;
  }

  void _goTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.questions.length) return;
    _commitQuestionTime();
    setState(() {
      _currentIndex = nextIndex;
      _questionEnteredAt = DateTime.now();
      _blinkOn = false;
    });
  }

  Future<void> _finishExam({bool timeExpired = false}) async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    _commitQuestionTime();

    await widget.adService.showInterstitial();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(
          questions: widget.questions,
          answers: Map.unmodifiable(_answers),
          timeExpired: timeExpired,
          elapsed: _elapsed,
        ),
      ),
    );
  }

  Future<void> _confirmFinish() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Denemeyi bitir'),
        content: const Text(
          'Sınavı şimdi bitirmek istediğine emin misin? Sonuç ekranına geçilecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sınavı Bitir'),
          ),
        ],
      ),
    );
    if (shouldFinish == true) {
      await _finishExam();
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final selected = _answers[_currentIndex];
    final targetRemaining = _questionTargetRemaining;
    final background = _blinkOn
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${_currentIndex + 1} / ${widget.questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Toplam ${_formatDuration(_remainingTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _QuestionTargetClock(secondsRemaining: targetRemaining),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${question.subject} • ${question.topic}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RadioListTile<int>(
                        value: i,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _answers[_currentIndex] = value;
                            _blinkOn = false;
                          });
                        },
                        title: Text(
                          '${String.fromCharCode(65 + i)}) ${question.options[i]}',
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentIndex == 0
                          ? null
                          : () => _goTo(_currentIndex - 1),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Önceki'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _currentIndex == widget.questions.length - 1
                          ? _confirmFinish
                          : () => _goTo(_currentIndex + 1),
                      icon: Icon(
                        _currentIndex == widget.questions.length - 1
                            ? Icons.flag_outlined
                            : Icons.chevron_right,
                      ),
                      label: Text(
                        _currentIndex == widget.questions.length - 1
                            ? 'Bitir'
                            : 'Sonraki',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionTargetClock extends StatelessWidget {
  const _QuestionTargetClock({required this.secondsRemaining});

  final double secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final overdue = secondsRemaining <= 0;
    final seconds = secondsRemaining.abs().ceil();
    final label = overdue ? '+${_formatSeconds(seconds)}' : _formatSeconds(seconds);
    final urgent = !overdue && secondsRemaining <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: urgent || overdue
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Soru hedefi', style: TextStyle(fontSize: 10)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MockExamResultScreen extends StatelessWidget {
  const MockExamResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.timeExpired,
    required this.elapsed,
  });

  final List<Question> questions;
  final Map<int, int> answers;
  final bool timeExpired;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctIndex) correct++;
    }
    final blank = questions.length - answers.length;
    final wrong = answers.length - correct;
    final success = (correct / questions.length) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Deneme Sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (timeExpired)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '155 dakikalık toplam süre sona erdiği için sınav otomatik olarak bitirildi.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '%${success.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Text('Doğru cevap oranı'),
                  const SizedBox(height: 20),
                  _ResultRow(label: 'Doğru', value: correct.toString()),
                  _ResultRow(label: 'Yanlış', value: wrong.toString()),
                  _ResultRow(label: 'Boş', value: blank.toString()),
                  _ResultRow(
                    label: 'Kullanılan süre',
                    value: _formatDuration(elapsed),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bu ekran çalışma analizi içindir; gösterilen yüzde ÖSYM tarafından hesaplanan resmi sınav puanı değildir.',
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 99 * 3600);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String _formatSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
