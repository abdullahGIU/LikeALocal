import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/place_provider.dart';
import 'core/providers/user_provider.dart';

// Widgets
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const LikeALocalApp(),
    ),
  );
}

class LikeALocalApp extends StatelessWidget {
  const LikeALocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LikeALocal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}