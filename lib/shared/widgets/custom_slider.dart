import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class OffsetRoundSliderThumbShape extends SliderComponentShape {
  final double radius;
  final double elevation;
  final double pressedElevation;
  final double xOffset;

  const OffsetRoundSliderThumbShape({
    this.radius = 5,
    this.elevation = 3,
    this.pressedElevation = 3,
    this.xOffset = -2,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Offset shiftedCenter = center.translate(xOffset, 0);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withAlpha(35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pressedElevation);
    canvas.drawCircle(shiftedCenter, radius, shadowPaint);

    final Paint thumbPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white;
    canvas.drawCircle(shiftedCenter, radius, thumbPaint);
  }
}

class CustomeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String Function(double) getCurrentLabel;
  final double min;
  final double max;
  final Color activeColor;
  final String title;

  const CustomeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    required this.getCurrentLabel,
    required this.title,
    this.min = 0.0,
    this.max = 1.0,
    this.activeColor = const Color(0xFF7B61FF), // The purple from your image
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row (Title and Dynamic Status)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              getCurrentLabel(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. The Custom Styled Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12, // Thick "Pill" style
            activeTrackColor: activeColor,
            inactiveTrackColor: const Color(0xFFF0F0F0),
            thumbColor: Colors.white,
            // Shift the thumb slightly left for visual alignment.
            thumbShape: const OffsetRoundSliderThumbShape(
              radius: 5,
              elevation: 5,
              pressedElevation: 5,
              xOffset: -2,
            ),
            overlayColor: activeColor.withAlpha(32),
            // Makes the corners perfectly rounded
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            padding: EdgeInsets.symmetric(vertical: 10),
            onChanged: (newValue) {
              onChanged(newValue);
              if (SettingsService.cachedHaptic) {
                HapticFeedback.selectionClick();
              }
            },
            onChangeEnd: onChangeEnd,
          ),
        ),

        // 3. Footer Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFooterText("Slow"),
              _buildFooterText("Fast"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w400,
      ),
    );
  }
}