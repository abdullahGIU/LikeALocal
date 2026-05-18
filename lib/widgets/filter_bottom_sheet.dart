import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/search_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const _budgetOptions = ['Any', 'Low', 'Medium', 'High'];
  static const _atmosphereOptions = ['Any', 'Quiet', 'Lively', 'Romantic'];

  late String _budget;
  late String _atmosphere;
  late double _distanceKm;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SearchProvider>();
    _budget = _capitalize(provider.selectedBudget == 'any'
        ? 'Any'
        : provider.selectedBudget);
    _atmosphere = _capitalize(provider.selectedAtmosphere == 'any'
        ? 'Any'
        : provider.selectedAtmosphere);
    _distanceKm = provider.maxDistanceKm;
  }

  String _capitalize(String value) {
    if (value == 'Any') return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Budget', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _budgetOptions.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: _budget == option,
                selectedColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color: _budget == option ? Colors.white : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _budget = option),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Atmosphere', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _atmosphereOptions.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: _atmosphere == option,
                selectedColor: AppColors.primaryGreen,
                labelStyle: TextStyle(
                  color:
                      _atmosphere == option ? Colors.white : AppColors.textPrimary,
                ),
                onSelected: (_) => setState(() => _atmosphere = option),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Distance', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_distanceKm.round()} km'),
            ],
          ),
          Slider(
            value: _distanceKm,
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppColors.primaryGreen,
            label: '${_distanceKm.round()} km',
            onChanged: (value) => setState(() => _distanceKm = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<SearchProvider>().applyAdvancedFilters(
                      budget: _budget == 'Any' ? 'any' : _budget.toLowerCase(),
                      atmosphere:
                          _atmosphere == 'Any' ? 'any' : _atmosphere.toLowerCase(),
                      maxDistanceKm: _distanceKm,
                    );
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
