# Daily Motivation AI

Flutter app for daily quotes, habit streaks, a focus timer, and offline AI encouragement (Grok-ready).

**This repository is only the Flutter motivation app.** Other Android apps that were briefly nested here have been moved out:

| App | New home |
|---|---|
| **FloatNote** (Play-ready floating notepad) | [vitacreate-ai](https://github.com/sachin1024-92/vitacreate-ai) — rename that repo to `floatnote` in Settings |
| **Seeti / Bijli Guard / SafeShare / Ghar Clock** | [content-automation-tools](https://github.com/sachin1024-92/content-automation-tools) — rename to `utility-apps` in Settings |
| **Lesster suite** (policies) | [lesster-apps](https://github.com/sachin1024-92/lesster-apps) |

## Status (November 2026)

- Core MVP: quotes, habits (calendar streaks), focus timer, AI chat structure
- Offline-first; live Grok needs a server-side key (never bake keys into the APK)
- CI: analyze + test on every push; APK build when the Android project is present

## Features

- Daily inspirational quotes (local + AI-ready)
- Habit tracking with real streaks
- Focus / Pomodoro timer
- AI chat (offline responses; optional Grok via `--dart-define`)
- Dark / light theme

## Tech

Flutter 3.x / Dart · Riverpod · SharedPreferences · HTTP for Grok

```bash
git clone https://github.com/sachin1024-92/daily-motivation-ai.git
cd daily-motivation-ai
flutter pub get
flutter run
# optional live Grok:
flutter run --dart-define=GROK_API_KEY=xai-your-key
```

Play Store notes for this Flutter app: [docs/PLAY_STORE.md](docs/PLAY_STORE.md)

## License

MIT — [@sachin1024-92](https://github.com/sachin1024-92)
