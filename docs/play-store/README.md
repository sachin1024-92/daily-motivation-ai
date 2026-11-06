# Publishing Orbit on Google Play

Everything in this folder gets Orbit from this repo onto Google Play under the **princendlesster@gmail.com** developer account, set up to earn money from day one.

| File | What it is |
| --- | --- |
| `listing.md` | Store listing text, category and contact details |
| `privacy-policy.md` | Privacy policy (Play requires a public URL; use this file's GitHub link on `main`) |
| `terms-of-service.md` | Terms, including subscription and marketplace terms |
| `graphics/` | 512 px icon, 1024×500 feature graphic, 1080×1920 screenshots |

The app is set up for Play:

- Package `com.princendlesster.orbit`, version 2.0.0 (code 2), targets Android 16 (API 36).
- Release builds are signed with the upload key from `android/key.properties`. That file and the keystore are git-ignored. Back them up somewhere safe.
- Google Play Billing for Orbit Plus, AdMob ads with Google's consent form, and core library desugaring are wired in.

## How Orbit makes money

| Stream | How it works | Where in the app |
| --- | --- | --- |
| **Orbit Plus subscription** (primary) | Google Play subscriptions `orbit_plus_monthly` and `orbit_plus_yearly`. Perks: no ads, unlimited Orbit AI (free tier: 15 messages/day), premium vibes, Plus badge, featured service listings. | Profile → Orbit Plus card, Settings, the AI limit, locked vibes, "Feature this listing", "Remove ads" |
| **Ads** | A clearly labelled AdMob card after every fourth feed post for free users. Off until you supply real AdMob IDs, so you never ship test ads. | Home feed |
| **Services marketplace** (people-first) | People list coaching, shoots, lessons and more; others request them in chat. Payment for real-world services happens between the two people, which Play allows outside Google Play Billing. Featured placement is a Plus perk now; a booking fee or commission can come later with a payment provider. | Home → "Book a pro", storefront icon, profiles, search |

Suggested starting prices for India (Play converts for other countries): **₹99/month** and **₹799/year** (the yearly plan shows "Save 33%" automatically).

## Step by step

### 1. Developer account (one time, in a browser)

1. Sign in to https://play.google.com/console with **princendlesster@gmail.com**.
2. Create the developer account: pay the one-time US$25 fee and finish identity verification (government ID; can take a few days).
3. New **personal** accounts must run a **closed test with at least 12 testers for 14 days** before Play allows a production release. Check the current number in Play Console, and start recruiting testers now (friends, family, a WhatsApp or Telegram group).
4. Set up a **payments profile** (Settings → Payments profile) so you can sell subscriptions and get paid. Add your bank account and tax details.

### 2. Create the app

1. **Create app** → name `Orbit: Feed, Reels & Chat`, default language English, **App**, **Free**, accept the declarations.
2. **Testing → Internal testing → Create new release.** Accept **Play App Signing**, then upload `app-release.aab`. The first upload must be done by hand; it registers the package name `com.princendlesster.orbit`.
3. Add your own Gmail as an internal tester, open the opt-in link on your phone and install. This is the fastest way to try billing for real.

### 3. App content (Policy → App content)

| Section | Answer |
| --- | --- |
| Privacy policy | `https://github.com/sachin1024-92/daily-motivation-ai/blob/main/docs/play-store/privacy-policy.md` (merge this branch into `main` first) |
| Ads | **Yes, my app contains ads** if you enable AdMob (step 5); otherwise No, and change it when you turn ads on |
| App access | All functionality is available without special access |
| Content rating | Fill in the IARC questionnaire. Category: Social / Communication. Users can share content to other apps. No violence, gambling or mature content. Expect a Teen-level rating. |
| Target audience | **18 and over**. This keeps Orbit outside the Families policy, which restricts ads and data collection for children. |
| News app | No |
| Data safety | See the table below |
| Advertising ID | **Yes**, used for advertising (the AdMob SDK declares the AD_ID permission) |
| Financial features | None |
| Government app | No |

**Data safety answers** (for the current build):

| Question | Answer |
| --- | --- |
| Does your app collect or share user data? | Yes (because of AdMob) |
| Encrypted in transit? | Yes |
| Can users request deletion? | Yes, in-app (Settings → Delete my data) |
| Device or other IDs | Collected and shared: Advertising, Analytics (AdMob) |
| Approximate location | Collected and shared: Advertising (AdMob, from IP address) |
| App interactions, Crash logs, Diagnostics | Collected: Analytics, Advertising (AdMob) |
| Purchase history | Processed by Google Play; not collected by Orbit |
| Everything else (name, email, messages, photos, contacts) | Not collected. Stays on the device. |

If you ship without ads, answer "No data collected" except what Google Play itself handles.

### 4. Orbit Plus subscriptions (Monetize → Products → Subscriptions)

Create two subscriptions with these **exact IDs** (the app looks for them):

| Product ID | Base plan | Price (India) |
| --- | --- | --- |
| `orbit_plus_monthly` | `monthly`, auto-renewing, 1 month | ₹99 |
| `orbit_plus_yearly` | `yearly`, auto-renewing, 1 year | ₹799 |

Optional: add a 7-day free-trial offer to the yearly plan. Activate both. Add your Gmail under **Settings → License testing** to buy them for free while testing.

### 5. Turn on ads (AdMob)

1. At https://admob.google.com (same Google account), add an Android app linked to the Play listing and create one **Banner** ad unit (medium rectangle) named "Feed".
2. Build with your IDs (they are public identifiers, not secrets):

   ```bash
   ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY \
   flutter build appbundle --release --dart-define=ADMOB_FEED_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
   ```

3. In AdMob → Privacy & messaging, create a **GDPR consent message**. The app already shows it to EEA/UK users.
4. Add an `app-ads.txt` line to a website listed on your store listing once you have one.

### 6. Store listing and release

1. Paste the text from `listing.md` and upload the files from `graphics/`.
2. Promote the internal build to **Closed testing**, add your 12+ testers, and keep it running for 14 days.
3. Then **Production → Create release** (or promote the tested build), roll out, and send for review. Reviews usually take a few days for a new app.

### 7. Ship updates from GitHub

`.github/workflows/play-release.yml` builds a signed bundle and uploads it to any track. Add these repository secrets (GitHub → Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | `base64 -w0 orbit-upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password (the same as the keystore password for the provided key) |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key of a Google Cloud service account invited in Play Console → Users and permissions with "Release apps" access |
| `ADMOB_APP_ID`, `ADMOB_FEED_UNIT_ID` | Optional; ads stay off without them |

Then run **Actions → Play release → Run workflow** and pick a track. Version codes are set automatically from the run number.

## Before this earns real money

- **Real users need a real backend.** Today posts and chats are local and the community is sample content, so the app is honest about being a preview. The highest-value next step is a backend (for example Firebase Auth + Firestore) so people actually follow, message and book each other, plus reporting and blocking for user content.
- **Verify purchases on a server.** The app checks Plus with Google Play on the device. Once there is a backend, verify purchase tokens with the Google Play Developer API and listen to Real-time developer notifications.
- **Payments for services.** To take a booking fee or commission on real-world services, add a payment provider such as Razorpay or Stripe. Play allows this for physical services; digital goods must keep using Google Play Billing.
