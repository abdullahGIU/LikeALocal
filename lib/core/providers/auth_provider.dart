import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Clear any existing error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper to update loading state
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Check if a user is already logged in and fetch their data
  Future<void> checkCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentAppUser();
    } catch (e) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Up method
  Future<bool> signUp(String fullName, String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      _currentUser = await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset Password method
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout method
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }
}
