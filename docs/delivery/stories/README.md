# Stories

Stories are the smallest meaningful implementation units.
Each story should be implementable in one small PR.

## Directory structure

One subfolder per feature: `<NNNN-feature-name>/`
Individual stories within: `story-NNN-<slug>.md`

## Template

See `_template.md` in this folder.

## Rules

- A story is the implementation unit for Copilot.
- A story MUST contain test requirements.
- A story MUST contain acceptance criteria.
- A story MUST have a clear scope and out-of-scope section.
- Code is only changed from approved stories (status: ready).
