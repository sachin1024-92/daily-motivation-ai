# FloatNote: floating notepad for Android

A free, open-source notepad bubble that floats over any app and **autosaves on every keystroke**.
It has no ads, no trackers, and no Internet permission.

## Features

| | |
|---|---|
| **Chat-head bubble** | Drag it anywhere. It moves on spring physics (like Messenger chat heads). |
| **Fling & snap** | Fling it and it springs, with a little bounce, to the nearest screen edge. |
| **Tucks into the side** | After 2.5 s idle it slides half off the edge and fades, so it stays out of the way. Touch it and it comes back. |
| **Magnetic dismiss** | While you drag, a ✕ target rises from the bottom. Get close and the bubble snaps into it with a haptic tick. Let go to hide it. |
| **Grow-from-bubble panel** | Tap the bubble and the notepad scales out of it with an overshoot. Tap outside or press Back and it shrinks back in. |
| **Autosave** | Saves 400 ms after you stop typing, and again when the panel closes, the app pauses, or you switch notes. Files are written atomically, so a crash never corrupts them. |
| **Multiple notes** | Page between notes in the bubble with slide transitions, start a new one, copy, or open it in the app. |
| **Pop-out** | Use "Float this note" in the editor to pop any note into the bubble (like picture-in-picture for text). |
| **Quick Settings tile** | Toggle the bubble from the notification shade. |
| **Material You design** | Amber sticky-note theme with light and dark modes and edge-to-edge layouts. Swipe a note away to delete it, with Undo. |

## Download

Every push builds the app in GitHub Actions (**Actions → FloatNote Android → Artifacts**):

- `FloatNote.apk` is the installable release build.
- `FloatNote.aab` is the App Bundle for Google Play.

To publish a GitHub Release with the APK attached, push a tag:

```bash
git tag floatnote-v1.0.0 && git push origin floatnote-v1.0.0
```

## Build locally

You need Android Studio (or JDK 17 with the Android SDK):

```bash
cd floating-notepad
./gradlew assembleDebug      # app/build/outputs/apk/debug/app-debug.apk
```

## Release signing

Without signing secrets, CI signs release builds with the debug key. They install fine, but
Google Play will not accept them. To sign properly:

```bash
keytool -genkey -v -keystore floatnote.jks -keyalg RSA -keysize 2048 -validity 10000 -alias floatnote
base64 -w0 floatnote.jks   # paste as a secret
```

Add these repository secrets: `FLOATNOTE_KEYSTORE_BASE64`, `FLOATNOTE_KEYSTORE_PASSWORD`,
`FLOATNOTE_KEY_ALIAS`, `FLOATNOTE_KEY_PASSWORD`. **Back up the keystore.** You can never
update the app on Play without it.

## Google Play checklist

The app is built to pass review with the least friction:

- **Target SDK 36**, which Play currently requires for new apps.
- **Display over other apps** is a normal, user-granted permission. The app shows an
  in-app disclosure explaining why before it opens the system setting.
- **Foreground service (`specialUse`)**: in Play Console → *App content → Foreground service
  permissions*, declare **Special use** and describe it as "Keeps the user-enabled floating
  notepad bubble on screen." Include a short video of the bubble in use.
- **Data safety**: *No data collected, no data shared.* There is no INTERNET permission.
- **Privacy policy**: host [`PRIVACY.md`](PRIVACY.md), for example with GitHub Pages, and link it.
- **Store listing text** is in [`fastlane/metadata`](fastlane/metadata/android/en-US). F-Droid
  reads the same folder.

## Keeping it free and still earning something

Earning options that fit an open-source app and keep it Play-policy-safe:

1. **GitHub Sponsors / Ko-fi / Buy Me a Coffee** linked from this README, the GitHub repo,
   and F-Droid. Do *not* put external payment links inside the Play build. Play's payments
   policy requires Play Billing for in-app purchases of digital goods or tips.
2. **Optional "Supporter" tip in Play Billing** (a one-time purchase that unlocks nothing, or
   only cosmetic bubble colours). Everything stays free, and Google takes 15%.
3. **F-Droid + Liberapay/Open Collective**. F-Droid users support privacy-first apps and allow
   donation links in the listing.

Avoid ad SDKs. They would add the INTERNET permission and trackers, and they would break the
app's main selling point: nothing leaves your device.

## Project layout

```
app/src/main/java/io/github/sachin102492/floatnote/
├── data/          Note model + atomic JSON NoteRepository
├── overlay/       FloatingService, OverlayController (bubble physics, panel), QS tile
├── ui/            MainActivity (notes list, bubble switch), EditorActivity
└── util/          AutoSaver (debounced autosave), insets helper
```

Licensed under MIT. Contributions welcome.
