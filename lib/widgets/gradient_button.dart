import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A button with a gradient background, disabled state turns gray.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final Widget child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        color: isDisabled ? AppColors.surfaceHover : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isDisabled ? AppColors.textMuted : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
