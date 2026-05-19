import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService.instance;

  List<AppNotification> _notifications = [];
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _loading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _notifications = await _service.getNotifications();
    _loading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    await load();
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    await load();
  }

  Future<void> sendTestNotification() async {
    await _service.sendTestNotification();
    await load();
  }
}
