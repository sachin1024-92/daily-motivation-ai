import 'package:flutter/painting.dart';
import 'package:daily_motivation_ai/models/world.dart';

class OrbitUser {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final List<Color> colors;
  final bool verified;
  final bool online;
  final bool isBot;
  final int followers;
  final int following;
  final Map<World, String> worlds;

  const OrbitUser({
    required this.id,
    required this.name,
    required this.handle,
    this.bio = '',
    required this.colors,
    this.verified = false,
    this.online = false,
    this.isBot = false,
    this.followers = 0,
    this.following = 0,
    this.worlds = const {},
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  OrbitUser copyWith({
    String? name,
    String? handle,
    String? bio,
    Map<World, String>? worlds,
  }) {
    return OrbitUser(
      id: id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      colors: colors,
      verified: verified,
      online: online,
      isBot: isBot,
      followers: followers,
      following: following,
      worlds: worlds ?? this.worlds,
    );
  }
}
