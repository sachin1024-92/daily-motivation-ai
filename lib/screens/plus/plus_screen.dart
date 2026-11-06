import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/links.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';
import 'package:daily_motivation_ai/services/billing_service.dart';
import 'package:daily_motivation_ai/services/external_share.dart';

const _perks = [
  (Icons.block_rounded, 'No ads, anywhere', 'A clean feed and uninterrupted video.'),
  (Icons.auto_awesome_rounded, 'Unlimited Orbit AI', 'Free accounts get $freeAiMessagesPerDay messages a day.'),
  (Icons.palette_rounded, 'Premium vibes', 'Exclusive gradients for posts, stories and reels.'),
  (Icons.storefront_rounded, 'Featured services', 'Your service listings show first in the marketplace.'),
  (Icons.workspace_premium_rounded, 'Plus badge', 'Stand out on your profile.'),
];

/// Orbit Plus paywall, sold through Google Play subscriptions.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key, this.reason});

  /// Why the paywall opened, e.g. "You've used today's free AI messages."
  final String? reason;

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final plus = ref.watch(plusProvider);
    final plans = plus.plans;
    final selected = _selected ?? (plans.any((p) => p.yearly) ? plusYearlyId : plans.firstOrNull?.id);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    PlusPlan? monthly;
    for (final p in plans) {
      if (!p.yearly) monthly = p;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Orbit Plus')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: OrbitColors.brandGradient, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                Text(
                  plus.active ? 'You\'re on Orbit Plus' : 'Get more from Orbit',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reason ?? (plus.active ? 'Thanks for supporting Orbit. All perks are unlocked.' : 'Go ad-free, chat with Orbit AI as much as you like, and grow your services.'),
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (plus.active)
            OutlinedButton.icon(
              onPressed: () => ExternalShare.open(context, OrbitLinks.manageSubscriptions),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Manage subscription in Google Play'),
            )
          else if (plus.loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (!plus.storeAvailable || plans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Orbit Plus is sold through Google Play. Plans appear here in the Android app once they are live in your region.',
                  style: TextStyle(color: muted),
                ),
              ),
            )
          else ...[
            for (final plan in plans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanTile(
                  plan: plan,
                  selected: plan.id == selected,
                  badge: plan.yearly && monthly != null && monthly.rawPrice > 0
                      ? 'Save ${(100 - plan.rawPrice / (monthly.rawPrice * 12) * 100).round()}%'
                      : null,
                  onTap: () => setState(() => _selected = plan.id),
                ),
              ),
            const SizedBox(height: 6),
            FilledButton(
              key: const ValueKey('plus-subscribe'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: plus.purchasing || selected == null ? null : () => ref.read(plusProvider.notifier).buy(selected),
              child: plus.purchasing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
          if (plus.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(plus.message!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error)),
            ),
          if (!plus.active)
            TextButton(
              onPressed: () => ref.read(plusProvider.notifier).restore(),
              child: const Text('Restore purchases'),
            ),
          const SizedBox(height: 4),
          const Text('What you get', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          for (final (icon, title, body) in _perks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: scheme.primary),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(body),
            ),
          const SizedBox(height: 8),
          Text(
            'Payment is charged to your Google Play account. The subscription renews automatically '
            'at the same price unless you cancel at least 24 hours before the period ends. Cancel anytime '
            'in Google Play: Payments & subscriptions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => ExternalShare.open(context, OrbitLinks.terms), child: const Text('Terms')),
              TextButton(onPressed: () => ExternalShare.open(context, OrbitLinks.privacyPolicy), child: const Text('Privacy')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.selected, required this.onTap, this.badge});

  final PlusPlan plan;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            Text('${plan.price}${plan.yearly ? '/yr' : '/mo'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
