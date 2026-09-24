import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/app/navigation.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/providers/app_providers.dart';
import 'package:daily_motivation_ai/providers/chats_provider.dart';
import 'package:daily_motivation_ai/screens/chats/chats_screen.dart';
import 'package:daily_motivation_ai/screens/feed/feed_screen.dart';
import 'package:daily_motivation_ai/screens/reels/reels_screen.dart';
import 'package:daily_motivation_ai/screens/watch/watch_screen.dart';

/// Home · Reels · Create · Watch · Chats — every way to connect, one app.
class OrbitShell extends ConsumerWidget {
  const OrbitShell({super.key});

  static const _pages = <OrbitTab, Widget>{
    OrbitTab.home: FeedScreen(),
    OrbitTab.reels: ReelsScreen(),
    OrbitTab.watch: WatchScreen(),
    OrbitTab.chats: ChatsScreen(),
  };

  // Navigation bar slots; slot 2 is the Create button, not a tab.
  static const _slots = [OrbitTab.home, OrbitTab.reels, null, OrbitTab.watch, OrbitTab.chats];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    final unread = ref.watch(unreadChatsProvider);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: [
          for (final t in OrbitTab.values) TickerMode(enabled: t == tab, child: _pages[t]!),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _slots.indexOf(tab),
        onDestinationSelected: (i) {
          final target = _slots[i];
          if (target == null) {
            openComposer(context);
          } else {
            ref.read(shellTabProvider.notifier).state = target;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.slow_motion_video_outlined),
            selectedIcon: Icon(Icons.slow_motion_video_rounded),
            label: 'Reels',
          ),
          NavigationDestination(
            icon: Container(
              key: const ValueKey('nav-create'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: OrbitColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
            label: 'Create',
          ),
          const NavigationDestination(
            icon: Icon(Icons.smart_display_outlined),
            selectedIcon: Icon(Icons.smart_display_rounded),
            label: 'Watch',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}
