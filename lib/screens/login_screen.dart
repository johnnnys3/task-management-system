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

const double _kLoginBreakpoint = 900;

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
  /// Two-pane layout (form + decorative preview) on wide screens, form-only below 900px.
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);
    final isWide = MediaQuery.sizeOf(context).width >= _kLoginBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildFormPane(authService)),
            if (isWide) const Expanded(child: _PreviewPane()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPane(AuthenticationService authService) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: keyboardHeight + 20,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLoginForm(authService),
                    const SizedBox(height: 16),
                    _buildRoleSelection(authService),
                    const SizedBox(height: 24),
                    _buildLoginButton(authService),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildRegistrationLink(),
            ],
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
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.terra,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 32,
            color: AppColors.shell,
          ),
        ),
        const SizedBox(height: 18),
        // App title and welcome message
        Text(
          'TaskHub',
          style: AppTheme.display(size: 30, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        const Text(
          'Welcome back! Please login to continue',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.ink2,
          ),
          textAlign: TextAlign.center,
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
          decoration: _pillDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            icon: Icons.person,
          ),
        ),
        const SizedBox(height: 14),
        // Email input field
        TextFormField(
          controller: emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: _pillDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            icon: Icons.email,
          ),
        ),
        const SizedBox(height: 14),
        // Password input field
        TextFormField(
          controller: passwordController,
          validator: _validatePassword,
          obscureText: _obscurePassword,
          decoration: _pillDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            icon: Icons.lock,
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

  InputDecoration _pillDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.ink3),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: AppColors.edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: AppColors.terra, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }

  /// Builds role selection dropdown
  Widget _buildRoleSelection(AuthenticationService authService) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Role',
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
              label: 'Sign in',
              onPressed: () => _handleLogin(authService),
            ),
    );
  }

  /// Builds registration link
  Widget _buildRegistrationLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          // Navigate to registration screen
        },
        child: const Text(
          'New here? Sign up',
          style: TextStyle(color: AppColors.ink2),
        ),
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

/// Decorative right-hand pane on wide screens: a sand background with an
/// overlapping preview card mimicking a mini "Today" list.
class _PreviewPane extends StatelessWidget {
  const _PreviewPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sand,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: AppTheme.display(size: 20)),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's on your plate",
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
                ),
                const SizedBox(height: 18),
                const _PreviewTaskRow(title: 'Review Q3 launch plan', done: true),
                const SizedBox(height: 10),
                const _PreviewTaskRow(title: 'Sync with design on TaskHub', done: false),
                const SizedBox(height: 10),
                const _PreviewTaskRow(title: 'Ship the notifications redesign', done: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewTaskRow extends StatelessWidget {
  final String title;
  final bool done;

  const _PreviewTaskRow({required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          size: 20,
          color: done ? AppColors.terra : AppColors.ink3,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              color: done ? AppColors.ink3 : AppColors.ink,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
