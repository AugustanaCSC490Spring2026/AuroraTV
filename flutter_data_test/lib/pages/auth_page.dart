import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../widgets/retro_ui.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isObscured = true;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'email-already-in-use':
          message = 'That email is already in use.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'invalid-credential':
          message = 'Invalid login credentials.';
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  Future<void> _continueAsGuest() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> _forgotPassword() async {
    if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email first.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Something went wrong.')),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsivePage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final brand = const _BrandPanel();
            final form = _buildSignInPanel(context);

            if (!isWide) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [brand, const SizedBox(height: 22), form],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: brand),
                const SizedBox(width: 24),
                Expanded(flex: 9, child: form),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSignInPanel(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final actionLabel = _isLogin ? 'Sign in' : 'Create account';
    final supportLabel = _isLogin ? 'New to the club?' : 'Already a member?';
    final supportAction = _isLogin ? 'Create account' : 'Sign in';

    return RetroPanel(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RetroWindowBar(title: 'AURORA.EXE'),
            const SizedBox(height: 18),
            Text(
              _isLogin ? 'Member Login' : 'Create Membership',
              style: text.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Enter your credentials, or boot straight into guest mode.'
                  : 'Set up your account and start building your shelf.',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (val) =>
                  (val == null || !val.contains('@')) ? 'Invalid email' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordCtrl,
              obscureText: _isObscured,
              textInputAction: _isLogin
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _isObscured ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
              validator: (val) => (val == null || val.length < 6)
                  ? 'Password must be at least 6 characters'
                  : null,
              onFieldSubmitted: (_) {
                if (_isLogin) _submit();
              },
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmPasswordCtrl,
                obscureText: _isObscured,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (val) =>
                    val != passwordCtrl.text ? 'Passwords do not match' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            if (_isLogin) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _forgotPassword,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Forgot password?'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            RetroButton(
              label: actionLabel,
              icon: _isLogin
                  ? Icons.login_rounded
                  : Icons.person_add_alt_1_rounded,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            RetroButton(
              label: 'Continue as guest',
              icon: Icons.person_outline_rounded,
              isPrimary: false,
              onPressed: _continueAsGuest,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Text(supportLabel, style: text.bodyMedium),
                TextButton.icon(
                  onPressed: _toggleMode,
                  icon: Icon(
                    _isLogin
                        ? Icons.person_add_alt_1_rounded
                        : Icons.login_rounded,
                    size: 18,
                  ),
                  label: Text(supportAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: auroraBlue,
        border: Border.all(color: auroraInk, width: 4),
        boxShadow: const [
          BoxShadow(color: auroraShadow, blurRadius: 0, offset: Offset(8, 8)),
        ],
      ),
      child: CustomPaint(
        painter: const _BrandPanelPainter(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LogoMark(),
            const SizedBox(height: 104),
            DecoratedBox(
              decoration: BoxDecoration(
                color: auroraCream.withAlpha(220),
                border: Border.all(color: auroraInk, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'AuroraTV',
                  style: text.displaySmall?.copyWith(color: auroraInk),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Pick a mood, genre, or topic and launch a curated video channel without the endless scroll.',
              style: text.bodyLarge?.copyWith(
                color: auroraWhite,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 28),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                RetroFeaturePill(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Curated channels',
                ),
                RetroFeaturePill(
                  icon: Icons.tune_rounded,
                  label: 'Smart filters',
                ),
                RetroFeaturePill(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'Auto play',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: auroraInk,
            border: Border(
              top: BorderSide(color: auroraWhite, width: 3),
              left: BorderSide(color: auroraWhite, width: 3),
              right: BorderSide(color: auroraInk, width: 3),
              bottom: BorderSide(color: auroraInk, width: 3),
            ),
          ),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        const Text(
          'Aurora',
          style: TextStyle(
            color: auroraInk,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _BrandPanelPainter extends CustomPainter {
  const _BrandPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = auroraYellow;
    canvas.drawRect(Rect.fromLTWH(size.width - 118, 28, 72, 72), paint);

    paint.color = auroraGreen;
    canvas.drawCircle(Offset(size.width - 62, size.height - 84), 48, paint);

    paint
      ..color = auroraInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    for (var y = 88.0; y < size.height - 40; y += 22) {
      canvas.drawLine(
        Offset(size.width - 170, y),
        Offset(size.width - 118, y + 16),
        paint,
      );
    }

    final triangle = Path()
      ..moveTo(28, size.height - 90)
      ..lineTo(74, size.height - 148)
      ..lineTo(118, size.height - 78)
      ..close();
    paint
      ..style = PaintingStyle.fill
      ..color = auroraBlue;
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
