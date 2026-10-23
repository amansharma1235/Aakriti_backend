import 'package:flutter/material.dart';

import '../screen/notifications_screen.dart';
import '../services/notifications_store.dart';

class NotificationAppBarButton extends StatefulWidget {
  final Color iconColor;
  final Color badgeBgColor;
  final double iconSize;

  const NotificationAppBarButton({
    super.key,
    this.iconColor = Colors.white,
    this.badgeBgColor = Colors.redAccent,
    this.iconSize = 24.0,
  });

  @override
  State<NotificationAppBarButton> createState() =>
      _NotificationAppBarButtonState();
}

class _NotificationAppBarButtonState extends State<NotificationAppBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationStore.instance,
      builder: (context, _) {
        final count = NotificationStore.instance.unreadCount;
        final hasUnread = count > 0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              iconSize: widget.iconSize,
              icon: hasUnread
                  ? ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: widget.iconColor,
                      ),
                    )
                  : Icon(
                      Icons.notifications_none_rounded,
                      color: widget.iconColor,
                    ),
              tooltip: "Notifications",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (hasUnread)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: widget.badgeBgColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: widget.badgeBgColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? "9+" : "$count",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
