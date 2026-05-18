import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/place.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/main_navigation_provider.dart';
import '../../core/services/firestore_service.dart';
import '../auth/auth_wrapper.dart';
import '../auth/login_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../places/place_details_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                ),
                child: const Text('Log In', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1D9E75),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF1D9E75)),
                title: const Text('Settings'),
                subtitle: const Text('Notifications, AI, privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF1D9E75)),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome, color: Color(0xFF1D9E75)),
                title: const Text('AI Local Guide'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium,
                    color: Color(0xFF1D9E75)),
                title: const Text('Premium'),
                subtitle: Text(user.isPremium ? 'Active plan' : 'Upgrade for more'),
                trailing: user.isPremium
                    ? const Icon(Icons.check_circle, color: Color(0xFF1D9E75))
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Color(0xFF1D9E75)),
                title: const Text('Super User'),
                subtitle: user.isPremium
                    ? const Text('Included with Premium')
                    : null,
                trailing: (user.isPremium || user.isSuperUser)
                    ? const Text(
                        'Yes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D9E75),
                        ),
                      )
                    : const Text('No'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.push_pin, color: Color(0xFF1D9E75)),
                title: const Text('Pin Limit'),
                trailing: Text(user.pinLimit.toString()),
              ),
            ),
            if (userId != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My pinned places',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<MainNavigationProvider>().openMap(
                            pinnedOnly: true,
                          );
                    },
                    child: const Text('Show all on map'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Place>>(
                stream: FirestoreService().streamPinnedPlaces(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final pins = snapshot.data ?? [];
                  if (pins.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No pinned places yet. Open a place and tap Pin Place.',
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pins.map((place) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.push_pin,
                            color: Colors.amber.shade800,
                          ),
                          title: Text(place.name),
                          subtitle: Text(
                            place.address.isNotEmpty
                                ? place.address
                                : place.category,
                          ),
                          trailing: const Icon(Icons.map_outlined),
                          onTap: () {
                            context.read<MainNavigationProvider>().openMap(
                                  focusPlaceId: place.id,
                                );
                          },
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlaceDetailsScreen(place: place),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthWrapper(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
