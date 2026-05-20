import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/audio_engine.dart';
import '../haptic/haptic_engine.dart';
import '../../data/services/safety_service.dart';

class GestureShell extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSingleVerticalSwipeUp;
  final VoidCallback? onSingleVerticalSwipeDown;
  final VoidCallback? onTwoFingerDoubleTap;
  final VoidCallback? onTwoFingerDownwardSwipe;
  final VoidCallback? onLongPress;

  const GestureShell({
    Key? key,
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onSingleTap,
    this.onDoubleTap,
    this.onSingleVerticalSwipeUp,
    this.onSingleVerticalSwipeDown,
    this.onTwoFingerDoubleTap,
    this.onTwoFingerDownwardSwipe,
    this.onLongPress,
  }) : super(key: key);

  @override
  ConsumerState<GestureShell> createState() => _GestureShellState();
}

class _GestureShellState extends ConsumerState<GestureShell> {
  int _activePointers = 0;
  Offset? _startPosition;

  void _handleTapDown(TapDownDetails details) {
    ref.read(hapticEngineProvider).weakImpact();
  }

  void _handleTap() {
    if (_activePointers == 1) {
      widget.onSingleTap?.call();
    }
  }

  void _handleDoubleTap() {
    final safetyService = ref.read(safetyServiceProvider);
    if (safetyService.isAlertPending) {
      safetyService.cancelAlert();
    } else {
      widget.onDoubleTap?.call();
    }
  }

  void _handleLongPress() {
    widget.onLongPress?.call();
  }

  void _handlePanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPosition == null) return;
    final endPosition = details.globalPosition;
    final dx = endPosition.dx - _startPosition!.dx;
    final dy = endPosition.dy - _startPosition!.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal
      if (dx.abs() > 50) {
        if (dx > 0) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
        }
      }
    } else {
      // Vertical
      if (dy.abs() > 50) {
        if (_activePointers == 2 && dy > 0) {
          widget.onTwoFingerDownwardSwipe?.call();
        } else if (_activePointers == 1) {
          if (dy < 0) {
            widget.onSingleVerticalSwipeUp?.call();
          } else {
            widget.onSingleVerticalSwipeDown?.call();
          }
        }
      }
    }
    _startPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          _activePointers++;
        });
      },
      onPointerUp: (event) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              if (_activePointers > 0) _activePointers--;
            });
          }
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPress: _handleLongPress,
        onPanStart: _handlePanStart,
        onPanEnd: _handlePanEnd,
        child: widget.child,
      ),
    );
  }
}
