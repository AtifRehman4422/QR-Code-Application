import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_manager.dart';
import '../utils/pin_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Get.find<ThemeManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionTitle(title: 'Appearance'),
          Obx(() => ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeModeLabel(themeManager.themeMode.value)),
                onTap: () => _showThemePicker(context, themeManager),
              )),
          const Divider(height: 1),
          _SectionTitle(title: 'Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN lock'),
            subtitle: Text(
              PinAuth.isPinEnabled ? 'On' : 'Off',
            ),
            trailing: Switch(
              value: PinAuth.isPinEnabled,
              onChanged: (v) => _onPinToggle(context, v),
            ),
          ),
          if (PinAuth.isPinEnabled) ...[
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Unlock with biometrics'),
              trailing: Switch(
                value: PinAuth.isBiometricEnabled,
                onChanged: (v) async {
                  await PinAuth.setBiometricEnabled(v);
                  Get.forceAppUpdate();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Auto-lock timeout'),
              subtitle: Text('${PinAuth.lockTimeoutMinutes} min'),
              onTap: () => _showLockTimeoutPicker(context),
            ),
          ],
          const Divider(height: 1),
          _SectionTitle(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('QR Scanner'),
            subtitle: const Text('Offline • Secure • Light/Dark'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeModeOption mode) {
    switch (mode) {
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
      case ThemeModeOption.system:
        return 'System';
    }
  }

  void _showThemePicker(BuildContext context, ThemeManager themeManager) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () {
                themeManager.setThemeMode(ThemeModeOption.system);
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.light_mode),
              onTap: () {
                themeManager.setThemeMode(ThemeModeOption.light);
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.dark_mode),
              onTap: () {
                themeManager.setThemeMode(ThemeModeOption.dark);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPinToggle(BuildContext context, bool enable) async {
    if (enable) {
      final pin = await _showSetPinDialog(context);
      if (pin != null && pin.length >= 4) {
        await PinAuth.setPin(pin);
        Get.forceAppUpdate();
      }
    } else {
      final pin = await _showEnterPinDialog(context, 'Enter current PIN to disable');
      if (pin != null) {
        final ok = await PinAuth.verifyPin(pin);
        if (ok) {
          await PinAuth.removePin(pin);
          Get.forceAppUpdate();
        } else {
          Get.snackbar('Error', 'Wrong PIN');
        }
      }
    }
  }

  Future<String?> _showSetPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter 4–6 digit PIN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showEnterPinDialog(BuildContext context, String message) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLockTimeoutPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 5, 10, 15, 30]
              .map((m) => ListTile(
                    title: Text('$m min'),
                    onTap: () async {
                      await PinAuth.setLockTimeout(m);
                      Get.back();
                      Get.forceAppUpdate();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
