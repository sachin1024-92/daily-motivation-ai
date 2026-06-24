# 🚀 Daily Motivation AI

**Grok-powered daily motivation, habit tracking, focus timers & AI encouragement app.**

Built with Flutter + Riverpod. Ready for Firebase and real Grok/xAI API integration.

## Features (MVP)
- 📅 Daily inspirational quotes (local + extensible to AI)
- ✅ Habit tracking with streaks
- ⏱️ Focus / Pomodoro timer with sessions
- 🤖 AI Chat powered by Grok (simulated + ready for real API)
- 📊 Simple progress & mood check-ins
- 🔒 Offline-first with local persistence
- Dark/light theme support

## Tech Stack
- Flutter 3.x / Dart
- Riverpod for state management
- SharedPreferences for local storage
- HTTP for Grok API calls
- Ready for Firebase (Auth, Firestore, Analytics)

## Getting Started

```bash
git clone https://github.com/sachin1024-92/daily-motivation-ai.git
cd daily-motivation-ai
flutter pub get
flutter run
```

## Configuration (for full features)
1. Get a Grok API key from xAI
2. Add to `lib/services/grok_service.dart`
3. (Optional) Set up Firebase project and uncomment dependencies

## Roadmap
- Real Grok API integration with streaming
- Firebase sync & user accounts
- Voice mode & Wear OS
- Premium subscriptions via Play Store
- Community challenges

## License
MIT

Built in public with Grok. Part of @sachin1024-92 open source tools.