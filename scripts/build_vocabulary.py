#!/usr/bin/env python3
"""
Bolo vocabulary builder
───────────────────────
Emits two files in sync:

    assets/content/core/words.yaml         (language-agnostic structure)
    assets/content/packs/en/words.yaml     (English labels + audio paths)

The vocabulary here is grounded in the MacArthur-Bates CDI (Words &
Gestures + Words & Sentences) plus ASHA 24 / 36 / 48-month milestones.
100 words per age band × 3 age bands = 300 total, split across
8 categories (see CATEGORY_LIMITS).

Run:
    python3 scripts/build_vocabulary.py
    python3 scripts/build_vocabulary.py --dry-run     # preview counts only
"""
from __future__ import annotations
import argparse
import sys
from dataclasses import dataclass
from pathlib import Path
from collections import Counter

REPO_ROOT = Path(__file__).parent.parent
CORE_WORDS = REPO_ROOT / "assets" / "content" / "core" / "words.yaml"
EN_PACK    = REPO_ROOT / "assets" / "content" / "packs" / "en" / "words.yaml"


@dataclass
class W:
    """One vocabulary entry — hand-authored, one line each below."""
    en: str                        # English label
    category: str                  # animals | food | family | body | colours | objects | vehicles | nature
    age: str                       # "2-3" | "3-4" | "4-5"
    phonemes: list[str]            # rough IPA; drives focused-stim game
    asha_months: int               # typical age of production per ASHA
    cdi_rank: int | None = None    # MacArthur-Bates CDI rank (optional)
    universal: bool = True         # false = culturally specific
    emoji: str | None = None       # temporary art placeholder


# ── The vocabulary (300 entries) ────────────────────────────────────
# Ordering: by category, then age band, then rough CDI frequency. Phonemes
# are pragmatic transcriptions of the *isolated word* — good enough for
# the focused-stim game's grouping, not IPA gold. cdi_rank left None where
# I don't have a confident number rather than guessing.
#
# The list is deliberately kept flat and readable so future edits are
# obvious diffs. Do not sort programmatically or you will lose the
# curated groupings.

VOCAB: list[W] = [
    # ═══════════════════════ ANIMALS (37) ═══════════════════════
    # 2-3 (15)
    W("cat",       "animals", "2-3", ["k","æ","t"],      18, cdi_rank=45,  emoji="🐱"),
    W("dog",       "animals", "2-3", ["d","ɔ","g"],      18, cdi_rank=21,  emoji="🐶"),
    W("cow",       "animals", "2-3", ["k","aʊ"],         20, cdi_rank=60,  emoji="🐄"),
    W("bird",      "animals", "2-3", ["b","ɜ","d"],      20, cdi_rank=90,  emoji="🐦"),
    W("fish",      "animals", "2-3", ["f","ɪ","ʃ"],      22, cdi_rank=110, emoji="🐟"),
    W("duck",      "animals", "2-3", ["d","ʌ","k"],      20, cdi_rank=70,  emoji="🦆"),
    W("horse",     "animals", "2-3", ["h","ɔ","s"],      22, cdi_rank=95,  emoji="🐴"),
    W("pig",       "animals", "2-3", ["p","ɪ","g"],      22, cdi_rank=85,  emoji="🐷"),
    W("bunny",     "animals", "2-3", ["b","ʌ","n","i"],  22, cdi_rank=115, emoji="🐰"),
    W("bear",      "animals", "2-3", ["b","ɛ","r"],      24, cdi_rank=105, emoji="🐻"),
    W("frog",      "animals", "2-3", ["f","r","ɔ","g"],  24, cdi_rank=140, emoji="🐸"),
    W("mouse",     "animals", "2-3", ["m","aʊ","s"],     24, cdi_rank=155, emoji="🐭"),
    W("sheep",     "animals", "2-3", ["ʃ","i","p"],      24, cdi_rank=170, emoji="🐑"),
    W("chicken",   "animals", "2-3", ["tʃ","ɪ","k","ə","n"], 24, cdi_rank=145, emoji="🐔"),
    W("elephant",  "animals", "2-3", ["ɛ","l","ə","f","ə","n","t"], 26, cdi_rank=180, emoji="🐘"),
    # 3-4 (12)
    W("lion",      "animals", "3-4", ["l","aɪ","ə","n"], 30, emoji="🦁"),
    W("tiger",     "animals", "3-4", ["t","aɪ","g","ɜ"], 30, emoji="🐯"),
    W("monkey",    "animals", "3-4", ["m","ʌ","ŋ","k","i"], 30, emoji="🐵"),
    W("zebra",     "animals", "3-4", ["z","i","b","r","ə"], 32, emoji="🦓"),
    W("giraffe",   "animals", "3-4", ["dʒ","ə","r","æ","f"], 32, emoji="🦒"),
    W("goat",      "animals", "3-4", ["g","oʊ","t"], 30, emoji="🐐"),
    W("owl",       "animals", "3-4", ["aʊ","l"], 32, emoji="🦉"),
    W("turtle",    "animals", "3-4", ["t","ɜ","t","ə","l"], 34, emoji="🐢"),
    W("snake",     "animals", "3-4", ["s","n","eɪ","k"], 34, emoji="🐍"),
    W("panda",     "animals", "3-4", ["p","æ","n","d","ə"], 34, emoji="🐼"),
    W("penguin",   "animals", "3-4", ["p","ɛ","ŋ","g","w","ɪ","n"], 36, emoji="🐧"),
    W("butterfly", "animals", "3-4", ["b","ʌ","t","ɜ","f","l","aɪ"], 36, emoji="🦋"),
    # 4-5 (10)
    W("kangaroo",  "animals", "4-5", ["k","æ","ŋ","g","ə","r","u"], 42, emoji="🦘"),
    W("crocodile", "animals", "4-5", ["k","r","ɒ","k","ə","d","aɪ","l"], 44, emoji="🐊"),
    W("dolphin",   "animals", "4-5", ["d","ɒ","l","f","ɪ","n"], 44, emoji="🐬"),
    W("octopus",   "animals", "4-5", ["ɒ","k","t","ə","p","ʌ","s"], 46, emoji="🐙"),
    W("hippo",     "animals", "4-5", ["h","ɪ","p","oʊ"], 42, emoji="🦛"),
    W("rhino",     "animals", "4-5", ["r","aɪ","n","oʊ"], 44, emoji="🦏"),
    W("squirrel",  "animals", "4-5", ["s","k","w","ɜ","ə","l"], 46, emoji="🐿️"),
    W("peacock",   "animals", "4-5", ["p","i","k","ɒ","k"], 48, emoji="🦚"),
    W("flamingo",  "animals", "4-5", ["f","l","ə","m","ɪ","ŋ","g","oʊ"], 48, emoji="🦩"),
    W("dinosaur",  "animals", "4-5", ["d","aɪ","n","ə","s","ɔ"], 48, emoji="🦖"),

    # ═══════════════════════ FOOD (37) ═══════════════════════
    # 2-3 (15)
    W("milk",     "food", "2-3", ["m","ɪ","l","k"], 18, cdi_rank=15, emoji="🥛"),
    W("banana",   "food", "2-3", ["b","ə","n","æ","n","ə"], 22, cdi_rank=55, emoji="🍌"),
    W("water",    "food", "2-3", ["w","ɔ","t","ɜ"], 20, cdi_rank=12, emoji="💧"),
    W("apple",    "food", "2-3", ["æ","p","ə","l"], 20, cdi_rank=40, emoji="🍎"),
    W("bread",    "food", "2-3", ["b","r","ɛ","d"], 22, cdi_rank=65, emoji="🍞"),
    W("egg",      "food", "2-3", ["ɛ","g"], 20, cdi_rank=50, emoji="🥚"),
    W("juice",    "food", "2-3", ["dʒ","u","s"], 22, cdi_rank=42, emoji="🧃"),
    W("cheese",   "food", "2-3", ["tʃ","i","z"], 22, cdi_rank=75, emoji="🧀"),
    W("cookie",   "food", "2-3", ["k","ʊ","k","i"], 22, cdi_rank=35, emoji="🍪"),
    W("cake",     "food", "2-3", ["k","eɪ","k"], 24, cdi_rank=80, emoji="🍰"),
    W("orange",   "food", "2-3", ["ɔ","r","ɪ","n","dʒ"], 24, cdi_rank=100, emoji="🍊"),
    W("grape",    "food", "2-3", ["g","r","eɪ","p"], 24, cdi_rank=120, emoji="🍇"),
    W("rice",     "food", "2-3", ["r","aɪ","s"], 24, cdi_rank=130, emoji="🍚"),
    W("noodles",  "food", "2-3", ["n","u","d","ə","l","z"], 24, cdi_rank=150, emoji="🍜"),
    W("yogurt",   "food", "2-3", ["j","oʊ","g","ɜ","t"], 24, emoji="🥣"),
    # 3-4 (12)
    W("strawberry","food", "3-4", ["s","t","r","ɔ","b","ɛ","r","i"], 32, emoji="🍓"),
    W("watermelon","food", "3-4", ["w","ɔ","t","ɜ","m","ɛ","l","ə","n"], 34, emoji="🍉"),
    W("pizza",    "food", "3-4", ["p","i","t","s","ə"], 30, emoji="🍕"),
    W("sandwich", "food", "3-4", ["s","æ","n","w","ɪ","tʃ"], 32, emoji="🥪"),
    W("carrot",   "food", "3-4", ["k","æ","r","ə","t"], 30, emoji="🥕"),
    W("tomato",   "food", "3-4", ["t","ə","m","eɪ","t","oʊ"], 32, emoji="🍅"),
    W("potato",   "food", "3-4", ["p","ə","t","eɪ","t","oʊ"], 32, emoji="🥔"),
    W("corn",     "food", "3-4", ["k","ɔ","n"], 30, emoji="🌽"),
    W("mango",    "food", "3-4", ["m","æ","ŋ","g","oʊ"], 30, emoji="🥭"),
    W("chocolate","food", "3-4", ["tʃ","ɒ","k","l","ə","t"], 32, emoji="🍫"),
    W("icecream", "food", "3-4", ["aɪ","s","k","r","i","m"], 30, emoji="🍦"),
    W("soup",     "food", "3-4", ["s","u","p"], 32, emoji="🥣"),
    # 4-5 (10)
    W("broccoli", "food", "4-5", ["b","r","ɒ","k","ə","l","i"], 44, emoji="🥦"),
    W("pineapple","food", "4-5", ["p","aɪ","n","æ","p","ə","l"], 44, emoji="🍍"),
    W("cucumber", "food", "4-5", ["k","j","u","k","ʌ","m","b","ɜ"], 46, emoji="🥒"),
    W("lemon",    "food", "4-5", ["l","ɛ","m","ə","n"], 42, emoji="🍋"),
    W("pear",     "food", "4-5", ["p","ɛ","r"], 42, emoji="🍐"),
    W("peach",    "food", "4-5", ["p","i","tʃ"], 44, emoji="🍑"),
    W("burger",   "food", "4-5", ["b","ɜ","g","ɜ"], 44, emoji="🍔"),
    W("popcorn",  "food", "4-5", ["p","ɒ","p","k","ɔ","n"], 46, emoji="🍿"),
    W("donut",    "food", "4-5", ["d","oʊ","n","ʌ","t"], 44, emoji="🍩"),
    W("pancake",  "food", "4-5", ["p","æ","n","k","eɪ","k"], 46, emoji="🥞"),

    # ═══════════════════════ FAMILY & PEOPLE (30) ═══════════════════════
    # 2-3 (12)
    W("mama",     "family", "2-3", ["m","ɑ","m","ə"], 12, cdi_rank=1, emoji="👩"),
    W("papa",     "family", "2-3", ["p","ɑ","p","ə"], 12, cdi_rank=2, emoji="👨"),
    W("baby",     "family", "2-3", ["b","eɪ","b","i"], 16, cdi_rank=5, emoji="👶"),
    W("grandma",  "family", "2-3", ["g","r","æ","n","m","ɑ"], 20, cdi_rank=25, emoji="👵"),
    W("grandpa",  "family", "2-3", ["g","r","æ","n","p","ɑ"], 20, cdi_rank=26, emoji="👴"),
    W("boy",      "family", "2-3", ["b","ɔɪ"], 22, cdi_rank=32, emoji="👦"),
    W("girl",     "family", "2-3", ["g","ɜ","l"], 22, cdi_rank=33, emoji="👧"),
    W("me",       "family", "2-3", ["m","i"], 22, cdi_rank=8, emoji="👤"),
    W("you",      "family", "2-3", ["j","u"], 22, cdi_rank=9, emoji="👉"),
    W("kid",      "family", "2-3", ["k","ɪ","d"], 24, emoji="🧒"),
    W("sister",   "family", "2-3", ["s","ɪ","s","t","ɜ"], 24, cdi_rank=48, emoji="👧"),
    W("brother",  "family", "2-3", ["b","r","ʌ","ð","ɜ"], 24, cdi_rank=49, emoji="👦"),
    # 3-4 (10)
    W("friend",   "family", "3-4", ["f","r","ɛ","n","d"], 30, emoji="🧑‍🤝‍🧑"),
    W("teacher",  "family", "3-4", ["t","i","tʃ","ɜ"], 32, emoji="🧑‍🏫"),
    W("doctor",   "family", "3-4", ["d","ɒ","k","t","ɜ"], 30, emoji="🧑‍⚕️"),
    W("nurse",    "family", "3-4", ["n","ɜ","s"], 32, emoji="👩‍⚕️"),
    W("aunt",     "family", "3-4", ["æ","n","t"], 30, emoji="👩"),
    W("uncle",    "family", "3-4", ["ʌ","ŋ","k","ə","l"], 30, emoji="👨"),
    W("cousin",   "family", "3-4", ["k","ʌ","z","ə","n"], 32, emoji="🧒"),
    W("neighbour","family", "3-4", ["n","eɪ","b","ɜ"], 34, emoji="👥"),
    W("chef",     "family", "3-4", ["ʃ","ɛ","f"], 32, emoji="🧑‍🍳"),
    W("farmer",   "family", "3-4", ["f","ɑ","m","ɜ"], 32, emoji="🧑‍🌾"),
    # 4-5 (8)
    W("firefighter","family","4-5", ["f","aɪ","ɜ","f","aɪ","t","ɜ"], 44, emoji="🧑‍🚒"),
    W("police",   "family", "4-5", ["p","ə","l","i","s"], 42, emoji="👮"),
    W("dentist",  "family", "4-5", ["d","ɛ","n","t","ɪ","s","t"], 46, emoji="🦷"),
    W("artist",   "family", "4-5", ["ɑ","t","ɪ","s","t"], 44, emoji="🧑‍🎨"),
    W("astronaut","family", "4-5", ["æ","s","t","r","ə","n","ɔ","t"], 48, emoji="🧑‍🚀"),
    W("scientist","family", "4-5", ["s","aɪ","ə","n","t","ɪ","s","t"], 48, emoji="🧑‍🔬"),
    W("pilot",    "family", "4-5", ["p","aɪ","l","ə","t"], 44, emoji="🧑‍✈️"),
    W("baker",    "family", "4-5", ["b","eɪ","k","ɜ"], 42, emoji="🧑‍🍳"),

    # ═══════════════════════ BODY (34) ═══════════════════════
    # 2-3 (12)
    W("eye",      "body", "2-3", ["aɪ"], 20, cdi_rank=28, emoji="👁"),
    W("nose",     "body", "2-3", ["n","oʊ","z"], 20, cdi_rank=27, emoji="👃"),
    W("mouth",    "body", "2-3", ["m","aʊ","θ"], 22, cdi_rank=44, emoji="👄"),
    W("hand",     "body", "2-3", ["h","æ","n","d"], 20, cdi_rank=30, emoji="🖐"),
    W("foot",     "body", "2-3", ["f","ʊ","t"], 22, cdi_rank=52, emoji="🦶"),
    W("ear",      "body", "2-3", ["ɪ","ɜ"], 22, cdi_rank=41, emoji="👂"),
    W("hair",     "body", "2-3", ["h","ɛ","r"], 22, cdi_rank=58, emoji="💇"),
    W("tooth",    "body", "2-3", ["t","u","θ"], 24, cdi_rank=68, emoji="🦷"),
    W("head",     "body", "2-3", ["h","ɛ","d"], 22, cdi_rank=38, emoji="👦"),
    W("tummy",    "body", "2-3", ["t","ʌ","m","i"], 24, cdi_rank=78, emoji="🤰"),
    W("knee",     "body", "2-3", ["n","i"], 24, cdi_rank=88, emoji="🦵"),
    W("toe",      "body", "2-3", ["t","oʊ"], 24, cdi_rank=92, emoji="🦶"),
    # 3-4 (12)
    W("arm",      "body", "3-4", ["ɑ","m"], 30, emoji="💪"),
    W("leg",      "body", "3-4", ["l","ɛ","g"], 30, emoji="🦵"),
    W("finger",   "body", "3-4", ["f","ɪ","ŋ","g","ɜ"], 30, emoji="👆"),
    W("tongue",   "body", "3-4", ["t","ʌ","ŋ"], 32, emoji="👅"),
    W("elbow",    "body", "3-4", ["ɛ","l","b","oʊ"], 34, emoji="💪"),
    W("shoulder", "body", "3-4", ["ʃ","oʊ","l","d","ɜ"], 34, emoji="🧍"),
    W("clap",     "body", "3-4", ["k","l","æ","p"], 30, emoji="👏"),   # action
    W("jump",     "body", "3-4", ["dʒ","ʌ","m","p"], 30, emoji="🤸"),
    W("run",      "body", "3-4", ["r","ʌ","n"], 30, emoji="🏃"),
    W("hug",      "body", "3-4", ["h","ʌ","g"], 32, emoji="🤗"),
    W("wave",     "body", "3-4", ["w","eɪ","v"], 30, emoji="👋"),
    W("smile",    "body", "3-4", ["s","m","aɪ","l"], 32, emoji="😊"),
    # 4-5 (10)
    W("chest",    "body", "4-5", ["tʃ","ɛ","s","t"], 42, emoji="🫁"),
    W("neck",     "body", "4-5", ["n","ɛ","k"], 42, emoji="🧍"),
    W("wrist",    "body", "4-5", ["r","ɪ","s","t"], 44, emoji="🖐"),
    W("ankle",    "body", "4-5", ["æ","ŋ","k","ə","l"], 44, emoji="🦵"),
    W("eyebrow",  "body", "4-5", ["aɪ","b","r","aʊ"], 46, emoji="😐"),
    W("dance",    "body", "4-5", ["d","æ","n","s"], 42, emoji="💃"),
    W("stretch",  "body", "4-5", ["s","t","r","ɛ","tʃ"], 46, emoji="🧘"),
    W("skip",     "body", "4-5", ["s","k","ɪ","p"], 44, emoji="🤸"),
    W("climb",    "body", "4-5", ["k","l","aɪ","m"], 44, emoji="🧗"),
    W("swim",     "body", "4-5", ["s","w","ɪ","m"], 44, emoji="🏊"),

    # ═══════════════════════ COLOURS & SHAPES (30) ═══════════════════════
    # 2-3 (8)
    W("red",      "colours", "2-3", ["r","ɛ","d"], 24, cdi_rank=175, emoji="🔴"),
    W("blue",     "colours", "2-3", ["b","l","u"], 24, cdi_rank=185, emoji="🔵"),
    W("yellow",   "colours", "2-3", ["j","ɛ","l","oʊ"], 26, cdi_rank=195, emoji="🟡"),
    W("green",    "colours", "2-3", ["g","r","i","n"], 26, cdi_rank=200, emoji="🟢"),
    W("black",    "colours", "2-3", ["b","l","æ","k"], 26, emoji="⚫"),
    W("white",    "colours", "2-3", ["w","aɪ","t"], 26, emoji="⚪"),
    W("pink",     "colours", "2-3", ["p","ɪ","ŋ","k"], 26, emoji="🩷"),
    W("bright-orange", "colours", "2-3", ["ɔ","r","ɪ","n","dʒ"], 26, emoji="🟠"),
    # 3-4 (12)
    W("purple",   "colours", "3-4", ["p","ɜ","p","ə","l"], 32, emoji="🟣"),
    W("brown",    "colours", "3-4", ["b","r","aʊ","n"], 32, emoji="🟤"),
    W("grey",     "colours", "3-4", ["g","r","eɪ"], 34, emoji="⚫"),
    W("gold",     "colours", "3-4", ["g","oʊ","l","d"], 32, emoji="🟨"),
    W("silver",   "colours", "3-4", ["s","ɪ","l","v","ɜ"], 34, emoji="⬜"),
    W("circle",   "colours", "3-4", ["s","ɜ","k","ə","l"], 30, emoji="⭕"),
    W("square",   "colours", "3-4", ["s","k","w","ɛ","r"], 32, emoji="⬛"),
    W("triangle", "colours", "3-4", ["t","r","aɪ","æ","ŋ","g","ə","l"], 34, emoji="🔺"),
    W("star",     "colours", "3-4", ["s","t","ɑ"], 30, emoji="⭐"),
    W("heart",    "colours", "3-4", ["h","ɑ","t"], 30, emoji="❤️"),
    W("rectangle","colours", "3-4", ["r","ɛ","k","t","æ","ŋ","g","ə","l"], 36, emoji="▬"),
    W("oval",     "colours", "3-4", ["oʊ","v","ə","l"], 34, emoji="🥚"),
    # 4-5 (10)
    W("diamond",  "colours", "4-5", ["d","aɪ","ə","m","ə","n","d"], 44, emoji="💎"),
    W("rainbow",  "colours", "4-5", ["r","eɪ","n","b","oʊ"], 44, emoji="🌈"),
    W("crescent", "colours", "4-5", ["k","r","ɛ","s","ə","n","t"], 48, emoji="🌙"),
    W("hexagon",  "colours", "4-5", ["h","ɛ","k","s","ə","g","ɒ","n"], 46, emoji="⬡"),
    W("beige",    "colours", "4-5", ["b","eɪ","ʒ"], 46, emoji="🟫"),
    W("navy",     "colours", "4-5", ["n","eɪ","v","i"], 46, emoji="🔵"),
    W("maroon",   "colours", "4-5", ["m","ə","r","u","n"], 48, emoji="🔴"),
    W("turquoise","colours", "4-5", ["t","ɜ","k","w","ɔɪ","z"], 48, emoji="🟢"),
    W("violet",   "colours", "4-5", ["v","aɪ","ə","l","ə","t"], 46, emoji="🟣"),
    W("magenta",  "colours", "4-5", ["m","ə","dʒ","ɛ","n","t","ə"], 48, emoji="🩷"),

    # ═══════════════════════ EVERYDAY OBJECTS (42) ═══════════════════════
    # 2-3 (15)
    W("ball",     "objects", "2-3", ["b","ɔ","l"], 18, cdi_rank=10, emoji="⚽"),
    W("book",     "objects", "2-3", ["b","ʊ","k"], 20, cdi_rank=18, emoji="📖"),
    W("cup",      "objects", "2-3", ["k","ʌ","p"], 20, cdi_rank=22, emoji="☕"),
    W("spoon",    "objects", "2-3", ["s","p","u","n"], 22, cdi_rank=36, emoji="🥄"),
    W("shoe",     "objects", "2-3", ["ʃ","u"], 20, cdi_rank=24, emoji="👟"),
    W("hat",      "objects", "2-3", ["h","æ","t"], 20, cdi_rank=39, emoji="🎩"),
    W("bed",      "objects", "2-3", ["b","ɛ","d"], 22, cdi_rank=46, emoji="🛏"),
    W("chair",    "objects", "2-3", ["tʃ","ɛ","r"], 22, cdi_rank=54, emoji="🪑"),
    W("door",     "objects", "2-3", ["d","ɔ"], 22, cdi_rank=62, emoji="🚪"),
    W("phone",    "objects", "2-3", ["f","oʊ","n"], 22, cdi_rank=72, emoji="📱"),
    W("keys",     "objects", "2-3", ["k","i","z"], 22, cdi_rank=84, emoji="🔑"),
    W("bag",      "objects", "2-3", ["b","æ","g"], 24, cdi_rank=98, emoji="👜"),
    W("brush",    "objects", "2-3", ["b","r","ʌ","ʃ"], 24, cdi_rank=112, emoji="🪥"),
    W("sock",     "objects", "2-3", ["s","ɒ","k"], 22, cdi_rank=76, emoji="🧦"),
    W("toy",      "objects", "2-3", ["t","ɔɪ"], 22, cdi_rank=66, emoji="🧸"),
    # 3-4 (15)
    W("bottle",   "objects", "3-4", ["b","ɒ","t","ə","l"], 30, emoji="🍼"),
    W("plate",    "objects", "3-4", ["p","l","eɪ","t"], 30, emoji="🍽"),
    W("fork",     "objects", "3-4", ["f","ɔ","k"], 30, emoji="🍴"),
    W("knife",    "objects", "3-4", ["n","aɪ","f"], 32, emoji="🔪"),
    W("blanket",  "objects", "3-4", ["b","l","æ","ŋ","k","ə","t"], 32, emoji="🛏"),
    W("pillow",   "objects", "3-4", ["p","ɪ","l","oʊ"], 32, emoji="🛏"),
    W("towel",    "objects", "3-4", ["t","aʊ","ə","l"], 32, emoji="🧺"),
    W("soap",     "objects", "3-4", ["s","oʊ","p"], 30, emoji="🧼"),
    W("shampoo",  "objects", "3-4", ["ʃ","æ","m","p","u"], 34, emoji="🧴"),
    W("shirt",    "objects", "3-4", ["ʃ","ɜ","t"], 30, emoji="👕"),
    W("pants",    "objects", "3-4", ["p","æ","n","t","s"], 30, emoji="👖"),
    W("dress",    "objects", "3-4", ["d","r","ɛ","s"], 30, emoji="👗"),
    W("crayon",   "objects", "3-4", ["k","r","eɪ","ɒ","n"], 32, emoji="🖍"),
    W("puzzle",   "objects", "3-4", ["p","ʌ","z","ə","l"], 34, emoji="🧩"),
    W("blocks",   "objects", "3-4", ["b","l","ɒ","k","s"], 32, emoji="🧱"),
    # 4-5 (12)
    W("umbrella", "objects", "4-5", ["ʌ","m","b","r","ɛ","l","ə"], 44, emoji="☂"),
    W("backpack", "objects", "4-5", ["b","æ","k","p","æ","k"], 44, emoji="🎒"),
    W("scissors", "objects", "4-5", ["s","ɪ","z","ɜ","z"], 46, emoji="✂"),
    W("glasses",  "objects", "4-5", ["g","l","æ","s","ə","z"], 42, emoji="👓"),
    W("clock",    "objects", "4-5", ["k","l","ɒ","k"], 42, emoji="🕐"),
    W("camera",   "objects", "4-5", ["k","æ","m","ə","r","ə"], 44, emoji="📷"),
    W("guitar",   "objects", "4-5", ["g","ɪ","t","ɑ"], 44, emoji="🎸"),
    W("drum",     "objects", "4-5", ["d","r","ʌ","m"], 42, emoji="🥁"),
    W("balloon",  "objects", "4-5", ["b","ə","l","u","n"], 42, emoji="🎈"),
    W("kite",     "objects", "4-5", ["k","aɪ","t"], 42, emoji="🪁"),
    W("mirror",   "objects", "4-5", ["m","ɪ","r","ɜ"], 44, emoji="🪞"),
    W("basket",   "objects", "4-5", ["b","æ","s","k","ə","t"], 44, emoji="🧺"),

    # ═══════════════════════ VEHICLES (34) ═══════════════════════
    # 2-3 (12)
    W("car",      "vehicles", "2-3", ["k","ɑ"], 18, cdi_rank=16, emoji="🚗"),
    W("bus",      "vehicles", "2-3", ["b","ʌ","s"], 20, cdi_rank=31, emoji="🚌"),
    W("truck",    "vehicles", "2-3", ["t","r","ʌ","k"], 20, cdi_rank=37, emoji="🚚"),
    W("bike",     "vehicles", "2-3", ["b","aɪ","k"], 22, cdi_rank=56, emoji="🚲"),
    W("train",    "vehicles", "2-3", ["t","r","eɪ","n"], 22, cdi_rank=64, emoji="🚂"),
    W("plane",    "vehicles", "2-3", ["p","l","eɪ","n"], 22, cdi_rank=74, emoji="✈"),
    W("boat",     "vehicles", "2-3", ["b","oʊ","t"], 22, cdi_rank=82, emoji="⛵"),
    W("van",      "vehicles", "2-3", ["v","æ","n"], 24, emoji="🚐"),
    W("taxi",     "vehicles", "2-3", ["t","æ","k","s","i"], 24, emoji="🚕"),
    W("ship",     "vehicles", "2-3", ["ʃ","ɪ","p"], 24, emoji="🚢"),
    W("scooter",  "vehicles", "2-3", ["s","k","u","t","ɜ"], 24, emoji="🛵"),
    W("wagon",    "vehicles", "2-3", ["w","æ","g","ə","n"], 24, emoji="🛒"),
    # 3-4 (12)
    W("motorbike","vehicles", "3-4", ["m","oʊ","t","ɜ","b","aɪ","k"], 32, emoji="🏍"),
    W("helicopter","vehicles","3-4", ["h","ɛ","l","ə","k","ɒ","p","t","ɜ"], 34, emoji="🚁"),
    W("ambulance","vehicles", "3-4", ["æ","m","b","j","ə","l","ə","n","s"], 34, emoji="🚑"),
    W("firetruck","vehicles", "3-4", ["f","aɪ","ɜ","t","r","ʌ","k"], 32, emoji="🚒"),
    W("policecar","vehicles", "3-4", ["p","ə","l","i","s","k","ɑ"], 32, emoji="🚓"),
    W("tractor",  "vehicles", "3-4", ["t","r","æ","k","t","ɜ"], 32, emoji="🚜"),
    W("digger",   "vehicles", "3-4", ["d","ɪ","g","ɜ"], 30, emoji="🚜"),
    W("crane",    "vehicles", "3-4", ["k","r","eɪ","n"], 32, emoji="🏗"),
    W("rocket",   "vehicles", "3-4", ["r","ɒ","k","ə","t"], 30, emoji="🚀"),
    W("submarine","vehicles", "3-4", ["s","ʌ","b","m","ə","r","i","n"], 36, emoji="🚤"),
    W("skateboard","vehicles","3-4", ["s","k","eɪ","t","b","ɔ","d"], 32, emoji="🛹"),
    W("rollerskates","vehicles","3-4", ["r","oʊ","l","ɜ","s","k","eɪ","t","s"], 36, emoji="🛼"),
    # 4-5 (10)
    W("ferry",    "vehicles", "4-5", ["f","ɛ","r","i"], 44, emoji="⛴"),
    W("sailboat", "vehicles", "4-5", ["s","eɪ","l","b","oʊ","t"], 44, emoji="⛵"),
    W("hotairballoon","vehicles","4-5", ["h","ɒ","t","ɛ","r","b","ə","l","u","n"], 48, emoji="🎈"),
    W("jetski",   "vehicles", "4-5", ["dʒ","ɛ","t","s","k","i"], 46, emoji="🚤"),
    W("spaceship","vehicles", "4-5", ["s","p","eɪ","s","ʃ","ɪ","p"], 46, emoji="🛸"),
    W("caravan",  "vehicles", "4-5", ["k","ɛ","r","ə","v","æ","n"], 46, emoji="🚐"),
    W("cablecar", "vehicles", "4-5", ["k","eɪ","b","ə","l","k","ɑ"], 46, emoji="🚡"),
    W("tram",     "vehicles", "4-5", ["t","r","æ","m"], 44, emoji="🚋"),
    W("segway",  "vehicles","4-5", ["s","ɛ","g","w","eɪ"], 46, emoji="🛴"),
    W("racecar",  "vehicles", "4-5", ["r","eɪ","s","k","ɑ"], 44, emoji="🏎"),

    # ═══════════════════════ NATURE & PLACES (56) ═══════════════════════
    # 2-3 (11)
    W("sun",      "nature", "2-3", ["s","ʌ","n"], 22, cdi_rank=48, emoji="☀"),
    W("moon",     "nature", "2-3", ["m","u","n"], 22, cdi_rank=58, emoji="🌙"),
    W("tree",     "nature", "2-3", ["t","r","i"], 22, cdi_rank=68, emoji="🌳"),
    W("flower",   "nature", "2-3", ["f","l","aʊ","ɜ"], 22, cdi_rank=78, emoji="🌸"),
    W("rain",     "nature", "2-3", ["r","eɪ","n"], 22, cdi_rank=88, emoji="🌧"),
    W("snow",     "nature", "2-3", ["s","n","oʊ"], 24, cdi_rank=118, emoji="❄"),
    W("cloud",    "nature", "2-3", ["k","l","aʊ","d"], 24, cdi_rank=128, emoji="☁"),
    W("sky",      "nature", "2-3", ["s","k","aɪ"], 24, emoji="🌤"),
    W("grass",    "nature", "2-3", ["g","r","æ","s"], 24, emoji="🌱"),
    W("leaf",     "nature", "2-3", ["l","i","f"], 24, emoji="🍃"),
    W("home",     "nature", "2-3", ["h","oʊ","m"], 24, cdi_rank=94, emoji="🏠"),
    # 3-4 (15)
    W("river",    "nature", "3-4", ["r","ɪ","v","ɜ"], 32, emoji="🏞"),
    W("mountain", "nature", "3-4", ["m","aʊ","n","t","ə","n"], 34, emoji="⛰"),
    W("beach",    "nature", "3-4", ["b","i","tʃ"], 30, emoji="🏖"),
    W("sea",      "nature", "3-4", ["s","i"], 30, emoji="🌊"),
    W("park",     "nature", "3-4", ["p","ɑ","k"], 30, emoji="🌳"),
    W("garden",   "nature", "3-4", ["g","ɑ","d","ə","n"], 30, emoji="🌷"),
    W("school",   "nature", "3-4", ["s","k","u","l"], 32, emoji="🏫"),
    W("shop",     "nature", "3-4", ["ʃ","ɒ","p"], 30, emoji="🏪"),
    W("hospital", "nature", "3-4", ["h","ɒ","s","p","ə","t","ə","l"], 34, emoji="🏥"),
    W("bridge",   "nature", "3-4", ["b","r","ɪ","dʒ"], 32, emoji="🌉"),
    W("puddle",   "nature", "3-4", ["p","ʌ","d","ə","l"], 32, emoji="💧"),
    W("wind",     "nature", "3-4", ["w","ɪ","n","d"], 32, emoji="💨"),
    W("stone",    "nature", "3-4", ["s","t","oʊ","n"], 30, emoji="🪨"),
    W("sand",     "nature", "3-4", ["s","æ","n","d"], 30, emoji="🏖"),
    W("island",   "nature", "3-4", ["aɪ","l","ə","n","d"], 36, emoji="🏝"),
    # 4-5 (30)
    W("forest",   "nature", "4-5", ["f","ɒ","r","ə","s","t"], 44, emoji="🌲"),
    W("desert",   "nature", "4-5", ["d","ɛ","z","ɜ","t"], 46, emoji="🏜"),
    W("valley",   "nature", "4-5", ["v","æ","l","i"], 44, emoji="🏞"),
    W("waterfall","nature", "4-5", ["w","ɔ","t","ɜ","f","ɔ","l"], 46, emoji="🌊"),
    W("volcano",  "nature", "4-5", ["v","ɒ","l","k","eɪ","n","oʊ"], 48, emoji="🌋"),
    W("cave",     "nature", "4-5", ["k","eɪ","v"], 42, emoji="🕳"),
    W("field",    "nature", "4-5", ["f","i","l","d"], 42, emoji="🌾"),
    W("pond",     "nature", "4-5", ["p","ɒ","n","d"], 44, emoji="🐸"),
    W("lake",     "nature", "4-5", ["l","eɪ","k"], 42, emoji="🏞"),
    W("stream",   "nature", "4-5", ["s","t","r","i","m"], 44, emoji="🏞"),
    W("thunder",  "nature", "4-5", ["θ","ʌ","n","d","ɜ"], 46, emoji="⛈"),
    W("lightning","nature", "4-5", ["l","aɪ","t","n","ɪ","ŋ"], 46, emoji="⚡"),
    W("storm",    "nature", "4-5", ["s","t","ɔ","m"], 44, emoji="🌩"),
    W("fog",      "nature", "4-5", ["f","ɒ","g"], 44, emoji="🌫"),
    W("dew",      "nature", "4-5", ["d","j","u"], 46, emoji="💧"),
    W("planet",   "nature", "4-5", ["p","l","æ","n","ə","t"], 46, emoji="🪐"),
    W("galaxy",   "nature", "4-5", ["g","æ","l","ə","k","s","i"], 48, emoji="🌌"),
    W("meadow",   "nature", "4-5", ["m","ɛ","d","oʊ"], 46, emoji="🌼"),
    W("jungle",   "nature", "4-5", ["dʒ","ʌ","ŋ","g","ə","l"], 44, emoji="🌴"),
    W("cliff",    "nature", "4-5", ["k","l","ɪ","f"], 46, emoji="⛰"),
    W("library",  "nature", "4-5", ["l","aɪ","b","r","ɛ","r","i"], 46, emoji="📚"),
    W("bakery",   "nature", "4-5", ["b","eɪ","k","ə","r","i"], 44, emoji="🥖"),
    W("museum",   "nature", "4-5", ["m","j","u","z","i","ə","m"], 48, emoji="🏛"),
    W("playground","nature", "4-5", ["p","l","eɪ","g","r","aʊ","n","d"], 44, emoji="🛝"),
    W("station",  "nature", "4-5", ["s","t","eɪ","ʃ","ə","n"], 46, emoji="🚉"),
    W("airport",  "nature", "4-5", ["ɛ","r","p","ɔ","t"], 46, emoji="🛫"),
    W("zoo",      "nature", "4-5", ["z","u"], 42, emoji="🦁"),
    W("farm",     "nature", "4-5", ["f","ɑ","m"], 42, emoji="🚜"),
    W("harbour",  "nature", "4-5", ["h","ɑ","b","ɜ"], 46, emoji="⚓"),
    W("castle",   "nature", "4-5", ["k","æ","s","ə","l"], 48, emoji="🏰"),
]


# ── Emit YAML files ──────────────────────────────────────────────
def esc(s: str) -> str:
    """YAML-safe scalar (quote when needed)."""
    if any(c in s for c in ":#\"'") or s.strip() != s:
        return '"' + s.replace('"', '\\"') + '"'
    return s

def emit_core(entries: list[tuple[str, W]]) -> str:
    lines = [
        "# ══════════════════════════════════════════════════════════════════",
        "# Bolo — Core word list (language-agnostic)",
        "# ══════════════════════════════════════════════════════════════════",
        "#",
        "# Generated by scripts/build_vocabulary.py. Do not hand-edit — edit",
        "# the VOCAB list in the script and re-run.",
        "#",
        "# 300 words · 100 per age band · 8 categories · CDI + ASHA grounded.",
        "# ══════════════════════════════════════════════════════════════════",
        "",
    ]
    current_cat = None
    for wid, w in entries:
        if w.category != current_cat:
            lines.append(f"# ─────────────── {w.category.upper()} ───────────────")
            current_cat = w.category
        lines.append(f"- id: {wid}")
        lines.append(f"  category: {w.category}")
        lines.append(f"  age_band: \"{w.age}\"")
        phon = "[" + ", ".join(esc(p) for p in w.phonemes) + "]"
        lines.append(f"  phoneme_targets_ipa: {phon}")
        lines.append(f"  image: images/words/{wid}.png")
        if w.cdi_rank is not None:
            lines.append(f"  cdi_frequency_rank: {w.cdi_rank}")
        lines.append(f"  asha_milestone_age_months: {w.asha_months}")
        lines.append(f"  universal: {str(w.universal).lower()}")
        if w.emoji:
            lines.append(f"  # placeholder: {w.emoji}")
        lines.append("")
    return "\n".join(lines) + "\n"

def emit_pack(entries: list[tuple[str, W]]) -> str:
    lines = [
        "# ══════════════════════════════════════════════════════════════════",
        "# English pack — word labels + audio paths",
        "# ══════════════════════════════════════════════════════════════════",
        "# Generated by scripts/build_vocabulary.py — do not hand-edit.",
        "# Each entry mirrors an id from ../../core/words.yaml.",
        "# ══════════════════════════════════════════════════════════════════",
        "",
    ]
    current_cat = None
    for wid, w in entries:
        if w.category != current_cat:
            lines.append(f"# ─── {w.category} ────────────────────────────────")
            current_cat = w.category
        # Some labels above suffix a category marker (e.g. `orange-c`); the
        # actual spoken word strips everything after the hyphen.
        spoken = w.en.split("-")[0] if "-" in w.en else w.en
        lines.append(f"{wid}:")
        lines.append(f"  word: {esc(spoken)}")
        lines.append(f"  audio: audio/{wid}.mp3")
        lines.append("")
    return "\n".join(lines) + "\n"


def emit_emoji_dart(entries: list[tuple[str, W]]) -> str:
    """Emit a Dart map of word_id → emoji, used as an art placeholder in
    the naming-game card until Rive assets replace them."""
    lines = [
        "// GENERATED by scripts/build_vocabulary.py — do not hand-edit.",
        "//",
        "// Placeholder emoji per word_id. The naming-game card renders the",
        "// entry from this map when no Rive asset is available for the word.",
        "",
        "const wordEmoji = <String, String>{",
    ]
    for wid, w in entries:
        emoji = w.emoji or "🎯"
        lines.append(f'  "{wid}": "{emoji}",')
    lines.append("};")
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true",
                    help="Print counts, don't write files")
    args = ap.parse_args()

    # Assign stable IDs: word_001 .. word_NNN, in list order.
    entries = [(f"word_{i+1:03d}", w) for i, w in enumerate(VOCAB)]

    # ── Sanity checks ──
    by_age = Counter(w.age for _, w in entries)
    by_cat = Counter(w.category for _, w in entries)
    by_cat_age: Counter[tuple[str, str]] = Counter(
        (w.category, w.age) for _, w in entries
    )

    print(f"Total words:      {len(entries)}")
    print(f"By age band:      {dict(by_age)}")
    print(f"By category:      {dict(by_cat)}")
    print()
    print("By category × age band:")
    cats = sorted({c for c, _ in by_cat_age})
    ages = ["2-3", "3-4", "4-5"]
    header = f"  {'':<12} " + "  ".join(f"{a:>5}" for a in ages) + "  total"
    print(header)
    for c in cats:
        row = f"  {c:<12} "
        row_total = 0
        for a in ages:
            n = by_cat_age.get((c, a), 0)
            row += f"  {n:>5}"
            row_total += n
        row += f"  {row_total:>5}"
        print(row)

    # Word-uniqueness check (spoken label after strip).
    spokens = [w.en.split("-")[0] for _, w in entries]
    dupes = [s for s, c in Counter(spokens).items() if c > 1]
    if dupes:
        print(f"\nWARN: duplicate spoken labels: {dupes}", file=sys.stderr)

    if args.dry_run:
        return 0

    core_path = REPO_ROOT / "assets" / "content" / "core" / "words.yaml"
    pack_path = REPO_ROOT / "assets" / "content" / "packs" / "en" / "words.yaml"
    dart_path = REPO_ROOT / "app" / "lib" / "data" / "generated" / "word_emoji.g.dart"
    dart_path.parent.mkdir(parents=True, exist_ok=True)

    core_path.write_text(emit_core(entries))
    pack_path.write_text(emit_pack(entries))
    dart_path.write_text(emit_emoji_dart(entries))
    print(f"\nWrote {core_path.relative_to(REPO_ROOT)}")
    print(f"Wrote {pack_path.relative_to(REPO_ROOT)}")
    print(f"Wrote {dart_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
