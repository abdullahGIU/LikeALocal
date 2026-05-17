import 'package:flutter/material.dart';

import '../core/models/place.dart';
import 'media_picker_widget.dart';

class PlaceFormResult {
  final String name;
  final String description;
  final String category;
  final String address;
  final String localTips;
  final String recommendedDishes;
  final double? latitude;
  final double? longitude;
  final List<String> existingMediaUrls;
  final List<String> existingMediaTypes;
  final List<PickedMedia> newMedia;

  const PlaceFormResult({
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.localTips,
    required this.recommendedDishes,
    required this.latitude,
    required this.longitude,
    required this.existingMediaUrls,
    required this.existingMediaTypes,
    required this.newMedia,
  });
}

class PlaceForm extends StatefulWidget {
  static const categories = [
    'Hidden Gem',
    'Restaurant',
    'Cafe',
    'Museum',
    'Outdoor',
    'Shopping',
    'Nightlife',
    'Local Experience',
    'Other',
  ];

  final Place? initialPlace;
  final bool isLoading;
  final String submitLabel;
  final ValueChanged<PlaceFormResult> onSubmit;

  const PlaceForm({
    super.key,
    this.initialPlace,
    required this.isLoading,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _localTipsController;
  late final TextEditingController _recommendedDishesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  late String? _category;
  late List<String> _existingMediaUrls;
  late List<String> _existingMediaTypes;
  List<PickedMedia> _newMedia = [];

  @override
  void initState() {
    super.initState();
    final place = widget.initialPlace;
    _nameController = TextEditingController(text: place?.name ?? '');
    _descriptionController =
        TextEditingController(text: place?.description ?? '');
    _addressController = TextEditingController(text: place?.address ?? '');
    _localTipsController = TextEditingController(text: place?.localTips ?? '');
    _recommendedDishesController =
        TextEditingController(text: place?.recommendedDishes ?? '');
    _latitudeController =
        TextEditingController(text: place?.latitude?.toString() ?? '');
    _longitudeController =
        TextEditingController(text: place?.longitude?.toString() ?? '');
    _category =
        PlaceForm.categories.contains(place?.category) ? place?.category : null;
    _existingMediaUrls = [...?place?.mediaUrls];
    _existingMediaTypes = [...?place?.mediaTypes];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _localTipsController.dispose();
    _recommendedDishesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      PlaceFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category!,
        address: _addressController.text.trim(),
        localTips: _localTipsController.text.trim(),
        recommendedDishes: _recommendedDishesController.text.trim(),
        latitude: _parseOptionalDouble(_latitudeController.text),
        longitude: _parseOptionalDouble(_longitudeController.text),
        existingMediaUrls: _existingMediaUrls,
        existingMediaTypes: _existingMediaTypes,
        newMedia: _newMedia,
      ),
    );
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.parse(trimmed);
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    final requiredError = _requiredValidator(value, 'Description');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 20) {
      return 'Description must be at least 20 characters.';
    }
    return null;
  }

  String? _optionalNumberValidator(String? value, String label) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (double.tryParse(trimmed) == null) {
      return '$label must be a valid number.';
    }
    return null;
  }

  void _removeExistingMedia(int index) {
    setState(() {
      _existingMediaUrls.removeAt(index);
      if (index < _existingMediaTypes.length) {
        _existingMediaTypes.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(labelText: 'Place name'),
            validator: (value) => _requiredValidator(value, 'Place name'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: PlaceForm.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: widget.isLoading
                ? null
                : (value) => setState(() => _category = value),
            validator: (value) => _requiredValidator(value, 'Category'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            enabled: !widget.isLoading,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: _descriptionValidator,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressController,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: (value) => _requiredValidator(value, 'Address'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _localTipsController,
            enabled: !widget.isLoading,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Local tips'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _recommendedDishesController,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(labelText: 'Recommended dishes'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  enabled: !widget.isLoading,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (value) =>
                      _optionalNumberValidator(value, 'Latitude'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  enabled: !widget.isLoading,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (value) =>
                      _optionalNumberValidator(value, 'Longitude'),
                ),
              ),
            ],
          ),
          if (_existingMediaUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Current media',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _existingMediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final type = index < _existingMediaTypes.length
                      ? _existingMediaTypes[index]
                      : 'image';
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 96,
                          height: 96,
                          color: Colors.black12,
                          child: type == 'image'
                              ? Image.network(
                                  _existingMediaUrls[index],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.play_circle_outline,
                                  size: 36,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: widget.isLoading
                              ? null
                              : () => _removeExistingMedia(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          IgnorePointer(
            ignoring: widget.isLoading,
            child: MediaPickerWidget(
              selectedMedia: _newMedia,
              onChanged: (media) => setState(() => _newMedia = media),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
