import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/place.dart';
import '../../core/providers/place_provider.dart';
import '../../core/providers/search_provider.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/place_card.dart';
import '../chat/ai_chat_screen.dart';
import '../places/place_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;

  static const _categories = [
    'All',
    'Cafés',
    'Restaurants',
    'Parks',
    'Museums',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showHistorySheet() async {
    final search = context.read<SearchProvider>();
    await search.reloadHistory();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlacesListSheet(
        title: 'Recently viewed',
        emptyMessage: 'Places you open will appear here.',
        places: search.viewedPlacesHistory,
        onRemove: search.removeHistoryPlace,
        onPlaceTap: (place) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailsScreen(place: place),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPinnedSheet() async {
    await context.read<PlaceProvider>().refresh();
    if (!mounted) return;

    final pinned = context.read<PlaceProvider>().pinnedPlaces;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlacesListSheet(
        title: 'Pinned places',
        emptyMessage: 'Pin places from their detail page to see them here.',
        places: pinned,
        leadingIcon: Icons.push_pin,
        iconColor: Colors.amber.shade800,
        onPlaceTap: (place) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailsScreen(place: place),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI guide',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: search.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search by name, category, address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => FilterBottomSheet.show(context),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: _showHistorySheet,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.push_pin, size: 18, color: Colors.amber.shade800),
                    label: const Text('Pinned'),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: _showPinnedSheet,
                  ),
                ),
                ..._categories.map((category) {
                  final isSelected = search.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.grey.shade300,
                      ),
                      onSelected: (_) => search.setCategory(category),
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${search.filteredResults.length} places found',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (search.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                search.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: search.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : search.filteredResults.isEmpty
                    ? const Center(child: Text('No places match your search.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: search.filteredResults.length,
                        itemBuilder: (context, index) {
                          return PlaceCard(
                            place: search.filteredResults[index],
                            showOpenStatus: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PlacesListSheet extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<Place> places;
  final void Function(Place place) onPlaceTap;
  final void Function(String placeId)? onRemove;
  final IconData leadingIcon;
  final Color? iconColor;

  const _PlacesListSheet({
    required this.title,
    required this.emptyMessage,
    required this.places,
    required this.onPlaceTap,
    this.onRemove,
    this.leadingIcon = Icons.place_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (places.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(emptyMessage),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: places.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(leadingIcon, color: iconColor),
                    title: Text(place.name),
                    subtitle: Text(
                      place.address.isNotEmpty
                          ? place.address
                          : place.category,
                    ),
                    trailing: onRemove != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => onRemove!(place.id),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => onPlaceTap(place),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
