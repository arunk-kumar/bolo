# Core content — language-agnostic

This directory holds the **structural** side of Bolo's content: the schema
of a word, the list of word IDs, developmental milestones, question
templates, and dialog scripts.

**What is NOT here:** the actual translations, audio, or images per
language. Those live in `../packs/<locale>/`.

## Files

| File | Purpose |
|---|---|
| `words.yaml`         | Master list of word IDs with categories, age bands, phoneme targets, image refs |
| `milestones.yaml`    | ASHA-derived developmental milestones (universal; translated in each pack) |
| `questions.yaml`     | WH-question templates (What/Where/Who/Why) — future |
| `dialogs.yaml`       | Turn-taking dialog scripts — future |

## Adding a new word

1. Add a new entry to `words.yaml` with the next `word_XXX` ID.
2. Fill in: `category`, `age_band`, `phoneme_targets_ipa`, `image` path,
   `cdi_frequency_rank` (from MacArthur-Bates CDI), `asha_milestone_age_months`.
3. In **every** language pack under `../packs/`, add either:
   - A translation entry in that pack's `words.yaml`, **or**
   - A skip entry in the pack's `cultural_overrides.yaml` if the word
     doesn't apply in that culture.

## References

- **MacArthur-Bates CDI**: https://mb-cdi.stanford.edu/
- **ASHA developmental norms**: https://www.asha.org/public/speech/development/
- **IPA phoneme chart**: https://www.internationalphoneticassociation.org/content/full-ipa-chart
