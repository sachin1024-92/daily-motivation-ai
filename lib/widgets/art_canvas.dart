import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:daily_motivation_ai/models/media_art.dart';

/// Renders a [MediaArt] as a gradient with soft floating orbs and an emoji.
class ArtCanvas extends StatelessWidget {
  const ArtCanvas({
    super.key,
    required this.art,
    this.emojiSize = 72,
    this.showEmoji = true,
    this.borderRadius,
    this.child,
    this.phase = 0,
  });

  final MediaArt art;
  final double emojiSize;
  final bool showEmoji;
  final BorderRadius? borderRadius;
  final Widget? child;

  /// 0..1 animation phase; rotates the gradient and drifts the orbs.
  final double phase;

  @override
  Widget build(BuildContext context) {
    final angle = phase * 2 * math.pi;
    final begin = Alignment(math.cos(angle), math.sin(angle));
    final colors = art.colors.length == 1 ? [art.colors.first, art.colors.first] : art.colors;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: phase == 0 ? Alignment.topLeft : begin,
          end: phase == 0 ? Alignment.bottomRight : -begin,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _OrbsPainter(seed: art.seed, phase: phase)),
          if (showEmoji)
            Center(
              child: Transform.scale(
                scale: 1 + 0.06 * math.sin(angle * 2),
                child: Text(art.emoji, style: TextStyle(fontSize: emojiSize)),
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );

    // Clip so the orbs never paint outside the artwork's bounds.
    if (borderRadius == null) return ClipRect(child: content);
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

/// An [ArtCanvas] that animates while [playing], used to stand in for video.
class LiveArtCanvas extends StatefulWidget {
  const LiveArtCanvas({
    super.key,
    required this.art,
    this.playing = true,
    this.emojiSize = 96,
    this.period = const Duration(seconds: 8),
    this.child,
  });

  final MediaArt art;
  final bool playing;
  final double emojiSize;
  final Duration period;
  final Widget? child;

  @override
  State<LiveArtCanvas> createState() => _LiveArtCanvasState();
}

class _LiveArtCanvasState extends State<LiveArtCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant LiveArtCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ArtCanvas(
        art: widget.art,
        emojiSize: widget.emojiSize,
        phase: _controller.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({required this.seed, required this.phase});

  final int seed;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final shortest = size.shortestSide;
    for (var i = 0; i < 6; i++) {
      final drift = math.sin((phase + i / 6) * 2 * math.pi) * shortest * 0.04;
      final center = Offset(
        random.nextDouble() * size.width + drift,
        random.nextDouble() * size.height - drift,
      );
      final radius = (0.12 + random.nextDouble() * 0.3) * shortest;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.05 + random.nextDouble() * 0.1);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) => old.seed != seed || old.phase != phase;
}
