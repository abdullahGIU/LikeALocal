import 'package:flutter/material.dart';

class MainNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int _homeScrollToTopNonce = 0;
  bool _mapNearMeOnOpen = false;
  String? _mapCategoryFilter;
  bool _mapShowPinnedOnly = false;
  String? _mapFocusPlaceId;

  int get currentIndex => _currentIndex;
  int get homeScrollToTopNonce => _homeScrollToTopNonce;
  bool get mapNearMeOnOpen => _mapNearMeOnOpen;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  /// Bottom nav tap — re-tapping Home while on Home scrolls to top.
  void onBottomNavTap(int index) {
    if (index == 0 && _currentIndex == 0) {
      _homeScrollToTopNonce++;
      notifyListeners();
      return;
    }
    setIndex(index);
  }

  void openSearch() {
    _currentIndex = 1;
    notifyListeners();
  }

  void openMap({
    bool nearMe = false,
    String? category,
    bool pinnedOnly = false,
    String? focusPlaceId,
  }) {
    _currentIndex = 2;
    _mapNearMeOnOpen = nearMe;
    _mapCategoryFilter = category;
    _mapShowPinnedOnly = pinnedOnly;
    _mapFocusPlaceId = focusPlaceId;
    notifyListeners();
  }

  bool consumeMapNearMeFlag() {
    if (!_mapNearMeOnOpen) return false;
    _mapNearMeOnOpen = false;
    return true;
  }

  String? consumeMapCategoryFilter() {
    final category = _mapCategoryFilter;
    _mapCategoryFilter = null;
    return category;
  }

  bool consumeMapShowPinnedOnly() {
    if (!_mapShowPinnedOnly) return false;
    _mapShowPinnedOnly = false;
    return true;
  }

  String? consumeMapFocusPlaceId() {
    final id = _mapFocusPlaceId;
    _mapFocusPlaceId = null;
    return id;
  }
}
