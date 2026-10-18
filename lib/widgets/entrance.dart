import 'package:flutter/material.dart';

/// Fades and lifts its child into place, one step behind the one before it.
///
/// The delay is built into the controller's own duration rather than a timer
/// so the animation is always driving frames. A `Future.delayed` would leave
/// the widget invisible while no frame was scheduled, which means a test
/// waiting for the screen to settle would move on while cards were still
/// hidden, and a real user would see a card blink in a frame late.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 380),
    this.offset = 14,
  });

  /// Position in the sequence. The first item is 0.
  final int index;

  final Widget child;

  /// How much later each successive item starts.
  final Duration step;

  /// How long one item takes to arrive.
  final Duration duration;

  /// How far below its final position it starts, in logical pixels.
  final double offset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final Duration _total = widget.duration + widget.step * widget.index;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_startFraction, 1, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _lift = CurvedAnimation(
    parent: _controller,
    curve: Interval(_startFraction, 1, curve: Curves.easeOutCubic),
  );

  /// Where this item's own animation begins within the shared timeline.
  double get _startFraction => (_total.inMilliseconds == 0)
      ? 0
      : (widget.step * widget.index).inMilliseconds / _total.inMilliseconds;

  @override
  void initState() {
    super.initState();
    _controller.forward();
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
      builder: (context, child) {
        final t = _lift.value;
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
