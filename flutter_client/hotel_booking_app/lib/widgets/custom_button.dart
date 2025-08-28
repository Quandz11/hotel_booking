import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum ButtonVariant { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 50,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary
                    ? AppTheme.textLight
                    : AppTheme.primaryColor,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: _getTextColor(isDisabled),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(isDisabled),
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: _buildButton(context, child, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, Widget child, bool isDisabled) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? AppTheme.borderColor : AppTheme.primaryColor,
            foregroundColor: AppTheme.textLight,
            elevation: isDisabled ? 0 : 2,
            shadowColor: AppTheme.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: child,
        );

      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? AppTheme.borderColor : AppTheme.secondaryColor,
            foregroundColor: AppTheme.textLight,
            elevation: isDisabled ? 0 : 2,
            shadowColor: AppTheme.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: child,
        );

      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDisabled ? AppTheme.textTertiary : AppTheme.primaryColor,
            side: BorderSide(
              color: isDisabled ? AppTheme.borderColor : AppTheme.primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: child,
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDisabled ? AppTheme.textTertiary : AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: child,
        );
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return variant == ButtonVariant.primary || variant == ButtonVariant.secondary
          ? AppTheme.textLight.withOpacity(0.7)
          : AppTheme.textTertiary;
    }

    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return AppTheme.textLight;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return AppTheme.primaryColor;
    }
  }
}
