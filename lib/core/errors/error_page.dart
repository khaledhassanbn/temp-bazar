import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';

/// قالب موحّد لشاشات الأخطاء (عدم اتصال، 404، …).
class ErrorPage extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryPressed;
  final bool isPrimaryLoading;
  final IconData? primaryIcon;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;

  const ErrorPage({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.primaryButtonLabel,
    required this.onPrimaryPressed,
    this.isPrimaryLoading = false,
    this.primaryIcon,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  imageAsset,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF2C3E50),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isPrimaryLoading ? null : onPrimaryPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      disabledBackgroundColor:
                          AppColors.mainColor.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: isPrimaryLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(primaryIcon ?? Icons.refresh_rounded),
                    label: Text(
                      primaryButtonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (secondaryButtonLabel != null &&
                    onSecondaryPressed != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(
                      secondaryButtonLabel!,
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
