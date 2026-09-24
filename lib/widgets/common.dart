import 'package:flutter/material.dart';
import 'package:daily_motivation_ai/app/theme.dart';
import 'package:daily_motivation_ai/models/user.dart';

/// The Orbit wordmark.
class OrbitLogo extends StatelessWidget {
  const OrbitLogo({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return GradientMask(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.blur_circular_rounded, size: size + 2, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'orbit',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints its (white) child with the brand gradient.
class GradientMask extends StatelessWidget {
  const GradientMask({super.key, required this.child, this.gradient = OrbitColors.brandGradient});

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      child: child,
    );
  }
}

/// Display name with a verified tick.
class UserName extends StatelessWidget {
  const UserName({super.key, required this.user, this.style, this.color});

  final OrbitUser user;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle(fontWeight: FontWeight.w700)).copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(user.name, style: textStyle, overflow: TextOverflow.ellipsis)),
        if (user.verified) ...[
          const SizedBox(width: 3),
          Icon(Icons.verified_rounded, size: (textStyle.fontSize ?? 14) + 1, color: OrbitColors.verified),
        ],
      ],
    );
  }
}

/// Pill-shaped button filled with the brand gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon, this.dense = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: OrbitColors.brandGradient,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 20, vertical: dense ? 7 : 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: dense ? 16 : 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: dense ? 13 : 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8)});

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Wraps content so a double tap fires [onDoubleTap] with a heart burst.
class DoubleTapLike extends StatefulWidget {
  const DoubleTapLike({super.key, required this.child, required this.onDoubleTap, this.onTap, this.heartSize = 110});

  final Widget child;
  final VoidCallback onDoubleTap;
  final VoidCallback? onTap;
  final double heartSize;

  @override
  State<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends State<DoubleTapLike> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                final scale = Curves.elasticOut.transform((t * 1.6).clamp(0, 1));
                final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
                return Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: widget.heartSize,
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black38, blurRadius: 24)],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat label used on profiles and cards.
class StatLabel extends StatelessWidget {
  const StatLabel({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
