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

## Telegram channel (daily quote cards)

`telegram_bot/post_daily.py` renders today's quote (from `lib/models/quote.dart`) as a 1080×1080 image on a blurred nature photo and posts it to a Telegram channel. The `Telegram Daily Quote` workflow runs it every day at 03:00 UTC.

One-time setup:

1. In Telegram, create a **public channel** (e.g. `@dailymotivationai`).
2. Message [@BotFather](https://t.me/BotFather), send `/newbot`, and copy the token.
3. Add the bot to the channel as an **admin** with permission to post messages.
4. In GitHub → Settings → Secrets and variables → Actions, add:
   - `TELEGRAM_BOT_TOKEN` — the BotFather token
   - `TELEGRAM_CHAT_ID` — the channel's `@username`
   - `PEXELS_API_KEY` — optional, free from [pexels.com/api](https://www.pexels.com/api/); picks nature photos (mountains, forests, oceans…). Without it a random [Lorem Picsum](https://picsum.photos) photo is used, and if no photo can be downloaded a drawn landscape is used.
5. Actions → **Telegram Daily Quote** → Run workflow. Tick *dry run* first to download a preview image, then run it again without it to post.

Preview locally: `pip install -r telegram_bot/requirements.txt && python telegram_bot/post_daily.py --dry-run quote.png`

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
