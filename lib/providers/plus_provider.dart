import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/services/billing_service.dart';

/// Overridden in main() with [PlayPlusStore] on Android.
final plusStoreProvider = Provider<PlusStore>((ref) => const UnavailablePlusStore());

class PlusState {
  final bool active;
  final bool storeAvailable;
  final bool loading;
  final bool purchasing;
  final List<PlusPlan> plans;
  final String? message;

  const PlusState({
    this.active = false,
    this.storeAvailable = false,
    this.loading = true,
    this.purchasing = false,
    this.plans = const [],
    this.message,
  });

  PlusState copyWith({
    bool? active,
    bool? storeAvailable,
    bool? loading,
    bool? purchasing,
    List<PlusPlan>? plans,
    String? message,
    bool clearMessage = false,
  }) {
    return PlusState(
      active: active ?? this.active,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      loading: loading ?? this.loading,
      purchasing: purchasing ?? this.purchasing,
      plans: plans ?? this.plans,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final plusProvider = StateNotifierProvider<PlusNotifier, PlusState>((ref) {
  return PlusNotifier(ref.watch(plusStoreProvider));
});

/// Whether Orbit Plus is active. Most of the app only needs this.
final isPlusProvider = Provider<bool>((ref) => ref.watch(plusProvider).active);

/// Orbit Plus: the subscription that removes ads, lifts the daily AI limit,
/// unlocks premium vibes and features your service listings.
class PlusNotifier extends StateNotifier<PlusState> {
  PlusNotifier(this._store) : super(const PlusState()) {
    _events = _store.events.listen(_onEvent);
    _init();
  }

  static const _key = 'plus_active';

  final PlusStore _store;
  late final StreamSubscription<PlusEvent> _events;

  Future<void> _init() async {
    // Show the last known entitlement immediately, then confirm with the store.
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted && (prefs.getBool(_key) ?? false)) state = state.copyWith(active: true);
    } catch (_) {}
    var available = false;
    var plans = const <PlusPlan>[];
    try {
      available = await _store.isAvailable();
      if (available) {
        plans = await _store.loadPlans();
        await _store.refresh();
      }
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    state = state.copyWith(storeAvailable: available, plans: plans, loading: false);
  }

  Future<void> buy(String planId) async {
    state = state.copyWith(purchasing: true, clearMessage: true);
    try {
      await _store.buy(planId);
    } catch (e) {
      if (mounted) state = state.copyWith(purchasing: false, message: 'The purchase could not start. Try again.');
    }
  }

  Future<void> restore() async {
    state = state.copyWith(clearMessage: true);
    try {
      await _store.refresh();
      if (mounted && !state.active) state = state.copyWith(message: 'No active Orbit Plus subscription found on this Google account.');
    } catch (_) {
      if (mounted) state = state.copyWith(message: 'Could not reach Google Play. Check your connection.');
    }
  }

  void _onEvent(PlusEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case PlusEventType.granted:
        _save(true);
        state = state.copyWith(active: true, purchasing: false, clearMessage: true);
      case PlusEventType.revoked:
        _save(false);
        state = state.copyWith(active: false, purchasing: false);
      case PlusEventType.pending:
        state = state.copyWith(purchasing: true, message: event.message);
      case PlusEventType.cancelled:
        state = state.copyWith(purchasing: false);
      case PlusEventType.error:
        state = state.copyWith(purchasing: false, message: event.message);
    }
  }

  Future<void> _save(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, active);
    } catch (_) {}
  }

  @override
  void dispose() {
    _events.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Daily Orbit AI allowance for the free tier
// ---------------------------------------------------------------------------

const int freeAiMessagesPerDay = 15;

class AiQuota {
  final String day;
  final int used;

  const AiQuota(this.day, this.used);
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

final aiQuotaProvider = StateNotifierProvider<AiQuotaNotifier, AiQuota>((ref) => AiQuotaNotifier());

/// Remaining free Orbit AI messages today; null means unlimited (Plus).
final aiMessagesLeftProvider = Provider<int?>((ref) {
  if (ref.watch(isPlusProvider)) return null;
  final quota = ref.watch(aiQuotaProvider);
  final used = quota.day == _today() ? quota.used : 0;
  return (freeAiMessagesPerDay - used).clamp(0, freeAiMessagesPerDay);
});

class AiQuotaNotifier extends StateNotifier<AiQuota> {
  AiQuotaNotifier() : super(AiQuota(_today(), 0)) {
    _load();
  }

  static const _key = 'ai_quota';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || !mounted) return;
      final parts = raw.split('|');
      if (parts.length == 2 && parts[0] == _today()) state = AiQuota(parts[0], int.tryParse(parts[1]) ?? 0);
    } catch (_) {}
  }

  /// Records one message to Orbit AI.
  void use() {
    final today = _today();
    state = AiQuota(today, (state.day == today ? state.used : 0) + 1);
    SharedPreferences.getInstance().then((p) => p.setString(_key, '${state.day}|${state.used}')).catchError((_) => false);
  }
}
