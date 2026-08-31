import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lean_eat_theme.dart';
import 'profile_service.dart';

class LeanEatAuthGate extends StatefulWidget {
  final Widget onboardingHome;
  final Widget Function(Map<String, dynamic> profile) completedHomeBuilder;

  const LeanEatAuthGate({
    super.key,
    required this.onboardingHome,
    required this.completedHomeBuilder,
  });

  @override
  State<LeanEatAuthGate> createState() => _LeanEatAuthGateState();
}

class _LeanEatAuthGateState extends State<LeanEatAuthGate> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadProfile() {
    return ProfileService(Supabase.instance.client).currentProfileMap();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LeanEatAuthScreen();

    return ValueListenableBuilder<int>(
      valueListenable: ProfileService.revision,
      builder: (context, _, __) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 12),
                        const Text(
                          'LeanEat could not load your saved profile.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final profile = snapshot.data;
            final completed = profile?['onboarding_complete'] == true;
            if (completed && profile != null) {
              return widget.completedHomeBuilder(profile);
            }
            return widget.onboardingHome;
          },
        );
      },
    );
  }
}

class LeanEatAuthScreen extends StatefulWidget {
  const LeanEatAuthScreen({super.key});

  @override
  State<LeanEatAuthScreen> createState() => _LeanEatAuthScreenState();
}

class _LeanEatAuthScreenState extends State<LeanEatAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = true;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    if (!email.contains('@') || password.length < 8 || (_signUp && name.length < 2)) {
      _message('Enter a valid email, a name, and a password of at least 8 characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name, 'display_name': name},
        );
        if (response.session == null) {
          _message('Account created. Check your email to confirm your address, then sign in.');
          setState(() => _signUp = false);
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      _message(e.message);
    } catch (_) {
      _message('Could not complete that request. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F8F2), Color(0xFFE7F6EC), Color(0xFFF3F8DC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: LeanEatLogo(size: 70)),
                        const SizedBox(height: 26),
                        Text(
                          _signUp ? 'Build your strongest routine.' : 'Welcome back.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: LeanEatColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _signUp
                              ? 'Your training, recovery and progress in one adaptive fitness account.'
                              : 'Sign in to continue your programme and progress.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF66766D), height: 1.4),
                        ),
                        const SizedBox(height: 26),
                        if (_signUp) ...[
                          TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline))),
                          const SizedBox(height: 12),
                        ],
                        TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _hidePassword,
                          onSubmitted: (_) => _busy ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(_busy ? 'PLEASE WAIT…' : (_signUp ? 'CREATE ACCOUNT' : 'SIGN IN')),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                          child: Text(_signUp ? 'Already have an account? Sign in' : 'New to LeanEat? Create an account'),
                        ),
                        if (!_signUp)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final email = _email.text.trim();
                                    if (!email.contains('@')) {
                                      _message('Enter your email first.');
                                      return;
                                    }
                                    try {
                                      await Supabase.instance.client.auth.resetPasswordForEmail(email);
                                      _message('Password reset email sent.');
                                    } on AuthException catch (e) {
                                      _message(e.message);
                                    }
                                  },
                            child: const Text('Forgot password?'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
