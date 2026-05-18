import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/search_history_service.dart';
import 'place_provider.dart';

class SearchProvider extends ChangeNotifier {
  PlaceProvider? _places;
  final SearchHistoryService _historyService;

  SearchProvider({SearchHistoryService? historyService})
      : _historyService = historyService ?? SearchHistoryService();

  List<Place> _filteredResults = [];
  List<Place> _viewedPlacesHistory = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBudget = 'any';
  String _selectedAtmosphere = 'any';
  double _maxDistanceKm = PlaceProvider.nearbyRadiusKm;

  List<Place> get filteredResults => _filteredResults;
  List<Place> get viewedPlacesHistory => _viewedPlacesHistory;
  bool get isLoading => _places?.isLoading ?? false;
  String? get errorMessage => _places?.errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedBudget => _selectedBudget;
  String get selectedAtmosphere => _selectedAtmosphere;
  double get maxDistanceKm => _maxDistanceKm;

  void bind(PlaceProvider places) {
    if (_places == places) return;
    _places?.removeListener(_onPlacesChanged);
    _places = places;
    _places!.addListener(_onPlacesChanged);
    _applyFilters();
  }

  void _onPlacesChanged() {
    _applyFilters();
    _resolveViewedHistory();
    notifyListeners();
  }

  Future<void> initialize() async {
    await _resolveViewedHistory();
    if ((_places?.allPlaces ?? []).isEmpty) {
      await _places?.refresh();
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> reloadHistory() async {
    await _resolveViewedHistory();
    notifyListeners();
  }

  Future<void> recordPlaceView(Place place) async {
    await _historyService.addViewedPlace(
      placeId: place.id,
      placeName: place.name,
    );
    await _resolveViewedHistory();
    notifyListeners();
  }

  Future<void> removeHistoryPlace(String placeId) async {
    await _historyService.removePlace(placeId);
    await _resolveViewedHistory();
    notifyListeners();
  }

  Future<void> _resolveViewedHistory() async {
    final entries = await _historyService.getViewedPlaces();
    final all = _places?.allPlaces ?? [];
    final pinned = _places?.pinnedPlaces ?? [];
    final pool = [...all, ...pinned];

    _viewedPlacesHistory = [
      for (final entry in entries)
        _findPlaceById(entry.id, pool) ?? _historyStub(entry),
    ];
  }

  Place _historyStub(ViewedPlaceEntry entry) {
    return Place(
      id: entry.id,
      name: entry.name,
      description: '',
      address: '',
      category: 'Other',
      latitude: 0,
      longitude: 0,
      mediaUrls: const [],
      mediaTypes: const [],
      tips: const [],
      rating: 0,
      reviewCount: 0,
      isOpen: true,
      budget: 'medium',
      atmosphere: 'lively',
    );
  }

  Place? _findPlaceById(String id, List<Place> places) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
  }

  void applyAdvancedFilters({
    required String budget,
    required String atmosphere,
    required double maxDistanceKm,
  }) {
    _selectedBudget = budget.toLowerCase();
    _selectedAtmosphere = atmosphere.toLowerCase();
    _maxDistanceKm = maxDistanceKm;
    _applyFilters();
  }

  void _applyFilters() {
    var results = List<Place>.from(_places?.allPlaces ?? []);

    if (_selectedCategory != 'All') {
      results = results.where((p) => p.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((place) {
        return place.name.toLowerCase().contains(query) ||
            place.description.toLowerCase().contains(query) ||
            place.address.toLowerCase().contains(query) ||
            place.category.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedBudget != 'any') {
      results = results.where((place) => place.budget == _selectedBudget).toList();
    }

    if (_selectedAtmosphere != 'any') {
      results =
          results.where((place) => place.atmosphere == _selectedAtmosphere).toList();
    }

    final userPosition = _places?.userPosition;
    if (userPosition != null) {
      results = results
          .where((place) => (place.distanceKm ?? double.infinity) <= _maxDistanceKm)
          .toList();
    }

    _filteredResults = results;
    notifyListeners();
  }
}
