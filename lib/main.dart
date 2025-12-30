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
import 'package:task_management/service/notification_service.dart';

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
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    notificationService.startNotificationScheduler();
    _logger.info('Notification service started');
    
    // Run the application with error handling
    await _runAppWithErrorHandling(notificationService);
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
    buffer.write('[${record.level.name}] ${record.time}: ${record.message}');
    
    if (record.error != null) {
      buffer.write('\nError: ${record.error}');
    }
    
    if (record.stackTrace != null) {
      buffer.write('\nStack trace: ${record.stackTrace}');
    }
    
    // Print formatted log message
    debugPrint(buffer.toString());
  });
  
  _logger.info('Logging system initialized');
}

/// Runs the app with comprehensive error handling
/// Catches and handles unhandled errors gracefully
Future<void> _runAppWithErrorHandling(NotificationService notificationService) async {
  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    _logger.severe(
      'Flutter error: ${details.exception}',
      details.exception,
      details.stack,
    );
  };
  
  // Run the main app with notification service provider
  runApp(TaskManagementApp(notificationService: notificationService));
}

/// Main application widget with comprehensive theming and configuration
/// Provides Material Design 3 theming, responsive design, and accessibility features
class TaskManagementApp extends StatelessWidget {
  final NotificationService notificationService;
  
  const TaskManagementApp({
    super.key,
    required this.notificationService,
  });

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
        // Notification service provider
        Provider<NotificationService>.value(
          value: notificationService,
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
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 2.0),
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

  /// Builds primary light theme
  /// Material Design 3 with purple productivity theme
  /// Represents focus, efficiency, and professional task management
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B46C1), // Professional purple
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF6B46C1), // Deep Purple
        secondary: const Color(0xFF9C27B0), // Accent Purple
        surface: Colors.white, // Clean white surfaces
        onPrimary: Colors.white, // White text on purple
        onSecondary: Colors.white, // White text on purple
        error: const Color(0xFFE53935), // Soft Red
        onError: Colors.white, // White text on red
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FF), // Very light purple background
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6B46C1), // Deep Purple
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0), // Purple
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E6), // Light Purple border
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6B46C1), // Deep Purple focus
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53935), // Red error
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53935), // Red error
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF6B46C1), // Deep Purple labels
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9E9E9E), // Medium Purple hints
        ),
        prefixIconColor: const Color(0xFF6B46C1), // Deep Purple icons
        suffixIconColor: const Color(0xFF9C27B0), // Accent Purple icons
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B46C1), // Deep Purple
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B46C1), // Deep Purple
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF2D3748), // Dark text
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF2D3748), // Dark text
        ),
      ),
      // Add text field theme for input text visibility
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFF6B46C1), // Purple cursor
        selectionColor: const Color(0xFF6B46C1).withOpacity(0.3), // Purple selection
        selectionHandleColor: const Color(0xFF6B46C1), // Purple handles
      ),
    );
  }

  /// Builds dark theme
  /// Material Design 3 dark theme with purple productivity theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B46C1), // Professional purple
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF9C27B0), // Lighter purple for dark mode
        secondary: const Color(0xFFB39DDB), // Light accent purple
        surface: const Color(0xFF1A1A2E), // Dark surface
        onPrimary: Colors.white, // White text on purple
        onSecondary: Colors.white, // White text on purple
        error: const Color(0xFFEF5350), // Lighter red for dark mode
        onError: Colors.white, // White text on red
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1E), // Very dark background
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E), // Dark surface
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: const Color(0xFF2D3748), // Dark cards
        shadowColor: Colors.black.withOpacity(0.3),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0), // Purple
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D3748), // Dark input background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4A5568), // Medium dark border
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF9C27B0), // Purple focus
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF5350), // Red error
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF5350), // Red error
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB39DDB), // Light purple labels
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF718096), // Gray hints
        ),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            // Loading text
            Text(
              'Loading TaskHub...',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
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
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Critical Error',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The application failed to start.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please restart the app or contact support.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          error,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}