# Daily Motivation AI + FloatNote

Two products in one repository:

1. **FloatNote** (Kotlin) — Play-ready floating notepad for Android  
2. **Daily Motivation AI** (Flutter) — offline-first habits, quotes, focus timer, AI chat

---

## FloatNote (ship first)

[`floating-notepad/`](floating-notepad) is a free, open-source notepad bubble that floats over any app and **autosaves on every keystroke**. Notes never leave the device.

| | |
|---|---|
| Package | `io.github.sachin102492.floatnote` |
| Version | **1.2.0** (versionCode 3) |
| Stack | Kotlin, Views + Material 3, minSdk 26, targetSdk 36 |
| Flavours | `play` (AdMob banner + Play Billing tips) · `foss` (no Google SDKs, no Internet) |
| CI | APK, AAB, FOSS APK on every push; tag → GitHub Release + Play internal upload |

Full feature list, signing, and Play Console steps: [floating-notepad/README.md](floating-notepad/README.md) · [PLAY_STORE.md](floating-notepad/PLAY_STORE.md)

```bash
cd floating-notepad
./gradlew assemblePlayDebug
```

Artifacts: Actions → **FloatNote Android** → `FloatNote.apk` / `FloatNote-foss.apk` / `FloatNote.aab`

---

## Daily Motivation AI (Flutter MVP)

Grok-ready daily motivation app with quotes, habit streaks, focus timers and AI encouragement.

### Status (November 2026)

- Core MVP complete (quotes, habits, focus timer, AI chat structure)
- Offline-first; habit streaks follow the calendar (one tick per day)
- CI runs analysis/tests and builds a test APK on every push
- Live Grok needs a server-side key — do not bake keys into the APK
- Play Store path for this Flutter app: [docs/PLAY_STORE.md](docs/PLAY_STORE.md)

### Features

- Daily inspirational quotes (local + AI-ready)
- Habit tracking with real streaks
- Focus / Pomodoro timer
- AI chat (offline responses; Grok via `--dart-define`)
- Dark / light theme

### Tech

- Flutter 3.x / Dart · Riverpod · SharedPreferences · HTTP for Grok

```bash
git clone https://github.com/sachin1024-92/daily-motivation-ai.git
cd daily-motivation-ai
flutter pub get
flutter run
# optional live Grok:
flutter run --dart-define=GROK_API_KEY=xai-your-key
```

### Roadmap

- [x] Core screens & local state
- [x] GitHub Actions CI (analyze + tests)
- [x] FloatNote native Android app (Play pipeline)
- [ ] Live Grok streaming via a small proxy
- [ ] Flutter Play Store release (after FloatNote launch learnings)

## License

MIT — part of [@sachin1024-92](https://github.com/sachin1024-92) open-source tools.
