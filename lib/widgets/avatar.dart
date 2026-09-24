import 'package:flutter/material.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/widgets/art_canvas.dart';

enum StoryRing { none, unseen, seen }

/// Gradient initials avatar with optional story ring and online dot.
class OrbitAvatar extends StatelessWidget {
  const OrbitAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.ring = StoryRing.none,
    this.showOnline = false,
  });

  final OrbitUser user;
  final double size;
  final StoryRing ring;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: user.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: user.isBot
          ? Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5)
          : Text(
              user.initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
                letterSpacing: -0.5,
              ),
            ),
    );
    return _decorate(context, core, size, ring, showOnline && user.online);
  }
}

/// Circular avatar for groups and channels.
class ArtAvatar extends StatelessWidget {
  const ArtAvatar({super.key, required this.art, this.size = 40});

  final MediaArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ArtCanvas(
        art: art,
        emojiSize: size * 0.45,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

/// Picks the right avatar for any chat.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.chat, required this.peer, this.size = 52});

  final Chat chat;
  final OrbitUser? peer;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (peer != null && (chat.kind == ChatKind.direct || chat.kind == ChatKind.bot)) {
      return OrbitAvatar(user: peer!, size: size, showOnline: true);
    }
    return ArtAvatar(art: chat.art ?? const MediaArt(colors: OrbitColors.brand, emoji: '💬'), size: size);
  }
}

Widget _decorate(BuildContext context, Widget core, double size, StoryRing ring, bool online) {
  final background = Theme.of(context).scaffoldBackgroundColor;
  Widget result = core;
  if (ring != StoryRing.none) {
    final ringWidth = size > 56 ? 3.0 : 2.4;
    result = Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring == StoryRing.unseen ? OrbitColors.brandGradient : null,
        color: ring == StoryRing.seen ? Colors.grey.withValues(alpha: 0.45) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: core,
      ),
    );
  }
  if (!online) return result;
  final dot = size * 0.28;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      result,
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: OrbitColors.online,
            shape: BoxShape.circle,
            border: Border.all(color: background, width: dot * 0.18),
          ),
        ),
      ),
    ],
  );
}
