import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/firebase_config.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/task_list_notifier.dart';
import 'package:task_management/screens/home_screen.dart';
import 'package:task_management/screens/login_screen.dart'; // Import the TaskListNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize(); // Initialize Firebase

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationService>(
          create: (context) => AuthenticationService(),
        ),
        ChangeNotifierProvider<TaskListNotifier>(
          create: (context) => TaskListNotifier(), // Use create method for initialization
        ),
      ],
      child: MaterialApp(
        title: 'Task Management App',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: Colors.orange,
          hintColor: Colors.black,
          scaffoldBackgroundColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);

    return StreamBuilder<CustomUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user != null) {
          bool isAdmin = authService.isAdmin ?? false;

          return HomeScreen(user: user, userId: '', isAdmin: isAdmin);
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

void main() {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });

  runApp(MyApp());
}