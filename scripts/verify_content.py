#!/usr/bin/env python3
"""
Bolo content verification script
─────────────────────────────────
Validates the consistency of assets/content/ before a build.
Run from the repo root:

    python3 scripts/verify_content.py

Exit codes:
    0  — all checks passed (possibly with warnings)
    1  — one or more errors found

Requires: pyyaml
    pip3 install pyyaml --user --break-system-packages
"""

import sys
import os
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is not installed.")
    print("Run:  pip3 install pyyaml --user --break-system-packages")
    print("Then re-run this script.")
    sys.exit(1)

# ── Paths ─────────────────────────────────────────────────────────
REPO_ROOT   = Path(__file__).parent.parent
CORE_DIR    = REPO_ROOT / "assets" / "content" / "core"
PACKS_DIR   = REPO_ROOT / "assets" / "content" / "packs"
WORDS_CORE  = CORE_DIR / "words.yaml"

# ── Known valid values ────────────────────────────────────────────
VALID_AGE_BANDS  = {"2-3", "3-4", "4-5"}
VALID_CATEGORIES = {"animals", "food", "family", "body", "transport",
                    "clothes", "home_objects", "nature", "actions", "descriptors"}
DEVANAGARI_RANGE = range(0x0900, 0x0980)  # Unicode block for Devanagari

# ── Colour helpers (ANSI — no extra library) ──────────────────────
def green(s):  return f"\033[92m{s}\033[0m"
def red(s):    return f"\033[91m{s}\033[0m"
def yellow(s): return f"\033[93m{s}\033[0m"
def bold(s):   return f"\033[1m{s}\033[0m"

# ── Result accumulator ────────────────────────────────────────────
errors   = []
warnings = []

def error(msg):
    errors.append(msg)
    print(f"  {red('✗ ERROR')}  {msg}")

def warn(msg):
    warnings.append(msg)
    print(f"  {yellow('⚠ WARN')}   {msg}")

def ok(msg):
    print(f"  {green('✓')}        {msg}")


# ─────────────────────────────────────────────────────────────────
# 1. CORE WORD LIST
# ─────────────────────────────────────────────────────────────────
def check_core_words():
    print(bold("\n── Core: assets/content/core/words.yaml ──────────────────"))

    if not WORDS_CORE.exists():
        error(f"File missing: {WORDS_CORE}")
        return {}

    with open(WORDS_CORE) as f:
        try:
            words = yaml.safe_load(f)
        except yaml.YAMLError as e:
            error(f"YAML parse error in words.yaml: {e}")
            return {}

    if not isinstance(words, list) or len(words) == 0:
        error("words.yaml must be a non-empty YAML list")
        return {}

    ok(f"Parsed {len(words)} word entries")

    seen_ids = {}
    core_words = {}  # id -> entry

    for i, word in enumerate(words):
        entry_ref = f"entry[{i}]"

        # ── Required fields ──
        required = ["id", "category", "age_band", "phoneme_targets_ipa",
                    "image", "universal"]
        missing = [f for f in required if f not in word]
        if missing:
            error(f"{entry_ref}: missing required fields: {missing}")
            continue

        wid = word["id"]
        entry_ref = f"word '{wid}'"

        # ── ID format ──
        if not re.match(r'^word_\d{3,}$', str(wid)):
            error(f"{entry_ref}: ID must match pattern word_NNN (e.g. word_001)")

        # ── Uniqueness ──
        if wid in seen_ids:
            error(f"{entry_ref}: duplicate ID (also at index {seen_ids[wid]})")
        else:
            seen_ids[wid] = i

        # ── Age band ──
        if word["age_band"] not in VALID_AGE_BANDS:
            error(f"{entry_ref}: invalid age_band '{word['age_band']}'. "
                  f"Must be one of {VALID_AGE_BANDS}")

        # ── Category ──
        if word["category"] not in VALID_CATEGORIES:
            warn(f"{entry_ref}: unknown category '{word['category']}'. "
                 f"Known: {sorted(VALID_CATEGORIES)}")

        # ── Phoneme targets ──
        if not isinstance(word["phoneme_targets_ipa"], list) or \
           len(word["phoneme_targets_ipa"]) == 0:
            error(f"{entry_ref}: phoneme_targets_ipa must be a non-empty list")

        # ── Image path convention ──
        img = word["image"]
        if not str(img).startswith("images/words/"):
            warn(f"{entry_ref}: image path '{img}' should start with images/words/")

        # ── universal must be bool ──
        if not isinstance(word["universal"], bool):
            error(f"{entry_ref}: 'universal' must be true or false (boolean)")

        core_words[wid] = word

    # ── Summary ──
    unique_ids = len(set(seen_ids.keys()))
    ok(f"{unique_ids} unique word IDs")

    age_dist = {}
    for w in core_words.values():
        age_dist[w["age_band"]] = age_dist.get(w["age_band"], 0) + 1
    ok(f"Age distribution: { {k: age_dist.get(k, 0) for k in sorted(VALID_AGE_BANDS)} }")

    cat_dist = {}
    for w in core_words.values():
        cat_dist[w["category"]] = cat_dist.get(w["category"], 0) + 1
    ok(f"Category distribution: {dict(sorted(cat_dist.items()))}")

    return core_words


# ─────────────────────────────────────────────────────────────────
# 2. LANGUAGE PACKS
# ─────────────────────────────────────────────────────────────────
def check_pack(pack_dir: Path, core_words: dict):
    locale = pack_dir.name
    print(bold(f"\n── Pack: {locale} ({pack_dir}) ──────────────────────────"))

    # ── manifest.yaml ──
    manifest_path = pack_dir / "manifest.yaml"
    if not manifest_path.exists():
        error(f"[{locale}] manifest.yaml is missing")
        return

    with open(manifest_path) as f:
        try:
            manifest = yaml.safe_load(f)
        except yaml.YAMLError as e:
            error(f"[{locale}] manifest.yaml parse error: {e}")
            return

    required_manifest = ["locale", "name_en", "name_native", "script",
                         "text_direction", "font_family", "maturity",
                         "tts_voice_provider", "tts_voice_id"]
    missing = [f for f in required_manifest if f not in manifest]
    if missing:
        error(f"[{locale}] manifest.yaml missing required fields: {missing}")
    else:
        ok(f"manifest.yaml valid — {manifest.get('name_en')} "
           f"({manifest.get('tts_voice_provider')}/{manifest.get('tts_voice_id')})")

    # ── words.yaml ──
    words_path = pack_dir / "words.yaml"
    if not words_path.exists():
        error(f"[{locale}] words.yaml is missing")
        return

    with open(words_path) as f:
        try:
            pack_words = yaml.safe_load(f) or {}
        except yaml.YAMLError as e:
            error(f"[{locale}] words.yaml parse error: {e}")
            return

    # ── cultural_overrides.yaml ──
    overrides_path = pack_dir / "cultural_overrides.yaml"
    skipped_ids = set()
    if overrides_path.exists():
        with open(overrides_path) as f:
            try:
                overrides = yaml.safe_load(f) or {}
                skipped_ids = set(overrides.get("skip", []) or [])
            except yaml.YAMLError as e:
                error(f"[{locale}] cultural_overrides.yaml parse error: {e}")

    ok(f"words.yaml loaded — {len(pack_words)} translated entries, "
       f"{len(skipped_ids)} skipped")

    # ── Coverage check: every core word must be translated or skipped ──
    untranslated = []
    for wid in core_words:
        if wid not in pack_words and wid not in skipped_ids:
            untranslated.append(wid)

    if untranslated:
        error(f"[{locale}] {len(untranslated)} core words not translated and not in skip list: "
              f"{untranslated[:10]}{'...' if len(untranslated) > 10 else ''}")
    else:
        ok(f"All {len(core_words)} core words covered (translated or skipped)")

    # ── No stale pack-only IDs ──
    stale = [wid for wid in pack_words if wid not in core_words]
    if stale:
        error(f"[{locale}] words.yaml has entries for IDs not in core: {stale}")

    # ── Per-entry field checks ──
    audio_missing = []
    for wid, entry in pack_words.items():
        if not isinstance(entry, dict):
            error(f"[{locale}] {wid}: entry must be a mapping (dict), got {type(entry)}")
            continue

        # word field
        if "word" not in entry or not str(entry.get("word", "")).strip():
            error(f"[{locale}] {wid}: 'word' field is missing or empty")

        # audio field
        if "audio" not in entry:
            error(f"[{locale}] {wid}: 'audio' field is missing")
        else:
            audio_path = pack_dir / entry["audio"]
            if not audio_path.exists():
                audio_missing.append(str(entry["audio"]))

        # Devanagari check for Hindi pack
        if locale == "hi":
            if "transliteration" not in entry or \
               not str(entry.get("transliteration", "")).strip():
                error(f"[{locale}] {wid}: Hindi pack requires 'transliteration' field")
            word_str = str(entry.get("word", ""))
            has_devanagari = any(
                ord(ch) in DEVANAGARI_RANGE for ch in word_str
            )
            if not has_devanagari:
                error(f"[{locale}] {wid}: word '{word_str}' contains no "
                      f"Devanagari characters (expected for Hindi pack)")

    # Audio missing is a warning (not yet generated)
    if audio_missing:
        warn(f"[{locale}] {len(audio_missing)}/{len(pack_words)} audio files not yet "
             f"generated (run generate_tts.py to create them) — this is expected "
             f"before the first TTS run")
    else:
        ok(f"All audio files present")


# ─────────────────────────────────────────────────────────────────
# 3. MILESTONES (basic check)
# ─────────────────────────────────────────────────────────────────
def check_milestones():
    print(bold("\n── Core: assets/content/core/milestones.yaml ─────────────"))
    milestones_path = CORE_DIR / "milestones.yaml"
    if not milestones_path.exists():
        warn("milestones.yaml not found — skipping milestone checks")
        return
    with open(milestones_path) as f:
        try:
            milestones = yaml.safe_load(f) or []
        except yaml.YAMLError as e:
            error(f"milestones.yaml parse error: {e}")
            return
    for i, ms in enumerate(milestones):
        if "id" not in ms:
            error(f"milestones[{i}]: missing 'id' field")
        if "text_en" not in ms:
            error(f"milestones[{i}]: missing 'text_en' field")
        if "age_range_months" not in ms or \
           not isinstance(ms.get("age_range_months"), list) or \
           len(ms["age_range_months"]) != 2:
            error(f"milestones entry '{ms.get('id','?')}': "
                  f"age_range_months must be a 2-element list e.g. [18, 24]")
    ok(f"Parsed {len(milestones)} milestones")


# ─────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────
def main():
    print(bold("\n🔍 Bolo content verification"))
    print(f"   Repo root: {REPO_ROOT}\n")

    core_words = check_core_words()
    check_milestones()

    if PACKS_DIR.exists():
        for pack_dir in sorted(PACKS_DIR.iterdir()):
            if pack_dir.is_dir():
                check_pack(pack_dir, core_words)
    else:
        error(f"Packs directory not found: {PACKS_DIR}")

    # ── Final summary ──────────────────────────────────────────
    print(bold("\n── Summary ────────────────────────────────────────────────"))
    if errors:
        print(red(f"  ✗ {len(errors)} error(s) found — fix before proceeding"))
        for e in errors:
            print(f"    • {e}")
        if warnings:
            print(yellow(f"\n  ⚠ {len(warnings)} warning(s) — non-blocking"))
        sys.exit(1)
    else:
        print(green(f"  ✓ All checks passed!") +
              (f"  ({len(warnings)} warning(s))" if warnings else ""))
        if warnings:
            print(yellow(f"\n  Warnings (non-blocking):"))
            for w in warnings:
                print(f"    • {w}")
        sys.exit(0)


if __name__ == "__main__":
    main()
