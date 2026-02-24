import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../database/hive_boxes.dart';

class PinAuth {
  static const _pinHashKey = 'pin_hash';
  static const _pinEnabledKey = 'pin_enabled';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _lockTimeoutKey = 'lock_timeout_minutes';

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static bool get isPinEnabled =>
      HiveBoxes.settings.get(_pinEnabledKey, defaultValue: false) as bool;

  static bool get isBiometricEnabled =>
      HiveBoxes.settings.get(_biometricEnabledKey, defaultValue: false) as bool;

  static int get lockTimeoutMinutes =>
      HiveBoxes.settings.get(_lockTimeoutKey, defaultValue: 5) as int;

  static Future<void> setPinEnabled(bool value) async {
    await HiveBoxes.settings.put(_pinEnabledKey, value);
  }

  static Future<void> setBiometricEnabled(bool value) async {
    await HiveBoxes.settings.put(_biometricEnabledKey, value);
  }

  static Future<void> setLockTimeout(int minutes) async {
    await HiveBoxes.settings.put(_lockTimeoutKey, minutes);
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> setPin(String pin) async {
    if (pin.length < 4) return false;
    final hash = _hashPin(pin);
    await HiveBoxes.pin.put(_pinHashKey, hash);
    await setPinEnabled(true);
    return true;
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = HiveBoxes.pin.get(_pinHashKey) as String?;
    if (stored == null) return true;
    return _hashPin(pin) == stored;
  }

  static Future<bool> changePin(String oldPin, String newPin) async {
    final ok = await verifyPin(oldPin);
    if (!ok) return false;
    return setPin(newPin);
  }

  static Future<bool> removePin(String currentPin) async {
    final ok = await verifyPin(currentPin);
    if (!ok) return false;
    await HiveBoxes.pin.delete(_pinHashKey);
    await setPinEnabled(false);
    await setBiometricEnabled(false);
    return true;
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometric() async {
    try {
      final can = await _localAuth.canCheckBiometrics;
      if (!can) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Unlock QR Scanner',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }
}
