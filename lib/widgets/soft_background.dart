import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The soft wash behind the page content.
///
/// Four painted radial gradients in the palette's pastels, drifting under the
/// content like light through a window. They are **painted**, not blurred: a
/// live `BackdropFilter` would re-blur the whole area on every frame, which
/// is the single most expensive thing you can put on a budget phone, and it
/// would only ever frost the app's own content anyway.
///
/// The gradients sit behind a scrolling list, so they never move. A frosted
/// effect that scrolls with the content is the one that costs a frame
/// budget; this one is a static backdrop and costs nothing.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _Wash()),
        child,
      ],
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Stack(
        children: const [
          Positioned(
            top: -90,
            left: -70,
            child: _Blob(size: 260, color: AppColors.meshBlush),
          ),
          Positioned(
            top: 40,
            right: -110,
            child: _Blob(size: 300, color: AppColors.meshLilac),
          ),
          Positioned(
            top: 320,
            left: -120,
            child: _Blob(size: 280, color: AppColors.meshMint),
          ),
          Positioned(
            top: 560,
            right: -60,
            child: _Blob(size: 240, color: AppColors.meshButter),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
