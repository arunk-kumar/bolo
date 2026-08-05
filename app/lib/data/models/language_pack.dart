class LanguagePack {
  final String locale;
  final String nameEn;
  final String nameNative;
  final String script;
  final String fontFamily;
  final String ttsVoiceProvider;
  final String ttsVoiceId;
  final String wonderTheme;
  final String maturity;

  const LanguagePack({
    required this.locale,
    required this.nameEn,
    required this.nameNative,
    required this.script,
    required this.fontFamily,
    required this.ttsVoiceProvider,
    required this.ttsVoiceId,
    required this.wonderTheme,
    required this.maturity,
  });

  bool get isDevanagari => script == 'Devanagari';
}
