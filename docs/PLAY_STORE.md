# Publishing Daily Motivation AI on Google Play

What is done, and what is left. Items marked **you** need the account owner in person: they involve passwords, identity checks, payments or legal agreements.

## Done in this repo

- App runs offline (quotes, habits with real daily streaks, focus timer, chat with built-in responses)
- CI builds a test APK on every push

## Before the first upload

1. **Play Console developer account (you).** Sign in at play.google.com/console with the Google account you publish from, pay the one-time USD 25 fee, and complete identity verification.
2. **Testing requirement (you).** Personal developer accounts created after 13 Nov 2023 must run a closed test with at least 12 testers for 14 days before they can apply for production access. Plan for this; it is the longest step.
3. **Commit the Android project.** Run `flutter create . --platforms=android --org com.sachinmajhee --project-name daily_motivation_ai` once and commit the `android/` folder. The application ID (`com.sachinmajhee.daily_motivation_ai`) is permanent after the first upload, so choose it deliberately.
4. **Upload key (you).** Create a keystore with `keytool`, keep it and its passwords out of the repo, and store them as GitHub secrets so CI can sign an App Bundle (`flutter build appbundle`).
5. **App icon and name.** Replace the default Flutter icon; set the label in `AndroidManifest.xml`.
6. **Privacy policy URL.** Required for every app. This app stores habits on the device only; if live AI chat is enabled, messages are sent to xAI and the policy must say so.
7. **Store listing.** Title, short and full description, at least 2 phone screenshots, a 512×512 icon and a 1024×500 feature graphic.
8. **Console forms (you).** Data safety, content rating, target audience, ads declaration.

## Earning from it

There is no monetization code in the app yet. Realistic options, in order of effort:

- **Ads (AdMob).** Needs an AdMob account (you), the `google_mobile_ads` package, and the ads declaration in the console. Income is small until the app has steady daily users.
- **One-time "Pro" unlock or subscription.** Needs a Play payments profile (you) and the `in_app_purchase` package. Something has to be worth paying for first, for example live AI coaching or unlimited habits.

A free app with a few hundred installs typically earns very little. Treat the first release as a way to learn the publishing process and get real users, not as income.

## Do not ship

- A Grok API key compiled into the app. It can be extracted from the APK and used at your cost. Put a small server between the app and the API first.
