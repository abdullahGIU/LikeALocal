import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../core/providers/auth_provider.dart' as app_auth;
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for Firebase to check auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final authProvider = context.read<app_auth.AuthProvider>();
          if (!authProvider.isLoggedIn) {
            authProvider.checkCurrentUser();
          }
          return const MainScreen();
        }

        // User is not logged in
        return const WelcomeScreen();
      },
    );
  }
}
