# Bolo build-time scripts

Scripts for content verification and TTS audio generation.
All scripts are run from the **repo root**, not from this directory.

## Setup (one-time)

```bash
pip3 install pyyaml --user --break-system-packages
```

## Scripts

### `verify_content.py` — Content integrity check

Validates that `assets/content/` is internally consistent before a build:
- Every core word has a translation in every active pack (or a documented skip)
- No duplicate word IDs
- Hindi words contain Devanagari codepoints + transliteration
- All required YAML fields present
- Audio files present (warning if not yet generated — expected pre-TTS)

**Run:**

```bash
python3 scripts/verify_content.py
```

Exit code `0` = pass, `1` = errors found.

Suitable for CI — add to GitHub Actions:

```yaml
- name: Verify content
  run: python3 scripts/verify_content.py
```

### `generate_tts.py` — Build-time audio generation *(coming soon)*

Reads `assets/content/packs/<locale>/words.yaml` and pre-generates MP3
audio files using:
- **English:** Piper TTS (open-source, MIT, runs locally)
- **Hindi:** Azure Neural TTS (`hi-IN-SwaraNeural`, `cheerful` style)

Idempotent — skips files that haven't changed since last run.

Requires API keys in `.env` (copy from `.env.example`).

## `.venv` (optional)

If you prefer an isolated environment:

```bash
cd scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The `.venv/` directory is gitignored.
