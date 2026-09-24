import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_motivation_ai/services/grok_service.dart';

final grokServiceProvider = Provider<GrokService>((ref) => GrokService());

/// Bottom navigation tabs of the shell.
enum OrbitTab { home, reels, watch, chats }

final shellTabProvider = StateProvider<OrbitTab>((ref) => OrbitTab.home);
