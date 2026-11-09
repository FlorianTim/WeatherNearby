# Feature Candidates

Feature candidates emerge from idea triage or are identified directly.
They are not implementation approvals but prioritized proposals for deeper specification.

---

## Candidate Template

```
### <Name>

- **Status:** candidate | specified | rejected
- **Source:** docs/ideas/simple/ideas.md / Issue / conversation
- **Target release:** now | next | v1 | v2 | v3 | later | someday
- **Priority:** high | medium | low
- **Confidence:** high | medium | low

#### Raw input

#### Interpreted intent

#### User value

#### Possible scope

#### Out of scope

#### Open questions

#### Architecture impact

#### Test considerations

#### Recommendation
```

---

## Candidates

### Backup and restore

- **Status:** candidate (lane `next`)
- **Source:** named as a 3.2+ candidate in
  `docs/delivery/implementation-plans/0001-todo-reference-app.md`, and
  deliberately excluded from spec 0005
- **User value:** taking your content to a new device, and getting it back
  after "Delete app data" was tapped by accident.
- **Why it is not in 3.2.1:** the export file format is a compatibility
  promise. Once one version of an app has written a file, every later
  version has to read it — that needs its own spec, its own golden
  fixtures, and a decision about whether it shares the JSCalendar
  interchange format (spec 0004) or defines its own.
- **Architecture impact:** a document share seam already exists
  (`core/platform/platform_seams.dart`); reading a file back does not.

### Real in-app purchases

- **Status:** candidate (lane `next`), blocked on a product decision
- **Source:** ADR-0015 and spec 0007
- **What already exists:** the whole shape — gateway interface, store-less
  default, deterministic fake, entitlement cache with a verification
  timestamp, fail-open gate catalogue, and a Pro page.
- **What is missing:** a configured store account, products, prices, and the
  answer to "what is actually paid?". None of it is a template decision.
- **Effort when it comes:** one dependency, one adapter file, one provider
  override — see
  `docs/architecture/patterns/in-app-purchase-gateway.md`.
