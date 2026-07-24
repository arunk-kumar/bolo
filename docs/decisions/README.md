# Architecture Decision Records (ADRs)

Short documents capturing significant technical decisions made on Bolo,
following the [Michael Nygard ADR format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

## Why ADRs

- Preserve context: "why did we do it this way?" answered six months later
- Cheap to write (~15 minutes each), high leverage
- One file per decision — easy to diff, easy to supersede

## Format

Each ADR has:

- **Status** — `Proposed | Accepted | Superseded by ADR-NNNN | Deprecated`
- **Context** — the situation forcing a decision
- **Decision** — the chosen option, in one sentence
- **Rationale** — why this option beats the alternatives
- **Consequences** — what becomes easier / harder because of this decision
- **Alternatives considered** — other options and why they were rejected

## Naming

`NNNN-kebab-case-title.md` where `NNNN` is a zero-padded 4-digit sequence.
Never reuse a number; when superseding, write a new ADR and update the old
one's status to point at the new number.

## Index

- [0001](./0001-plan-b-android-only-mvp.md) — MVP ships Android-only (Plan B)
