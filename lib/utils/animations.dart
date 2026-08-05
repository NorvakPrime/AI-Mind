import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.05, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var slideTween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            var fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: curve));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation1, animation2) => builder(context),
    transitionBuilder: (context, animation1, animation2, child) {
      const curve = Curves.easeOutCubic;
      
      final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: animation1, curve: curve),
      );
      
      final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation1, curve: curve),
      );

      return Opacity(
        opacity: opacity.value,
        child: Transform.scale(
          scale: scale.value,
          child: child,
        ),
      );
    },
  );
}
