import 'package:flutter/material.dart';

/// Custom animations and transitions for the app
class AppAnimations {
  AppAnimations._();

  /// Animation durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  /// Animation curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutCubic;
  static const Curve smoothCurve = Curves.easeInOutQuart;
  static const Curve gentleCurve = Curves.easeInOutSine;

  /// Fade transition
  static Widget fadeTransition({
    required Widget child,
    Duration duration = medium,
    Curve curve = defaultCurve,
    bool withScale = false,
    double scaleBegin = 0.95,
    double scaleEnd = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: withScale
              ? Transform.scale(
                  scale: scaleBegin + (scaleEnd - scaleBegin) * animation,
                  child: child,
                )
              : child,
        );
      },
      child: child,
    );
  }

  /// Slide transition
  static Widget slideTransition({
    required Widget child,
    Duration duration = medium,
    Curve curve = defaultCurve,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
    bool withFade = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        final slideOffset = begin + (end - begin) * animation;
        return Transform.translate(
          offset: slideOffset,
          child: withFade
              ? Opacity(
                  opacity: animation,
                  child: child,
                )
              : child,
        );
      },
      child: child,
    );
  }

  /// Scale transition
  static Widget scaleTransition({
    required Widget child,
    Duration duration = medium,
    Curve curve = bounceCurve,
    double begin = 0.0,
    double end = 1.0,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        return Align(
          alignment: alignment,
          child: Transform.scale(
            scale: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Rotation transition
  static Widget rotationTransition({
    required Widget child,
    Duration duration = slow,
    Curve curve = defaultCurve,
    double turns = 1.0,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: turns),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        return Align(
          alignment: alignment,
          child: Transform.rotate(
            angle: animation * 2 * 3.14159,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered animation for list items
  static Widget staggeredAnimation({
    required List<Widget> children,
    Duration duration = medium,
    Curve curve = defaultCurve,
    Duration staggerDelay = const Duration(milliseconds: 100),
    bool slideIn = true,
    bool fadeIn = true,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = Duration(milliseconds: staggerDelay.inMilliseconds * index);
        
        return AnimatedContainer(
          duration: duration + delay,
          curve: curve,
          child: slideIn
              ? slideTransition(
                  child: child,
                  duration: duration,
                  curve: curve,
                  withFade: fadeIn,
                )
              : fadeIn
                  ? fadeTransition(
                      child: child,
                      duration: duration,
                      curve: curve,
                    )
                  : child,
        );
      }).toList(),
    );
  }

  /// Shimmer loading animation
  static Widget shimmerLoading({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerLoading(
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      child: child,
    );
  }

  /// Pulse animation
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double scaleBegin = 1.0,
    double scaleEnd = 1.05,
    Curve curve = defaultCurve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: scaleBegin, end: scaleEnd),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Bounce animation
  static Widget bounceAnimation({
    required Widget child,
    Duration duration = medium,
    Curve curve = bounceCurve,
    double bounceHeight = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        final bounceValue = (1.0 - animation) * (1.0 - animation) * bounceHeight;
        return Transform.translate(
          offset: Offset(0, -bounceValue),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Shake animation for error states
  static Widget shakeAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double shakeAmount = 10.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: defaultCurve,
      builder: (context, animation, child) {
        final offset = shakeAmount * animation * (1 - animation) * 4;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide and fade combination
  static Widget slideAndFade({
    required Widget child,
    Duration duration = medium,
    Curve curve = defaultCurve,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        final slideOffset = begin + (end - begin) * (1 - animation);
        return Transform.translate(
          offset: slideOffset,
          child: Opacity(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Scale and fade combination
  static Widget scaleAndFade({
    required Widget child,
    Duration duration = medium,
    Curve curve = defaultCurve,
    double scaleBegin = 0.8,
    double scaleEnd = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, animation, child) {
        final scale = scaleBegin + (scaleEnd - scaleBegin) * animation;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shimmer loading animation widget
class _ShimmerLoading extends StatefulWidget {

  const _ShimmerLoading({
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value * 0.785),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Page transition animations
class PageTransitions {
  PageTransitions._();

  /// Slide page transition
  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.defaultCurve,
    SlideDirection direction = SlideDirection.left,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, 1.0);
            break;
        }
        return SlideTransition(
          position: animation.drive(
            Tween(begin: begin, end: Offset.zero),
          ),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Fade page transition
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.defaultCurve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Scale page transition
  static PageRouteBuilder scaleTransition({
    required Widget page,
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.bounceCurve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Rotation page transition
  static PageRouteBuilder rotationTransition({
    required Widget page,
    Duration duration = AppAnimations.slow,
    Curve curve = AppAnimations.defaultCurve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }
}

/// Slide direction enum
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Animated container with custom transitions
class AnimatedContainerWidget extends StatefulWidget {

  const AnimatedContainerWidget({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.defaultCurve,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  State<AnimatedContainerWidget> createState() => _AnimatedContainerWidgetState();
}

class _AnimatedContainerWidgetState extends State<AnimatedContainerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
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
      animation: _animation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          color: widget.color,
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: widget.border,
            boxShadow: widget.boxShadow,
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Animated list item with staggered entrance
class AnimatedListItem extends StatelessWidget {

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.curve = AppAnimations.defaultCurve,
    this.slideIn = true,
    this.fadeIn = true,
  });
  final Widget child;
  final int index;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool slideIn;
  final bool fadeIn;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        // Create an Animation<double> from the value
        final animation = AlwaysStoppedAnimation<double>(value);
        
        final delayedAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay.inMilliseconds / duration.inMilliseconds,
            1.0,
            curve: Curves.easeOut,
          ),
        );

        Widget animatedChild = child!;
        
        if (slideIn) {
          animatedChild = SlideTransition(
            position: delayedAnimation.drive(
              Tween(begin: const Offset(0, 0.3), end: Offset.zero),
            ),
            child: animatedChild,
          );
        }
        
        if (fadeIn) {
          animatedChild = FadeTransition(
            opacity: delayedAnimation,
            child: animatedChild,
          );
        }
        
        return animatedChild;
      },
      child: child,
    );
  }
}