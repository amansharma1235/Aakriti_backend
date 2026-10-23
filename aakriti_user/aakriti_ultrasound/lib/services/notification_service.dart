import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'notifications_store.dart';

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🌙 FCM BACKGROUND NOTIFICATION: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');

  final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
  final body = message.notification?.body ?? message.data['message'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    NotificationStore.instance.addNotification(
      icon: _getIconForNotification(title),
      title: title,
      message: body,
      color: _getColorForNotification(title),
    );
  }
}

IconData _getIconForNotification(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('appointment') || lower.contains('booked')) {
    return Icons.calendar_month_rounded;
  }
  if (lower.contains('report')) {
    return Icons.description_rounded;
  }
  if (lower.contains('payment') || lower.contains('receipt')) {
    return Icons.payments_rounded;
  }
  if (lower.contains('reminder')) {
    return Icons.access_time_rounded;
  }
  return Icons.notifications_active_rounded;
}

Color _getColorForNotification(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('confirm') || lower.contains('success')) {
    return const Color(0xFF1677FF);
  }
  if (lower.contains('cancel')) {
    return Colors.redAccent;
  }
  if (lower.contains('report')) {
    return const Color(0xFF18C8C8);
  }
  if (lower.contains('payment')) {
    return Colors.green;
  }
  return const Color(0xFF1677FF);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 FCM User granted notification permission');
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 FOREGROUND NOTIFICATION RECEIVED: ${message.data}');
        final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
        final body = message.notification?.body ?? message.data['message'] ?? '';

        NotificationStore.instance.addNotification(
          icon: _getIconForNotification(title),
          title: title,
          message: body,
          color: _getColorForNotification(title),
        );
      });

      // Notification clicked when app in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 NOTIFICATION OPENED APP: ${message.data}');
        final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
        final body = message.notification?.body ?? message.data['message'] ?? '';

        NotificationStore.instance.addNotification(
          icon: _getIconForNotification(title),
          title: title,
          message: body,
          color: _getColorForNotification(title),
        );
      });

      // Register FCM device token with backend
      try {
        final fcmToken = await _messaging.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          debugPrint('🔔 FCM Device Token: $fcmToken');
          final currentPid = await AuthService.getPatientId();
          await ApiService.registerFcmToken(
            token: fcmToken,
            userType: 'patient',
            userId: currentPid,
          );
        }

        _messaging.onTokenRefresh.listen((newToken) async {
          final currentPid = await AuthService.getPatientId();
          await ApiService.registerFcmToken(
            token: newToken,
            userType: 'patient',
            userId: currentPid,
          );
        });
      } catch (tokenErr) {
        debugPrint('🔔 FCM token registration warning: $tokenErr');
      }
    } catch (e) {
      debugPrint('FCM listeners error: $e');
    }
  }

  static void startRealtimeSync({String? patientId}) {}
  static void stopRealtimeSync() {}

  /// Manually dispatch a real-time notification
  static void showRealtimeNotification({
    required String title,
    required String message,
    IconData? icon,
    Color? color,
  }) {
    NotificationStore.instance.addNotification(
      icon: icon ?? _getIconForNotification(title),
      title: title,
      message: message,
      color: color ?? _getColorForNotification(title),
    );
  }
}
