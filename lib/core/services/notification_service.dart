import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.handleBackgroundMessage(message);
}

typedef NotificationTapCallback = void Function(AppNotification notification);

/// FCM + local notifications + in-app notification inbox.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _storageKey = 'app_notifications';
  static const _channelId = 'like_a_local_default';
  static const _channelName = 'LikeALocal';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? onNotificationTap;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _initLocalNotifications();
    await _requestPermissions();
    await _configureFcm();
    await _seedDemoNotificationsIfEmpty();

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          onNotificationTap?.call(AppNotification.fromJson(map));
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'LikeALocal alerts and reminders',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _configureFcm() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) async {
      await _handleRemoteMessage(message, showLocal: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleRemoteMessage(message, showLocal: false);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handleRemoteMessage(initial, showLocal: false);
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'LikeALocal';
    final body =
        message.notification?.body ?? message.data['body'] ?? 'New update';
    final service = NotificationService.instance;
    await service._saveNotification(
      AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: message.data['type'] ?? 'push',
      ),
    );
  }

  Future<void> _handleRemoteMessage(
    RemoteMessage message, {
    required bool showLocal,
  }) async {
    final title = message.notification?.title ??
        message.data['title'] ??
        'LikeALocal';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new notification';

    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      type: message.data['type'] ?? 'push',
    );

    await _saveNotification(notification);
    if (showLocal) {
      await showLocalNotification(
        title: title,
        body: body,
        type: notification.type,
        payload: notification,
      );
    } else {
      onNotificationTap?.call(notification);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'local',
    AppNotification? payload,
  }) async {
    final notification = payload ??
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          createdAt: DateTime.now(),
          type: type,
        );

    await _saveNotification(notification);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _local.show(
      notification.id.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(notification.toJson()),
    );
  }

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((e) {
          try {
            return AppNotification.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<AppNotification>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markAsRead(String id) async {
    final all = await getNotifications();
    final updated = all
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _persistAll(updated);
  }

  Future<void> markAllAsRead() async {
    final all = await getNotifications();
    final updated = all.map((n) => n.copyWith(isRead: true)).toList();
    await _persistAll(updated);
  }

  Future<void> addInAppNotification(AppNotification notification) async {
    await _saveNotification(notification);
  }

  Future<int> unreadCount() async {
    final all = await getNotifications();
    return all.where((n) => !n.isRead).length;
  }

  Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: 'LikeALocal test',
      body: 'Push & local notifications are working!',
      type: 'test',
    );
  }

  Future<void> notifyNearbyPlace(String placeName) async {
    await showLocalNotification(
      title: 'You are nearby!',
      body: 'You are near $placeName — tap to explore.',
      type: 'nearby',
    );
  }

  Future<void> _saveNotification(AppNotification notification) async {
    final all = await getNotifications();
    all.removeWhere((n) => n.id == notification.id);
    all.insert(0, notification);
    await _persistAll(all.take(50).toList());
  }

  Future<void> _persistAll(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      notifications.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  Future<void> _seedDemoNotificationsIfEmpty() async {
    final existing = await getNotifications();
    if (existing.isNotEmpty) return;

    final demos = [
      AppNotification(
        id: 'demo_review',
        title: 'New review added',
        body: 'Someone left a review on one of your saved places.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'review',
      ),
      AppNotification(
        id: 'demo_nearby',
        title: 'Near a saved restaurant',
        body: 'You are near a pinned place you saved earlier.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'nearby',
      ),
      AppNotification(
        id: 'demo_ai',
        title: 'New local recommendation',
        body: 'Try the AI assistant for personalized place ideas.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: 'recommendation',
      ),
    ];

    for (final n in demos) {
      await _saveNotification(n);
    }
  }
}
