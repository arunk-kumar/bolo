import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/providers/content_provider.dart';

/// Tracks a minimal set of progress counters for the parent dashboard.
///
/// Backed by SharedPreferences at MVP so we don't need Isar wired up yet.
/// When Isar lands (post-launch), the same public API can flip to
/// SessionRecord queries without touching the UI. All values live under
/// well-known `bolo_progress_*` keys so a future migration is a for-loop
/// over `prefs.getKeys()`.
class ProgressService {
  ProgressService(this._prefs);
  final SharedPreferences _prefs;

  static const _kTotal    = 'bolo_progress_words_total';
  static const _kToday    = 'bolo_progress_words_today';
  static const _kTodayDay = 'bolo_progress_today_day'; // yyyymmdd of _kToday
  static const _kStreak   = 'bolo_progress_streak';
  static const _kLastDay  = 'bolo_progress_last_day';  // yyyymmdd string
  static const _kByCat    = 'bolo_progress_by_cat_';   // + category key

  /// Bump counters after a naming game round.
  Future<void> recordRoundComplete({
    required int wordsSpoken,
    required String? category,
  }) async {
    final today = _yyyymmdd(DateTime.now());
    // Total
    final total = _prefs.getInt(_kTotal) ?? 0;
    await _prefs.setInt(_kTotal, total + wordsSpoken);
    // Today — reset if the day changed
    final storedDay = _prefs.getInt(_kTodayDay);
    final currentToday = _prefs.getInt(_kToday) ?? 0;
    final newToday = storedDay == today ? currentToday + wordsSpoken : wordsSpoken;
    await _prefs.setInt(_kToday, newToday);
    await _prefs.setInt(_kTodayDay, today);
    // Streak
    await _bumpStreak(today);
    // Per-category
    if (category != null) {
      final k = '$_kByCat$category';
      await _prefs.setInt(k, (_prefs.getInt(k) ?? 0) + wordsSpoken);
    }
  }

  Future<void> _bumpStreak(int today) async {
    final lastDay = _prefs.getInt(_kLastDay);
    final streak = _prefs.getInt(_kStreak) ?? 0;
    if (lastDay == today) {
      // Same day — streak unchanged, still on today.
      return;
    }
    // Compute yesterday as YYYYMMDD.
    final now = DateTime.now();
    final yesterday = _yyyymmdd(now.subtract(const Duration(days: 1)));
    final newStreak = (lastDay == yesterday) ? streak + 1 : 1;
    await _prefs.setInt(_kStreak, newStreak);
    await _prefs.setInt(_kLastDay, today);
  }

  ProgressSummary summary() {
    final today = _yyyymmdd(DateTime.now());
    final storedTodayDay = _prefs.getInt(_kTodayDay);
    final wordsToday = storedTodayDay == today ? (_prefs.getInt(_kToday) ?? 0) : 0;
    final byCat = <String, int>{};
    for (final k in _prefs.getKeys()) {
      if (k.startsWith(_kByCat)) {
        byCat[k.substring(_kByCat.length)] = _prefs.getInt(k) ?? 0;
      }
    }
    return ProgressSummary(
      wordsToday: wordsToday,
      wordsTotal: _prefs.getInt(_kTotal) ?? 0,
      streakDays: _prefs.getInt(_kStreak) ?? 0,
      lastPlayed: _prefs.getInt(_kLastDay),
      byCategory: byCat,
    );
  }

  Future<void> reset() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('bolo_progress_')).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  static int _yyyymmdd(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;
}

class ProgressSummary {
  final int wordsToday;
  final int wordsTotal;
  final int streakDays;
  final int? lastPlayed; // yyyymmdd
  final Map<String, int> byCategory;

  const ProgressSummary({
    required this.wordsToday,
    required this.wordsTotal,
    required this.streakDays,
    required this.lastPlayed,
    required this.byCategory,
  });
}

// ── Riverpod ──────────────────────────────────────────────────────

final progressServiceProvider = Provider<ProgressService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return ProgressService(prefs);
});

/// Force reads to re-run after a write. Bump this int in the notifier and
/// any widget watching `progressSummaryProvider` rebuilds.
final progressBumpProvider = StateProvider<int>((_) => 0);

final progressSummaryProvider = Provider<ProgressSummary>((ref) {
  ref.watch(progressBumpProvider);
  return ref.watch(progressServiceProvider).summary();
});
