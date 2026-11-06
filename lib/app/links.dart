/// Public links shown in the app and in the Play Store listing.
///
/// The documents live in docs/play-store/ and are served from the default
/// branch, so merge it before submitting to Play.
class OrbitLinks {
  static const supportEmail = 'princendlesster@gmail.com';
  static const _docs = 'https://github.com/sachin1024-92/daily-motivation-ai/blob/main/docs/play-store';
  static final privacyPolicy = Uri.parse('$_docs/privacy-policy.md');
  static final terms = Uri.parse('$_docs/terms-of-service.md');
  static final manageSubscriptions = Uri.parse('https://play.google.com/store/account/subscriptions');
}
