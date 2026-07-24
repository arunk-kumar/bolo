# Bolo

**A Multilingual Speech-Therapy Play App for Toddlers with Speech Delay**

*Ages 2–5 · Android-first · Free-tools-first · Zero infrastructure*

---

**Document version:** 1.0
**Date:** 2026-07-23
**Author:** Arun Kumar
**Path chosen:** Plan B — Android-only launch, iOS later once proven

---

## Table of Contents

1. [The Problem](#the-problem)
2. [The Approach](#the-approach)
3. [What Makes Bolo Different](#what-makes-bolo-different)
4. [Product Design Decisions](#product-design-decisions)
5. [Technology Stack](#technology-stack)
6. [Pluggable Language-Pack Architecture](#pluggable-language-pack-architecture)
7. [Directory Layout](#directory-layout)
8. [Core Game Modules](#core-game-modules)
9. [Tiered Reward System — "Wonder"](#tiered-reward-system--wonder)
10. [Session & Pacing Rules](#session--pacing-rules)
11. [Parent Coaching Layer](#parent-coaching-layer)
12. [TTS Pipeline](#tts-pipeline)
13. [Store Readiness — Google Play (Designed for Families)](#store-readiness--google-play-designed-for-families)
14. [Phase Breakdown — Ship MVP in 1 Month](#phase-breakdown--ship-mvp-in-1-month)
15. [Post-Launch Monthly Releases](#post-launch-monthly-releases)
16. [Risks & Mitigations](#risks--mitigations)
17. [Verification](#verification)
18. [Budget — Plan B Free-First](#budget--plan-b-free-first)
19. [Infrastructure Requirements](#infrastructure-requirements)
20. [Appendix A: First-Day Concrete Tasks](#appendix-a-first-day-concrete-tasks)
21. [Appendix B: Sources & Research](#appendix-b-sources--research)

---

## The Problem

Speech delay in toddlers has become widespread. Every existing speech-therapy
app on the market is English-first — **zero apps target Hindi, Tamil, or any
Indian language for actual therapy use** (researched: Speech Blubs, Otsimo,
Articulation Station, Lingokids, Hallooo, and adjacent tools).

Meanwhile the strongest evidence base — the American Speech-Language-Hearing
Association (ASHA) and the Hanen Centre — points to **parent-mediated
intervention** as the most effective approach for late talkers under 3, yet
no current app treats the parent as more than a passive dashboard viewer.

Indian families face a specific gap:

- Content is uniformly Western (raccoons, bagels, yellow school buses)
- Grandparents and home caregivers often speak only the regional language,
  so English-only apps can't extend into daily life
- Indian speech-language pathology has a severe shortage of bilingual SLPs
- Subscription pricing ($10–15/month) excludes most Indian families
- Rural India has intermittent internet — cloud-dependent apps fail

## The Approach

**Bolo** is a multilingual speech-play app for toddlers ages 2–5, launching
on **Google Play (Designed for Families)** as an Android-only MVP, with
iOS added post-launch once the concept is validated.

Design principles:

- **Play-first, therapy-informed** — evidence-based techniques (focused
  stimulation, imitation modeling, WH-question hierarchy, turn-taking)
  delivered as games a toddler will actually want to play.
- **Culturally relevant** — Indian first words (chai, dal, nana/nani,
  rickshaw), not translated Americana.
- **Parent-inclusive** — Hanen-style coaching tips between rounds; Hindi
  Devanagari included so grandparents can engage.
- **Zero infrastructure** — no backend, no accounts, no cloud calls at
  runtime. COPPA-safe by construction.
- **Free tools where free tools are good enough** — Piper TTS instead of
  ElevenLabs, Kenney.nl assets instead of Midjourney, GitHub Pages instead
  of a paid domain.

## What Makes Bolo Different

1. **Pluggable language-pack architecture from day one.**
   India has 22 scheduled languages. A Chennai household is often Tamil +
   Hindi + English; a Delhi household Punjabi + Hindi + English. Bolo
   supports multiple simultaneously selected languages. Adding a new
   language = drop a new pack folder, no code changes. Scales globally
   (Spanish, Mandarin, Arabic, Portuguese) via the same pack format.

2. **Two modes by developmental stage.**
   - **Co-play** (ages 2–3): parent + child together, with Hanen-style
     OWL/PACE coaching tips between rounds. This is the strongest
     evidence-based approach for late talkers under 3.
   - **Solo** (ages 4–5): child-independent play. Parent-gate protects
     settings and progress.

3. **Full speech development, not just labeling.**
   Six game types cover the full ASHA expressive-language progression:
   naming → focused stimulation → imitation → responding to WH-questions
   (What → Where → Who → Why) → asking questions → conversational
   turn-taking.

4. **Visual "wonder" rewards, not confetti bursts.**
   Tiered reward system culminating in genuine full-screen spectacle:
   character transformations, world-scale particle systems, collectible
   creatures. The reward is the product's engagement engine.

5. **COPPA-safe by construction.**
   Pre-generated TTS assets, on-device any-vocalization detection only,
   zero analytics, zero ads, zero PII, no accounts required.

## Product Design Decisions

Locked in with the user during planning:

| Decision | Choice |
|---|---|
| Languages at MVP | English + Hindi. Tamil, Telugu, Bengali, Marathi, Kannada, Malayalam, Gujarati, Punjabi post-launch. |
| User model | Two modes by age at first launch. Parent gate on every non-play surface. |
| Speech input at MVP | "Did the child vocalize?" detection only. No word matching, no pronunciation scoring. On-device STT. |
| Content scope | Full expressive-language development. Six game types. |
| Content authoring | Self-authored, referenced against MacArthur-Bates CDI + ASHA milestones. |
| Reward design | Tiered: micro → moment → wonder. |
| Compliance | Google Play Designed for Families + COPPA. |
| Platform | Android-only at MVP. iOS added when concept is validated. |

## Technology Stack

Every choice is free-first where a good free option exists.

| Layer | Pick | Why |
|---|---|---|
| Framework | **Flutter** (stable) | Dart reads like Java; hot reload; Impeller renders 60fps; free. |
| Game overlay | **Flame** | Free game loop, sprite/component model, `flame_audio` AudioCache for sub-50ms tap-to-sound latency. |
| Character animation | **Flutter native `AnimationController` + `flutter_animate` (free, MIT)** with 3-pose PNG swap | No Rive subscription needed for MVP. Bouncy, playful character in ~100 lines of Dart. |
| One-shot celebrations | **Lottie** (free, MIT) — animations from LottieFiles.com free library (CC-BY/CC0) | Thousands of "confetti," "sparkle," "reward" animations. |
| State management | **Riverpod** with `@riverpod` codegen | Less boilerplate than Bloc for a solo dev; composes with Flame naturally. |
| Local storage | **Isar** | Type-safe Dart-first query API; no manual adapter registration; ACID transactions. |
| Routing | **`go_router`** | Type-safe declarative routing. |
| TTS (build-time) | **Piper TTS** (MIT, open-source) for EN; **Azure `hi-IN-SwaraNeural`** (free tier) for HI | Piper runs on your Mac locally. Zero cost. Azure Hindi free tier covers MVP content many times over. |
| STT (runtime) | **`speech_to_text`** Flutter package | Wraps Android SpeechRecognizer on-device. Free. COPPA-safe. |
| Crash reporting | **Sentry** free tier with `beforeSend` PII scrub | Only telemetry allowed by Designed for Families; 5K errors/mo free. |
| Assets in Git | **Git LFS** for `*.mp3`, `*.png` | Keeps history clean. Free on GitHub up to 1 GB. |
| Fonts | Bundled Noto Sans Devanagari (Google Fonts, SIL Open Font License) | Never rely on system Devanagari on Samsung/older Android — inconsistent. |
| CI | **GitHub Actions** on GitHub-hosted runners | 2000 min/mo free. Runs content verification test + `flutter analyze` + `flutter test`. |
| Privacy policy hosting | **GitHub Pages** | Free static hosting with HTTPS. |

## Pluggable Language-Pack Architecture

The content architecture separates **language-agnostic structure** (word
IDs, categories, phoneme targets, images, milestones, game scripts) from
**per-language content** (translations, audio, cultural notes). Adding a
new language means dropping a new pack folder — no Dart code changes.

### Directory layout

```
assets/
  content/
    core/                              # language-agnostic
      words.yaml                       # word IDs, categories, phonemes, image refs, CDI ranks
      questions.yaml                   # WH-question templates by ID
      dialogs.yaml                     # conversational turn-taking scripts by ID
      milestones.yaml                  # ASHA milestones (universal, translated per pack)
    packs/
      en/                              # ship at MVP
        manifest.yaml                  # pack name, locale, script, direction, TTS voice IDs
        words.yaml                     # id → { word, transliteration?, audio }
        questions.yaml                 # id → { question_text, expected_answer_words[], audio }
        dialogs.yaml                   # id → { prompts[], character_responses[], audio[] }
        coaching_tips.yaml             # Hanen tips translated
        cultural_overrides.yaml        # e.g. word_047: "raccoon" → skip
        audio/                         # per-pack MP3s
      hi/                              # ship at MVP
        manifest.yaml   words.yaml   questions.yaml   dialogs.yaml
        coaching_tips.yaml   cultural_overrides.yaml   audio/
      ta/  te/  bn/  mr/  kn/  ml/  gu/  pa/ ...  # future packs
```

### `manifest.yaml` example (Hindi pack)

```yaml
locale: hi
name_en: Hindi
name_native: हिन्दी
script: Devanagari
text_direction: ltr
font_family: NotoSansDevanagari
tts_voice_provider: azure
tts_voice_id: hi-IN-SwaraNeural
tts_voice_style: cheerful
supported_regions: [IN, NP]
maturity: stable
```

### `core/words.yaml` (language-agnostic)

```yaml
- id: word_001
  category: animals
  age_band: "2-3"
  phoneme_targets_ipa: [b, ɑ]
  image: images/words/word_001.png
  cdi_frequency_rank: 12
  asha_milestone_age_months: 18
  universal: true
```

### `packs/hi/words.yaml` (per-language)

```yaml
word_001:
  word: गेंद
  transliteration: gend
  audio: audio/word_001.mp3
  cultural_note: ""
```

### Cultural substitutions (per pack)

```yaml
skip: [word_047, word_112]            # not culturally relevant
substitute:
  word_017:
    substitute_id: word_301
    reason: "roti more familiar to Indian toddlers"
```

Examples of cultural adaptation:

| Core word (English default) | Hindi pack substitute | Reason |
|---|---|---|
| raccoon | बंदर (bandar/monkey) | Common in Indian childhood |
| bagel | रोटी (roti) | Daily food item |
| grandpa / grandma | नाना/नानी/दादा/दादी | Actual kinship terms |
| juice box | चाय (chai) — 4–5 band only | Culturally resonant |
| swimming pool | नदी (nadi/river) | More familiar |

### Adding a new language pack (7-step procedure)

1. Copy `assets/content/packs/en/` as a template into `packs/<iso-code>/`
2. Fill `manifest.yaml` with locale, script, TTS provider/voice
3. Translate `words.yaml`, `questions.yaml`, `dialogs.yaml`,
   `coaching_tips.yaml`; list culturally inappropriate words in
   `cultural_overrides.yaml:skip`
4. Run `scripts/generate_tts.py --pack <iso-code>` — generates all audio
5. Run `flutter test test/content_verification_test.dart --dart-define=PACK=<iso-code>`
6. Recruit 2–3 native speakers to review TTS quality via WhatsApp voice note
7. Ship in next release. Zero Dart code touched.

## Directory Layout

```
lib/
  main.dart                    # ProviderScope + AppRouter init
  app.dart                     # MaterialApp.router + theme

  core/                        # constants, theme, router, error handler (Sentry PII scrub)
  data/
    models/                    # WordEntry, SessionRecord, AgeProfile (Isar entities)
    repositories/              # LanguagePackRegistry, ContentRepository, SessionRepository, ProfileRepository

  features/
    onboarding/                # welcome → language (multi-select) → age picker → mode → mic perm
    game_naming/               # Phase 1
    game_focused_stim/         # Post-launch M+1
    game_imitation/            # Post-launch M+2
    game_respond_wh/           # Phase 1 (What only for MVP)
    game_ask_questions/        # Post-launch M+4
    game_turn_taking/          # Post-launch M+5
    parent_coaching/           # tip screen (gated), session summary, milestone screen
    progress/                  # parent-gated Isar-backed progress screen
    session/                   # SessionController — clock, phases, round sequencer
    home/                      # CoPlayHomeScreen, SoloHomeScreen; shows friends collection
    friends_collection/        # persistent creatures earned via wonder-tier rewards

  shared/
    audio/                     # AudioService (flame_audio wrapper), SpeechDetectionService
    rewards/                   # RewardController + tier1_micro, tier2_moment, tier3_wonder
    widgets/                   # ParentGateDialog, CharacterWidget, MultilingualLabel, CelebrationOverlay
    providers/                 # audioProvider, sttProvider, appModeProvider, activePacksProvider

assets/
  audio/sfx/  audio/music/     # non-per-pack (universal SFX)
  images/words/  images/scenes/  images/ui/
  content/core/  content/packs/en/  content/packs/hi/
  fonts/NotoSansDevanagari-*.ttf
  LICENSES.md                  # source + license per asset

scripts/
  generate_tts.py              # idempotent build-time TTS via Piper (EN) + Azure (HI)
  art_credits.md               # attribution for Kenney.nl / OpenGameArt assets
```

**Critical files (build first — everything else composes on top):**

- `lib/data/repositories/language_pack_registry.dart` — enumerates packs
  from bundle at launch, loads manifests, exposes active packs to games.
  Pluggability keystone.
- `lib/features/session/session_controller.dart` — central orchestrator;
  owns the SessionClock, phase transitions, round sequencer.
- `lib/data/repositories/content_repository.dart` — merges core/words.yaml
  with per-active-pack overlays; every game module reads from it.
- `lib/shared/audio/speech_detection_service.dart` — wraps speech_to_text;
  amplitude-based fallback when STT unavailable.
- `lib/shared/rewards/reward_controller.dart` — decides tier per event;
  tier 3 wonder rotation logic.
- `scripts/generate_tts.py` — hash-cached idempotent script; supports
  `--pack <code>` to scope generation.
- `assets/content/core/words.yaml` — language-agnostic word structure;
  drives every pack.

## Core Game Modules

Six game types cover the full expressive-language progression. Every game
is language-pack-driven and auto-filters by the child's age band.

### 1. Naming game — Phase 1 (MVP)

Image card center-screen (≥280×280 pt tap zone), character says word,
multilingual label below (one line per active pack), 4-sec response window
— any vocalization OR tap succeeds. Reward: tier 1 micro. 6 words per
round. Ages 2–5.

### 2. Focused stimulation — Post-launch M+1

One phoneme target, Flame scene with tappable objects, character animates
through 5 "beats" delivering ~15 exposures of the target word in context.
5-min continuous scene. Ages 2–4.

### 3. Imitation / video model — Post-launch M+2

Character shows exaggerated mouth movement for target phoneme (2 sec),
then BigTalkButton (≥100 pt) with pulsing ring during 3-sec listening
window. Any vocalization → reward tier 2. Two gentle retries max. Ages 3–5.

### 4. Respond-to-questions (WH-hierarchy) — Phase 1 (What) / post-launch (rest)

**The speech-not-just-words layer.** Sequenced following ASHA norms:

- **What?** ("What is this?" → single-noun answer) — age 3+
- **Where?** ("Where is the ball?" → prepositional phrase) — age 3.5+
- **Who?** ("Who is eating?" → agent noun) — age 4+
- **Why?** ("Why is she crying?" → causal explanation) — age 4.5+

Scenes are static illustrations from the language pack. Character asks
question in active pack language(s), STT listens for any vocalization
>800 ms duration, reward fires.

### 5. Ask-questions game — Post-launch M+4

Inverts #4. Scene shows something curious (hidden animal, mystery object).
Character invites: "Ask me what's inside the box." Waits for child
utterance. Any vocalization → character reveals answer expressively.
Builds *initiation* skills, commonly delayed in late talkers even after
vocabulary catches up. Ages 4–5.

### 6. Turn-taking dialog — Post-launch M+5

Scripted 4–6 turn conversations from `packs/*/dialogs.yaml`. Character
says something → child responds → character responds contingently →
repeat. Even without word-matching, the app enforces the *rhythm* of
conversation. Teaches conversational turn structure, a documented weakness
in delayed-speech toddlers. Ages 4–5.

### Game → Age-band matrix

| Game | 2–3 | 3–4 | 4–5 | Phase |
|---|---|---|---|---|
| Naming | ✓ | ✓ | ✓ | 1 (MVP) |
| Focused stim | ✓ | ✓ | — | M+1 |
| Imitation | — | ✓ | ✓ | M+2 |
| Respond-WH (What) | — | ✓ | ✓ | 1 (MVP) |
| Respond-WH (Where/Who/Why) | — | partial | ✓ | M+3 to M+6 |
| Ask-questions | — | — | ✓ | M+4 |
| Turn-taking dialog | — | — | ✓ | M+5 |

## Tiered Reward System — "Wonder"

Rewards escalate through a session. The wonder tier is what creates the
"I want to play again" pull.

### Tier 1 — Micro (per correct utterance/tap, ~1.5 sec)

- Character bounces via `AnimatedSwitcher` pose swap + Tween scale
- 3–5 particles burst from the tapped/spoken word
- Warm "ding + happy chime" audio (single sound)
- No screen takeover — game continues immediately

### Tier 2 — Moment (per round completed, ~3 sec)

- Character does a themed celebration (dance, spin)
- Screen fills with pack-themed particles (butterflies, stars, petals)
- Progress meter fills visibly
- One line of positive naming: "You said ball! Amazing!" (in active packs)

### Tier 3 — Wonder (per session milestone, ~6–8 sec, full-screen)

Rotated so the child doesn't predict them:

- **Character transformation** — Mittu grows a rainbow, sprouts wings,
  turns into a butterfly momentarily, then returns to normal
- **World-scale particles** — full-screen flowers bloom in from every
  edge, fireflies swarm and form the child's earned word in the air,
  aurora borealis effect sweeps the background
- **Creature reveal** — a new friendly creature emerges from a bubble/egg
  and waves at the child. This creature is now visible in the "friends"
  collection on the home screen (persistent visual reward)
- **Pack-themed spectacle** — peacocks fan tails, elephants spray water,
  monsoon-cloud rain of stars — culturally themed per active pack

Wonder-tier moments are:
- Rendered via Flame particle systems layered over the character animation
- Skippable by tap after 2 sec (respects toddler attention)
- Logged to `SessionRecord` so no wonder repeats within a session
- Tied to *clarity* in Phase X (Azure Pronunciation Assessment) — wonder
  only fires on clearly-articulated attempts

## Session & Pacing Rules

| Mode | Age | Max session | Round cap | Wind-down begins |
|---|---|---|---|---|
| Co-play | 2–3 | 8 min | 6 rounds × ~75 sec | 7:00 |
| Solo | 4–5 | 12 min | 8 rounds × ~90 sec | 11:00 |

- **End on success.** SessionController never cuts a round mid-word; when
  the clock enters wind-down it stops scheduling new rounds after the
  current celebration completes.
- **No negative feedback ever.** Timeouts → gentle re-model then advance.
  Wrong taps → neutral redirection, no red X, no sad sound.
- **Parent gate:** 3-digit arithmetic in a plain-white 16pt serif card.
  Gates Settings, Progress, Milestone screens, and the between-round
  coaching tip. Never appears during active gameplay. Solving grants a
  5-min in-memory session token — never persisted.
- **First-launch flow:** parent gate → language select (multi-select) →
  age picker → mode explain → mic permission → tour → home.
- **Child intro:** 20-sec animated greeting from Mittu on first session
  of the day (co-play mode only).

## Parent Coaching Layer

Co-play mode only.

**Between rounds:** `CoachingTipScreen` modal (parent-gated first time
per session, then session-token unlocked). One OWL or PACE tip rotated so
the parent sees every tip within a week. Shown in EN, Hindi Devanagari,
and romanized Hindi simultaneously so grandparents who read Devanagari
can engage.

**After session:** `SessionSummaryScreen` — words practiced today + one
concrete home-practice suggestion generated from the most-practiced
phoneme (simple lookup table, no ML).

**Weekly:** Parent-reported ASHA milestone checklist (`MilestoneScreen`),
explicitly labeled "a conversation guide, not a clinical assessment."

## TTS Pipeline

`scripts/generate_tts.py` is **idempotent by hash**. For each
word × language, hash `(text + voice_id + voice_style)` → check
`.tts_cache/{id}_{lang}.hash` → skip if match, else call TTS and rewrite
MP3 + hash. API keys via `.env` (never committed; `.env.example`
documents required vars). MP3s tracked via Git LFS.

**Providers:**

- **English:** Piper TTS running locally on your Mac (MIT, open-source).
  Voice: `en_US-amy-medium` or `en_GB-cori-high`. Cost: $0.
- **Hindi:** Azure Neural TTS, voice `hi-IN-SwaraNeural`, style
  `cheerful`. Well within 500K-char/mo free tier. Cost: $0 for MVP scope.

**Runtime cost:** $0. Zero cloud calls once shipped — all audio bundled
into the APK.

## Store Readiness — Google Play (Designed for Families)

### Pre-submission checklist

- [ ] Target audience in Play Console set to "Children" (0–5 sub-group)
- [ ] Data Safety form: ALL fields = "No data collected" (verify against reality)
- [ ] Content rating questionnaire: complete IARC/ESRB → "Everyone" rating
- [ ] Only sensitive permission declared: `RECORD_AUDIO`
- [ ] Zero ad SDKs (`flutter pub deps --style=tree | grep -iE "admob|firebase|analytics"` returns empty)
- [ ] Zero analytics SDKs (only Sentry allowed; verify `beforeSend` scrubs PII)
- [ ] No Google Advertising ID (GAID) access
- [ ] Privacy policy URL entered in Play Console (GitHub Pages URL)
- [ ] Age rating: ESRB Everyone
- [ ] Family-friendly content policy acknowledged
- [ ] AndroidManifest.xml declares only necessary permissions

### Privacy policy must state

- No personal information collected from children
- Microphone used only for on-device sound detection (no recording, no transmission)
- No third-party servers except crash reports (Sentry) with PII scrub
- No account required
- No behavioral advertising
- Parent contact info
- Last-updated date

### Store listing rules

- Do NOT use "For Kids" in the listing — reserved for a specific category
- Use "for toddlers ages 2–5" or "designed for young children"
- Do NOT promise clinical outcomes — use "supports" not "treats" or "cures"
- Short description (80 chars): "Bilingual speech play for toddlers — English & Hindi"
- Keywords: "speech therapy app", "toddler vocabulary", "bilingual learning", "early language"

### Assets to prepare

- Feature graphic: 1024×500 px
- Phone screenshots: min 2, up to 8. Recommended frames:
  1. Character greeting animation
  2. Naming game mid-play (bilingual label visible)
  3. Wonder-tier reward moment
  4. Parent coaching tip (with parent gate visible)
  5. Session summary screen
- Optional promo video: YouTube URL, 30 sec, showing the naming game loop
  in real-time (not sped up), recorded on physical Android device.

## Phase Breakdown — Ship MVP in 1 Month

Goal: **shippable MVP on Google Play in 4 weeks (~30 calendar days).**
Assumes 40–50 hours/week (either full-time focus or heavy side-project
push). If 15–20 hrs/week are available, this slips to ~10–12 weeks — see
"Timeline sensitivity" below.

### MVP scope (Days 1–30)

| Week | Deliverable | Hours |
|---|---|---|
| **W1 — Foundation** (Days 1–7) | Flutter/Dart ramp via Codelabs in parallel with real work. LanguagePackRegistry + ContentRepository (pack pluggability from day one). Isar profile + session models. Router + first-launch flow. `flame_audio` audio primitives + `speech_to_text` primitives verified on physical Android. 20-word English pack authored. | ~40 |
| **W2 — Naming game + Hindi pack** (Days 8–14) | Naming game working end-to-end. One character with 3 poses (idle/excited/reward) via AnimatedSwitcher + Tween. Tier-1 micro rewards. Session controller (8-min timer, end-on-success). **Hindi pack added** (20 words, Devanagari font bundled, Azure TTS) — validates pack architecture. | ~45 |
| **W3 — Respond-to-What + wonder + parent gate** (Days 15–21) | Respond-to-"What?" question game. Tier-2 moment + 1 Tier-3 wonder reward (creature reveal via Lottie). Friends-collection screen. Parent gate + 3 rotating coaching tips + session summary. Age picker + mode routing. | ~45 |
| **W4 — Compliance + beta + submit** (Days 22–30) | `LICENSES.md`, content verification Dart test in CI, privacy policy hosted on GitHub Pages, Play Console listing filled, screenshots + 30-sec promo video recorded. Play Internal Testing with 2 families (recruit from own network — 1 Hindi-first). Fix showstoppers. **Submit to Google Play by Day 30.** | ~40 |

**MVP totals:** ~170 hours over 30 days.

### Timeline sensitivity

| Weekly hours available | Realistic MVP submission date |
|---|---|
| 40–50 (this plan) | Day 30 |
| 25–30 (nights + weekends, heavy) | Day 50–60 |
| 15–20 (nights + weekends, sustainable) | Day 75–90 |

Google Play review typically takes **3–7 days** for Designed for Families
(often involves human review). Budget 1 additional week for possible
resubmission. **Live date = submission date + ~1–2 weeks.**

### What the MVP intentionally cuts

Each item is a post-launch monthly release, not lost — just phased:

- Focused stimulation game (M+1)
- Imitation / mouth-model game (M+2)
- WH-questions beyond "What?" — Where, Who, Why (M+3 to M+6)
- Ask-questions game (M+4)
- Turn-taking dialog (M+5)
- Content past 20 words per pack (grow monthly)
- Additional wonder-tier variants beyond 1 (add 1/month)
- Tamil and further language packs (one every 4–6 weeks post-launch)
- iOS build and App Store submission (once Play validates the concept)
- Minimal pairs, milestone screen

**Why this cut works:** every game reads from the same ContentRepository
and triggers the same RewardController. The MVP proves the whole loop
with the two most important games (naming + respond-to-What). Everything
else is composition on top of primitives already built.

## Post-Launch Monthly Releases

Two parallel tracks after Day 30: **games** and **languages**.

| Month | Games track | Languages track |
|---|---|---|
| M+1 | Focused stimulation game | EN + HI content 20 → 60 words each |
| M+2 | Imitation game + wonder variant #2 | Tamil pack (`ta`) |
| M+3 | Respond-WH: Where + Who | Telugu pack (`te`) |
| M+4 | Ask-questions game + wonder variant #3 | Bengali pack (`bn`) |
| M+5 | Turn-taking dialog | Marathi pack (`mr`) |
| M+6 | Respond-WH: Why + milestone screen | Kannada + Malayalam |
| M+7+ | Minimal pairs, further wonder variants, polish | Gujarati, Punjabi, then global (Spanish, Mandarin, Arabic) |

### Optional Phase X (any time after launch)

- **iOS build + App Store submission** — install Xcode (~15 GB), no code
  changes needed since Flutter is cross-platform. Cost: $99/yr Apple.
- **Pronunciation feedback** — Azure Pronunciation Assessment integration.
  Wonder-tier gates on articulation clarity. Requires re-COPPA review +
  parental consent screen.
- **Therapist portal** — Flutter Web companion for SLPs. Consent-gated;
  separate compliance posture. B2B revenue channel.

## Risks & Mitigations

- **R0.1 Free-first animation risk** (W1–2): The 3-pose PNG swap approach
  works but requires 3 well-drawn character poses. Source from Kenney.nl
  "Cartoon Animals" or "Character Pack" — pick one style upfront and
  never mix. If nothing matches the 3 emotion states you need, commission
  on Fiverr for $10–15, or upgrade to Rive Cadet for one month ($9,
  cancel after).
- **R1.1 Android audio latency** (W2): If `flame_audio` > 100 ms on
  mid-range Android, swap to `soundpool` for short SFX. Measure with
  Stopwatch before proceeding.
- **R1.2 STT false positives** (W2): Fall back to amplitude detection via
  the `record` package when SpeechRecognizer is unavailable; design
  fallback path in `SpeechDetectionService` from day one.
- **R2.1 Devanagari font rendering** (W2): Bundle Noto Sans Devanagari in
  assets; never rely on system font on Android; test complex conjuncts
  (क्ष, त्र) on Samsung or older Android.
- **R2.2 Wonder-tier scope creep** (W3): Resist the urge to build more
  than 1 wonder variant for MVP. Users won't notice missing #2–#6 in the
  first release; they will notice #1 being unpolished.
- **R4.1 Play Designed for Families rejection** (W4): Common causes —
  broken parent gate, Data Safety form mismatch with app behavior, crash
  on reviewer's test device. Test on Android 10 (oldest supported)
  before submitting. Budget 1 week of buffer for a possible resubmission.
- **R4.2 TTS quality iteration** (W2): Get 2 native Hindi speakers to
  review a 10-word Azure TTS sample before generating all 20. Cheaper to
  regenerate 10 with a different voice than 20.

## Verification

### Real-device testing (from Week 2 onwards)

- **Audio latency < 100 ms** measured via `Stopwatch` around
  `AudioCache.play()` vs `onPlayerStateChanged` on a mid-range Android
  device (Moto G Power class = worst-case Android target)
- **60 fps confirmed** via Flutter DevTools Performance tab during a
  full naming game round; no frame budget violations
- **Tap targets ≥ 80 pt** (talk button ≥ 100 pt) — debug overlay draws
  red borders around every `GestureDetector` with logical size labels
- **Real toddler test:** give device to a 2–3 year old for 10 minutes
  with no instruction; observe which taps miss

### Compliance verification

```
# No analytics or ad SDKs
flutter pub deps --style=tree | grep -iE "firebase|analytics|admob|facebook|amplitude|mixpanel|segment|adjust|appsflyer"
# → must be empty (Sentry may appear)

# beforeSend scrub is present
grep -r "beforeSend" lib/ --include="*.dart"
# → must have exactly one hit in error_handler.dart
```

**Parent gate:** on fresh install, 100 random center-screen taps must
not reach Settings. Adult flow (padlock → gate → Settings) must work.

### Content verification (CI-enforced)

`test/content_verification_test.dart` runs on every push with `git lfs pull`:

```
for each word in ContentRepository.loadAll():
  assert File(word.en.audioPath).existsSync()
  assert File(word.hi.audioPath).existsSync()
  assert File(word.imagePath).existsSync()
  assert word.id is unique across all words
  assert word.hi.word contains ≥ 1 Devanagari codepoint (U+0900–U+097F)
```

### Language quality verification

- Share generated Azure TTS samples (10 words, cheerful + neutral) with
  2–3 native Hindi speakers via WhatsApp voice note. Ask:
  1. Is the word clearly pronounced?
  2. Is the intonation natural for speaking to a small child?
  3. Is the word one a child would actually hear at home (vs. literary Hindi)?
  Iterate `cultural_note` before final TTS generation.
- SLP sanity check: send EN word list (PDF export of `vocab.yaml`) to
  1–2 SLP students or practicing SLPs. Ask them to flag late-emergence
  words, missing common words, and whether phoneme groupings make
  therapeutic sense.

## Budget — Plan B Free-First

### One-time to reach Google Play submission

| Item | Cost | Notes |
|---|---|---|
| Google Play Console registration | **$25** | One-time forever. Only immovable cost in Plan B. |
| Domain name | **$0** | Skipped — use `https://<user>.github.io/bolo-privacy` for privacy policy |
| Privacy policy hosting | **$0** | GitHub Pages free tier |
| Character animation tool | **$0** | Flutter native `AnimationController` + `flutter_animate` |
| Character art | **$0** | Kenney.nl + OpenGameArt.org (CC0 public domain) |
| English TTS | **$0** | Piper TTS (MIT, runs locally) |
| Hindi TTS | **$0** | Azure `hi-IN-SwaraNeural` free tier |
| Sound effects | **$0** | Freesound.org + Kenney.nl audio packs (CC0) |
| Native Hindi review | **$0** | Ask a Hindi-speaking friend via WhatsApp voice note |
| Devanagari font | **$0** | Google Fonts — Noto Sans Devanagari (SIL OFL) |
| Crash reporting | **$0** | Sentry free tier (5K errors/mo) |
| Git hosting + CI | **$0** | GitHub free tier (2000 CI min/mo, 1 GB LFS) |
| **Total to launch** | **$25** | |

### Ongoing recurring

**$0/month.** No subscriptions. No cloud calls at runtime. No per-user
serving cost. Whether 10 or 10 million users install it, monthly cost
stays $0.

### Optional upgrades (only if MVP proves out)

| Item | Cost | When |
|---|---|---|
| Apple Developer Program | $99/yr | When adding iOS |
| Domain name (`.app` TLD) | $14/yr | When brand identity matters |
| Rive Cadet plan | $9/mo when active | If PNG-swap animations feel stale |
| Fiverr character commission | $10–15 one-time | If Kenney assets don't match vision |

### What is not in the budget (and why)

- **Backend servers** — none needed. See Infrastructure.
- **Databases** — Isar is on-device only.
- **STT service fees** — on-device Android SpeechRecognizer is free.
- **Runtime TTS fees** — all audio pre-generated at build time.
- **Analytics** — prohibited by Designed for Families.
- **Ad networks** — no ads.
- **Payment processing** — no in-app purchases at MVP.
- **CDN** — assets bundled into the APK.
- **Legal / privacy policy drafting** — use FTC COPPA model policy
  language as template. Free.

## Infrastructure Requirements

### Developer-side (your Mac)

| Component | Requirement | Space |
|---|---|---|
| Local machine | macOS with ≥16 GB RAM, ≥100 GB free disk | (you have 244 GB free) |
| Flutter SDK (stable) | Install via `brew install --cask flutter` | ~2 GB |
| Android Studio | Latest stable | ~15–20 GB |
| Physical Android phone | Any Android 10+ device, mid-range preferred (Moto G Power class) | — |
| Git + Git LFS | `brew install git-lfs` | negligible |
| Xcode | **Not installed at MVP** (Plan B is Android-only) | ~15 GB deferred |
| **Plan B total disk** | | **~20 GB (of your 244 GB free)** |

- API keys (dev-only): Azure TTS key + Sentry DSN, stored in `.env` file
  (never committed; `.env.example` documents required vars)
- Content authoring runs on your Mac locally — Piper TTS, image sourcing
  from Kenney.nl

### Runtime (what the shipped app uses)

| Component | Requirement | Notes |
|---|---|---|
| Backend server | **None** | No API. No accounts. No sync. |
| Database | **None** (Isar is on-device) | Data never leaves the phone. |
| Object storage / CDN | **None** | All audio/images bundled in the APK. |
| Auth | **None** | Anonymous by design. |
| Push notifications | **None** for MVP | Kids apps should not be intrusive. Consider FCM only if there's a clear parent-facing use case in a later phase. |
| Crash reporting | **Sentry free tier** | 5K errors/mo. Configured with `beforeSend` scrubbing `device.id` and any transcribed audio. |
| Privacy policy hosting | **GitHub Pages** | One static HTML page. $0. |

### Store-side

| Component | Requirement | Notes |
|---|---|---|
| Google Play Console | Included with $25 one-time fee | Manages Android AAB uploads, internal testing, Play Store listing. |
| Play Internal Testing | Free | Up to 100 testers; MVP beta needs 2–3. |

### External services (build-time only — never called by shipped app)

| Service | Purpose | Runtime dependency? |
|---|---|---|
| Piper TTS (local) | English TTS generation | No — output committed as MP3 assets |
| Azure Cognitive Services | Hindi TTS generation | No — output committed as MP3 assets |
| Kenney.nl / OpenGameArt.org | Character + word images | No — output committed as PNG assets |

### Scale considerations

Because compute is on-device, **the app costs $0/user to serve.**
Whether 10 or 10 million users install it, developer infrastructure
costs don't change.

The only scaling concern is **binary size.** Each language pack adds
~5 MB (audio) + ~2 MB (images). At 10 packs, that's 70 MB — approaching
Google Play's 150 MB base APK cellular cap. Mitigation for later: Play
Feature Delivery — a native mechanism to download language packs only
when the user selects them. Deferred to Month 6+ when >5 packs ship.

## Appendix A: First-Day Concrete Tasks

Follow this sequence on Day 1 to prove the toolchain works before writing
any product code:

1. `brew install --cask flutter` — installs Flutter SDK
2. `flutter doctor` — fix every checkmark it flags
3. `brew install --cask android-studio` — installs Android Studio
4. Open Android Studio → Preferences → Plugins → install "Flutter" and
   "Dart" plugins
5. Android Studio → Preferences → Android SDK → install:
   - Android SDK Platform (latest stable)
   - Android SDK Build-Tools
   - Android Emulator (or plan to test on physical device)
6. Connect physical Android phone via USB → enable Developer Options →
   USB Debugging
7. `flutter create --org com.YOURNAME --platforms android bolo_app`
8. `cd bolo_app && flutter run` on the connected device — the counter
   app should launch. If yes, toolchain is verified.
9. Add packages to `pubspec.yaml`:
   ```
   flame  flame_audio  speech_to_text  flutter_riverpod
   riverpod_annotation  riverpod_generator  build_runner
   isar  isar_flutter_libs  go_router  sentry_flutter  flutter_animate
   lottie  yaml
   ```
10. Add one MP3 to `assets/audio/sfx/tap.mp3` (grab any tap SFX from
    Freesound.org CC0). Declare in `pubspec.yaml` under `flutter: assets:`.
11. In `main.dart`: preload with `FlameAudio.audioCache.load('sfx/tap.mp3')`.
    Play it on button tap. **Measure latency with stopwatch on physical
    device** — do not accept simulator numbers.
12. Add `speech_to_text` mic permission request. Start listening. Print
    "HEARD SOMETHING" on any result. Test on physical device.
13. Create `assets/content/core/words.yaml` with 5 test entries. Write
    a unit test that parses it and asserts all 5 entries load.
14. Initialize `git`, add `.gitignore` (Flutter default + `.env`), run
    `git lfs install`, `git lfs track "*.mp3" "*.png"`.
15. Create a GitHub repo, push initial commit.

**Completing that sequence proves:** Flutter toolchain works, audio has
acceptable latency, STT fires, the data layer parses, and CI/version
control is set up. Everything else in Week 1 is composition of these
verified primitives.

## Appendix B: Sources & Research

### Speech-therapy evidence base

- ASHA Practice Portal — Late Language Emergence: [asha.org/practice-portal/clinical-topics/late-language-emergence/](https://www.asha.org/practice-portal/clinical-topics/late-language-emergence/)
- ASHA Practice Portal — Spoken Language Disorders: [asha.org/practice-portal/clinical-topics/spoken-language-disorders/](https://www.asha.org/practice-portal/clinical-topics/spoken-language-disorders/)
- ASHA Bilingual Service Delivery guidelines
- Hanen Centre — It Takes Two to Talk: [hanen.org/Programs/For-Parents/It-Takes-Two-to-Talk.aspx](https://www.hanen.org/Programs/For-Parents/It-Takes-Two-to-Talk.aspx)
- Hanen Centre — More Than Words (for ASD-spectrum): [hanen.org/Programs/For-Parents/More-Than-Words.aspx](https://www.hanen.org/Programs/For-Parents/More-Than-Words.aspx)
- MacArthur-Bates CDI normative data: [mb-cdi.sdsu.edu](https://mb-cdi.sdsu.edu)

### Competitor apps surveyed

- Speech Blubs 2 — English/Spanish/German, ~$50–80/yr, video-based imitation
- Otsimo Speech Therapy — English/Turkish, ASD-focused
- Articulation Station — English only, SLP tool
- Lingokids — English learning (not therapy)
- Hallooo — English only, parent-in-the-loop design

### Toddler UX principles

- Joan Ganz Cooney Center — Learning at Home: [joanganzcooneycenter.org](https://joanganzcooneycenter.org/publication/learning-at-home/)
- Joan Ganz Cooney Center — Tap, Click, Read: [tapclickread.org](https://tapclickread.org)
- AAP Media and Young Minds (2016 policy statement): [pediatrics.aappublications.org](https://pediatrics.aappublications.org/content/138/5/e20162591)

### Technology references

- Flutter Impeller renderer: [docs.flutter.dev/perf/impeller](https://docs.flutter.dev/perf/impeller)
- Flame engine: [docs.flame-engine.org](https://docs.flame-engine.org)
- `speech_to_text` package: [pub.dev/packages/speech_to_text](https://pub.dev/packages/speech_to_text)
- `flame_audio` package: [pub.dev/packages/flame_audio](https://pub.dev/packages/flame_audio)
- Piper TTS: [github.com/rhasspy/piper](https://github.com/rhasspy/piper)
- Azure Neural TTS languages: [learn.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support)

### Compliance references

- Google Play Families Program: [support.google.com/googleplay/android-developer/answer/9893335](https://support.google.com/googleplay/android-developer/answer/9893335)
- COPPA (FTC): [ftc.gov/business-guidance/privacy-security/childrens-privacy](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy)

### Free asset sources

- Kenney.nl (CC0): [kenney.nl](https://kenney.nl)
- OpenGameArt.org: [opengameart.org](https://opengameart.org)
- Freesound.org: [freesound.org](https://freesound.org)
- LottieFiles free library: [lottiefiles.com/featured](https://lottiefiles.com/featured)
- Google Fonts (Noto Sans Devanagari): [fonts.google.com/noto/specimen/Noto+Sans+Devanagari](https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari)

---

*End of plan document.*

*Save this file for reference during implementation. The living version
of this plan is under `/Users/arunkumar/.claude/plans/`. All choices in
this document reflect the free-first, Android-only Plan B locked in on
2026-07-23.*
