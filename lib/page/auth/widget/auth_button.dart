import 'package:flutter/material.dart';

/// Custom button widget for authentication pages.
///
/// A styled button that supports loading state and outlined or filled variants.
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: isOutlined ? Colors.transparent : null,
              foregroundColor: isOutlined ? theme.colorScheme.primary : null,
              elevation: isOutlined ? 0 : null,
              side: isOutlined
                  ? BorderSide(color: theme.colorScheme.primary)
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              backgroundColor: isOutlined
                  ? WidgetStateProperty.all(Colors.transparent)
                  : WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetStateProperty.resolveWith)) {
                        return Colors.transparent;
                      }
                      return null;
                    }),
            ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined ? theme.colorScheme.primary : Colors.white,
                  ),
                ),
              )
            : Container(
                decoration: isOutlined
                    ? null
                    : BoxDecoration(borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isOutlined
                          ? theme.colorScheme.primary
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
