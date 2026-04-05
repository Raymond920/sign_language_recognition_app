import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class DashboardBlock extends StatelessWidget {
  const DashboardBlock({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.onTap,
    this.iconColor = Colors.blue,
    this.iconSize = 28,
    this.flipIconHorizontally = false,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE0E0E0),
    this.titleColor = Colors.black,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;
  final bool flipIconHorizontally;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;

  bool get isClickable => onTap != null;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          /// 
          SizedBox(height: 10.0),
          Row(
            children: [
              if (icon != null) ...[
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    flipIconHorizontally ? -1 : 1,
                    1,
                    1,
                  ),
                  child: Icon(icon, size: iconSize, color: iconColor),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// CONTENT
          child,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),

        /// 👇 Only enable InkWell if clickable
        child: isClickable
            ? InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (SettingsService.cachedHaptic) {
                    HapticFeedback.selectionClick();
                  }
                  onTap?.call();
                },
                child: content,
              )
            : content,
      ),
    );
  }
}
