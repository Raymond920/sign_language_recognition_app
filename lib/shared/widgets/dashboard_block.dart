import 'package:flutter/material.dart';

class DashboardBlock extends StatelessWidget {
  const DashboardBlock({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.onTap,
    this.iconColor = Colors.blue,
    this.iconSize = 28,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;

  bool get isClickable => onTap != null;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
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
                Icon(icon, size: iconSize, color: iconColor),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),

        /// 👇 Only enable InkWell if clickable
        child: isClickable
            ? InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: content,
              )
            : content,
      ),
    );
  }
}
