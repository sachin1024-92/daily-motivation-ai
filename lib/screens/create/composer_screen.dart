import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/reel.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/providers/app_providers.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/services/external_share.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

/// Where an Omni-post can go.
enum PublishTarget { feed, story, reel, channel }

extension PublishTargetInfo on PublishTarget {
  String get label => switch (this) {
        PublishTarget.feed => 'Feed',
        PublishTarget.story => 'Story',
        PublishTarget.reel => 'Reels',
        PublishTarget.channel => 'My channel',
      };

  IconData get icon => switch (this) {
        PublishTarget.feed => Icons.dynamic_feed_rounded,
        PublishTarget.story => Icons.amp_stories_rounded,
        PublishTarget.reel => Icons.slow_motion_video_rounded,
        PublishTarget.channel => Icons.campaign_rounded,
      };
}

/// Omni-post: write once, publish to your feed, story, reels and broadcast
/// channel in one tap — then hand it to any other app if you like.
class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key, this.initialTargets, this.initialText});

  final Set<PublishTarget>? initialTargets;
  final String? initialText;

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  late final TextEditingController _text = TextEditingController(text: widget.initialText ?? '');
  late Set<PublishTarget> _targets = {...?widget.initialTargets};
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];
  int? _palette;
  String _emoji = artEmojis.first;
  bool _poll = false;
  bool _magic = false;

  @override
  void initState() {
    super.initState();
    if (_targets.isEmpty) _targets = {PublishTarget.feed};
    if (_needsArt) _palette = 0;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _needsArt => _targets.contains(PublishTarget.story) || _targets.contains(PublishTarget.reel);

  MediaArt? get _art =>
      _palette == null ? null : MediaArt(colors: artPalettes[_palette!], emoji: _emoji, seed: _palette! * 13 + artEmojis.indexOf(_emoji));

  List<String> get _pollOptions => _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  bool get _canPublish =>
      _targets.isNotEmpty &&
      (_text.text.trim().isNotEmpty || _art != null) &&
      (!_poll || _pollOptions.length >= 2);

  Future<void> _magicCaption() async {
    setState(() => _magic = true);
    final caption = await ref.read(grokServiceProvider).suggestCaption(_text.text);
    if (!mounted) return;
    setState(() => _magic = false);
    _text.text = caption;
  }

  void _publish() {
    final text = _text.text.trim();
    final art = _art;
    final visualArt = art ?? MediaArt(colors: artPalettes.first, emoji: _emoji);
    final now = DateTime.now();
    final me = ref.read(profileProvider);
    String? postId;

    if (_targets.contains(PublishTarget.feed)) {
      postId = newId('p');
      ref.read(feedProvider.notifier).add(
            Post(
              id: postId,
              authorId: meId,
              text: text,
              createdAt: now,
              art: art,
              poll: _poll ? _pollOptions.map(PollOption.new).toList() : const [],
            ),
          );
    }
    if (_targets.contains(PublishTarget.story)) {
      ref.read(storiesProvider.notifier).addToMyStory(
            StoryFrame(id: newId('s'), art: visualArt, caption: text.isEmpty ? _emoji : text, at: now),
          );
    }
    if (_targets.contains(PublishTarget.reel)) {
      ref.read(reelsProvider.notifier).add(
            Reel(id: newId('r'), authorId: meId, caption: text, audio: 'Original audio · ${me.handle}', art: visualArt),
          );
    }
    if (_targets.contains(PublishTarget.channel)) {
      ref.read(chatsProvider.notifier).broadcast(
            postId == null ? text : '',
            attachment: postId == null
                ? null
                : SharedRef(kind: SharedKind.post, id: postId, ownerId: meId, title: text, art: art),
          );
    }

    if (_targets.contains(PublishTarget.feed)) {
      ref.read(shellTabProvider.notifier).state = OrbitTab.home;
    } else if (_targets.contains(PublishTarget.reel)) {
      ref.read(shellTabProvider.notifier).state = OrbitTab.reels;
    }

    final messenger = ScaffoldMessenger.of(context);
    final labels = PublishTarget.values.where(_targets.contains).map((t) => t.label).join(' · ');
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('Published to $labels ✨')));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(profileProvider);
    final subscribers = ref.watch(chatProvider(myChannelId))?.subscribers ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final art = _art;
    final tall = _targets.length == 1 && _needsArt;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Create'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              key: const ValueKey('publish'),
              label: 'Publish',
              dense: true,
              icon: Icons.rocket_launch_rounded,
              onPressed: _canPublish ? _publish : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              OrbitAvatar(user: me, size: 44),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(me.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    _targets.isEmpty
                        ? 'Pick where to publish'
                        : 'Publishing to ${_targets.length} ${_targets.length == 1 ? 'place' : 'places'}',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          TextField(
            key: const ValueKey('composer-text'),
            controller: _text,
            autofocus: widget.initialText == null,
            minLines: 3,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 18, height: 1.35),
            decoration: const InputDecoration(
              hintText: 'What\'s orbiting your mind?',
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('magic-caption'),
              onPressed: _magic ? null : _magicCaption,
              icon: _magic
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('Magic caption'),
            ),
          ),
          if (art != null) ...[
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: AspectRatio(
                  aspectRatio: tall ? 9 / 16 : 1,
                  child: ArtCanvas(
                    art: art,
                    emojiSize: 80,
                    borderRadius: BorderRadius.circular(20),
                    child: _text.text.trim().isEmpty
                        ? null
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _text.text.trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
          const SectionHeader('Vibe', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Swatch(
                  selected: _palette == null,
                  onTap: _needsArt ? null : () => setState(() => _palette = null),
                  child: Icon(Icons.text_fields_rounded, color: _needsArt ? muted.withValues(alpha: 0.4) : muted),
                ),
                for (var i = 0; i < artPalettes.length; i++)
                  _Swatch(
                    key: ValueKey('palette-$i'),
                    selected: _palette == i,
                    colors: artPalettes[i],
                    onTap: () => setState(() => _palette = i),
                  ),
              ],
            ),
          ),
          if (art != null)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in artEmojis)
                    Padding(
                      padding: const EdgeInsets.only(right: 4, top: 8),
                      child: ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 18)),
                        selected: _emoji == e,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _emoji = e),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.poll_rounded),
            title: const Text('Add a poll'),
            subtitle: const Text('Shows on your feed post'),
            value: _poll,
            onChanged: (v) => setState(() => _poll = v),
          ),
          if (_poll) ...[
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  key: ValueKey('poll-option-$i'),
                  controller: _options[i],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: 'Option ${i + 1}'),
                ),
              ),
            if (_options.length < 4)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _options.add(TextEditingController())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add option'),
                ),
              ),
          ],
          const SectionHeader('Publish to', padding: EdgeInsets.fromLTRB(0, 16, 0, 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final target in PublishTarget.values)
                FilterChip(
                  key: ValueKey('target-${target.name}'),
                  avatar: Icon(target.icon, size: 18),
                  label: Text(target.label),
                  selected: _targets.contains(target),
                  showCheckmark: false,
                  onSelected: (on) => setState(() {
                    on ? _targets.add(target) : _targets.remove(target);
                    if (_needsArt && _palette == null) _palette = 0;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Story and Reels use your vibe artwork. My channel broadcasts to ${compactCount(subscribers)} subscribers.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SectionHeader('Beyond Orbit', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share to WhatsApp, Telegram, Instagram & more'),
              subtitle: const Text('Opens your phone\'s share sheet'),
              onTap: _text.text.trim().isEmpty ? null : () => ExternalShare.share(context, _text.text.trim()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({super.key, required this.selected, required this.onTap, this.colors, this.child});

  final bool selected;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2.5),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors == null ? scheme.surfaceContainerHighest : null,
              gradient: colors == null ? null : LinearGradient(colors: colors!),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
