import 'package:flutter/material.dart';

void showAchievementNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => _AchievementBanner(message: message),
  );

  overlay.insert(overlayEntry);

  // Remove after 3 seconds
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

class _AchievementBanner extends StatefulWidget {
  final String message;

  const _AchievementBanner({required this.message});

  @override
  State<_AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<_AchievementBanner>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset(0, -1), // Start above screen
      end: Offset(0, 0),    // Slide into view
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _animation,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          color: Colors.green,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}