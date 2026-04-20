import 'package:flutter/material.dart';

final ValueNotifier<String?> achievementBannerMessage =
    ValueNotifier<String?>(null);

void showAchievementNotification(String message) {
  achievementBannerMessage.value = message;

  Future.delayed(const Duration(seconds: 3), () {
    if (achievementBannerMessage.value == message) {
      achievementBannerMessage.value = null;
    }
  });
}

class AchievementBannerHost extends StatelessWidget {
  final Widget child;

  const AchievementBannerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<String?>(
          valueListenable: achievementBannerMessage,
          builder: (context, message, _) {
            if (message == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Dismissible(
                  key: ValueKey(message),
                  direction: DismissDirection.up,
                  onDismissed: (_) {
                    if (achievementBannerMessage.value == message) {
                      achievementBannerMessage.value = null;
                    }
                  },
                  child: _AchievementBanner(message: message),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (achievementBannerMessage.value == widget.message) {
                    achievementBannerMessage.value = null;
                  }
                },
                icon: const Icon(Icons.close, color: Colors.blueGrey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}