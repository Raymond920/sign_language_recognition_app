import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class ResetDataDialog extends StatelessWidget {
  const ResetDataDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        // 1. The Main Content Box
        Container(
          padding: const EdgeInsets.only(left: 20, top: 65, right: 20, bottom: 20),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.26),
                offset: const Offset(0, 10),
                blurRadius: 10,
              ),
            ],
            border: Border.all(
              color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Reset Data?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? colorScheme.onSurface : Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "This will clear all your saved learning progress, quiz scores, and achievements. This action cannot be undone.",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.black45,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? colorScheme.onSurfaceVariant : Colors.black45,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (SettingsService.cachedHaptic) {
                        HapticFeedback.vibrate();
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      "Reset",
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 2. The Top "Popping" Icon
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: isDark
                ? colorScheme.errorContainer
                : const Color(0xFFFFEBEE),
            radius: 45,
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 50,
            ),
          ),
        ),
      ],
    );
  }
}