import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_language_recognition_app/services/settings_service.dart';

class NavigationButton extends StatefulWidget {
  const NavigationButton({
    super.key,
    required this.title,
    required this.icon,
    this.color = Colors.black,
    required this.route,
    required this.description,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String description;

  @override
  State<NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<NavigationButton> {
  bool _isNavigating = false;

  Future<void> _handleTap() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    if (SettingsService.cachedHaptic) {
      HapticFeedback.selectionClick();
    }

    // Let one frame render the spinner before starting route transition.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    await context.push(widget.route);
    if (!mounted) return;

    setState(() {
      _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isDark ? colorScheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? colorScheme.outlineVariant : const Color(0xFFE0E0E0),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isNavigating)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: widget.color,
                    ),
                  )
                else
                  Icon(widget.icon, size: 32, color: widget.color),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorScheme.onSurface : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? colorScheme.onSurfaceVariant : const Color.fromRGBO(0, 0, 0, 0.4),
                  ),
                )
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
