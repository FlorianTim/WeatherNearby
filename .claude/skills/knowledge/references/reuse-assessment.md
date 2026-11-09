# Reuse assessment

> IDs, paths and values in the examples on this page are illustrative. They
> are not facts about the named application.

Reuse existing knowledge and implementations before building. Similar code in
two apps is not, by itself, a reason for a shared library.

## Strategies

| Strategy | Use when |
|---|---|
| `REUSE` | the existing implementation fits without design changes |
| `CONFIGURE` | it fits with configuration changes only |
| `EXTEND` | an existing library or reusable component needs new behavior |
| `EXTRACT` | app-specific code should become a reusable module first |
| `ADAPT` | an implementation is a good starting point, copied and changed for this app |
| `BUILD` | nothing suitable exists |

`EXTRACT` must justify itself: a stable abstraction, at least two real
consumers with overlapping needs, and an owner. Otherwise prefer `ADAPT`.

## Criteria

For each candidate weigh: functional coverage, missing functionality, platform
compatibility, dependency compatibility (SDK and package constraints), API
stability, test coverage, maintenance status (last commit, open issues),
security requirements, coupling to app-specific code, integration effort,
extension effort, long-term maintenance cost.

Effort is an estimate: say `S`, `M`, `L` with one line of reasoning, never a
date.

## Matrix

```markdown
| Requirement | Candidate | Reference | Maturity | Coverage | Missing | Strategy | Adaptations | Risks |
|---|---|---|---|---|---|---|---|---|
| Month view | impl.packzeit.calendar | Packzeit apps/mobile_app/lib/features/calendar/ | implemented · test-verified | day/week/month, navigation | recurring events | ADAPT | copy view layer, replace drift DAO | divergence from Packzeit |
```

*Maturity* is always `lifecycle · verification`. A candidate that is only
`specified` is listed, but never as `REUSE`.

## Comparing similar implementations

When two apps implement the same capability (for example a calendar):

1. One `cap.*` entry describes the capability.
2. Each app keeps its own `impl.*` entry and code reference.
3. Compare in a table: supported operations, data model, persistence,
   platforms, tests, coupling.
4. Link them with `similar_to`, never as one implementation.
5. If extraction looks worthwhile, create a `candidate.*` entry with the
   assessment and the estimated work — it is not a library until a package
   exists with a version.

## Libraries

A library entry needs source evidence for: package name (from `pubspec.yaml`
or `package.json`), version, repository and path, publication status (pub.dev,
npm, private git ref, path dependency — check the consumers' dependency
declarations), public API surface (exports), dependencies, known consumers,
and released versus unreleased changes (`git log <last-tag>..HEAD -- <path>`).
