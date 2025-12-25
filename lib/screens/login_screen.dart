import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/registration_screen.dart';
import 'package:task_management/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthenticationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 300,
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person, color: Colors.orange),
                  labelStyle: TextStyle(color: Colors.orange),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 300,
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.orange),
                  labelStyle: TextStyle(color: Colors.orange),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 300,
              child: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.orange),
                  labelStyle: TextStyle(color: Colors.orange),
                ),
                obscureText: true,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: authService.isRoleSelected,
                  onChanged: (value) {
                    authService.isRoleSelected = value ?? false;
                  },
                ),
                Text('Select Role', style: TextStyle(color: Colors.orange)),
              ],
            ),
            if (authService.isRoleSelected)
              SizedBox(height: 16),
              Container(
                width: 300,
                child: TextField(
                  controller: TextEditingController(text: authService.selectedRole),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.orange),
                    labelStyle: TextStyle(color: Colors.orange),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 24,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                try {
                  final user = await authService.signIn(
                    name,
                    email,
                    password,
                  );

                  if (user != null) {
                    final isAdmin = authService.isAdmin;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          user: user,
                          isAdmin: isAdmin,
                          userId: '',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login failed. Please check your credentials.'),
                      ),
                    );
                  }
                } catch (e) {
                  print('Login Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('An error occurred. Please try again.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.orange,
              ),
              child: Text('Login', style: TextStyle(color: Colors.black)),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}
