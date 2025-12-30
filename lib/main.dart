/// Main application entry point for the Task Management System
/// Provides comprehensive app initialization, theming, and authentication handling
/// Includes advanced logging, error handling, and responsive design features
library;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/firebase_config.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/task_list_notifier.dart';
import 'package:task_management/screens/home_screen.dart';
import 'package:task_management/screens/login_screen.dart';

/// Global logger for application-wide logging
final Logger _logger = Logger('TaskManagementApp');

/// Main application entry point
/// Initializes Firebase, logging, and runs the app
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize comprehensive logging system
  _initializeLogging();
  
  try {
    // Initialize Firebase configuration
    await FirebaseConfig.initialize();
    _logger.info('Firebase initialized successfully');
    
    // Run the application with error handling
    await _runAppWithErrorHandling();
  } catch (e, stackTrace) {
    _logger.severe('Failed to initialize application', e, stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

/// Initializes comprehensive logging configuration
/// Sets up different log levels for debug and release modes
void _initializeLogging() {
  // Set appropriate log level based on build mode
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  
  // Configure log output with detailed formatting
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer();
    buffer.writeln('[${record.level.name}] ${record.time}: ${record.message}');
    
    if (record.error != null) {
      buffer.writeln('Error: ${record.error}');
    }
    
    if (record.stackTrace != null) {
      buffer.writeln('Stack trace: ${record.stackTrace}');
    }
    
    // Print formatted log message
    print(buffer.toString());
  });
  
  _logger.info('Logging system initialized');
}

/// Runs the app with comprehensive error handling
/// Catches and handles unhandled errors gracefully
Future<void> _runAppWithErrorHandling() async {
  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    _logger.severe(
      'Flutter error: ${details.exception}',
      details.exception,
      details.stack,
    );
  };
  
  // Run the main app
  runApp(const TaskManagementApp());
}

/// Main application widget with comprehensive theming and configuration
/// Provides Material Design 3 theming, responsive design, and accessibility features
class TaskManagementApp extends StatelessWidget {
  const TaskManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication service provider
        ChangeNotifierProvider<AuthenticationService>(
          create: (context) => AuthenticationService(),
          lazy: false, // Initialize immediately for auth state
        ),
        // Task list notifier provider
        ChangeNotifierProvider<TaskListNotifier>(
          create: (context) => TaskListNotifier(),
          lazy: true, // Initialize only when needed
        ),
      ],
      child: MaterialApp(
        // App metadata
        title: 'Task Management System',
        debugShowCheckedModeBanner: kDebugMode,
        
        // Comprehensive theming configuration
        theme: _buildTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system, // Follow system theme
        
        // Navigation and routing configuration
        home: const AuthenticationWrapper(),
        
        // Material 3 features
        useInheritedMediaQuery: true,
        builder: (context, child) {
          return MediaQuery(
            // Ensure minimum text scale for accessibility
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 2.0)),
            ),
            child: child!,
          );
        },
        
        // Error handling configuration
        onUnknownRoute: (settings) {
          _logger.warning('Unknown route accessed: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => const ErrorScreen(
              title: 'Page Not Found',
              message: 'The requested page could not be found.',
            ),
          );
        },
      ),
    );
  }

  /// Builds the primary light theme
  /// Material Design 3 with orange accent and comprehensive styling
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.light,
      ),
      
      // App bar theming
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        scrolledUnderElevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card theming
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Elevated button theming
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      // Input decoration theming
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Visual density and spacing
        visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
    );
  }

  /// Builds the dark theme
  /// Material Design 3 dark theme with orange accent
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.dark,
      ),
      
      // Dark theme specific configurations
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
      ),
      
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Apply same theming as light theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[800],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

/// Authentication wrapper widget with comprehensive user state management
/// Handles authentication flow, admin role checking, and error recovery
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the auth service without listening to it
    final authService = Provider.of<AuthenticationService>(context, listen: false);
    
    return StreamBuilder<CustomUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Log authentication state changes
        if (snapshot.hasData) {
          _logger.info('Authentication state changed: ${snapshot.data?.uid ?? 'null'}');
        }
        
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        // Handle error state
        if (snapshot.hasError) {
          _logger.severe('Authentication snapshot error', snapshot.error);
          return ErrorScreen(
            title: 'Authentication Error',
            message: 'Failed to load authentication state. Please try again.',
            onRetry: () {
              // Trigger a rebuild by creating a new widget
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthenticationWrapper()),
              );
            },
          );
        }
        
        final user = snapshot.data;
        
        // Handle authenticated user
        if (user != null) {
          try {
            final isAdmin = authService.isAdmin;
            _logger.info('User authenticated: ${user.uid}, Admin: $isAdmin');
            
            return HomeScreen(
              user: user,
              userId: user.uid,
              isAdmin: isAdmin,
            );
          } catch (e) {
            _logger.severe('Error creating home screen', e);
            return const ErrorScreen(
              title: 'Application Error',
              message: 'Failed to load home screen. Please restart the app.',
            );
          }
        } 
        // Handle unauthenticated user
        else {
          _logger.info('User not authenticated, showing login screen');
          return const LoginScreen();
        }
      },
    );
  }
}

/// Loading screen widget for showing during authentication initialization
/// Provides a clean loading experience with branding
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.task,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            // Loading text
            Text(
              'Loading Task Manager...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen widget for displaying application errors
/// Provides user-friendly error messages and recovery options
class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              // Error title
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Error message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Retry button
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emergency error app for critical initialization failures
/// Shows when the main app cannot be initialized
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Critical Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The application failed to start. Please restart the app.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (kDebugMode)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}