---
name: CI conventions
description: Rules for GitHub Actions workflows
applyTo: ".github/workflows/**/*.yml,.github/workflows/**/*.yaml"
---

# CI conventions

- Prefer official GitHub actions when there is a good fit.
- Keep workflows modular and narrowly scoped.
- Upload build outputs as artifacts.
- Avoid hardcoding secrets or environment-specific values.
- Document required secrets in repository docs.
- Fail fast on linting, analyze, or test errors.

## Script syntax validation

Always validate script syntax before merging or releasing. Use these steps in CI or pre-commit hooks:

- **Shell scripts (`.sh`)**: run `shellcheck` on every `.sh` file under `scripts/`.
  ```yaml
  - run: find scripts -name '*.sh' | xargs shellcheck --severity=warning
  ```
- **PowerShell scripts (`.ps1`)**: use the PS parser via `pwsh`.
  ```yaml
  - name: Validate PS1 syntax
    shell: pwsh
    run: |
      $errors = Get-ChildItem scripts -Filter *.ps1 -Recurse |
        ForEach-Object {
          $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$null, [ref]$e)
          $e
        }
      if ($errors) { $errors; exit 1 }
  ```
- **Dart/Flutter**: use `flutter analyze` / `dart analyze` (already in CI).
- **YAML**: use `yamllint` or the built-in YAML parser via the `validate` step.
