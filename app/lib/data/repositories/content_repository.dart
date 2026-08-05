import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/word_entry.dart';
import '../models/language_pack.dart';

class ContentRepository {
  // Singleton — loaded once at app start
  static ContentRepository? _instance;
  static ContentRepository get instance => _instance!;

  final List<WordEntry> _words;
  final Map<String, LanguagePack> _packs;

  ContentRepository._({
    required this._words,
    required this._packs,
  });

  // ── Load everything from assets ───────────────────────────────
  static Future<void> initialize(String locale) async {
    final coreYaml = await rootBundle.loadString(
        'assets/content/core/words.yaml');
    final coreWords = loadYaml(coreYaml) as YamlList;

    final packManifestYaml = await rootBundle.loadString(
        'assets/content/packs/$locale/manifest.yaml');
    final packManifest = loadYaml(packManifestYaml) as YamlMap;

    final packWordsYaml = await rootBundle.loadString(
        'assets/content/packs/$locale/words.yaml');
    final packWords = loadYaml(packWordsYaml) as YamlMap;

    final overridesYaml = await rootBundle.loadString(
        'assets/content/packs/$locale/cultural_overrides.yaml');
    final overrides = loadYaml(overridesYaml) as YamlMap;
    final skippedIds = Set<String>.from(
        (overrides['skip'] as YamlList? ?? YamlList()).cast<String>());

    final pack = LanguagePack(
      locale: packManifest['locale'] as String,
      nameEn: packManifest['name_en'] as String,
      nameNative: packManifest['name_native'] as String,
      script: packManifest['script'] as String,
      fontFamily: packManifest['font_family'] as String,
      ttsVoiceProvider: packManifest['tts_voice_provider'] as String,
      ttsVoiceId: packManifest['tts_voice_id'] as String,
      wonderTheme: packManifest['wonder_theme'] as String? ?? 'butterfly',
      maturity: packManifest['maturity'] as String? ?? 'alpha',
    );

    final words = <WordEntry>[];
    for (final raw in coreWords) {
      final core = raw as YamlMap;
      final id = core['id'] as String;

      if (skippedIds.contains(id)) continue;
      if (!packWords.containsKey(id)) continue;

      final pw = packWords[id] as YamlMap;
      final phonemes = (core['phoneme_targets_ipa'] as YamlList)
          .cast<String>()
          .toList();

      words.add(WordEntry(
        id: id,
        category: core['category'] as String,
        ageBand: core['age_band'] as String,
        phonemeTargets: phonemes,
        imageAsset: 'assets/${core['image']}',
        cdiRank: core['cdi_frequency_rank'] as int?,
        ashaAgeMonths: core['asha_milestone_age_months'] as int,
        universal: core['universal'] as bool,
        word: pw['word'] as String,
        transliteration: pw['transliteration'] as String?,
        audioAsset: 'assets/content/packs/$locale/${pw['audio']}',
      ));
    }

    _instance = ContentRepository._(
      words: words,
      packs: {locale: pack},
    );
  }

  // ── Queries ───────────────────────────────────────────────────

  List<WordEntry> wordsForAgeBand(String ageBand) =>
      _words.where((w) => w.ageBand == ageBand).toList();

  List<WordEntry> wordsForCategory(String category) =>
      _words.where((w) => w.category == category).toList();

  List<WordEntry> get allWords => List.unmodifiable(_words);

  LanguagePack? packFor(String locale) => _packs[locale];

  List<WordEntry> roundWords({
    required String ageBand,
    int count = 6,
  }) {
    final pool = wordsForAgeBand(ageBand)..shuffle();
    return pool.take(count).toList();
  }
}
