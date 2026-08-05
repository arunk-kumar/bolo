import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/word_entry.dart';
import '../../data/repositories/content_repository.dart';

// Active locale — persisted across sessions
final activeLocaleProvider = StateProvider<String>((ref) => 'en');

// All words for the active locale
final allWordsProvider = Provider<List<WordEntry>>((ref) {
  ref.watch(activeLocaleProvider); // rebuild when locale changes
  return ContentRepository.instance.allWords;
});

// Words filtered by age band
final wordsByAgeBandProvider =
    Provider.family<List<WordEntry>, String>((ref, ageBand) {
  ref.watch(activeLocaleProvider);
  return ContentRepository.instance.wordsForAgeBand(ageBand);
});

// SharedPreferences — for session streak, last-played info
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
