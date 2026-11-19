# Utility apps

Four small Android apps for everyday life in India, each supported by one AdMob banner.

| App | What it does | Package |
|---|---|---|
| **Seeti** | Listens for the pressure cooker, counts whistles, rings when the dish is done | `io.github.sachin102492.seeti` |
| **Bijli Guard** | Predicts the electricity bill from meter readings, warns before 150 units (MP subsidy), tenant sub-meter bills | `io.github.sachin102492.bijli` |
| **SafeShare ID** | Masks the ID number and QR code on an ID photo and stamps who the copy is for | `io.github.sachin102492.safeshare` |
| **Ghar Clock** | Learns how long the LPG cylinder lasts; reminders for RO, AC, inverter and other home servicing | `io.github.sachin102492.gharclock` |

## How it's built
- Kotlin + Jetpack Compose, minSdk 26, targetSdk 36. One Gradle project; `core/` holds the shared
  ad/consent code, theme and About screen.
- Ads: Google Mobile Ads 23.6.0 with the User Messaging Platform for consent. Debug builds always
  use Google's test ad IDs. Release builds read real IDs from `admob.properties`.
- Every push that touches `utility-apps/` runs `.github/workflows/utility-apps.yml`: unit tests, lint, debug + release APKs and Play
  bundles (`.aab`), then installs all four apps on an Android 14 emulator, walks through their
  screens, saves screenshots, and fails if any app crashes.

## Signing for Google Play
Release bundles are signed with the upload key from four repository secrets:
`UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD`, `UPLOAD_KEY_ALIAS`, `UPLOAD_KEY_PASSWORD`.
Without them the build still works, but its release files can't be uploaded to Play.
The keystore itself is never committed.

## Store listings and privacy
- `docs/store-listings.md`: title, short and full description for each app.
- `docs/privacy/`: one privacy policy per app, to link from Play Console.
