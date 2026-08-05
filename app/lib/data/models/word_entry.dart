class WordEntry {
  final String id;
  final String category;
  final String ageBand;
  final List<String> phonemeTargets;
  final String imageAsset;
  final int? cdiRank;
  final int ashaAgeMonths;
  final bool universal;

  // Per-language fields (populated after merging with pack)
  final String word;
  final String? transliteration;
  final String audioAsset;

  const WordEntry({
    required this.id,
    required this.category,
    required this.ageBand,
    required this.phonemeTargets,
    required this.imageAsset,
    this.cdiRank,
    required this.ashaAgeMonths,
    required this.universal,
    required this.word,
    this.transliteration,
    required this.audioAsset,
  });
}
