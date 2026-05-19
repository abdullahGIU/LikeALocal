import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

/// User preferences + premium helpers (synced with [AuthProvider] after upgrades).
class UserProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  String _budget = 'medium';
  String _atmosphere = 'lively';
  bool _chatPrivacyHideEmail = true;
  bool _chatPrivacyReadReceipts = true;
  bool _notificationsEnabled = true;

  String get budget => _budget;
  String get atmosphere => _atmosphere;
  bool get chatPrivacyHideEmail => _chatPrivacyHideEmail;
  bool get chatPrivacyReadReceipts => _chatPrivacyReadReceipts;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> loadForUser(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    _budget = prefs.getString('pref_budget') ?? 'medium';
    _atmosphere = prefs.getString('pref_atmosphere') ?? 'lively';
    _chatPrivacyHideEmail = prefs.getBool('pref_hide_email') ?? true;
    _chatPrivacyReadReceipts = prefs.getBool('pref_read_receipts') ?? true;
    _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;

    if (userId != null) {
      try {
        final remote = await _firestore.getUserPreferences(userId);
        _budget = remote['budget'] as String? ?? _budget;
        _atmosphere = remote['atmosphere'] as String? ?? _atmosphere;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setBudget(String value) async {
    _budget = value;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setAtmosphere(String value) async {
    _atmosphere = value;
    await _persistLocal();
    notifyListeners();
  }

  Future<void> setChatPrivacyHideEmail(bool value) async {
    _chatPrivacyHideEmail = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_hide_email', value);
    notifyListeners();
  }

  Future<void> setChatPrivacyReadReceipts(bool value) async {
    _chatPrivacyReadReceipts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_read_receipts', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notifications', value);
    notifyListeners();
  }

  Future<void> syncPreferencesToFirestore(String userId) async {
    await _firestore.updateUserPreferences(
      userId: userId,
      preferences: {
        'budget': _budget,
        'atmosphere': _atmosphere,
      },
    );
  }

  Future<AppUser?> upgradeToPremium(String userId) async {
    await _firestore.setUserPremium(userId: userId, isPremium: true);
    return null;
  }

  static bool canPinMore({required AppUser user, required int currentPinCount}) {
    if (user.isPremium) return true;
    return currentPinCount < user.pinLimit;
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_budget', _budget);
    await prefs.setString('pref_atmosphere', _atmosphere);
  }
}
