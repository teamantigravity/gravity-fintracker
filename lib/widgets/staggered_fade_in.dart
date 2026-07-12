import 'package:flutter/material.dart';

/// Fades + slides a child in once, with a delay proportional to [index].
/// Delay is capped so long lists don't produce absurdly slow entrances.
/// Respects `disableAnimations` (accessibility: reduced motion) by skipping
/// straight to the end state.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;
  final int maxStaggeredItems;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.maxStaggeredItems = 10,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }
    final cappedIndex = widget.index.clamp(0, widget.maxStaggeredItems);
    Future.delayed(widget.baseDelay * cappedIndex, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
