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
import '../chat/chat_privacy_screen.dart';
import '../notifications/notifications_screen.dart';
import '../places/place_details_screen.dart';
import '../places/my_places_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import '../../core/services/user_score_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color get mainGreen => const Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserScore();
    });
  }

  Future<void> _refreshUserScore() async {
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await UserScoreService().updateUserScore(userId);
        if (mounted) {
          await context.read<AuthProvider>().refreshUser();
        }
      } catch (e) {
        debugPrint('Error updating user score: $e');
      }
    }
  }

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
              const Text('You are not logged in',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                child: const Text('Log In',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: mainGreen,
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (user.isSuperUser)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⭐ Super Local',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            const SizedBox(height: 28),

            // Membership / Premium
            _profileCard(
              icon: Icons.workspace_premium,
              title: 'Membership',
              subtitle:
                  user.isPremium ? 'Premium account' : 'Free account',
              trailing: user.isPremium
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF1D9E75))
                  : TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen()),
                      ),
                      child: const Text('Upgrade'),
                    ),
            ),

            // Super User
            _profileCard(
              icon: Icons.star,
              title: 'Super User Status',
              subtitle: user.isSuperUser
                  ? 'Your posts get higher visibility'
                  : 'Help more tourists to become Super Local',
              trailing: user.isSuperUser
                  ? const Icon(Icons.verified, color: Colors.amber)
                  : const Text('Not yet'),
            ),

            // Pin Limit
            _profileCard(
              icon: Icons.push_pin,
              title: 'Pin Limit',
              subtitle: user.isPremium
                  ? 'Unlimited saved places'
                  : 'Free users have limited pins',
              trailing: Text(
                user.isPremium ? '∞' : user.pinLimit.toString(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            // Chat Privacy
            _profileCard(
              icon: Icons.chat_bubble_outline,
              title: 'Chat Privacy',
              subtitle: user.chatEnabled
                  ? user.chatScheduleEnabled
                      ? 'Chat ON (${user.chatAvailableFrom} - ${user.chatAvailableTo})'
                      : 'Chat ON, anytime'
                  : 'Chat OFF',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChatPrivacyScreen()),
              ),
            ),

            // Notifications
            _profileCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage your alerts',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),

            // AI Local Guide
            _profileCard(
              icon: Icons.auto_awesome,
              title: 'AI Local Guide',
              subtitle: 'Personalized recommendations',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              ),
            ),

            // Settings
            _profileCard(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Notifications, AI, privacy',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),

            // My Created Places
            if (userId != null)
              _profileCard(
                icon: Icons.add_location_alt,
                title: 'My Created Places',
                subtitle: 'Add, edit, or delete your places',
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyPlacesScreen()),
                ),
              ),

            // Pinned places
            if (userId != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Pinned Places',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context
                        .read<MainNavigationProvider>()
                        .openMap(pinnedOnly: true),
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
                          leading: Icon(Icons.push_pin,
                              color: Colors.amber.shade800),
                          title: Text(place.name),
                          subtitle: Text(place.address.isNotEmpty
                              ? place.address
                              : place.category),
                          trailing: const Icon(Icons.map_outlined),
                          onTap: () => context
                              .read<MainNavigationProvider>()
                              .openMap(focusPlaceId: place.id),
                          onLongPress: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaceDetailsScreen(place: place),
                            ),
                          ),
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
                          builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: mainGreen),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}
