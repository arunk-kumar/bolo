# ADR-0001: MVP ships Android-only (Plan B)

- Status: Accepted
- Date: 2026-07-25
- Deciders: Arun Kumar

## Context

The Bolo plan (see `BOLO-PLAN.md`) proposed three ship paths, differing in
which stores to target at MVP:

- Path A: Both Apple App Store + Google Play (Kids Category + Designed for
  Families). Requires Apple Developer Program ($99/yr) + Xcode (~15 GB local
  disk) + iOS-specific compliance work.
- **Path B: Google Play only.** One-time $25 developer fee. No iOS
  toolchain needed. Skip Xcode + CocoaPods locally.
- Path C: Zero-store beta via GitHub Releases + itch.io side-loading. $0 but
  poor fit for a kids app where parents distrust APK side-loading.

## Decision

**Ship Path B (Google Play, Android-only) for MVP.**

## Rationale

1. **Cost minimization.** Path B costs $25 one-time forever versus Path A's
   $99/year recurring. Aligns with the "free-first" principle already agreed
   for tooling choices.
2. **Market coverage.** Google Play holds ~95% of the Indian mobile market;
   the primary MVP audience is Indian families and diaspora. iOS coverage
   loss at MVP is small in absolute terms.
3. **Local footprint.** Skipping Xcode saves ~15 GB of disk plus ongoing
   Xcode updates. Solo developer time is scarcer than disk, but the mental
   overhead of maintaining two native toolchains is real.
4. **Reversible.** iOS can be added post-launch by installing Xcode, paying
   the $99 fee, and adding an `ios/` sub-target to the same Flutter project.
   The architectural cost of "iOS later" is near zero because Flutter shares
   99% of the codebase across platforms.

## Consequences

- **Positive:** Faster MVP path. Lower financial floor. Simpler compliance
  surface (only Google Play "Designed for Families" — not Apple's Kids
  Category on top).
- **Negative:** Diaspora iOS families (typical in US/UK/AU/CA) can't
  install Bolo at MVP. Some brand risk from being perceived as
  "Android-only." Mitigation: clear "iOS coming soon" messaging in the
  landing page.
- **Neutral:** All plan sections that assumed both stores now target only
  Google Play — updated `BOLO-PLAN.md` compliance checklist accordingly.

## Alternatives considered

- Path A rejected: not the current priority given cost sensitivity.
- Path C rejected: side-loading APKs is a red flag for the target audience
  (parents installing on their kids' devices). Not appropriate for
  first impression.

## Related

- `BOLO-PLAN.md` — main plan
- Future ADR: iOS onboarding (when we cross that bridge)
