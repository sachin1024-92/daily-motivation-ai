import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bridges Orbit to the rest of your apps (WhatsApp, Telegram, Instagram,
/// Facebook, YouTube, ...) using only public OS mechanisms: the system share
/// sheet and regular links. No private APIs, no scraping.
class ExternalShare {
  /// Opens the system share sheet. Falls back to copying the text when no
  /// share target is available (e.g. desktop builds, tests).
  static Future<void> share(BuildContext context, String text, {String? subject}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(const SnackBar(content: Text('Copied — paste it into any app')));
    }
  }

  /// Opens a profile or page in its own app (or the browser).
  static Future<void> open(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url.toString()));
      messenger?.showSnackBar(SnackBar(content: Text('Link copied: $url')));
    }
  }
}
