import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_management/firebase_options.dart';
import 'package:task_management/screens/home_screen.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod providers
final authServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService();
});

final authStateProvider = StreamProvider<CustomUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(
    child: TaskManagementApp(),
  ));
}

class TaskManagementApp extends StatelessWidget {
  const TaskManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends ConsumerWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return HomeScreen(
            userId: user.uid,
            user: user,
          );
        }
        return const LoginScreen();
      },
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Text('Authentication Error: $error'),
          ),
        );
      },
    );
  }
}
