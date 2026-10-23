import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/notifications_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  final NotificationStore notificationStore = NotificationStore.instance;

  // ================= THEME COLORS =================

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get primaryText => isDark ? Colors.white : navy;

  Color get secondaryText => isDark ? Colors.white70 : Colors.black54;

  Color get smallText => isDark ? Colors.white54 : Colors.grey.shade600;

  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    notificationStore.loadRealNotifications(force: true);
    notificationStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    notificationStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  void markAllAsRead() {
    notificationStore.markAllAsRead();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All notifications marked as read"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  void deleteNotification(int index) {
    if (index >= 0 && index < notificationStore.notifications.length) {
      final notif = notificationStore.notifications[index];
      final itemKey = (notif["id"] ?? notif["notification_id"] ?? '').toString();
      deleteNotificationByKey(itemKey);
    }
  }

  void deleteNotificationByKey(String key) {
    notificationStore.deleteNotification(key);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification deleted"),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  void markAsRead(int index) {
    if (index >= 0 && index < notificationStore.notifications.length) {
      final notif = notificationStore.notifications[index];
      final itemKey = (notif["id"] ?? '').toString();
      if (itemKey.isNotEmpty) {
        FirestoreService.instance.markNotificationAsRead(itemKey);
      }
    }
    setState(() {});
  }

  // ============================================================
  // CLEAR ALL CONFIRMATION
  // ============================================================

  void showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Clear all notifications?",
            style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "All notifications will be marked as read.",
            style: TextStyle(color: secondaryText, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("Cancel", style: TextStyle(color: secondaryText)),
            ),
            ElevatedButton(
              onPressed: () {
                notificationStore.markAllAsRead();

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications marked as read"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Clear All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final notifications = notificationStore.notifications;

    final unreadCount = notificationStore.unreadCount;

    return Scaffold(
      backgroundColor: bgColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navy,
        foregroundColor: Colors.white,

        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),

        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: markAllAsRead,
              tooltip: "Mark all as read",
              icon: const Icon(Icons.done_all_rounded),
            ),

          if (notifications.isNotEmpty)
            IconButton(
              onPressed: showClearAllDialog,
              tooltip: "Clear all",
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: notifications.isEmpty
          ? _emptyNotification()
          : Column(
              children: [
                // ==================================================
                // HEADER CARD
                // ==================================================

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [navy, Color(0xFF123A5A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: teal,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Stay Updated",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              unreadCount == 0
                                  ? "You're all caught up"
                                  : "$unreadCount unread notification${unreadCount > 1 ? 's' : ''}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // NOTIFICATION LIST
                // ==================================================
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => notificationStore.loadRealNotifications(force: true),
                    color: const Color(0xFF1677FF),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final itemKey = (notification["notification_id"] ??
                                notification["id"] ??
                                notification["created_at"] ??
                                "${notification["title"]}-${notification["time"]}")
                            .toString();

                        return Dismissible(
                          key: Key(itemKey),

                          direction: DismissDirection.endToStart,

                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          onDismissed: (_) {
                            deleteNotificationByKey(itemKey);
                          },

                          child: _notificationCard(notification, index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard(Map<String, dynamic> notification, int index) {
    final bool isUnread = notification["read"] == false;

    final Color notificationColor = notification["color"] as Color;

    final IconData notificationIcon = notification["icon"] as IconData;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          markAsRead(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isUnread
              ? cardColor
              : isDark
              ? const Color(0xFF0B1D2D)
              : const Color(0xFFFDFDFD),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isUnread ? blue.withValues(alpha: 0.18) : borderColor,
          ),

          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON

            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: notificationColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(notificationIcon, color: notificationColor, size: 25),
            ),

            const SizedBox(width: 13),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification["title"].toString(),
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                      ),

                      if (isUnread)
                        Container(
                          height: 8,
                          width: 8,
                          decoration: const BoxDecoration(
                            color: blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    notification["message"].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: secondaryText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    notification["time"].toString(),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: smallText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyNotification() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 65,
                color: blue,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              "No Notifications",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "You're all caught up.\nWe'll notify you when something important arrives.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: secondaryText),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => notificationStore.loadRealNotifications(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
