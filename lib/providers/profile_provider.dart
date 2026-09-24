import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_motivation_ai/data/seed.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/models/world.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, OrbitUser>((ref) {
  return ProfileNotifier();
});

/// The signed-in user's profile. Persisted locally so edits and linked
/// worlds survive restarts.
class ProfileNotifier extends StateNotifier<OrbitUser> {
  ProfileNotifier() : super(seedMe) {
    _load();
  }

  static const _key = 'profile';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || !mounted) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final worlds = <World, String>{};
      (json['worlds'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        final world = World.values.where((w) => w.name == k);
        if (world.isNotEmpty) worlds[world.first] = v as String;
      });
      state = state.copyWith(
        name: json['name'] as String?,
        handle: json['handle'] as String?,
        bio: json['bio'] as String?,
        worlds: worlds,
      );
    } catch (_) {
      // Corrupt or unavailable storage: keep defaults.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'name': state.name,
          'handle': state.handle,
          'bio': state.bio,
          'worlds': {for (final e in state.worlds.entries) e.key.name: e.value},
        }),
      );
    } catch (_) {}
  }

  Future<void> update({String? name, String? handle, String? bio}) async {
    state = state.copyWith(
      name: name?.trim().isEmpty ?? true ? null : name!.trim(),
      handle: handle?.trim().isEmpty ?? true ? null : handle!.trim().replaceFirst(RegExp(r'^@'), ''),
      bio: bio?.trim(),
    );
    await _save();
  }

  Future<void> setWorld(World world, String? handle) async {
    final worlds = Map<World, String>.of(state.worlds);
    final value = handle?.trim() ?? '';
    if (value.isEmpty) {
      worlds.remove(world);
    } else {
      worlds[world] = value.replaceFirst(RegExp(r'^@'), '');
    }
    state = state.copyWith(worlds: worlds);
    await _save();
  }
}

final usersProvider = Provider<Map<String, OrbitUser>>((ref) {
  return {...seedUsers, meId: ref.watch(profileProvider)};
});

final userProvider = Provider.family<OrbitUser, String>((ref, id) {
  return ref.watch(usersProvider)[id] ??
      OrbitUser(id: id, name: 'Orbit user', handle: id, colors: const [Color(0xFF9E9E9E), Color(0xFF616161)]);
});

final followingProvider = StateNotifierProvider<FollowingNotifier, Set<String>>((ref) {
  return FollowingNotifier();
});

class FollowingNotifier extends StateNotifier<Set<String>> {
  FollowingNotifier() : super(seedFollowing());

  void toggle(String userId) {
    state = state.contains(userId) ? ({...state}..remove(userId)) : {...state, userId};
  }
}
