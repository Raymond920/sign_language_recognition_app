import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF7B61FF), // The purple from your image
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Text Section (Title & Description)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        
        // 2. Custom Styled Switch
        Transform.scale(
          scale: 0.8, // Slightly larger to match the bold UI
          child: Switch(
            padding: EdgeInsets.zero,
            value: value,
            onChanged: (newValue) {
              onChanged(newValue);
              if (SettingsService.cachedHaptic) {
                HapticFeedback.selectionClick();
              }
            },
            activeTrackColor: activeColor,
            activeColor: Colors.white, // Thumb color
            inactiveTrackColor: Colors.grey[300],
            inactiveThumbColor: Colors.white,
            // This removes the default Material 3 border if needed
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return activeColor;
                }
                return Colors.grey[400];
              },
            ),
          ),
        ),
      ],
    );
  }
}