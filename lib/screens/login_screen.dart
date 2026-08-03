/// Login screen for user authentication
/// Provides secure access to the task management application
/// Includes form validation, error handling, and role-based authentication
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/widgets/app_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form controllers for user input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Form state management
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Validates email format using regex pattern
  /// Ensures email follows standard format (local@domain)
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    // Email regex pattern for basic validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password strength and requirements
  /// Ensures password meets security standards
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    
    if (value.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validates name input
  /// Ensures name is not empty and meets basic requirements
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name must not exceed 50 characters';
    }
    
    return null;
  }

  /// Builds the main login interface
  /// Creates responsive layout with form validation and modern styling
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Container(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: keyboardHeight + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo and title
                  _buildHeader(),
                  SizedBox(height: screenHeight * 0.05),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Login form
                          _buildLoginForm(authService),
                          const SizedBox(height: 16),
                          // Role selection
                          _buildRoleSelection(authService),
                          const SizedBox(height: 24),
                          // Login button
                          _buildLoginButton(authService),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Registration link
                  _buildRegistrationLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds app header with logo and title
  /// Creates visual branding and welcome message
  Widget _buildHeader() {
    return Column(
      children: [
        // App logo/icon
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.terra,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 36,
            color: AppColors.shell,
          ),
        ),
        const SizedBox(height: 20),
        // App title and welcome message
        Text(
          'TaskHub',
          style: AppTheme.display(size: 32, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        const Text(
          'Welcome back! Please login to continue',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }

  /// Builds the main login form fields
  /// Includes name, email, and password inputs with validation
  Widget _buildLoginForm(AuthenticationService authService) {
    return Column(
      children: [
        // Name input field
        TextFormField(
          controller: nameController,
          validator: _validateName,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person, color: AppColors.ink3),
          ),
        ),
        const SizedBox(height: 16),
        // Email input field
        TextFormField(
          controller: emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email, color: AppColors.ink3),
          ),
        ),
        const SizedBox(height: 16),
        // Password input field
        TextFormField(
          controller: passwordController,
          validator: _validatePassword,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock, color: AppColors.ink3),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.ink3,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds role selection dropdown
  Widget _buildRoleSelection(AuthenticationService authService) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Role',
      ),
      initialValue: authService.selectedRole.isEmpty ? null : authService.selectedRole,
      items: ['admin', 'regular'].map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(role[0].toUpperCase() + role.substring(1)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          authService.selectedRole = value;
        }
      },
    );
  }

  /// Builds login button
  Widget _buildLoginButton(AuthenticationService authService) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _isLoading
          ? const ElevatedButton(
              onPressed: null,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.shell,
                  strokeWidth: 2,
                ),
              ),
            )
          : PillButton(
              label: 'Login',
              onPressed: () => _handleLogin(authService),
            ),
    );
  }

  /// Builds registration link
  Widget _buildRegistrationLink() {
    return TextButton(
      onPressed: () {
        // Navigate to registration screen
      },
      child: const Text(
        'Don\'t have an account? Register',
        style: TextStyle(color: AppColors.ink2),
      ),
    );
  }

  /// Handles login process
  Future<void> _handleLogin(AuthenticationService authService) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await authService.signIn(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text,
        );
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: AppColors.rust,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
