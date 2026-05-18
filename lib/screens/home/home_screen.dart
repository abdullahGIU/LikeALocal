import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/main_navigation_provider.dart';
import '../../core/providers/place_provider.dart';
import '../../widgets/ai_recommendations_card.dart';
import '../../widgets/place_card.dart';
import '../../widgets/sponsored_places_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  late final ScrollController _scrollController;
  MainNavigationProvider? _navigation;
  int _homeScrollNonce = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<MainNavigationProvider>();
    if (_navigation != nav) {
      _navigation?.removeListener(_onNavigationChanged);
      _navigation = nav;
      _homeScrollNonce = nav.homeScrollToTopNonce;
      _navigation!.addListener(_onNavigationChanged);
    }
  }

  @override
  void dispose() {
    _navigation?.removeListener(_onNavigationChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavigationChanged() {
    final nav = _navigation;
    if (nav == null) return;
    if (nav.homeScrollToTopNonce != _homeScrollNonce) {
      _homeScrollNonce = nav.homeScrollToTopNonce;
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final places = context.watch<PlaceProvider>();
    final displayedPlaces = _selectedCategory == null
        ? home.nearbyPlaces
        : places.placesForCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: home.isLoading && home.nearbyPlaces.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<PlaceProvider>().refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 160,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF00BC7D),
                              Color(0xFF009689),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LikeALocal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Discover hidden gems near you',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SponsoredPlacesSection()),
                  const SliverToBoxAdapter(child: AiRecommendationsCard()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GestureDetector(
                        onTap: () =>
                            context.read<MainNavigationProvider>().openSearch(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey.shade500),
                              const SizedBox(width: 10),
                              Text(
                                'Search places, cafés, parks...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (home.locationMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Material(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.location_off,
                                    color: Colors.amber.shade900),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    home.locationMessage!,
                                    style:
                                        TextStyle(color: Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (home.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          home.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trending',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<MainNavigationProvider>().openMap(
                                    nearMe: true,
                                    category: _selectedCategory,
                                  );
                            },
                            child: Text(
                              _selectedCategory == null
                                  ? 'View Map'
                                  : 'Map: $_selectedCategory',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: home.trendingCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final entry =
                              home.trendingCategories.entries.elementAt(index);
                          final isSelected = _selectedCategory == entry.key;
                          return _CategoryChip(
                            label: entry.key,
                            count: entry.value,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory =
                                    isSelected ? null : entry.key;
                              });
                              context.read<MainNavigationProvider>().openMap(
                                    category: isSelected ? null : entry.key,
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        _selectedCategory == null
                            ? 'Nearby Gems'
                            : '$_selectedCategory near you',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (displayedPlaces.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No nearby places found.'),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: PlaceCard(place: displayedPlaces[index]),
                          );
                        },
                        childCount: displayedPlaces.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : const Color(0xFFE8FFF5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : const Color(0xFF00BC7D).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF007A53),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
