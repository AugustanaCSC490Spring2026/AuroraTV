import 'package:flutter/material.dart';
import 'youtube_page.dart';

void main() => runApp(const MaterialApp(home: AuthPage()));

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true; // State toggle
  bool _isObscured = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Logic for Login vs Sign Up
      final message = _isLogin ? "Logging in..." : "Creating account...";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      // Navigate to YouTube page after successful validation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YoutubePage(
            videos: [
              {
                'videoId': 'dQw4w9WgXcQ', // Example video ID
                'title': 'Example Video',
                'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              },
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Prevents keyboard overflow
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Title
                Text(
                  _isLogin ? "Welcome Back" : "Create Account",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Email
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) => (val == null || !val.contains('@'))
                      ? 'Invalid email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _isObscured = !_isObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_isLogin ? "LOGIN" : "SIGN UP"),
                  ),
                ),

                // The Toggle Button
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: const TextStyle(color: Colors.blueGrey),
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
