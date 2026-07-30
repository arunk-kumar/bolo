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

### `generate_tts.py` — Build-time audio generation

Reads `assets/content/packs/<locale>/words.yaml` and pre-generates MP3
audio files. Idempotent — skips files whose content hash hasn't changed.

**Providers:**
- **English (`en`):** Piper TTS (open-source, MIT, runs locally — free forever)
- **Hindi (`hi`):** Azure Neural TTS (`hi-IN-SwaraNeural`, `cheerful` style — free tier)

**First-time setup:**
```bash
# English: install Piper (no API key needed)
pip3 install piper-tts --user --break-system-packages

# Hindi: set Azure key in .env
cp .env.example .env
# edit .env and fill in AZURE_TTS_KEY and AZURE_TTS_REGION
```

**Run:**
```bash
# Preview without making any API calls
python3 scripts/generate_tts.py --pack en --dry-run
python3 scripts/generate_tts.py --pack hi --dry-run

# Generate for real (runs idempotently — skips unchanged words)
python3 scripts/generate_tts.py --pack en
python3 scripts/generate_tts.py --pack hi

# Regenerate all (ignore cache)
python3 scripts/generate_tts.py --pack all --force
```

Hash cache lives in `.tts_cache/` (committed — keeps CI skipping
already-generated audio). MP3 files tracked via Git LFS.

## `.venv` (optional)

If you prefer an isolated environment:

```bash
cd scripts
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

The `.venv/` directory is gitignored.
