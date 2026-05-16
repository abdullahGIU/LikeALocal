import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../auth/auth_wrapper.dart';
import '../auth/login_screen.dart';

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
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
                child: const Text('Log In', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1D9E75),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            // Email
            Text(
              user.email,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Info Cards
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: Color(0xFF1D9E75)),
                title: const Text('Premium'),
                trailing: user.isPremium
                    ? const Icon(Icons.check_circle, color: Color(0xFF1D9E75))
                    : const Text('Free'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Color(0xFF1D9E75)),
                title: const Text('Super User'),
                trailing: user.isSuperUser
                    ? const Icon(Icons.check_circle, color: Color(0xFF1D9E75))
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
            const SizedBox(height: 32),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthWrapper()),
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
