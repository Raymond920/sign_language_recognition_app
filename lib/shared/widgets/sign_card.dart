import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class SignCard extends StatelessWidget {
  const SignCard({
    super.key,
    required this.sign
  });

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (SettingsService.cachedHaptic) {
          HapticFeedback.selectionClick();
        }
        context.pushNamed('sign_detail', extra: sign);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sign.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? colorScheme.onSurface : Colors.black,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                _buildCategoryBadge(context, sign.category)
              ],
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
              size: 20,
            ),
          ]
        ),
      )
    );
  }
  
  Widget _buildCategoryBadge(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? colorScheme.outlineVariant : const Color.fromRGBO(227, 230, 234, 1),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          height: 1.0,
          color: isDark ? colorScheme.onSurfaceVariant : Colors.black,
        ),
      ),
    );
  }
}