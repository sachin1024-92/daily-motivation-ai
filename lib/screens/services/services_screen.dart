import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/service.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/plus_provider.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

/// Your own listings first (so you see what you just published), then
/// featured listings, then the best rated.
List<OrbitService> _sorted(Iterable<OrbitService> services) {
  int rank(OrbitService s) => s.providerId == meId ? 0 : (s.featured ? 1 : 2);
  return services.toList()
    ..sort((a, b) => rank(a) != rank(b) ? rank(a) - rank(b) : b.rating.compareTo(a.rating));
}

/// The marketplace: people on Orbit offering coaching, shoots, reviews,
/// lessons and more. Requests start a chat with the provider.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(serviceCategoryProvider);
    final all = ref.watch(servicesProvider);
    final visible = _sorted(category == 'All' ? all : all.where((s) => s.category == category));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          TextButton.icon(
            key: const ValueKey('offer-service'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(fullscreenDialog: true, builder: (_) => const OfferServiceScreen()),
            ),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Offer'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: serviceCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(serviceCategories[i]),
                selected: serviceCategories[i] == category,
                showCheckmark: false,
                onSelected: (_) => ref.read(serviceCategoryProvider.notifier).state = serviceCategories[i],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Book people you follow and discover new pros. You agree on timing and payment directly in chat.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          if (visible.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No services here yet. Be the first to offer one.')))
          else
            for (final service in visible) ServiceCard(key: ValueKey(service.id), service: service),
        ],
      ),
    );
  }
}

class ServiceCard extends ConsumerWidget {
  const ServiceCard({super.key, required this.service});

  final OrbitService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(userProvider(service.providerId));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final mine = service.providerId == meId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Card(
        child: InkWell(
          onTap: () => showServiceDetail(context, service.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 76, height: 76, child: ArtCanvas(art: service.art, emojiSize: 34, borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.featured)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: GradientMask(
                            child: Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                          ),
                        ),
                      Text(service.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      UserName(user: provider, style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (service.reviews > 0) '★ ${service.rating.toStringAsFixed(1)} (${compactCount(service.reviews)})',
                          service.mode.label,
                        ].join(' · '),
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: service.priceLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                TextSpan(text: ' ${service.unit}', style: TextStyle(color: muted, fontSize: 12)),
                              ]),
                            ),
                          ),
                          if (!mine)
                            FilledButton.tonal(
                              key: ValueKey('request-${service.id}'),
                              onPressed: () => showRequestSheet(context, service),
                              child: const Text('Request'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact horizontal shelf of top services for the home feed.
class ServicesShelf extends ConsumerWidget {
  const ServicesShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = _sorted(ref.watch(servicesProvider)).take(6).toList();
    if (services.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Book a pro',
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          trailing: TextButton(
            key: const ValueKey('see-all-services'),
            onPressed: () => openServices(context),
            child: const Text('See all'),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = services[i];
              final provider = ref.watch(userProvider(s.providerId));
              return SizedBox(
                width: 150,
                child: GestureDetector(
                  onTap: () => showServiceDetail(context, s.id),
                  child: ArtCanvas(
                    art: s.art,
                    emojiSize: 40,
                    borderRadius: BorderRadius.circular(18),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            Text(
                              '${provider.name.split(' ').first} · ${s.priceLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showServiceDetail(BuildContext context, String serviceId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final service = ref.watch(serviceProvider(serviceId));
        if (service == null) return const SizedBox(height: 200, child: Center(child: Text('This service is no longer listed')));
        final provider = ref.watch(userProvider(service.providerId));
        final mine = service.providerId == meId;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 150, child: ArtCanvas(art: service.art, emojiSize: 64, borderRadius: BorderRadius.circular(20))),
                const SizedBox(height: 14),
                Text(service.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${service.category} · ${service.mode.label}${service.reviews > 0 ? ' · ★ ${service.rating.toStringAsFixed(1)} (${service.reviews} reviews)' : ''}',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                Text(service.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: OrbitAvatar(user: provider, size: 42),
                  title: UserName(user: provider),
                  subtitle: Text('@${provider.handle}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openProfile(context, provider.id);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(service.priceLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text(service.unit, style: TextStyle(color: muted)),
                    const Spacer(),
                    if (mine)
                      OutlinedButton(
                        onPressed: () {
                          ref.read(servicesProvider.notifier).remove(service.id);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Remove listing'),
                      )
                    else
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          showRequestSheet(context, service);
                        },
                        child: const Text('Request'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

const _whenOptions = ['Today', 'Tomorrow', 'This weekend', 'Flexible'];

Future<void> showRequestSheet(BuildContext context, OrbitService service) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RequestSheet(service: service, hostContext: context),
  );
}

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({required this.service, required this.hostContext});

  final OrbitService service;
  final BuildContext hostContext;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  final _note = TextEditingController();
  String _when = _whenOptions.first;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _send() {
    final provider = ref.read(userProvider(widget.service.providerId));
    final chatId = ref.read(chatsProvider.notifier).requestService(
          widget.service,
          providerName: provider.name,
          when: _when,
          note: _note.text,
        );
    Navigator.pop(context);
    openChat(widget.hostContext, chatId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(userProvider(widget.service.providerId));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Request ${widget.service.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${widget.service.priceLabel} ${widget.service.unit} · with ${provider.name}', style: TextStyle(color: muted)),
          const SizedBox(height: 14),
          const Text('When works for you?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in _whenOptions)
                ChoiceChip(label: Text(w), selected: _when == w, showCheckmark: false, onSelected: (_) => setState(() => _when = w)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('request-note'),
            controller: _note,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Anything they should know? (optional)'),
          ),
          const SizedBox(height: 10),
          Text(
            'You\'ll confirm details and payment with ${provider.name.split(' ').first} in chat.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton(key: const ValueKey('request-send'), onPressed: _send, child: const Text('Send request')),
        ],
      ),
    );
  }
}

/// List a service of your own. Featuring a listing is an Orbit Plus perk.
class OfferServiceScreen extends ConsumerStatefulWidget {
  const OfferServiceScreen({super.key});

  @override
  ConsumerState<OfferServiceScreen> createState() => _OfferServiceScreenState();
}

class _OfferServiceScreenState extends ConsumerState<OfferServiceScreen> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _unit = TextEditingController(text: 'per session');
  final _description = TextEditingController();
  String _category = serviceCategories[1];
  ServiceMode _mode = ServiceMode.online;
  bool _featured = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _price, _description]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _price, _unit, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && int.tryParse(_price.text.trim()) != null;

  void _publish() {
    final index = serviceCategories.indexOf(_category);
    final service = OrbitService(
      id: newId('sv'),
      providerId: meId,
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim().isEmpty ? 'Message me to talk through what you need.' : _description.text.trim(),
      price: int.parse(_price.text.trim()),
      unit: _unit.text.trim().isEmpty ? 'per session' : _unit.text.trim(),
      mode: _mode,
      art: MediaArt(colors: artPalettes[index % artPalettes.length], emoji: artEmojis[index % artEmojis.length], seed: index * 7),
      featured: _featured && ref.read(isPlusProvider),
    );
    ref.read(servicesProvider.notifier).add(service);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Your service is live in the marketplace')));
  }

  @override
  Widget build(BuildContext context) {
    final plus = ref.watch(isPlusProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Offer a service'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(key: const ValueKey('publish-service'), label: 'Publish', dense: true, onPressed: _valid ? _publish : null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const ValueKey('service-title'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What do you offer?', hintText: 'e.g. 1:1 guitar lesson'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('service-price'),
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Per'))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in serviceCategories.skip(1))
                ChoiceChip(label: Text(c), selected: _category == c, showCheckmark: false, onSelected: (_) => setState(() => _category = c)),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<ServiceMode>(
            segments: [for (final m in ServiceMode.values) ButtonSegment(value: m, label: Text(m.label))],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Describe it', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.workspace_premium_rounded),
            title: const Text('Feature this listing'),
            subtitle: Text(plus ? 'Shows first in Services and on the home feed' : 'Orbit Plus perk'),
            value: plus && _featured,
            onChanged: (v) => plus ? setState(() => _featured = v) : openPlus(context, reason: 'Featured listings show first to everyone browsing services.'),
          ),
          const SizedBox(height: 8),
          Text(
            'People request your service in chat, and you agree on timing and payment with them directly.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A button that opens Orbit Plus, styled with the brand gradient.
class PlusCta extends StatelessWidget {
  const PlusCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: OrbitColors.brandGradient, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
        title: const Text('Orbit Plus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: const Text('No ads · unlimited AI · featured services', style: TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
      ),
    );
  }
}
