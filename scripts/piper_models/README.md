# Piper voice models

Piper voice models are **build-time tools**, not shipped app assets. They
are used by `scripts/generate_tts.py` on your machine to synthesize the
`.wav` files that go into the app. The shipped APK/AAB never contains
them.

This directory is `.gitignore`d because the models are large (~60 MB each)
and versioned by upstream — checking them into git bloats history for no
gain.

## How to fetch a model

```
# From the repo root
mkdir -p scripts/piper_models
cd scripts/piper_models

# English (US) — medium quality, child-friendly
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json
```

All Piper voices live at <https://huggingface.co/rhasspy/piper-voices> —
browse for other languages (Hindi is under `hi/`, Tamil `ta/`, etc.).

## Then generate audio

```
cd ~/my-workshop/bolo
python3 scripts/generate_tts.py --pack en
```

The script is idempotent — it skips words whose content hash matches the
cache in `.tts_cache/`. Re-run any time the vocabulary changes; only
edited/new words regenerate.
