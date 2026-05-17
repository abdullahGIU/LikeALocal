import 'package:flutter/material.dart';
import '../models/place.dart';
import 'place_provider.dart';

class SearchProvider extends ChangeNotifier {
  PlaceProvider? _places;

  List<Place> _filteredResults = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBudget = 'Any';
  String _selectedAtmosphere = 'Any';
  double _maxDistanceKm = PlaceProvider.nearbyRadiusKm;

  List<Place> get filteredResults => _filteredResults;
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
    notifyListeners();
  }

  Future<void> initialize() async {
    if ((_places?.allPlaces ?? []).isEmpty) {
      await _places?.refresh();
    }
    _applyFilters();
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
    _selectedBudget = budget;
    _selectedAtmosphere = atmosphere;
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

    if (_selectedBudget != 'Any') {
      results =
          results.where((place) => place.budget == _selectedBudget.toLowerCase()).toList();
    }

    if (_selectedAtmosphere != 'Any') {
      results = results
          .where((place) => place.atmosphere == _selectedAtmosphere.toLowerCase())
          .toList();
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
