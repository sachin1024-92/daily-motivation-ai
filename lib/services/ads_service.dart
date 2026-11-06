import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';

/// Ad unit for the in-feed card. Pass your AdMob unit at build time:
///   flutter build appbundle --dart-define=ADMOB_FEED_UNIT_ID=ca-app-pub-XXXX/YYYY
const String _feedUnitFromBuild = String.fromEnvironment('ADMOB_FEED_UNIT_ID');

/// Google's public test banner unit, used only in debug builds.
const String _testBannerUnit = 'ca-app-pub-3940256099942544/6300978111';

class AdsConfig {
  final bool enabled;
  final String feedUnitId;

  const AdsConfig({this.enabled = false, this.feedUnitId = ''});
}

/// Disabled unless main() turns ads on (Android builds only).
final adsConfigProvider = Provider<AdsConfig>((ref) => const AdsConfig());

/// Whether to show ad slots right now: ads configured and no Orbit Plus.
final showAdsProvider = Provider<bool>((ref) => ref.watch(adsConfigProvider).enabled && !ref.watch(isPlusProvider));

class AdsService {
  /// Decides whether ads run in this build and starts the SDK in the
  /// background: consent first (GDPR/UK via Google's UMP), then Mobile Ads.
  /// Release builds without a real ad unit show no ads at all.
  static AdsConfig start() {
    final unit = _feedUnitFromBuild.isNotEmpty ? _feedUnitFromBuild : (kReleaseMode ? '' : _testBannerUnit);
    if (unit.isEmpty) return const AdsConfig();
    unawaited(_initialize());
    return AdsConfig(enabled: true, feedUnitId: unit);
  }

  static Future<void> _initialize() async {
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consent.isCompleted) consent.complete();
      },
      (_) {
        if (!consent.isCompleted) consent.complete();
      },
    );
    await consent.future;
    if (await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
    }
  }
}

/// A clearly labelled sponsored card for the feed. Renders nothing until an
/// ad has actually loaded, so a slow or blocked network never leaves a gap.
class FeedAdCard extends ConsumerStatefulWidget {
  const FeedAdCard({super.key, required this.onRemoveAds});

  final VoidCallback onRemoveAds;

  @override
  ConsumerState<FeedAdCard> createState() => _FeedAdCardState();
}

class _FeedAdCardState extends ConsumerState<FeedAdCard> {
  BannerAd? _ad;
  bool _loaded = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = ref.read(adsConfigProvider);
    if (!config.enabled) return;
    bool allowed;
    try {
      allowed = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      allowed = false;
    }
    if (!mounted) return;
    if (!allowed) {
      // Consent may still be loading on first launch; check once more.
      _retry ??= Timer(const Duration(seconds: 4), _load);
      return;
    }
    final ad = BannerAd(
      adUnitId: config.feedUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Sponsored', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(onPressed: widget.onRemoveAds, child: const Text('Remove ads')),
                ],
              ),
              SizedBox(width: 300, height: 250, child: AdWidget(ad: ad)),
            ],
          ),
        ),
      ),
    );
  }
}
