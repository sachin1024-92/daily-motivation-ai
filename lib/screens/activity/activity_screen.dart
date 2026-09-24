import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/providers/content_providers.dart';
import 'package:daily_motivation_ai/providers/profile_provider.dart';
import 'package:daily_motivation_ai/utils/format.dart';
import 'package:daily_motivation_ai/widgets/avatar.dart';
import 'package:daily_motivation_ai/widgets/common.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  // Remember what was new when the screen opened, so it stays highlighted.
  late final Set<String> _newIds = ref.read(activityProvider).where((a) => !a.read).map((a) => a.id).toSet();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(activityProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(activityProvider);
    final following = ref.watch(followingProvider);
    final fresh = items.where((a) => _newIds.contains(a.id)).toList();
    final earlier = items.where((a) => !_newIds.contains(a.id)).toList();

    Widget tile(ActivityItem item) {
      final actor = ref.watch(userProvider(item.actorId));
      final icon = switch (item.type) {
        ActivityType.like => Icons.favorite_rounded,
        ActivityType.comment => Icons.mode_comment_rounded,
        ActivityType.follow => Icons.person_add_alt_1_rounded,
        ActivityType.mention => Icons.alternate_email_rounded,
        ActivityType.milestone => Icons.celebration_rounded,
      };
      return ListTile(
        leading: GestureDetector(onTap: () => openProfile(context, actor.id), child: OrbitAvatar(user: actor, size: 46)),
        title: Text.rich(
          TextSpan(children: [
            TextSpan(text: actor.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: ' ${item.text}'),
          ]),
        ),
        subtitle: Text(timeAgo(item.at)),
        trailing: item.type == ActivityType.follow && !following.contains(actor.id)
            ? FilledButton(
                onPressed: () => ref.read(followingProvider.notifier).toggle(actor.id),
                child: const Text('Follow back'),
              )
            : Icon(icon, color: Theme.of(context).colorScheme.primary),
        onTap: () => openProfile(context, actor.id),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView(
        children: [
          if (fresh.isNotEmpty) ...[
            const SectionHeader('New', padding: EdgeInsets.fromLTRB(16, 8, 16, 4)),
            for (final item in fresh) tile(item),
          ],
          if (earlier.isNotEmpty) ...[
            const SectionHeader('Earlier', padding: EdgeInsets.fromLTRB(16, 16, 16, 4)),
            for (final item in earlier) tile(item),
          ],
        ],
      ),
    );
  }
}
