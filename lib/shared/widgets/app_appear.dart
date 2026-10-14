import 'package:flutter/material.dart';

ScrollableState? _verticalScrollable(BuildContext context) {
  ScrollableState? state = Scrollable.maybeOf(context);
  while (state != null && state.position.axis != Axis.vertical) {
    state = Scrollable.maybeOf(state.context);
  }
  return state;
}

/// Same entrance as the home sections: fade, rise, and a slight scale
/// once the block scrolls into view.
class AppAppear extends StatefulWidget {
  const AppAppear({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<AppAppear> createState() => _AppAppearState();
}

class _AppAppearState extends State<AppAppear> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  ScrollPosition? _position;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 860));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = _verticalScrollable(context)?.position;
    if (!identical(_position, position)) {
      _position?.removeListener(_onScroll);
      _position = position;
      _position?.addListener(_onScroll);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _started = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }
  }

  void _onScroll() {
    if (!mounted || _started) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _started = true;
      return;
    }
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) return;
    final top = object.localToGlobal(Offset.zero).dy;
    final viewport = MediaQuery.sizeOf(context).height;
    if (top < viewport * 0.98) {
      _started = true;
      final delay = widget.index.clamp(0, 6) * 40;
      if (delay == 0) {
        _enter.forward();
      } else {
        Future<void>.delayed(Duration(milliseconds: delay), () {
          if (mounted) _enter.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 72),
            child: Transform.scale(
              scale: 0.94 + (0.06 * t),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
