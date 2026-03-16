import 'package:flutter/material.dart';
import '../main.dart';

const Color auroraMint = Color(0xFFC5FDD3);
const Color auroraLight = Color(0xFF94E1B4);
const Color auroraGreen = Color(0xFF69C5A0);
const Color auroraTeal = Color(0xFF45A994);
const Color auroraBlueTeal = Color(0xFF288D8A);
const Color auroraDeep = Color(0xFF126171);
const Color auroraNavy = Color(0xFF033854);
const Color auroraPanel = Color(0xFF08263D);
const Color auroraGlow = Color(0xFF5EF2D6);

void main() => runApp(
  MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: auroraNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: auroraBlueTeal,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: auroraPanel,
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: auroraLight),
        prefixIconColor: auroraGlow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: auroraDeep, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: auroraGlow, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: auroraBlueTeal,
          foregroundColor: auroraMint,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    ),
    home: const AuthPage(),
  ),
);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true; // State toggle
  bool _isObscured = true;
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

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
        MaterialPageRoute(builder: (context) => const KeyWordPage()),
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
                    color: auroraMint,
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

                // Confirm Password (only for sign up)
                if (!_isLogin)
                  TextFormField(
                    controller: confirmPasswordCtrl,
                    obscureText: _isObscured,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) => val != passwordCtrl.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                if (!_isLogin) const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: passwordCtrl,
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
                  validator: (val) => (val == null || val.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),

                // Main Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
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
                    style: const TextStyle(color: auroraLight),
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
