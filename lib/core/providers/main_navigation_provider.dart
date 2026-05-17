import 'package:flutter/material.dart';

class MainNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _mapNearMeOnOpen = false;

  int get currentIndex => _currentIndex;
  bool get mapNearMeOnOpen => _mapNearMeOnOpen;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void openSearch() {
    _currentIndex = 1;
    notifyListeners();
  }

  void openMap({bool nearMe = false}) {
    _currentIndex = 2;
    _mapNearMeOnOpen = nearMe;
    notifyListeners();
  }

  bool consumeMapNearMeFlag() {
    if (!_mapNearMeOnOpen) return false;
    _mapNearMeOnOpen = false;
    return true;
  }
}
