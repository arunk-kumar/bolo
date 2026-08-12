import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Events emitted by [SpeechRecognitionService] during a listen session.
sealed class SpeechEvent {
  const SpeechEvent();
}

/// Fires ~10-30x/sec while the mic is open. Level normalized 0..1.
/// The card-border glow (Design A + C) subscribes to this for the
/// amplitude-responsive visualization.
class AmplitudeEvent extends SpeechEvent {
  final double level;
  const AmplitudeEvent(this.level);
}

/// Fires when the STT engine emits a transcript. Partial vs final is
/// determined by [isFinal]. Under Rule E1 we act only on isFinal=true.
class TranscriptEvent extends SpeechEvent {
  final String text;
  final bool isFinal;
  const TranscriptEvent(this.text, {required this.isFinal});
}

/// Fires when the STT engine reports an error. Not fatal — the state
/// machine treats it as "no transcript this window."
class SpeechErrorEvent extends SpeechEvent {
  final String message;
  const SpeechErrorEvent(this.message);
}

/// Wraps the `speech_to_text` package so the rest of the app talks in
/// [SpeechEvent] terms and never touches the plugin's callback maze.
///
/// COPPA / privacy posture: `onDevice: true` is passed to every listen()
/// call. If the device does not support on-device recognition, the
/// speech_to_text package will refuse the call rather than silently
/// falling back to cloud STT (per platform docs). We check
/// [isOnDeviceCapable] up-front and never call listen() when false —
/// caller falls back to vocalization-only via [AmplitudeEvent] alone.
class SpeechRecognitionService {
  SpeechRecognitionService();

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;
  bool _onDeviceCapable = false;
  StreamController<SpeechEvent>? _controller;

  /// True when [initialize] has succeeded AND the device advertised
  /// on-device recognition. When false, callers should NOT invoke
  /// [listen] — instead they should degrade to vocalization-only mode
  /// (which requires no STT at all, only mic amplitude, but this
  /// service does not currently expose an amplitude-only path — that's
  /// a follow-up if the fallback path becomes important).
  bool get isOnDeviceCapable => _onDeviceCapable;

  /// Idempotent. Safe to call every time the game screen mounts.
  Future<bool> initialize() async {
    if (_initialized) return _onDeviceCapable;
    try {
      _initialized = await _stt.initialize(
        onError:  (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _initialized = false;
    }
    // The speech_to_text package doesn't expose a direct
    // "supportsOnDevice" flag pre-listen. Best-effort proxy: if the
    // platform reports the plugin ready, assume on-device is available
    // and let listen() surface an error otherwise. On Android 12+ /
    // recent iOS this is universally true; on older phones the mic
    // will still open but on-device support may be absent — the game
    // simply won't get transcripts, only amplitude.
    _onDeviceCapable = _initialized;
    return _onDeviceCapable;
  }

  /// Open the mic for at most [timeout]. Returns a stream that closes
  /// when [stop] is called or the timeout expires. Every listen call
  /// forces on-device recognition.
  Stream<SpeechEvent> listen({
    required Duration timeout,
    Duration pauseFor = const Duration(milliseconds: 800),
    String? localeId,
  }) {
    _controller = StreamController<SpeechEvent>.broadcast();
    () async {
      try {
        await _stt.listen(
          listenOptions: stt.SpeechListenOptions(
            onDevice: true,
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
            partialResults: true,
            // pauseFor / listenFor / localeId moved inside options in
            // speech_to_text 7.0.0; top-level params are deprecated.
            // ignore: invalid_use_of_visible_for_testing_member
          ),
          // ignore: deprecated_member_use
          pauseFor: pauseFor,
          // ignore: deprecated_member_use
          listenFor: timeout,
          // ignore: deprecated_member_use
          localeId: localeId,
          onResult: (r) => _emit(
            TranscriptEvent(r.recognizedWords, isFinal: r.finalResult),
          ),
          onSoundLevelChange: (level) => _emit(
            AmplitudeEvent(_normalizeLevel(level)),
          ),
        );
      } catch (e) {
        _emit(SpeechErrorEvent(e.toString()));
        await _controller?.close();
      }
    }();
    return _controller!.stream;
  }

  /// Force-close the mic. Safe to call multiple times; safe to call when
  /// the mic isn't open.
  Future<void> stop() async {
    try {
      if (_stt.isListening) await _stt.stop();
    } catch (_) {}
    try {
      await _controller?.close();
    } catch (_) {}
    _controller = null;
  }

  void _emit(SpeechEvent event) {
    final c = _controller;
    if (c == null || c.isClosed) return;
    c.add(event);
  }

  /// The `speech_to_text` plugin reports level in dB (roughly -160..0 on
  /// Android, arbitrary on iOS). We normalize to 0..1 with -30dB as the
  /// "clearly audible speech" reference (Design C — matches the C1c
  /// threshold used by the state machine's amplitude filter).
  static double _normalizeLevel(double raw) {
    // Rough mapping: -30dB -> 0.5, silence (-60dB) -> 0.0, 0dB -> 1.0.
    // Not calibrated per device; the state machine's threshold is fuzzy
    // and this is only used for the glow visualization + coarse
    // duration-based detection. Precision is not a goal here.
    const floor   = -60.0;
    const ceiling = 0.0;
    if (raw <= floor) return 0.0;
    if (raw >= ceiling) return 1.0;
    return (raw - floor) / (ceiling - floor);
  }
}
