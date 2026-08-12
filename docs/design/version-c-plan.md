# Version C — Speech-first Naming Game

Written after a decision session covering Rules 1-6 and Design Points A-F.
This is the canonical spec for the naming-game rework. Nothing else should
override this until we ship and iterate.

## 1. Product intent in one sentence

Every word waits for the child's voice or tap, and rewards warmly regardless
of which comes first — with an extra sparkle if the child said the actual word.

## 2. Locked decisions

### Rule 1 — Tap always advances, revealed sequentially

- Tap-affordance is HIDDEN during the app's word audio and the "Your turn!" prompt.
- Only after the prompt finishes does the card become tappable AND the mic open.
- Prompt copy alternates across words: `Now you!` on odd-indexed words, `Say it!` on even. Never the same twice in a row.
- The tap-affordance appears with a **pop-in animation** — soft scale from 0.9 → 1.0 with a subtle bounce (200ms).

### Rule 2 — Always advance, no retry loop

- Every child interaction (Path Y / X / Z / early-listen α) advances to the next word after its celebration.
- No "try again" loop. Six words per round is fixed.

### Rule 3 — Silence timeout policy

- After listening starts, wait `6 sec` for any interaction.
  - First word of a round: wait `8 sec` instead (warm-up buffer).
- If silence → app re-speaks the word once + plays `"Let's try again"` (gentle voice, ~500ms).
- Listen again for another 6 sec.
- If still silent → advance silently to next word. No shame, no red X, no timeout screen.
- Score does NOT increment on silence-advance (that's Path Q, +0).

### Rule 4 — On-device STT only, ever

- On `SpeechToText.listen()`, always pass `SpeechListenOptions(onDevice: true)`.
- On `initialize()`, check the returned capability.
  - If device supports on-device STT → full Version C with word matching.
  - If NOT → fall back to **vocalization-only mode**:
    - Mic still opens, amplitude detection still runs.
    - Path X (any vocalization) still triggers.
    - Path Y (matched word) NEVER triggers on this device.
    - Parent-zone shows a small note: "Word-recognition unavailable on this device."
- **Under NO condition** do we fall back to cloud STT. That would break the privacy policy.

### Rule 5 — Union match for Path Y

STT transcription is normalized (lowercase, strip non-letters, collapse whitespace).
Path Y fires if ANY of the following holds against the target word:

1. **Substring match** — transcription contains target OR target contains transcription.
2. **Edit distance** — Levenshtein distance ≤ 2 if target ≥ 5 chars, else ≤ 1.
3. **First-3-char prefix** — first 3 chars of transcription match first 3 chars of target AND transcription is at least `target.length / 2` chars long.

### Rule 6 — Score = engagements

- All three success paths score +1: Y = X = Z = +1.
- Path Q (silence-advance) scores +0.
- Path Y additionally triggers a **star-burst animation** on the score pill (visual weight, no math change).
- Parent-zone counts match the in-game score exactly (includes Z).

### Design A — Invisible mic, card border glow

- No mic icon anywhere on the screen.
- During listening state, the card border pulses with a saffron glow:
  - Color: `BoloColors.saffron` @ **20% opacity**
  - Fade-in: 300ms when listening starts
  - Steady state: continuous pulse, **1.5-sec period**, ease-in-out
  - Fade-out: 200ms when any path fires
- The card border glow is also **amplitude-responsive** (see Design C): louder child voice → brighter glow, so the child sees "the app is hearing me."

### Design B — B2-α-3: early-listen with "You said it first!"

- App's word audio plays with mic OFF.
- Immediately after audio ends, wait `100ms` (audio tail decay), then open mic for a `400ms` amplitude-only window.
- During this 400ms window:
  - If sound detected above threshold + duration ≥ 300ms → **skip** the "Your turn!" prompt.
  - Play `"You said it first!"` (bigger, warmer reward, ~700-800ms).
  - Advance as Path X or Path Y (STT still evaluates once it finalizes, but the "first!" acknowledgment plays regardless).
- If no sound in the 400ms window → proceed to "Your turn!" / "Now you!" prompt (per Rule 1).

### Design C — Background noise handling

- **C1c amplitude + duration filter:**
  - Amplitude threshold: `-30dB` (roughly "quiet talking at 3 feet").
  - Duration requirement: sound must sustain ≥ `300ms` to count as a vocalization.
  - Filters out car horns, coughs, short spikes; passes toddler utterances.
- **C2b grace period:** mic opens 100ms after our audio ends (audio tail decay).
- **Mic amplitude visualization enabled:** the card border glow (Design A) scales with mic amplitude in real-time during listening. Louder speech = brighter glow.

### Design D — D1-long celebration

- Full 4-sec crowd cheer (`session_complete.wav`) plays after every 6-word round.
- No variation, no A/B based on score. Repetition is a feature for toddlers.
- Session-complete text: `"Amazing!"` (unchanged).

### Design E — E1: wait for STT final

- Path Y evaluation triggers ONLY on `SpeechRecognitionResult.finalResult == true`.
- Do NOT act on partial transcripts.
- Configure `speech_to_text` with `pauseFor: Duration(milliseconds: 800)`.
- Note: this is separate from early-listen (Design B), which is amplitude-only and fires on sound, not on STT.

### Design F — F1: trust Rule 5 for MVP

- Ship Version C with Rule 5's algorithmic matching only.
- No per-word `stt_alts` field yet.
- After 1-2 weeks of real usage, review which words most often miss and add `stt_alts` for those (evolution to F5).

## 3. Per-word state machine

```
                 ┌─────────────┐
                 │  IDLE       │  (round just started or previous word done)
                 └─────────────┘
                        │ auto after 400ms
                        ▼
                 ┌─────────────┐
                 │ SPEAK_WORD  │  Play "chicken" (~800ms audio)
                 └─────────────┘   mic OFF, card NOT tappable, no hint text
                        │ audio end + 100ms
                        ▼
                 ┌─────────────┐
                 │ EARLY_LISTEN│  400ms amplitude-only window
                 └─────────────┘   mic ON (amplitude only)
                        │
              ┌─────────┴──────────┐
              │                    │
     voice detected            no voice
              │                    │
              ▼                    ▼
       ┌──────────────┐     ┌─────────────┐
       │ CELEB_FIRST  │     │ SPEAK_PROMPT│  "Now you!" or "Say it!"
       │ "You said    │     └─────────────┘  (~400ms alternating)
       │  it first!"  │            │ prompt end
       └──────────────┘            ▼
              │             ┌─────────────┐
              │             │ LISTEN      │  mic on (STT + amplitude)
              │             │             │  card tappable, glow starts
              │             └─────────────┘  6s (or 8s if first word)
              │                    │
              │        ┌───────────┼──────────┬────────────┐
              │        ▼           ▼          ▼            ▼
              │   STT match  Vocalized     Card tap    Timeout
              │   (Path Y)   (Path X)      (Path Z)    (Path Q)
              │        │           │          │            │
              │        ▼           ▼          ▼            ▼
              │  ┌──────────┐ ┌─────────┐ ┌────────┐ ┌────────────┐
              │  │CELEB_Y   │ │CELEB_X  │ │CELEB_Z │ │REPROMPT    │
              │  │"You said │ │"Nice    │ │"Good!" │ │(re-speak + │
              │  │ it!"     │ │ try!"   │ │        │ │"Let's try  │
              │  │+starburst│ │         │ │        │ │ again")    │
              │  └──────────┘ └─────────┘ └────────┘ └────────────┘
              │        │           │          │            │
              │        │           │          │            │ silent again
              │        │           │          │            ▼ (6s more)
              │        │           │          │      ┌──────────┐
              │        │           │          │      │ SILENT_ADV│
              │        │           │          │      │ (Path Q,  │
              │        │           │          │      │  score+0) │
              │        │           │          │      └──────────┘
              └────────┴───────────┴──────────┴────────────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │ ADVANCE     │  next word, or session complete
                            └─────────────┘
```

## 4. Audio assets needed

All 7 clips should be recorded by the same warm adult voice for consistency:

| File | Copy | Duration | Fires when |
|---|---|---|---|
| `prompt_now_you.wav` | "Now you!" | ~400ms | Rule 1 prompt (odd words) |
| `prompt_say_it.wav` | "Say it!" | ~400ms | Rule 1 prompt (even words) |
| `prompt_lets_try.wav` | "Let's try again" | ~500ms | Rule 3 re-prompt |
| `feedback_said_it.wav` | "You said it!" | ~800ms | Path Y (matched word) |
| `feedback_said_it_first.wav` | "You said it first!" | ~700-800ms | Design B early-listen |
| `feedback_nice_try.wav` | "Nice try!" | ~600ms | Path X (vocalized, no match) |
| `feedback_good.wav` | "Good!" | ~500ms | Path Z (silent tap) |

All at PCM 16-bit mono 44.1kHz to match `session_complete.wav` and `reward.wav`.

## 5. Code changes required

### 5.1 New file: `app/lib/shared/audio/speech_recognition_service.dart`

Wraps `speech_to_text` package. Public API:

- `Future<bool> initialize()` — Returns true if on-device STT available.
- `Stream<SpeechEvent> listen({required String targetWord, required Duration timeout})` — Opens mic, streams events. `SpeechEvent` is one of: `amplitudeSpike(double amp)`, `matchedWord()`, `vocalized(String transcript)`, `silence()`.
- `Future<void> stop()` — Force-close mic.
- `bool get isOnDeviceAvailable`

Amplitude detection uses `onSoundLevelChange` from `speech_to_text`. STT uses `listen()` with `onDevice: true`.

### 5.2 New file: `app/lib/features/game_naming/naming_state_machine.dart`

Pure Dart state machine. Takes events (audio end, mic voice, tap, timer expiry) → emits state transitions.

States: `idle | speakWord | earlyListen | speakPrompt | listen | celebY | celebX | celebZ | celebFirst | reprompt | silentAdvance | advance`

Kept separate from the widget so the state machine can be unit-tested without pumping frames.

### 5.3 Rewrite: `app/lib/features/game_naming/naming_game_screen.dart`

- Replace the current `_onTap()`-driven flow with the state machine above.
- Card becomes non-tappable during `speakWord`, `earlyListen`, `speakPrompt`, `reprompt`.
- Card becomes tappable during `listen` only. Tap → Path Z celeb.
- Card border glow — new `_CardGlow` widget layered over the current card, driven by mic amplitude stream from `SpeechRecognitionService`.
- Score pill gets `AnimatedSwitcher` with star-burst overlay on Path Y.
- Hint text `"🎤 Say it or tap!"` appears with pop-in scale animation when entering `listen`.

### 5.4 Update: `app/lib/shared/audio/audio_service.dart`

Add `playFeedback(FeedbackKind)` method covering the 7 new clips. Enum-driven so callers don't hard-code filenames.

### 5.5 Update: `docs/privacy/index.html`

Line 158-161 currently claims:
> "Bolo does not perform speech recognition, transcription, or pronunciation scoring in this version."

Replace with:
> "Bolo listens for your child's voice during a word game. Speech recognition runs entirely on your device using its built-in offline recognizer — audio is never recorded, stored, or transmitted. If your device does not support on-device recognition, Bolo listens only for sound level (does not try to recognize words). Bolo does not perform pronunciation scoring."

### 5.6 Update: `app/lib/features/parent/progress_service.dart`

No API change. Under the hood, `recordRoundComplete(wordsSpoken:)` receives the score, which now under Rule 6 counts Path Y/X/Z (not Q). No code change here — the caller (`NamingGameScreen`) already computes the score correctly.

### 5.7 Optional: `app/lib/features/parent/progress_screen.dart`

If STT is unavailable on the device, add a small info tile:
> "Word recognition is unavailable on this device. Bolo still cheers your child on when they speak — it just can't tell whether the word matched."

## 6. Test plan

### 6.1 Widget tests

- State machine unit test: full round of 6 words, each path through the FSM. Assert state transitions and score increments.
- Widget test: card is non-tappable during `speakWord`; becomes tappable during `listen`.
- Widget test: after 6s silence, `SPEAK_PROMPT` re-fires. After another 6s, `silentAdvance` fires.
- Widget test: star-burst animation only renders on Path Y.

### 6.2 Real-device tests

- Manual: play a round on physical Android with STT available. Verify Path Y fires for clear utterances.
- Manual: play a round on physical Android with STT unavailable (test by revoking Google Speech Services permission). Verify Path X still fires and Path Y never does.
- Manual: run a round while a sibling is talking in the background. Verify false-positive rate feels tolerable.
- Manual: run a round while playing music through the phone speaker. Verify no self-triggered false positives.

### 6.3 Privacy audit (before Play Store)

- Run `mitmproxy` with phone routed through it. Complete a full session in the app.
- Assert: zero outbound requests to `www.google.com/speech-api/*`, `fonts.gstatic.com`, or any host outside `github.com` (release channel only).

## 7. Timeline estimate

| Phase | Effort | Blocker |
|---|---|---|
| Audio assets — user records | ~1-2 hours | User time |
| Speech recognition service | ~4 hours | None |
| State machine | ~3 hours | None |
| Naming game rewrite | ~5 hours | None |
| Card glow + amplitude visualization | ~2 hours | None |
| Privacy policy update | ~15 min | None |
| Unit + widget tests | ~3 hours | None |
| Real-device testing | ~2 hours | Physical Android |
| Iteration on real-device findings | ~2-4 hours | Test data |
| **Total** | **~1.5-2 days** of focused work | Audio delivery |

## 8. What Version C does NOT change

- Word list, category order, age bands, progress storage, parent gate, stage map UI.
- Session structure (6 words per round, 8 categories).
- Play Store listing (still says "on-device only" — because we still are).
- The COPPA compliance posture (no PII, no accounts, no analytics, no tracking).

## 9. Post-ship evolution

- **F5:** After 1-2 weeks of real usage data, curate `stt_alts` for the ~30-50 words with highest miss rates.
- **Voice fingerprinting:** if a sibling-noise problem becomes real, consider training an on-device speaker-identification model (Google Teachable Machine-style) to distinguish the target child. Deep post-MVP.
- **Multilingual (Hindi):** Hindi on-device STT is far less common on Android. Version C for Hindi will likely need to be vocalization-only mode for months to years, until Google's on-device Hindi model matures.
