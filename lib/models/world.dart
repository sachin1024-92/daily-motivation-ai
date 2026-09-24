import 'package:flutter/material.dart';

/// External social "worlds" a person can link to their Orbit identity.
///
/// Orbit does not scrape or proxy other networks. Instead it links your
/// handles (so friends can jump to you anywhere) and hands content off to
/// installed apps through the OS share sheet.
enum World { facebook, instagram, whatsapp, telegram, youtube }

extension WorldInfo on World {
  String get label => switch (this) {
        World.facebook => 'Facebook',
        World.instagram => 'Instagram',
        World.whatsapp => 'WhatsApp',
        World.telegram => 'Telegram',
        World.youtube => 'YouTube',
      };

  IconData get icon => switch (this) {
        World.facebook => Icons.facebook,
        World.instagram => Icons.camera_alt_rounded,
        World.whatsapp => Icons.chat_rounded,
        World.telegram => Icons.telegram,
        World.youtube => Icons.smart_display_rounded,
      };

  Color get color => switch (this) {
        World.facebook => const Color(0xFF1877F2),
        World.instagram => const Color(0xFFE1306C),
        World.whatsapp => const Color(0xFF25D366),
        World.telegram => const Color(0xFF229ED9),
        World.youtube => const Color(0xFFFF0033),
      };

  String get hint => switch (this) {
        World.whatsapp => 'Phone number with country code',
        World.youtube => 'Channel handle',
        _ => 'Username',
      };

  /// Public profile URL for a handle on this world.
  Uri profileUrl(String handle) {
    final h = handle.trim().replaceFirst(RegExp(r'^@'), '');
    return switch (this) {
      World.facebook => Uri.https('facebook.com', '/$h'),
      World.instagram => Uri.https('instagram.com', '/$h'),
      World.whatsapp => Uri.https('wa.me', '/${h.replaceAll(RegExp(r'[^0-9]'), '')}'),
      World.telegram => Uri.https('t.me', '/$h'),
      World.youtube => Uri.https('youtube.com', '/@$h'),
    };
  }
}
