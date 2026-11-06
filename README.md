# 🎓 PrepVerse AI

**One learning app for every goal: JEE, NEET, GATE, SSC/Banking, school (Class 6–10) and career upskilling.**
It has live classes, recorded courses, mock tests, speed quizzes, flashcards, word games, engineering tools and a 24×7 AI doubt solver.

Built with Flutter (Android, iOS and web from one codebase). This app grew out of the *Daily Motivation AI* repo, and the original quotes, habits and focus timer are still here inside the **Study zone**.

## What's inside

| Area | Features |
|---|---|
| **Onboarding** | Pick your name and goal (JEE · NEET · GATE & B.Tech · Govt jobs · School · Upskill). Every screen is then personalised to that goal. |
| **Home** | Streak 🔥, XP and level, quick-start tiles, live and upcoming classes, continue learning, daily GK capsule, quote of the day |
| **Learn** | Exam batches, career programs and free courses. Chapter-wise curriculum with video, notes and practice lessons, a free preview lesson, enrolment, a progress bar per course and a certificate when you finish |
| **Lesson player** | Player with seek and 0.75–2× speed, written notes, "Ask a doubt" and "Practice this chapter" shortcuts, mark complete (+20 XP) |
| **Live classes** | Today's schedule with Join and Remind buttons. The live room has a viewer count, live chat, raise hand and in-class polls that award XP |
| **Practice** | **Speed Quiz** (20 s per question, auto-advances, NCERT-speed style) · **Full Mock Test** (exam timer, +4/−1 marking, question palette, mark for review) · **Daily Quiz** (same 5 questions for everyone that day) · subject-wise practice · bookmarks · test history |
| **Result analysis** | Score ring, correct/wrong/skipped, average time per question, topic-wise accuracy, "focus next on" weak topics, full answer review with explanations |
| **Flashcards** | Leitner-box spaced repetition for formulas and facts |
| **Word Builder** | 90-second vocabulary game for the English/verbal sections |
| **Engineering toolkit** | Quadratic solver, Ohm's law and power, series/parallel resistors, unit converter (length, mass, energy, pressure) |
| **AI Doubt Solver** | Claude-powered step-by-step tutor that knows your exam goal. It falls back to an offline tutor (formula cards, question bank, 7-day revision plan) when no AI is configured or there's no internet |
| **Profile** | Stats, goal switcher, daily study targets (habits), Pomodoro focus timer (+XP), badges, weekly leaderboard, dark mode |

Built-in content: 7 courses, 60 exam-style MCQs with explanations, 26 flashcards, GK capsules and 3 word rounds. Everything is in `lib/data/` so you can expand it.

## Run it

```bash
flutter pub get
flutter run                # Android / iOS device or emulator
flutter run -d chrome      # web
flutter test               # 12 tests: content integrity, logic, widgets
```

## Turn on the online AI tutor

The tutor calls the Claude API (`claude-opus-5-5`). Keys are passed at build time and never committed:

```bash
# Production: run a tiny backend that holds the key and forwards to the Claude Messages API
flutter run --dart-define=AI_PROXY_URL=https://your-backend.example.com/tutor

# Local development only (a key inside an APK can be extracted by anyone)
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

With neither set, the app uses the offline tutor.

## Build the APK

CI (`.github/workflows/flutter-ci.yml`) runs analyze, tests, a release APK and an AAB on every push. Download them from the run's **Artifacts**. To build locally:

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Before publishing to the Play Store, set your own `applicationId` in `android/app/build.gradle.kts` and configure a release signing key.

## Project structure

```
lib/
  data/          goals, courses, question bank, flashcards, live schedule, word rounds
  models/        quiz results, habits, quotes
  providers/     profile + progress (XP, streaks, results, bookmarks, flashcards), habits, theme
  services/      AI tutor (Claude API + offline fallback)
  screens/       home, onboarding, learn/, practice/, live/, doubts, profile, habits, focus
  widgets/       shared UI pieces
```

## Roadmap to production

- Backend (e.g. Firebase or Supabase): auth with phone OTP, cloud sync, a real leaderboard, an admin panel for content
- Video hosting (HLS) with the `video_player` package, offline downloads
- Real-time live classes (WebRTC/LL-HLS) and chat
- Payments (Razorpay or UPI) for batches and programs
- Photo doubts (camera → Claude vision), Hindi and other languages
- Push notifications for class reminders and streaks
