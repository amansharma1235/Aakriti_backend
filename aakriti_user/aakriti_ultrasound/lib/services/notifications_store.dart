import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore._() {
    _initFirestoreListener();
  }

  static final NotificationStore instance = NotificationStore._();

  final List<Map<String, dynamic>> notifications = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final ValueNotifier<Map<String, dynamic>?> realTimeBannerNotifier = ValueNotifier<Map<String, dynamic>?>(null);

  void dismissBanner() {
    realTimeBannerNotifier.value = null;
  }

  StreamSubscription? _subscription;

  int get unreadCount => notifications.where((n) => n['read'] == false).length;

  void _initFirestoreListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _subscription?.cancel();
      notifications.clear();
      notifyListeners();

      if (user != null) {
        _isLoading = true;
        notifyListeners();

        _subscription = FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .snapshots()
            .listen((snap) {
          _isLoading = false;
          notifications.clear();

          for (final doc in snap.docs) {
            final data = doc.data();
            final type = (data['type'] ?? 'general').toString();
            final title = (data['title'] ?? 'Notification').toString();

            String timeStr = 'Just now';
            if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              final dt = (data['createdAt'] as Timestamp).toDate();
              timeStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
            }

            notifications.add({
              'id': doc.id,
              'notification_id': doc.id,
              'title': title,
              'message': (data['message'] ?? '').toString(),
              'type': type,
              'time': timeStr,
              'color': _getColorForNotification(type),
              'icon': _getIconForNotification(type),
              'read': data['read'] == true,
            });
          }

          notifyListeners();
        }, onError: (e) {
          debugPrint('[NotificationStore] Firestore listen error: $e');
          _isLoading = false;
          notifyListeners();
        });
      }
    });
  }

  Future<void> loadRealNotifications({bool force = false}) async {
    // Handled automatically via authStateChanges listener
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snap.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('[NotificationStore] markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
    } catch (e) {
      debugPrint('[NotificationStore] deleteNotification error: $e');
    }
  }

  Future<void> addNotification({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': title,
        'message': message,
        'type': 'general',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Color _getColorForNotification(String type) {
    switch (type) {
      case 'appointment_confirmed':
      case 'test_completed':
      case 'report_uploaded':
      case 'payment_success':
        return const Color(0xFF159A8C);
      case 'appointment_cancelled':
        return const Color(0xFFD64545);
      case 'appointment_pending':
      case 'test_started':
      case 'bill_generated':
        return const Color(0xFF1677FF);
      default:
        return const Color(0xFF1677FF);
    }
  }

  IconData _getIconForNotification(String type) {
    switch (type) {
      case 'appointment_confirmed':
      case 'appointment_pending':
      case 'appointment_checked_in':
        return Icons.calendar_month_rounded;
      case 'test_started':
      case 'test_completed':
        return Icons.biotech_rounded;
      case 'report_uploaded':
        return Icons.description_rounded;
      case 'bill_generated':
      case 'payment_success':
        return Icons.receipt_long_rounded;
      case 'appointment_cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
