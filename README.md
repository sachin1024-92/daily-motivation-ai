# 🚀 Daily Motivation AI

**Grok-powered daily motivation, habit tracking, focus timers & AI encouragement app.**

Built with Flutter. Designed for real daily use and future Play Store monetization.

## Current Status (November 2026)

- Core MVP complete (quotes, habits, focus timer, AI chat structure)
- Offline-first architecture ready
- Prepared for real Grok / xAI API integration
- CI runs analysis and tests, and builds a test APK on every push
- Habit streaks follow the calendar: one tick per day, reset after a missed day
- Next priority: Play Store release (see docs/PLAY_STORE.md)

## 🗒️ Also in this repo: FloatNote

[`floating-notepad/`](floating-notepad) contains **FloatNote**, a free, open-source Android notepad bubble that floats over any app and autosaves as you type. See its [README](floating-notepad/README.md) for downloads and build steps.

## Features

- 📅 Daily inspirational quotes (local + AI-ready)
- ✅ Habit tracking with streaks
- ⏱️ Focus / Pomodoro timer with sessions
- 🤖 AI Chat powered by Grok (structure ready for live API)
- 📊 Simple progress & mood check-ins
- 🔒 Offline-first with local persistence
- Dark / light theme support

## Tech Stack

- Flutter 3.x / Dart
- Riverpod for state management
- SharedPreferences for local storage
- HTTP client ready for Grok API
- Architecture prepared for Firebase (Auth, Firestore, Analytics)

## Getting Started

```bash
git clone https://github.com/sachin1024-92/daily-motivation-ai.git
cd daily-motivation-ai
flutter pub get
flutter run
```

### Get an installable APK

Every push and pull request builds a release APK in GitHub Actions. Open the run under the **Actions** tab and download the `daily-motivation-ai-apk-…` artifact to install it on a phone.

That APK is signed with a debug key, which is fine for testing but **not accepted by the Play Store**. See [docs/PLAY_STORE.md](docs/PLAY_STORE.md) for what is still needed before publishing.

## Configuration

The AI chat works offline with built-in responses. To use live Grok responses, pass a key at build time (it is never stored in the repo):

```bash
flutter run --dart-define=GROK_API_KEY=xai-your-key
```

CI builds never include a key; the APKs it produces run in offline mode.

A key compiled into an app can be extracted from the APK. Before a public release, route chat requests through a small server of your own that holds the key.

## Roadmap

- [x] Core screens & local state
- [x] GitHub Actions CI (analyze + tests)
- [ ] Live Grok streaming responses
- [ ] Firebase Auth + cloud habit sync
- [ ] Beautiful onboarding + polish
- [ ] Play Store release (free + premium tiers)
- [ ] Widgets & notifications

## Why This Project Matters

Most motivation apps are either too basic or too subscription-heavy.  
This one combines practical habit tools with real AI encouragement — built by someone who actually uses it daily while doing a Ph.D. and building side income.

## License

MIT

Built in public with Grok. Part of [@sachin1024-92](https://github.com/sachin1024-92) open source tools.
