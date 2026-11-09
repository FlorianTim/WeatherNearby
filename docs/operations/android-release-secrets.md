# Android release secrets

How to set up signing and Google Play publishing for the release workflows
(`android-build-release.yml`, `android-publish-play.yml`,
`_android-release-build.yml`).

## Overview

| Secret | Used by | Content |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | build | base64 of the upload keystore (`.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | build | keystore password |
| `ANDROID_KEY_ALIAS` | build | key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | build | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | publish | Google Cloud service account JSON |

Without the keystore secrets the build falls back to **debug signing** —
the workflows still run end-to-end (useful in the template repo), but the
artifacts cannot be uploaded to Play.

## 1. Create the upload keystore (once per app)

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Keep `upload-keystore.jks` in a password manager — **never commit it**.
(`android/key.properties` and `*.jks` are written only at build time and
cleaned up with `if: always()`.)

## 2. Store the signing secrets

```bash
base64 -w0 upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD   # prompts for the value
gh secret set ANDROID_KEY_ALIAS --body "upload"
gh secret set ANDROID_KEY_PASSWORD
```

On Windows (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) |
  gh secret set ANDROID_KEYSTORE_BASE64
```

## 3. Google Play service account (for publishing)

1. Google Cloud Console → create a service account
   (e.g. `play-publisher@<project>.iam.gserviceaccount.com`), create a
   **JSON key**.
2. Google Play Console → *Users and permissions* → invite the service
   account e-mail → grant **Release to testing tracks** (internal) and, if
   desired, **Release to production**.
3. Store the JSON:

   ```bash
   gh secret set PLAY_SERVICE_ACCOUNT_JSON < service-account.json
   ```

## 4. GitHub environments (approval gates)

Create two environments in the repo settings:

- `google-play-internal` — internal testing; no reviewers needed.
- `google-play-production` — add **required reviewers**; production uploads
  then wait for manual approval.

Scope the Play/production secrets to these environments if you want
stricter separation.

## 5. Versioning scheme

Version name/code are derived from the ref by
`scripts/release/resolve_android_version.sh`:

```
release/<maj.min>/<semver>  |  v<semver>  |  <semver>
versionCode = major*10000000 + minor*100000 + patch*1000 + pre
pre: beta.N → N (1..499)  <  rc.N → 500+N  <  final → 999
```

So `1.3.0-beta.1 < 1.3.0-rc.1 < 1.3.0` and the Play versionCode limit
(2.1 billion) is never reached.

## 6. Signing config in build.gradle.kts

The native `android/` folder is generated (not committed in the template).
`tools/patch_android_signing.dart` injects the `key.properties` block after
bootstrap — idempotent, with debug fallback so local
`flutter build apk --release` works without secrets. The release workflows
run it automatically; in a derived app repo that commits `android/`, run it
once and commit the result.
