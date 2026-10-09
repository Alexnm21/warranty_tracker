import 'package:flutter/material.dart';

class ScaleOnPress extends StatefulWidget {
  const ScaleOnPress({
    super.key,
    required this.child,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.onLongPress,
    this.onTap,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) => _controller.forward();
  void _onPointerUp(PointerUpEvent _) => _controller.reverse();
  void _onPointerCancel(PointerCancelEvent _) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
