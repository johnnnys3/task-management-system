import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user.dart';

// Add this provider definition
final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService();
});
class AuthException implements Exception {

  AuthException(this.message, {this.code = 'unknown'});
  final String message;
  final String code;

  @override
  String toString() => 'AuthException: $message';
}

class AuthValidationException extends AuthException {
  AuthValidationException(super.message) : super(code: 'validation');
}

class AuthNetworkException extends AuthException {
  AuthNetworkException(super.message) : super(code: 'network');
}

class AuthUserNotFoundException extends AuthException {
  AuthUserNotFoundException(super.message) : super(code: 'user-not-found');
}

class AuthWrongCredentialsException extends AuthException {
  AuthWrongCredentialsException() : super('Invalid email or password', code: 'wrong-credentials');
}

class AuthenticationService extends ChangeNotifier {

  AuthenticationService() {
    init();
  }
  static final Logger _logger = Logger('AuthenticationService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SharedPreferences prefs;
  final CollectionReference<Map<String, dynamic>> _userCollection =
      FirebaseFirestore.instance.collection('users');
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  bool _isRoleSelected = false;
  bool get isRoleSelected => _isRoleSelected;
  set isRoleSelected(bool value) {
    _isRoleSelected = value;
    notifyListeners();
  }

  String _selectedRole = '';
  String get selectedRole => _selectedRole;
  set selectedRole(String value) {
    _selectedRole = value;
    notifyListeners();
  }

  CustomUser? get currentUser {
    if (!_isInitialized) return null;
    return _auth.currentUser != null
        ? CustomUser(
            uid: _auth.currentUser!.uid,
            email: _auth.currentUser!.email!,
            role: prefs.getString('userRole') ?? 'regular',
            assignedProjects: [],
            name: _auth.currentUser!.displayName ?? '',
          )
        : null;
  }

  Stream<CustomUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((User? user) async {
      // Wait for initialization before accessing prefs
      if (!_isInitialized) {
        await init();
      }
      
      if (user == null) {
        return null;
      } else {
        // Try to get user role from Firestore first, then fallback to SharedPreferences
        String userRole = 'regular';
        try {
          final userDoc = await _userCollection.doc(user.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            userRole = userData?['role']?.toString() ?? 'regular';
            // Update SharedPreferences with the role from Firestore
            await prefs.setString('userRole', userRole);
          } else {
            // Fallback to SharedPreferences if Firestore doesn't have the role
            userRole = prefs.getString('userRole') ?? 'regular';
          }
        } catch (e) {
          _logger.warning('Error loading user role from Firestore: $e');
          // Fallback to SharedPreferences
          userRole = prefs.getString('userRole') ?? 'regular';
        }
        
        return CustomUser(
          uid: user.uid,
          email: user.email!,
          role: userRole,
          assignedProjects: [],
          name: user.displayName ?? '',
        );
      }
    }).asBroadcastStream();
  }

  bool get keepSignedIn {
    if (!_isInitialized) return false;
    return prefs.getBool('keepSignedIn') ?? false;
  }
  
  set keepSignedIn(bool value) {
    if (!_isInitialized) return;
    prefs.setBool('keepSignedIn', value);
    notifyListeners();
  }

  bool get isAdmin {
    if (!_isInitialized) return false;
    return prefs.getString('userRole') == 'admin';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      _logger.info('AuthenticationService initialized successfully');
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to initialize AuthenticationService', e);
      rethrow;
    }
  }

  /// Validates user credentials and signs in the user
  /// Throws [AuthValidationException] if input is invalid
  /// Throws [AuthUserNotFoundException] if user is not found
  /// Throws [AuthWrongCredentialsException] if credentials are invalid
  /// Throws [AuthNetworkException] for network-related errors
  Future<CustomUser> signIn(String name, String email, String password) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await init();
      }
      
      _validateSignInInput(name, email, password);

      if (isRoleSelected) {
        await _validateUserRole(name, email);
      }

      _logger.fine('Attempting to sign in user: $email');
      
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) {
          _logger.warning('Authentication failed: No user returned');
          throw AuthException('Authentication failed');
        }

        final customUser = CustomUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: selectedRole,
          assignedProjects: [],
          name: name,
        );

        _logger.info('User signed in successfully: ${userCredential.user!.uid}');
        notifyListeners();
        return customUser;
      } on FirebaseAuthException catch (e) {
        _logger.warning('Firebase auth error during sign in: ${e.code} - ${e.message}');
        if (e.code == 'user-not-found' || e.code == 'user-disabled') {
          throw AuthUserNotFoundException('User not found or disabled');
        } else if (e.code == 'wrong-password') {
          throw AuthWrongCredentialsException();
        } else if (e.code == 'network-request-failed') {
          throw AuthNetworkException('Network error during sign in');
        }
        rethrow;
      }
    } catch (e) {
      _logger.severe('Sign in error', e);
      rethrow;
    }
  }

  /// Creates a new user account with the provided details
  /// Throws [AuthValidationException] if input is invalid
  /// Throws [AuthException] for other authentication errors
  Future<CustomUser> signUp(String name, String email, String password, String role) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await init();
      }
      
      _validateSignUpInput(name, email, password, role);
      _logger.fine('Attempting to create user: $email');

      try {
        // Create user in Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user == null) {
          throw AuthException('Failed to create user');
        }

        // Update user profile with display name
        await userCredential.user?.updateDisplayName(name);
        await userCredential.user?.reload();

        final customUser = CustomUser(
          uid: userCredential.user!.uid,
          email: email,
          role: role,
          assignedProjects: [],
          name: name, // Use the provided name directly
        );

        // Save user role in shared preferences
        await prefs.setString('userRole', role);

        // Create user document in Firestore
        await _userCollection.doc(customUser.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _logger.info('User created successfully: ${customUser.uid}');
        notifyListeners();

        return customUser;
      } on FirebaseAuthException catch (e) {
        _logger.warning('Firebase auth error during sign up: ${e.code} - ${e.message}');
        if (e.code == 'email-already-in-use') {
          throw AuthException('Email already in use', code: 'email-already-in-use');
        } else if (e.code == 'weak-password') {
          throw AuthValidationException('Password is too weak');
        } else if (e.code == 'network-request-failed') {
          throw AuthNetworkException('Network error during sign up');
        }
        rethrow;
      }
    } catch (e) {
      _logger.severe('Sign up error', e);
      rethrow;
    }
  }

  Future<List<String>> fetchAssignedMembers(String username) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _userCollection.doc(username).get();

      if (userSnapshot.exists) {
        final List<dynamic> assignedProjects =
            (userSnapshot.data()?['assignedProjects'] as List<dynamic>?) ?? [];
        return assignedProjects.cast<String>();
      } else {
        return [];
      }
    } catch (error) {
      _logger.warning('Error fetching assigned members: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.warning('SignOut Error: $e');
      rethrow;
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// Validates sign in input parameters
  void _validateSignInInput(String name, String email, String password) {
    if (name.isEmpty) {
      throw AuthValidationException('Name cannot be empty');
    }
    if (email.isEmpty || !email.contains('@')) {
      throw AuthValidationException('Please enter a valid email');
    }
    if (password.length < 6) {
      throw AuthValidationException('Password must be at least 6 characters');
    }
  }

  /// Validates sign up input parameters
  void _validateSignUpInput(String name, String email, String password, String role) {
    _validateSignInInput(name, email, password);
    if (role.isEmpty) {
      throw AuthValidationException('Role must be selected');
    }
  }

  /// Validates user role from Firestore
  Future<void> _validateUserRole(String name, String email) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> query = await _userCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        throw AuthUserNotFoundException('User not found in database');
      }
      
      final userData = query.docs.first.data();
      final storedRole = userData['role'] as String?;
      
      if (storedRole != selectedRole) {
        throw AuthValidationException('Role mismatch for user');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthNetworkException('Failed to validate user role');
    }
  }
}