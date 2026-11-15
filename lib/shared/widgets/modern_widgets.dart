import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class ModernGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const ModernGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColors = isDark
        ? [const Color(0xFF1A1A2E), const Color(0xFF121212), const Color(0xFF0F0F1A)]
        : [const Color(0xFFF8F9FD), const Color(0xFFFFFFFF), const Color(0xFFF0F4FF)];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? defaultColors,
        ),
      ),
      child: child,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool animate;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows,
    this.gradient,
    this.onTap,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final defaultShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: gradient == null
            ? (isDark ? const Color(0xFF242424) : Colors.white)
            : null,
        border: Border.all(
          color: borderColor ?? defaultBorderColor,
          width: borderWidth,
        ),
        boxShadow: shadows ?? defaultShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    if (animate) {
      content = content.animate()
          .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
    }

    return content;
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool animate;
  final int animationIndex;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.shadows,
    this.onTap,
    this.animate = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultShadows = [
      BoxShadow(
        color: gradient.colors.first.withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? defaultShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    if (animate) {
      content = content.animate()
          .fadeIn(duration: 500.ms, delay: (animationIndex * 80).ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.2, duration: 500.ms, delay: (animationIndex * 80).ms, curve: Curves.easeOutCubic);
    }

    return content;
  }
}

class AnimatedStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final Duration itemDuration;
  final Curve itemCurve;

  const AnimatedStaggeredList({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.spacing = 16,
    this.itemDuration = const Duration(milliseconds: 400),
    this.itemCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: scrollDirection,
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (_, __) => SizedBox(
        height: scrollDirection == Axis.vertical ? spacing : 0,
        width: scrollDirection == Axis.horizontal ? spacing : 0,
      ),
      itemBuilder: (context, index) {
        return children[index].animate()
            .fadeIn(duration: itemDuration, delay: (index * 60).ms, curve: itemCurve)
            .slideY(begin: 0.15, duration: itemDuration, delay: (index * 60).ms, curve: itemCurve);
      },
    );
  }
}

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Gradient? gradient;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double titleSpacing;
  final TextStyle? titleStyle;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.gradient,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.titleSpacing = 0,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF1E1E1E).withValues(alpha: 0.95), const Color(0xFF121212).withValues(alpha: 0.9)]
          : [Colors.white.withValues(alpha: 0.95), const Color(0xFFF8F9FD).withValues(alpha: 0.9)],
    );

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.primary,
      titleSpacing: titleSpacing,
      titleTextStyle: titleStyle ??
          TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: foregroundColor ?? Theme.of(context).colorScheme.primary,
            letterSpacing: -0.5,
          ),
      leading: leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? defaultGradient,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ModernFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Gradient? gradient;
  final double size;
  final bool mini;

  const ModernFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.gradient,
    this.size = 56,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF4DA6FF), const Color(0xFF0066CC)]
          : [const Color(0xFF0066CC), const Color(0xFF004499)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: (gradient ?? defaultGradient).colors.first.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(child: icon),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final List<BoxShadow>? shadows;
  final bool animate;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    this.borderRadius = 12,
    this.elevation = 2,
    this.shadows,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultShadows = [
      BoxShadow(
        color: gradient.colors.first.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? defaultShadows,
      ),
      child: Center(child: child),
    );

    if (onPressed != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    if (animate) {
      content = content.animate().scale(duration: 300.ms, curve: Curves.easeOutCubic);
    }

    return content;
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final int animationIndex;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ).animate()
                .fadeIn(duration: 400.ms, delay: (animationIndex * 80).ms)
                .slideX(begin: -0.1, duration: 400.ms, delay: (animationIndex * 80).ms),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ).animate()
                  .fadeIn(duration: 400.ms, delay: (animationIndex * 80 + 50).ms)
                  .slideX(begin: -0.1, duration: 400.ms, delay: (animationIndex * 80 + 50).ms),
            ],
          ],
        ),
        if (action != null)
          action!.animate()
              .fadeIn(duration: 400.ms, delay: (animationIndex * 80).ms)
              .slideX(begin: 0.1, duration: 400.ms, delay: (animationIndex * 80).ms),
      ],
    );
  }
}

class ModernChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Gradient? selectedGradient;
  final VoidCallback? onTap;
  final Color? unselectedColor;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.selectedGradient,
    this.onTap,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF4DA6FF), const Color(0xFF0066CC)]
          : [const Color(0xFF0066CC), const Color(0xFF004499)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected ? (selectedGradient ?? defaultGradient) : null,
        color: selected ? null : (unselectedColor ?? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0))),
        borderRadius: BorderRadius.circular(24),
        border: !selected
            ? Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              )
            : null,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: (selectedGradient ?? defaultGradient).colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutCubic);
  }
}

class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    required this.gradient,
    this.backgroundColor = const Color(0xFFE8E8E8),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0, 1),
              strokeWidth: strokeWidth,
              gradient: gradient,
              backgroundColor: backgroundColor,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _ProgressRingPainter &&
        oldDelegate.progress != progress;
  }
}

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            baseColor ?? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0)),
            highlightColor ?? (isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0)),
            baseColor ?? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0)),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.transparent);
  }
}

extension ShimmerExtension on Widget {
  Widget shimmer({Duration duration = const Duration(milliseconds: 1500), Color color = Colors.transparent}) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [color, color.withValues(alpha: 0.3), color],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5, 0),
          end: Alignment(1.5, 0),
          transform: GradientRotation(0),
        ).createShader(bounds);
      },
      child: this,
    );
  }
}