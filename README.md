# 🚀 Daily Motivation AI

**Grok-powered daily motivation, habit tracking, focus timers & AI encouragement app.**

Built with Flutter. Designed for real daily use and future Play Store monetization.

## Current Status (August 2026)

- Core MVP complete (quotes, habits, focus timer, AI chat structure)
- Offline-first architecture ready
- Prepared for real Grok / xAI API integration
- **CI is now green** (analyze + tests pass)
- Next priority: add platform folders → enable APK/AAB builds → Firebase + Play Store

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

### Enable full CI builds (APK + AAB)

The repository currently contains only the Dart source (`lib/`).  
To make the GitHub Actions workflow also build release APK and App Bundle, run this **once** on your local machine (where you already have the full project):

```bash
cd daily-motivation-ai
flutter create . --platforms=android,ios,web
# Review the generated folders, then:
git add android ios web .metadata analysis_options.yaml pubspec.lock
git commit -m "Add platform folders so CI can build APK/AAB"
git push
```

After that, every push to `main` will produce downloadable APK and AAB artifacts.

## Configuration

1. Get a Grok API key from xAI
2. Add it to the Grok service file
3. (Optional) Connect Firebase for cloud sync and user accounts

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
