#!/usr/bin/env python3
"""
Bolo TTS audio generator
────────────────────────
Pre-generates MP3 audio files for all words in a language pack.
Idempotent: skips files whose content hash hasn't changed since last run.

Usage:
    python3 scripts/generate_tts.py --pack en
    python3 scripts/generate_tts.py --pack hi
    python3 scripts/generate_tts.py --pack all
    python3 scripts/generate_tts.py --pack en --dry-run   # preview only, no API calls
    python3 scripts/generate_tts.py --pack en --force     # regenerate all, ignore cache

Requirements:
    pip3 install pyyaml python-dotenv requests --user --break-system-packages

API keys (copy .env.example → .env and fill in):
    AZURE_TTS_KEY       — for Hindi (hi) pack
    AZURE_TTS_REGION    — Azure region, e.g. eastus
    ELEVENLABS_API_KEY  — optional; only if using ElevenLabs instead of Piper for EN

Piper TTS (for English, free):
    Install: pip3 install piper-tts --user --break-system-packages
    Voice:   downloads automatically on first use (~50 MB)
    No API key needed.
"""

import argparse
import hashlib
import os
import sys
import time
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml not installed. Run: pip3 install pyyaml --user --break-system-packages")
    sys.exit(1)

try:
    from dotenv import load_dotenv  # type: ignore[import-untyped]
    load_dotenv()
except ImportError:
    pass  # .env loading is optional; keys can also be set as shell env vars

# ── Paths ─────────────────────────────────────────────────────────
REPO_ROOT  = Path(__file__).parent.parent
CORE_WORDS = REPO_ROOT / "assets" / "content" / "core" / "words.yaml"
PACKS_DIR  = REPO_ROOT / "assets" / "content" / "packs"
CACHE_DIR  = REPO_ROOT / ".tts_cache"   # committed; stores content hashes only

# ── Colour helpers ────────────────────────────────────────────────
def green(s):  return f"\033[92m{s}\033[0m"
def yellow(s): return f"\033[93m{s}\033[0m"
def red(s):    return f"\033[91m{s}\033[0m"
def bold(s):   return f"\033[1m{s}\033[0m"


# ─────────────────────────────────────────────────────────────────
# Idempotency: hash-based caching
# ─────────────────────────────────────────────────────────────────

def content_hash(text: str, voice_id: str, voice_style: str) -> str:
    """Deterministic SHA-256 of the inputs that affect the audio output."""
    payload = f"{text}|{voice_id}|{voice_style}"
    return hashlib.sha256(payload.encode()).hexdigest()[:16]


def load_hash(cache_key: str) -> str | None:
    """Return the stored hash for a cache key, or None if not cached."""
    path = CACHE_DIR / f"{cache_key}.hash"
    return path.read_text().strip() if path.exists() else None


def save_hash(cache_key: str, hash_value: str):
    """Persist the hash so future runs can skip unchanged entries."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    (CACHE_DIR / f"{cache_key}.hash").write_text(hash_value)


def is_cached(cache_key: str, current_hash: str) -> bool:
    stored = load_hash(cache_key)
    return stored == current_hash


# ─────────────────────────────────────────────────────────────────
# Provider: Azure Neural TTS (Hindi — hi-IN-SwaraNeural)
# ─────────────────────────────────────────────────────────────────

def generate_azure(text: str, voice_id: str, voice_style: str,
                   out_path: Path, dry_run: bool) -> bool:
    """
    Call Azure Cognitive Services TTS REST API.
    Returns True on success.

    Free tier: 500K characters/month neural TTS.
    Sign up:   https://portal.azure.com → create a "Speech" resource
    """
    if dry_run:
        print(yellow(f"  [dry-run] would call Azure TTS: voice={voice_id} style={voice_style} text='{text}'"))
        return True

    api_key = os.environ.get("AZURE_TTS_KEY", "")
    region  = os.environ.get("AZURE_TTS_REGION", "eastus")

    if not api_key:
        print(red("  AZURE_TTS_KEY not set in .env — skipping"))
        return False

    import requests  # type: ignore[import-untyped]  # only needed for real calls
    endpoint = f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
    headers = {
        "Ocp-Apim-Subscription-Key": api_key,
        "Content-Type": "application/ssml+xml",
        "X-Microsoft-OutputFormat": "audio-16khz-128kbitrate-mono-mp3",
        "User-Agent": "Bolo-TTS-Generator/1.0",
    }

    # SSML with optional style (cheerful, empathetic, etc.)
    style_tag = (
        f'<mstts:express-as style="{voice_style}">'
        if voice_style and voice_style != "default"
        else ""
    )
    style_close = "</mstts:express-as>" if style_tag else ""

    ssml = (
        '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="hi-IN">'
        f'<voice name="{voice_id}">'
        f"{style_tag}{text}{style_close}"
        "</voice></speak>"
    )

    try:
        resp = requests.post(endpoint, headers=headers, data=ssml.encode("utf-8"), timeout=15)
        resp.raise_for_status()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(resp.content)
        return True
    except Exception as e:
        print(red(f"  Azure TTS error: {e}"))
        return False


# ─────────────────────────────────────────────────────────────────
# Provider: Piper TTS (English — local, free, MIT)
# ─────────────────────────────────────────────────────────────────

def generate_piper(text: str, voice_id: str, out_path: Path, dry_run: bool) -> bool:
    """
    Generate audio using Piper TTS Python API.
    Install: pip3 install piper-tts --user --break-system-packages
    Voice model downloads automatically on first use (~50 MB).
    No API key needed. Free forever.
    """
    if dry_run:
        print(yellow(f"  [dry-run] would call Piper TTS: voice={voice_id} text='{text}'"))
        return True

    try:
        from piper import PiperVoice  # type: ignore[import-untyped]
        import wave as wave_module
    except ImportError:
        print(red("  Piper TTS not installed. Run:"))
        print(red("  pip3 install piper-tts --user --break-system-packages"))
        return False

    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        # Resolve model path — check local piper_models/ dir first
        model_dir = Path(__file__).parent / 'piper_models'
        model_file = model_dir / f'{voice_id}.onnx'
        if not model_file.exists():
            # Fall back to bare voice_id (may work if already on PATH)
            model_path = voice_id
        else:
            model_path = str(model_file)
        voice = PiperVoice.load(model_path, use_cuda=False)
        wav_path = out_path.with_suffix('.wav')
        with wave_module.open(str(wav_path), 'wb') as wav_file:
            # set_wav_format=True lets Piper configure channels/rate/width
            voice.synthesize_wav(text, wav_file, set_wav_format=True)
        # Rename to final .wav path (pack yaml says .mp3 but we store .wav)
        final_path = out_path.with_suffix('.wav')
        if wav_path != final_path:
            wav_path.rename(final_path)
        return True
    except Exception as e:
        print(red(f"  Piper error: {e}"))
        return False
    except Exception as e:
        print(red(f"  Piper subprocess error: {e}"))
        return False


# ─────────────────────────────────────────────────────────────────
# Provider: ElevenLabs (optional English alternative)
# ─────────────────────────────────────────────────────────────────

def generate_elevenlabs(text: str, voice_id: str, out_path: Path,
                         dry_run: bool) -> bool:
    """
    Call ElevenLabs API for English TTS.
    Only used if ELEVENLABS_API_KEY is set and --provider=elevenlabs is passed.
    Free tier excludes commercial use — need Starter ($6/mo) or above.
    """
    api_key = os.environ.get("ELEVENLABS_API_KEY", "")
    if not api_key:
        print(red("  ELEVENLABS_API_KEY not set in .env — skipping"))
        return False

    if dry_run:
        print(yellow(f"  [dry-run] would call ElevenLabs: voice={voice_id} text='{text}'"))
        return True

    import requests  # type: ignore[import-untyped]  # only needed for real calls

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "Accept": "audio/mpeg",
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    }
    body = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75},
    }
    try:
        resp = requests.post(url, headers=headers, json=body, timeout=20)
        resp.raise_for_status()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(resp.content)
        return True
    except Exception as e:
        print(red(f"  ElevenLabs error: {e}"))
        return False


# ─────────────────────────────────────────────────────────────────
# Route to the correct provider based on pack manifest
# ─────────────────────────────────────────────────────────────────

def generate_audio(text: str, manifest: dict, out_path: Path,
                   dry_run: bool) -> bool:
    provider   = manifest.get("tts_voice_provider", "piper")
    voice_id   = manifest.get("tts_voice_id", "")
    voice_style = manifest.get("tts_voice_style", "default")

    if provider == "azure":
        return generate_azure(text, voice_id, voice_style, out_path, dry_run)
    elif provider == "elevenlabs":
        return generate_elevenlabs(text, voice_id, out_path, dry_run)
    else:
        # default: piper (free, local)
        return generate_piper(text, voice_id, out_path, dry_run)


# ─────────────────────────────────────────────────────────────────
# Process one pack
# ─────────────────────────────────────────────────────────────────

def process_pack(pack_dir: Path, dry_run: bool, force: bool) -> dict:
    locale = pack_dir.name
    print(bold(f"\n── Pack: {locale} ──────────────────────────────────────────"))

    manifest_path = pack_dir / "manifest.yaml"
    words_path    = pack_dir / "words.yaml"

    if not manifest_path.exists() or not words_path.exists():
        print(red(f"  Missing manifest.yaml or words.yaml — skipping"))
        return {"skipped": 0, "generated": 0, "cached": 0, "failed": 0}

    with open(manifest_path) as f:
        manifest = yaml.safe_load(f)
    with open(words_path) as f:
        pack_words = yaml.safe_load(f) or {}

    voice_id    = manifest.get("tts_voice_id", "")
    voice_style = manifest.get("tts_voice_style", "default")

    stats = {"skipped": 0, "generated": 0, "cached": 0, "failed": 0}

    for word_id, entry in pack_words.items():
        if not isinstance(entry, dict):
            continue

        text = str(entry.get("word", "")).strip()
        if not text:
            print(yellow(f"  {word_id}: empty word text — skipping"))
            stats["skipped"] += 1
            continue

        # Resolve output path relative to pack directory
        audio_rel = entry.get("audio", f"audio/{word_id}.mp3")
        out_path  = pack_dir / audio_rel

        # Cache key and hash
        cache_key    = f"{locale}_{word_id}"
        current_hash = content_hash(text, voice_id, voice_style)

        if not force and is_cached(cache_key, current_hash) and out_path.exists():
            print(f"  {green('→')} {word_id} ({text}) — {yellow('cached, skipping')}")
            stats["cached"] += 1
            continue

        print(f"  {green('→')} {word_id} ({text}) — generating...")

        success = generate_audio(text, manifest, out_path, dry_run)

        if success:
            if not dry_run:
                save_hash(cache_key, current_hash)
            stats["generated"] += 1
        else:
            stats["failed"] += 1

        # Polite rate-limit: 200 ms between API calls
        if not dry_run:
            time.sleep(0.2)

    print(f"\n  Summary: {stats['generated']} generated, "
          f"{stats['cached']} cached, "
          f"{stats['skipped']} skipped, "
          f"{stats['failed']} failed")
    return stats


# ─────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Bolo build-time TTS audio generator"
    )
    parser.add_argument(
        "--pack", required=True,
        help="Pack locale code (e.g. 'en', 'hi') or 'all' to process every pack"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Preview what would be generated without making any API calls"
    )
    parser.add_argument(
        "--force", action="store_true",
        help="Ignore hash cache and regenerate all files"
    )
    args = parser.parse_args()

    print(bold("\n🔊 Bolo TTS generator"))
    if args.dry_run:
        print(yellow("  DRY RUN — no API calls will be made\n"))

    # Determine which packs to process
    if args.pack == "all":
        pack_dirs = sorted(p for p in PACKS_DIR.iterdir() if p.is_dir())
    else:
        pack_dir = PACKS_DIR / args.pack
        if not pack_dir.exists():
            print(red(f"Pack '{args.pack}' not found at {pack_dir}"))
            sys.exit(1)
        pack_dirs = [pack_dir]

    total = {"skipped": 0, "generated": 0, "cached": 0, "failed": 0}
    for pack_dir in pack_dirs:
        stats = process_pack(pack_dir, args.dry_run, args.force)
        for k in total:
            total[k] += stats[k]

    print(bold(f"\n── Total ───────────────────────────────────────────────────"))
    print(f"  Generated : {total['generated']}")
    print(f"  Cached    : {total['cached']}")
    print(f"  Skipped   : {total['skipped']}")
    print(f"  Failed    : {total['failed']}")

    if total["failed"] > 0:
        print(red(f"\n  {total['failed']} file(s) failed — check API keys and network"))
        sys.exit(1)
    else:
        mode = "dry run" if args.dry_run else "run"
        print(green(f"\n  ✓ {mode} complete"))


if __name__ == "__main__":
    main()
