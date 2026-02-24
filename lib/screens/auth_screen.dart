import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/pin_auth.dart';
import '../widgets/pin_keyboard.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _pin = '';
  static const _pinLength = 6;
  bool _showBiometric = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    PinAuth.canCheckBiometrics().then((v) {
      if (mounted) setState(() => _showBiometric = v && PinAuth.isBiometricEnabled);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!PinAuth.isBiometricEnabled || _checkingBiometric) return;
    _checkingBiometric = true;
    final ok = await PinAuth.authenticateWithBiometric();
    _checkingBiometric = false;
    if (!mounted) return;
    if (ok) Get.offAll(() => const HomeScreen());
  }

  void _onKey(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == _pinLength) _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    final ok = await PinAuth.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      Get.offAll(() => const HomeScreen());
    } else {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock QR Scanner',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),
              PinKeyboard(
                currentPin: _pin,
                pinLength: _pinLength,
                onKeyPressed: _onKey,
                onDelete: _onDelete,
                showBiometric: _showBiometric,
                onBiometric: _tryBiometric,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
