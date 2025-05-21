import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ntakomisiyo1/providers/product_provider.dart';
import 'package:ntakomisiyo1/screens/home/home_screen.dart';
import 'package:ntakomisiyo1/providers/favorites_provider.dart';
import 'package:ntakomisiyo1/providers/auth_provider.dart';
import 'package:ntakomisiyo1/screens/admin/admin_dashboard.dart';
import 'package:ntakomisiyo1/screens/user/user_dashboard.dart';
import 'package:ntakomisiyo1/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ntakomisiyo1/services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Test Firebase
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();

  // Get FCM token
  String? token = await messagingService.getToken();
  print('FCM Token: $token'); // Save this token for testing

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NtaKomisiyo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
