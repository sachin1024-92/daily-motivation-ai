import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Orbit Plus subscription products, as created in Play Console under
/// Monetize → Products → Subscriptions.
const String plusMonthlyId = 'orbit_plus_monthly';
const String plusYearlyId = 'orbit_plus_yearly';
const Set<String> plusProductIds = {plusMonthlyId, plusYearlyId};

/// A purchasable Orbit Plus plan with its store price.
class PlusPlan {
  final String id;
  final String title;
  final String price;
  final double rawPrice;
  final String currencyCode;

  const PlusPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
  });

  bool get yearly => id == plusYearlyId;
}

enum PlusEventType { granted, pending, revoked, cancelled, error }

class PlusEvent {
  final PlusEventType type;
  final String? message;

  const PlusEvent(this.type, [this.message]);
}

/// The store Orbit Plus is sold through. [PlayPlusStore] on Android;
/// [UnavailablePlusStore] everywhere else (web, tests, desktop).
abstract class PlusStore {
  Future<bool> isAvailable();

  Future<List<PlusPlan>> loadPlans();

  /// Starts the purchase flow; the outcome arrives on [events].
  Future<void> buy(String planId);

  /// Re-checks the user's active subscriptions; emits [PlusEventType.granted]
  /// or [PlusEventType.revoked].
  Future<void> refresh();

  Stream<PlusEvent> get events;

  void dispose();
}

class UnavailablePlusStore implements PlusStore {
  const UnavailablePlusStore();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<PlusPlan>> loadPlans() async => const [];

  @override
  Future<void> buy(String planId) async {}

  @override
  Future<void> refresh() async {}

  @override
  Stream<PlusEvent> get events => const Stream.empty();

  @override
  void dispose() {}
}

/// Google Play Billing via the official `in_app_purchase` plugin.
///
/// Entitlement is checked on-device against Play's purchase records. Before
/// scaling up, also verify purchase tokens on a server with the Google Play
/// Developer API (see docs/play-store/README.md).
class PlayPlusStore implements PlusStore {
  PlayPlusStore() {
    _subscription = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      _events.add(PlusEvent(PlusEventType.error, '$e'));
    });
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  final _events = StreamController<PlusEvent>.broadcast();
  final Map<String, ProductDetails> _products = {};
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  Stream<PlusEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<PlusPlan>> loadPlans() async {
    final response = await _iap.queryProductDetails(plusProductIds);
    _products.clear();
    for (final p in response.productDetails) {
      // Play returns one entry per base plan/offer; keep the cheapest per product.
      final current = _products[p.id];
      if (current == null || p.rawPrice < current.rawPrice) _products[p.id] = p;
    }
    return [
      for (final id in [plusMonthlyId, plusYearlyId])
        if (_products[id] case final p?)
          PlusPlan(
            id: id,
            title: id == plusYearlyId ? 'Yearly' : 'Monthly',
            price: p.price,
            rawPrice: p.rawPrice,
            currencyCode: p.currencyCode,
          ),
    ];
  }

  @override
  Future<void> buy(String planId) async {
    final product = _products[planId];
    if (product == null) {
      _events.add(const PlusEvent(PlusEventType.error, 'This plan is not available right now.'));
      return;
    }
    // Subscriptions are bought as non-consumables in in_app_purchase.
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> refresh() async {
    final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) return; // Keep the last known state when offline.
    final active = response.pastPurchases.any(
      (p) => plusProductIds.contains(p.productID) && p.status == PurchaseStatus.purchased,
    );
    for (final p in response.pastPurchases) {
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    _events.add(PlusEvent(active ? PlusEventType.granted : PlusEventType.revoked));
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!plusProductIds.contains(p.productID)) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _events.add(const PlusEvent(PlusEventType.pending, 'Payment pending. Plus unlocks as soon as it clears.'));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _events.add(const PlusEvent(PlusEventType.granted));
        case PurchaseStatus.canceled:
          _events.add(const PlusEvent(PlusEventType.cancelled));
        case PurchaseStatus.error:
          _events.add(PlusEvent(PlusEventType.error, p.error?.message ?? 'The purchase did not go through.'));
      }
      // Acknowledge within 3 days or Play refunds the purchase automatically.
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _events.close();
  }
}
