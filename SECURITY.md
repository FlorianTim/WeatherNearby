# Security Policy

Publisher: LumbreCode (LumbreCode.de)

Please do not report security issues in public issues. Use GitHub private
vulnerability reporting (Security → Report a vulnerability) or the security
contact documented for the concrete app repository.

## Sensitive files

Never commit:

- `.env` files with real values (commit `.env.example` with placeholder names instead)
- keystores or `.jks` files
- `.p12` certificates
- provisioning profiles
- production service account keys
- API tokens

## Template security baseline

- **Privacy by default:** no analytics, crash reporting, external fonts or
  tracking without an explicit, documented opt-in decision (EU/GDPR-friendly).
- **No external runtime dependencies:** splash Lottie animations and fonts
  are bundled as local assets — never loaded from external URLs at runtime.
- **GitHub Actions:** workflows run with minimal permissions
  (`contents: read` unless a job needs more).
- **Logging:** never log tokens, secrets, session ids or personal data —
  in the Flutter app and in backends.
- **Backend (Node, `backend/`):** validate every request body and all
  environment variables with Zod; limit JSON body size; disable
  `x-powered-by`; follow the
  [OWASP API Security Top 10](https://owasp.org/API-Security/).
- **Mobile:** follow the
  [OWASP MASVS](https://mas.owasp.org/MASVS/) baseline; store secrets in
  platform keychains, not in shared preferences or code.
- **Dependencies:** Dependabot (`.github/dependabot.yml`) updates pub, GitHub Actions and the Node backend (npm); green
  security and minor/patch updates are merged automatically, majors wait for a
  person. `security-scan.yml` (gitleaks, OSV-Scanner) runs on every pull
  request, `dependency-triage.yml` keeps open findings in one issue
  (ADR-0018). Do not add dependencies without justification.

## Third-party licenses

All template dependencies are OSS (see `pubspec.yaml` files and
`backend/package.json`). When shipping an app, generate a license report
(e.g. Flutter's built-in `showLicensePage`) and review transitive licenses.
