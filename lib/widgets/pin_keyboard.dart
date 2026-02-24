import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback? onDelete;
  final VoidCallback? onBiometric;
  final bool showBiometric;
  final int pinLength;
  final String currentPin;

  const PinKeyboard({
    super.key,
    required this.onKeyPressed,
    this.onDelete,
    this.onBiometric,
    this.showBiometric = false,
    this.pinLength = 6,
    this.currentPin = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (i) {
            final filled = i < currentPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.15),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBiometric && onBiometric != null)
              _keyButton(context, icon: Icons.fingerprint, onTap: onBiometric!)
            else
              const SizedBox(width: 72, height: 72),
            _keyButton(context, digit: '0'),
            _keyButton(context, icon: Icons.backspace_outlined, onTap: () {
              if (currentPin.isNotEmpty) onDelete?.call();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _keyButton(context, digit: d),
      )).toList(),
    );
  }

  Widget _keyButton(
    BuildContext context, {
    String? digit,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final effectiveTap = onTap ?? (digit != null ? () {
      HapticFeedback.lightImpact();
      onKeyPressed(digit);
    } : null);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: effectiveTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: digit != null
                ? Text(
                    digit,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : Icon(icon, size: 28, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
