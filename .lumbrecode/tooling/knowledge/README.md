# Knowledge tooling

Delivered to `.lumbrecode/tooling/knowledge/`. Used by the `/knowledge` skill;
runnable by hand or in CI.

```bash
python -m pip install PyYAML jsonschema

# Check drafts and the local manifest before proposing a publication
python .lumbrecode/tooling/knowledge/validate_knowledge.py docs/knowledge

# Is this change material for the knowledge base? (hint, not verdict)
python .lumbrecode/tooling/knowledge/validate_knowledge.py scope main..HEAD
```

`check` validates frontmatter against
`.lumbrecode/schemas/knowledge/v1/frontmatter.schema.json`, `manifest.yaml`
against `manifest.schema.json`, and the rules a schema cannot express: ID
prefix per type, `implemented` needs `code-verified` evidence, reuse
candidates are not libraries, unique IDs, relationship targets, existing
paths, and publication safety (secrets, personal e-mail addresses, base64
images, outdated or unreviewed screenshots marked as published). Errors exit
1; warnings do not.

`scope` buckets the changed paths of a git range (product, generated code,
tests, docs, screenshots, dependencies, localization, styling, lockfiles,
CI/tooling) and prints `material` or `minor` with reasons. `/knowledge finish` uses it to
recognize a change that needs no central update.

The validator never contacts Google Drive and never writes files.
