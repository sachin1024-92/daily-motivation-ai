import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/screens/create/composer_screen.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';

/// Instagram stories / WhatsApp status row.
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(storiesProvider);
    final users = ref.watch(usersProvider);
    final me = users[meId]!;
    final hasMine = groups.any((g) => g.userId == meId);
    final others = groups.where((g) => g.userId != meId).toList()
      ..sort((a, b) => a.seen == b.seen ? 0 : (a.seen ? 1 : -1));
    final order = others.map((g) => g.userId).toList();

    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _StoryBubble(
            key: const ValueKey('story-me'),
            user: me,
            label: 'Your story',
            ring: hasMine ? StoryRing.unseen : StoryRing.none,
            showAdd: true,
            onTap: () => hasMine
                ? openStories(context, [meId])
                : openComposer(context, targets: {PublishTarget.story}),
          ),
          for (var i = 0; i < others.length; i++)
            _StoryBubble(
              key: ValueKey('story-${others[i].userId}'),
              user: users[others[i].userId]!,
              label: users[others[i].userId]!.name.split(' ').first,
              ring: others[i].seen ? StoryRing.seen : StoryRing.unseen,
              onTap: () => openStories(context, order, initialIndex: i),
            ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    super.key,
    required this.user,
    required this.label,
    required this.ring,
    required this.onTap,
    this.showAdd = false,
  });

  final OrbitUser user;
  final String label;
  final StoryRing ring;
  final VoidCallback onTap;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                OrbitAvatar(user: user, size: ring == StoryRing.none ? 66 : 60, ring: ring),
                if (showAdd)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: OrbitColors.brandGradient),
                        child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: ring == StoryRing.unseen ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
