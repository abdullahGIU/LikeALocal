import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/main_navigation_provider.dart';
import '../core/providers/place_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/chat/chats_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'app_bootstrap.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    MapScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaceProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<MainNavigationProvider>();

    return AppBootstrap(
      child: Scaffold(
        body: IndexedStack(
          index: nav.currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          onTap: (index) =>
              context.read<MainNavigationProvider>().onBottomNavTap(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textSecondary,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
