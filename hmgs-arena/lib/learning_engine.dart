import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'question.dart';

class TopicProgress {
  const TopicProgress({
    required this.subject,
    required this.topic,
    required this.attempts,
    required this.correct,
  });

  final String subject;
  final String topic;
  final int attempts;
  final int correct;

  int get wrong => attempts - correct;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  double get accuracyPercent => accuracy * 100;

  bool get isWeak => attempts >= 5 && accuracy < 0.70;

  double get weaknessScore {
    if (attempts == 0) return 0;
    final errorRate = 1 - accuracy;
    final confidence = min(1.0, attempts / 12);
    return errorRate * confidence;
  }

  TopicProgress record(bool wasCorrect) {
    return TopicProgress(
      subject: subject,
      topic: topic,
      attempts: attempts + 1,
      correct: correct + (wasCorrect ? 1 : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'topic': topic,
        'attempts': attempts,
        'correct': correct,
      };

  factory TopicProgress.fromJson(Map<String, dynamic> json) {
    return TopicProgress(
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      attempts: json['attempts'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
    );
  }
}

class LearningEngine {
  LearningEngine._(this._prefs, this._random);

  static const _progressKey = 'hmgs_topic_progress_v1';
  static const _recentKey = 'hmgs_recent_question_ids_v1';
  static const _seenKey = 'hmgs_seen_question_ids_v1';
  static const _reinforcementKey = 'hmgs_reinforcement_topic_v1';

  final SharedPreferences _prefs;
  final Random _random;

  final Map<String, TopicProgress> _progress = {};
  final List<String> _recentIds = [];
  final Set<String> _seenIds = {};
  String? _pendingReinforcement;

  static Future<LearningEngine> create({Random? random}) async {
    final prefs = await SharedPreferences.getInstance();
    final engine = LearningEngine._(prefs, random ?? Random());
    engine._restore();
    return engine;
  }

  static String topicKey(String subject, String topic) => '$subject::$topic';

  void _restore() {
    final rawProgress = _prefs.getString(_progressKey);
    if (rawProgress != null && rawProgress.isNotEmpty) {
      final decoded = jsonDecode(rawProgress) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _progress[entry.key] = TopicProgress.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    _recentIds
      ..clear()
      ..addAll(_prefs.getStringList(_recentKey) ?? const []);
    _seenIds
      ..clear()
      ..addAll(_prefs.getStringList(_seenKey) ?? const []);
    _pendingReinforcement = _prefs.getString(_reinforcementKey);
  }

  List<TopicProgress> get weakTopics {
    final list = _progress.values.where((item) => item.isWeak).toList();
    list.sort((a, b) {
      final weakness = b.weaknessScore.compareTo(a.weaknessScore);
      if (weakness != 0) return weakness;
      return b.attempts.compareTo(a.attempts);
    });
    return list;
  }

  TopicProgress? progressFor(String subject, String topic) {
    return _progress[topicKey(subject, topic)];
  }

  Future<void> recordAnswer(Question question, bool wasCorrect) async {
    final key = topicKey(question.subject, question.topic);
    final current = _progress[key] ??
        TopicProgress(
          subject: question.subject,
          topic: question.topic,
          attempts: 0,
          correct: 0,
        );
    _progress[key] = current.record(wasCorrect);

    _seenIds.add(question.id);
    _rememberRecent(question.id);

    // Yanlış sorunun kendisini değil, yalnızca konu başlığını pekiştirme
    // kuyruğuna alıyoruz. Sonraki soru aynı konudan farklı bir soru olur.
    if (!wasCorrect) {
      _pendingReinforcement = key;
      await _prefs.setString(_reinforcementKey, key);
    }

    await _persist();
  }

  Question? pickNext(
    List<Question> bank, {
    Question? previous,
    String? subject,
    String? topic,
  }) {
    if (bank.isEmpty) return null;

    Iterable<Question> base = bank;
    if (subject != null) {
      base = base.where((q) => q.subject == subject);
    }
    if (topic != null) {
      base = base.where((q) => q.topic == topic);
    }

    final baseList = base.toList();
    if (baseList.isEmpty) return null;

    // 1) Yanlış cevaptan sonra aynı konu, fakat kesinlikle farklı soru.
    final reinforcement = _pendingReinforcement;
    if (reinforcement != null) {
      final alternatives = baseList.where((q) {
        return topicKey(q.subject, q.topic) == reinforcement &&
            q.id != previous?.id &&
            !_recentIds.contains(q.id);
      }).toList();

      if (alternatives.isNotEmpty) {
        _pendingReinforcement = null;
        _prefs.remove(_reinforcementKey);
        return _randomItem(alternatives);
      }
    }

    // 2) Normal akışta zaman zaman zayıf konulardan yeni soru getir.
    if (weakTopics.isNotEmpty && _random.nextDouble() < 0.35) {
      for (final weak in weakTopics.take(3)) {
        final candidates = baseList.where((q) {
          return q.subject == weak.subject &&
              q.topic == weak.topic &&
              q.id != previous?.id &&
              !_recentIds.contains(q.id) &&
              !_seenIds.contains(q.id);
        }).toList();
        if (candidates.isNotEmpty) return _randomItem(candidates);
      }
    }

    // 3) Öncelik hiç görülmemiş sorularda.
    final unseen = baseList.where((q) {
      return q.id != previous?.id &&
          !_seenIds.contains(q.id) &&
          !_recentIds.contains(q.id);
    }).toList();
    if (unseen.isNotEmpty) return _randomItem(unseen);

    // 4) Havuz daraldıysa yakın zamanda görülmemiş sorular kullanılabilir.
    final notRecent = baseList.where((q) {
      return q.id != previous?.id && !_recentIds.contains(q.id);
    }).toList();
    if (notRecent.isNotEmpty) return _randomItem(notRecent);

    // 5) Son çare: bir önceki sorudan farklı herhangi bir soru.
    final fallback = baseList.where((q) => q.id != previous?.id).toList();
    if (fallback.isNotEmpty) return _randomItem(fallback);
    return baseList.first;
  }

  String? get weakTopicMessage {
    final weak = weakTopics;
    if (weak.isEmpty) return null;
    final top = weak.first;
    final percent = top.accuracyPercent.toStringAsFixed(0);
    return 'Zayıf alanın: ${top.subject} • ${top.topic} (%$percent başarı)';
  }

  void _rememberRecent(String id) {
    _recentIds.remove(id);
    _recentIds.add(id);
    const recentWindow = 150;
    if (_recentIds.length > recentWindow) {
      _recentIds.removeRange(0, _recentIds.length - recentWindow);
    }
  }

  Question _randomItem(List<Question> items) {
    return items[_random.nextInt(items.length)];
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(
      _progress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await Future.wait([
      _prefs.setString(_progressKey, encoded),
      _prefs.setStringList(_recentKey, _recentIds),
      _prefs.setStringList(_seenKey, _seenIds.toList()),
    ]);
  }
}
