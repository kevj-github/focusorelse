import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/pact_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PactProvider()),
      ],
      child: MaterialApp(
        title: 'Focus or Else',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFFF2659),
          scaffoldBackgroundColor: const Color(0xFF0A0A0B),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFFF2659),
            secondary: const Color(0xFFFF4757),
            surface: const Color(0xFF1F1E1F),
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2659)),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
