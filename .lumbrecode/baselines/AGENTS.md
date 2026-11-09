# LumbreCode Repository Agent Baseline

## General rules

- Read repository-local architecture and product specifications first.
- Preserve existing terminology and conventions.
- Do not add external runtime services without an approved decision.
- Never store secrets or personal data in code, tests, logs or fixtures.
- Treat generated files according to repository documentation.
- Run the repository's documented quality command.
- Public app documentation belongs under `docs/public-site/`.
- Privacy and legal changes require human approval.
- Report commands run, failures and unverified assumptions.

## Knowledge base

- Before a major feature, check existing solutions with `/knowledge start`;
  after it, consider `/knowledge finish`. Not for routine changes.
- Every documented app keeps an accurate current-state snapshot; reuse the
  app's own docs and screenshots. Central (Google Drive) updates happen at
  milestones and only after approval.
