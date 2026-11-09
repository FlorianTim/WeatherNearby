# Contributing

## Branching

- `main` is the protected integration branch.
- Work in short-lived feature branches.
- Use pull requests for all changes.

## Commit style

Follow [Conventional Commits](https://conventionalcommits.org):

| Prefix | Meaning | Version effect |
|--------|---------|----------------|
| `feat:` | New feature | minor |
| `fix:` | Bug fix | patch |
| `docs:` | Documentation only | patch (optional) |
| `refactor:` | Code change without feature/fix | patch |
| `test:` | Test changes only | none |
| `ci:` | CI/CD changes | none |
| `chore:` | Maintenance | none |
| `feat!:` or `BREAKING CHANGE:` | Breaking change | major |

## Pull request checklist

- Scope is clear and limited
- Relevant docs updated
- Tests added or adjusted where reasonable
- CI remains green
- No secrets committed
- ADR added if architecture is affected

## Architecture decisions

Create or update an ADR in `docs/architecture/adr/` when a change affects:

- repository structure
- package boundaries
- runtime architecture
- deployment architecture
- CI/CD strategy
- app state management or navigation conventions

## Versioning

- The current version is in the `VERSION` file
- Update `VERSION` and `CHANGELOG.md` when preparing a release
- Tag releases as `vX.Y.Z`
- See ADR-0003 for the full versioning policy

## Design artifacts

When updating mockups or screenshots:

1. Move the old version to `design/archive/`
2. Place the new version in the appropriate folder
3. Update the manifest in `design/manifests/`

## Generated files

Do not edit directly:
- `docs/architecture/arc42/12-glossary.md` — edit `glossary.csv` instead
- Files under `docs/architecture/generated/` — use build scripts
