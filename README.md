# Bolo — Speech-play for toddlers with speech delay

A multilingual, culturally-adapted speech-therapy app for toddlers ages 2–5.
Built with Flutter. Ships with English + Hindi packs at MVP; designed so any
language can be added as a self-contained pack (no code change).

> **Bolo** (बोलो / boh-loh) is Hindi for *"speak."*

## Why this exists

Every existing toddler speech-therapy app is English-first. Zero apps target
Hindi, Tamil, or any Indian language for actual therapy use. Bolo fills that
gap — with culturally-familiar words (chai, dal, nana/nani), evidence-based
techniques (ASHA + Hanen), and a design that treats the parent as a partner,
not a passive dashboard viewer.

## Status

🚧 **Pre-alpha.** In active development. Not yet published on any store.

Full plan and rationale: [BOLO-PLAN.md](./BOLO-PLAN.md)

## Repository layout

```
bolo/
├── BOLO-PLAN.md           # Full product & implementation plan
├── README.md              # This file
├── LICENSE                # Apache 2.0
├── docs/                  # Design docs, ADRs, meeting notes
├── scripts/               # Build-time tooling (TTS generation, etc.)
├── assets/
│   └── content/
│       ├── core/          # Language-agnostic word structure (schema)
│       └── packs/         # One folder per language pack
│           ├── en/        # English pack
│           └── hi/        # Hindi pack
└── app/                   # Flutter application (Dart source, pubspec.yaml, etc.)
```

## Prerequisites

To build and run Bolo locally, you'll need:

- **macOS or Linux** (Windows should work but is untested)
- **Flutter SDK** (stable channel) — [install guide](https://docs.flutter.dev/get-started/install)
- **Android Studio** with Android SDK installed via SDK Manager
- **Git** with **Git LFS** for binary assets (`brew install git-lfs`)
- **Python 3.10+** for the build-time TTS script
- A physical Android device (Android 10+) — audio latency and STT cannot be
  reliably tested on the emulator

## Getting started

*(Instructions will be filled in as the project matures. See BOLO-PLAN.md for
current build phases.)*

```bash
git clone <this-repo>
cd bolo
git lfs pull                     # fetch large binary assets
cd app
flutter pub get
flutter run                      # on a connected Android device
```

## Development principles

1. **COPPA-safe by construction.** Zero PII collection, zero third-party
   analytics, zero ads. On-device speech detection only. Pre-generated TTS.
2. **Zero backend at MVP.** No servers, no accounts, no cloud sync. Progress
   lives in on-device storage.
3. **Language as a data-only extension.** Add a new language by dropping a
   pack folder — no Dart code changes.
4. **Wonder rewards, not confetti bursts.** Rewards must feel magical, not
   perfunctory.
5. **Full speech development, not just labeling.** Games cover naming,
   focused stimulation, imitation, responding to questions, asking
   questions, and turn-taking dialog.

## Contributing

*(Contribution guidelines TBD once the project reaches a stable enough state
for external contributions.)*

## License

Apache License 2.0 — see [LICENSE](./LICENSE) for the full text.

## Acknowledgements

- **ASHA** (American Speech-Language-Hearing Association) — developmental
  norms and clinical guidance
- **The Hanen Centre** — parent-mediated intervention frameworks (OWL, PACE)
- **MacArthur-Bates CDI** — early-vocabulary normative data
