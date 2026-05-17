import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/place_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/search_provider.dart';
import 'core/providers/map_provider.dart';
import 'core/providers/main_navigation_provider.dart';

// Widgets
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlaceProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<PlaceProvider, HomeProvider>(
          create: (_) => HomeProvider(),
          update: (_, places, home) => home!..bind(places),
        ),
        ChangeNotifierProxyProvider<PlaceProvider, SearchProvider>(
          create: (_) => SearchProvider(),
          update: (_, places, search) => search!..bind(places),
        ),
        ChangeNotifierProxyProvider<PlaceProvider, MapProvider>(
          create: (_) => MapProvider(),
          update: (_, places, map) => map!..bind(places),
        ),
        ChangeNotifierProvider(create: (_) => MainNavigationProvider()),
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
      home: const AuthWrapper(),
    );
  }
}
