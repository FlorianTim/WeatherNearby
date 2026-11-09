# iOS Signing mit GitHub Actions

## Grundidee

iOS-Builds laufen auf einem macOS-Runner. Für echte Signierung werden Zertifikat und
Provisioning-Profil als GitHub Secrets bereitgestellt.

## Empfohlene Secret-Namen

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`

## Hinweise

- Zertifikat als `.p12` exportieren und Base64-kodieren
- Provisioning-Profil Base64-kodieren
- niemals diese Artefakte ins Repository legen
- den Build-Workflow erst auf Signierung erweitern, wenn Bundle ID, Team und Profile stabil sind
