import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/humsafar_colors.dart';

/// Loading-state ("skeleton") widgets — Sarim's 22 Nov design handoff,
/// `docs/design/handoff/README.md`'s "Loading states (skeleton screens)"
/// section: grey placeholder shapes (`tabTrack` on `surface`, `border`
/// outline) with a looping shimmer sweep, standing in for a spinner while
/// a list screen's data loads, "like Facebook or YouTube". Mockups 07s,
/// 08s (3.9), 26s, 15s (5.9), 17s, 17bs (4.9) were not available to pull
/// into this pass — built directly from the handoff README's own written
/// rules instead (exact colours, timing, which screens are in/out), which
/// are explicit enough on their own that guessing at the unseen pixel
/// mockups wasn't needed; worth a side-by-side check against the real
/// mockups once they're reachable.
///
/// Per the README's own suggestion ("the `shimmer` package or a small
/// custom widget") this is the small-custom-widget option, not a new
/// pubspec dependency — pubspec.yaml already carries a long list of
/// version-pin workarounds for other packages (see its own comments), so
/// avoiding a new unvetted dependency for something this simple felt
/// like the safer call.
///
/// ---
///
/// [SkeletonShimmer] wraps one screen's worth of placeholders in a single
/// shared animation, so every [SkeletonBox] on screen sweeps in sync —
/// "a soft white band sweeping left -> right" reads as one continuous
/// effect, not N independent ones. `highContrast: true` (pass
/// `ref.watch(accessibilityModeProvider) == AccessibilityMode.highContrast`
/// at each call site) turns the sweep off entirely rather than slowing it
/// to a pulse — the spec allows either ("no sweep, a slow pulse or
/// nothing") and a static grey placeholder already reads as "loading"
/// without adding motion for a mode built for people who may want less
/// of it, not more.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.highContrast, required this.child});

  final bool highContrast;
  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _applyHighContrast(widget.highContrast);
  }

  @override
  void didUpdateWidget(covariant SkeletonShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highContrast != oldWidget.highContrast) {
      _controller?.dispose();
      _controller = null;
      _applyHighContrast(widget.highContrast);
    }
  }

  void _applyHighContrast(bool highContrast) {
    if (!highContrast) {
      _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SkeletonScope(animation: _controller, child: widget.child);
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.animation, required super.child});

  final Animation<double>? animation;

  static _SkeletonScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) => oldWidget.animation != animation;
}

/// The one placeholder shape every other skeleton widget below is built
/// from — a rounded grey rectangle, optionally swept by the nearest
/// [SkeletonShimmer] above it. Handoff README: "one skeleton widget per
/// list row type keeps it simple" — this is the single shared primitive
/// underneath all of them, rather than a bespoke shimmer per row type.
///
/// Direction: sweeps right -> left instead of left -> right under RTL
/// text direction (Urdu) — read from [Directionality.of] rather than the
/// current locale, since that's the actual signal the spec names
/// ("right -> left in Urdu").
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, required this.width, required this.height, this.borderRadius = 6});

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final animation = _SkeletonScope.of(context)?.animation;
    final radius = BorderRadius.circular(borderRadius);

    if (animation == null) {
      // High contrast: static grey, no sweep (see SkeletonShimmer's doc
      // comment).
      return Container(width: width, height: height, decoration: BoxDecoration(color: HumsafarColors.tabTrack, borderRadius: radius));
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final bandWidth = width * 0.6;
    final travel = width + bandWidth; // edge-to-edge distance the band crosses each loop.

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Container(color: HumsafarColors.tabTrack),
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final progress = animation.value * travel - bandWidth; // -bandWidth .. width
                final left = isRtl ? (width - bandWidth) - progress : progress;
                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: bandWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A placeholder text line — rounded-bar text, per the handoff README.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width = double.infinity, this.height = 14});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBox(width: width, height: height, borderRadius: height / 2);
}

/// A placeholder avatar — circle, per the handoff README.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SkeletonBox(width: size, height: size, borderRadius: size / 2);
}

/// One skeleton list row, matching the `Card` + leading-icon-or-avatar +
/// title/subtitle shape every list screen in this app already uses
/// (guardian home's dependent cards, Alerts/Messages/Medical
/// Vault/Vitals rows). [leadingIsCircle] picks avatar-circle (Messages'
/// real `CircleAvatar`, Guardian Home's role icon) vs a small square icon
/// placeholder (Alerts/Medical Vault/Vitals' plain `Icon`s) — one widget,
/// per the README's "one skeleton widget per list row type" note, with
/// just that one shape flag rather than a separate widget for each
/// screen.
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({
    super.key,
    this.leadingSize = 40,
    this.leadingIsCircle = true,
    this.showTrailing = true,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final double leadingSize;
  final bool leadingIsCircle;
  final bool showTrailing;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HumsafarColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HumsafarColors.border),
      ),
      child: Row(
        children: [
          leadingIsCircle
              ? SkeletonCircle(size: leadingSize)
              : SkeletonBox(width: leadingSize, height: leadingSize, borderRadius: 8),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLine(width: 170, height: 14),
                SizedBox(height: 8),
                SkeletonLine(width: 110, height: 12),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const SkeletonBox(width: 20, height: 20, borderRadius: 4),
          ],
        ],
      ),
    );
  }
}

/// One skeleton metric tile, matching Vitals' latest-reading tile grid
/// (`SizedBox(width: 150)` card with a label line and a value line).
class SkeletonMetricTile extends StatelessWidget {
  const SkeletonMetricTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HumsafarColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HumsafarColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonLine(width: 70, height: 11),
            SizedBox(height: 8),
            SkeletonLine(width: 90, height: 16),
          ],
        ),
      ),
    );
  }
}

/// One skeleton chat bubble, matching Chat's real message bubbles —
/// alternating sides with varying widths reads more like a real
/// conversation than a column of identical grey bars.
class SkeletonChatBubble extends StatelessWidget {
  const SkeletonChatBubble({super.key, required this.alignEnd, this.width = 180});

  final bool alignEnd;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: SkeletonBox(width: width, height: 40, borderRadius: 12),
      ),
    );
  }
}

/// Handoff README, "Loading states": "after about 10s the skeleton
/// becomes the normal 'Can't reach the server' message (F-21), never an
/// endless shimmer." Mixed into every screen the skeleton applies to;
/// each screen's own `_load()` calls [startSkeletonTimeout] at the same
/// place it sets `_isLoading = true`, passing a callback that puts the
/// screen into its own existing error state exactly as if the request
/// itself had failed — no second error UI to build or test, the skeleton
/// just times out into the same retry screen a real network error
/// already shows. [cancelSkeletonTimeout] is called from `_load()`'s
/// `finally` block so a request that finishes (success or failure) on
/// its own never has this fire late.
mixin SkeletonTimeoutMixin<T extends StatefulWidget> on State<T> {
  Timer? _skeletonTimeoutTimer;

  void startSkeletonTimeout(VoidCallback onTimeout, {Duration after = const Duration(seconds: 10)}) {
    _skeletonTimeoutTimer?.cancel();
    _skeletonTimeoutTimer = Timer(after, () {
      if (mounted) onTimeout();
    });
  }

  void cancelSkeletonTimeout() {
    _skeletonTimeoutTimer?.cancel();
    _skeletonTimeoutTimer = null;
  }

  @override
  void dispose() {
    _skeletonTimeoutTimer?.cancel();
    super.dispose();
  }
}
