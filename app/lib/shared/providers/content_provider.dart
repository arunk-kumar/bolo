import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/word_entry.dart';
import '../../data/repositories/content_repository.dart';

// ── Active language pack ─────────────────────────────────────────
//
// MVP ships English only. This provider is kept intentionally — Phase 2
// (Hindi + further packs) will flip the value and trigger a repository
// reload, but the UI still reads from a single `activePack` source.
final activePackProvider = StateProvider<String>((ref) => 'en');

// ── Age band ─────────────────────────────────────────────────────
//
// The developmental age band the child plays at: "2-3", "3-4", or "4-5".
// MVP defaults to "2-3" (our densest content bucket); the onboarding
// age-picker will write to this provider in a follow-up commit, and the
// value will persist to SharedPreferences at that point. Every game reads
// from here so a single flip re-shapes the whole word pool.
final ageBandProvider = StateProvider<String>((ref) => '2-3');

// All words for the active pack.
final allWordsProvider = Provider<List<WordEntry>>((ref) {
  ref.watch(activePackProvider); // rebuild when pack changes
  return ContentRepository.instance.allWords;
});

// Words filtered by age band.
final wordsByAgeBandProvider =
    Provider.family<List<WordEntry>, String>((ref, ageBand) {
  ref.watch(activePackProvider);
  return ContentRepository.instance.wordsForAgeBand(ageBand);
});

// SharedPreferences — session streak, last-played info.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
