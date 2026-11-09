# Architecture Decision Records (ADRs)

## When to write an ADR

An ADR is created when a durable architecture decision is made, e.g.:

- Export format choice
- Sync strategy
- Local database
- State management
- Authentication
- Backend communication
- Offline strategy
- Major dependency decisions
- Deployment / hosting decisions
- Security / privacy-relevant architecture decisions
- Test strategy for architecture-impacting changes

## Naming convention

`NNNN-slug.md` (e.g. `0008-export-format.md`)

## Template

See `_template.md` in this folder.

## Status values

- proposed
- accepted
- superseded (with reference to successor)
- rejected

## Relationship to arc42

ADRs complement arc42 chapter 09 (Architecture Decisions).
arc42 documents the overall architecture; ADRs document individual decisions with context.
