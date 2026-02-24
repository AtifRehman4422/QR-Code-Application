import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/qr_code_model.dart';
import '../utils/file_storage.dart';
import '../utils/qr_scanner.dart';
import '../widgets/custom_button.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _repaintKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  String _data = '';
  bool _generated = false;

  // Shape
  QrDataModuleShape _dataShape = QrDataModuleShape.square;
  QrEyeShape _eyeShape = QrEyeShape.square;

  // Color
  Color _foregroundColor = const Color(0xFF1a1a1a);
  Color _backgroundColor = Colors.white;
  bool _autoColors = false;

  // Logo
  String? _logoPath;
  // Expiry
  Duration? _expiryDuration;

  static const List<Color> _colorPresets = [
    Color(0xFF1a1a1a),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Error', 'Enter some content first');
      return;
    }
    setState(() {
      _data = text;
      _generated = true;
    });
    final model = QrCodeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: categorizeQrContent(text),
      source: QrSource.generate,
      timestamp: DateTime.now(),
      expiresAt: _expiryDuration != null ? DateTime.now().add(_expiryDuration!) : null,
    );
    FileStorage.saveQr(model);
  }

  void _reset() {
    setState(() {
      _data = '';
      _generated = false;
      _logoPath = null;
      _textController.clear();
    });
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _logoPath = picked.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image: $e');
    }
  }

  void _removeLogo() {
    setState(() => _logoPath = null);
  }

  Future<void> _savePng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      await ImageGallerySaver.saveImage(pngBytes, name: 'qr_${DateTime.now().millisecondsSinceEpoch}.png');
      if (mounted) Get.snackbar('Saved', 'QR code saved to gallery');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e');
    }
  }

  Future<void> _share() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/qr_share.png';
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles([XFile(path)], text: _data);
    } catch (e) {
      Get.snackbar('Error', 'Share failed: $e');
    }
  }

  void _applyTemplate(String type) {
    switch (type) {
      case 'url':
        _textController.text = 'https://example.com';
        break;
      case 'wifi':
        _textController.text = 'WIFI:S:MyWifi;T:WPA;P:password123;H:false;';
        break;
      case 'contact':
        _textController.text = [
          'BEGIN:VCARD',
          'VERSION:3.0',
          'N:Doe;John;;;',
          'TEL:+1234567890',
          'EMAIL:john.doe@example.com',
          'END:VCARD',
        ].join('\n');
        break;
      case 'email':
        _textController.text = 'mailto:john.doe@example.com?subject=Hello&body=Message';
        break;
      case 'sms':
        _textController.text = 'SMSTO:+1234567890:Hello';
        break;
      case 'phone':
        _textController.text = 'tel:+1234567890';
        break;
      case 'payment':
        _textController.text = 'upi://pay?pa=merchant@upi&pn=Merchant&am=100&tn=Payment';
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveForeground = _autoColors
        ? (isDark ? Colors.white : const Color(0xFF1a1a1a))
        : _foregroundColor;
    final effectiveBackground = _autoColors
        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
        : _backgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR'),
        actions: _generated
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _reset,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_generated) ...[
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Enter text, URL, Wi‑Fi config, etc.',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text('Templates', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TemplateChip(label: 'URL', onTap: () => _applyTemplate('url')),
                  _TemplateChip(label: 'Wi‑Fi', onTap: () => _applyTemplate('wifi')),
                  _TemplateChip(label: 'Contact', onTap: () => _applyTemplate('contact')),
                  _TemplateChip(label: 'Email', onTap: () => _applyTemplate('email')),
                  _TemplateChip(label: 'SMS', onTap: () => _applyTemplate('sms')),
                  _TemplateChip(label: 'Phone', onTap: () => _applyTemplate('phone')),
                  _TemplateChip(label: 'Payment', onTap: () => _applyTemplate('payment')),
                ],
              ),
              const SizedBox(height: 20),
              // ——— Validity ———
              Text('Validity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ValidityChip(
                    label: 'No limit',
                    selected: _expiryDuration == null,
                    onTap: () => setState(() => _expiryDuration = null),
                  ),
                  const SizedBox(width: 8),
                  _ValidityChip(
                    label: '1 hour',
                    selected: _expiryDuration == const Duration(hours: 1),
                    onTap: () => setState(() => _expiryDuration = const Duration(hours: 1)),
                  ),
                  const SizedBox(width: 8),
                  _ValidityChip(
                    label: '24 hours',
                    selected: _expiryDuration == const Duration(days: 1),
                    onTap: () => setState(() => _expiryDuration = const Duration(days: 1)),
                  ),
                  const SizedBox(width: 8),
                  _ValidityChip(
                    label: '7 days',
                    selected: _expiryDuration == const Duration(days: 7),
                    onTap: () => setState(() => _expiryDuration = const Duration(days: 7)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ——— Shape ———
              Text('Shape', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ShapeChip(
                    label: 'Square',
                    icon: Icons.crop_square_rounded,
                    selected: _dataShape == QrDataModuleShape.square && _eyeShape == QrEyeShape.square,
                    onTap: () => setState(() {
                      _dataShape = QrDataModuleShape.square;
                      _eyeShape = QrEyeShape.square;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ShapeChip(
                    label: 'Dots',
                    icon: Icons.circle_outlined,
                    selected: _dataShape == QrDataModuleShape.circle && _eyeShape == QrEyeShape.circle,
                    onTap: () => setState(() {
                      _dataShape = QrDataModuleShape.circle;
                      _eyeShape = QrEyeShape.circle;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ——— Color ———
              Text('QR color', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _autoColors,
                onChanged: (v) => setState(() => _autoColors = v),
                title: const Text('Auto adapt to theme'),
                subtitle: const Text('Adjust QR colors for light/dark'),
              ),
              Row(
                children: _colorPresets.map((c) {
                  final selected = effectiveForeground.value == c.value && !_autoColors;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _foregroundColor = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? theme.colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Custom:', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 36,
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveForeground,
                        foregroundColor: effectiveForeground.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      ),
                      onPressed: () async {
                        final c = await showDialog<Color>(
                          context: context,
                          builder: (ctx) => _ColorPickerDialog(initial: _foregroundColor),
                        );
                        if (c != null && mounted) setState(() => _foregroundColor = c);
                      },
                      child: const Text('Pick color'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ——— Background ———
              Text('Background', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _BgChip(
                    label: 'White',
                    color: Colors.white,
                    selected: effectiveBackground.value == Colors.white.value && !_autoColors,
                    onTap: () => setState(() => _backgroundColor = Colors.white),
                  ),
                  const SizedBox(width: 8),
                  _BgChip(
                    label: 'Light',
                    color: const Color(0xFFF1F5F9),
                    selected: effectiveBackground.value == 0xFFF1F5F9 && !_autoColors,
                    onTap: () => setState(() => _backgroundColor = const Color(0xFFF1F5F9)),
                  ),
                  const SizedBox(width: 8),
                  _BgChip(
                    label: 'Dark',
                    color: const Color(0xFF1E293B),
                    selected: effectiveBackground.value == 0xFF1E293B && !_autoColors,
                    onTap: () => setState(() => _backgroundColor = const Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ——— Logo ———
              Text('Brand logo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_logoPath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_logoPath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _removeLogo,
                      tooltip: 'Remove logo',
                    ),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
                      label: Text(_logoPath == null ? 'Add logo / image' : 'Change logo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                color: theme.colorScheme.primary,
                height: 52,
                width: double.infinity,
                borderColor: Colors.transparent,
                text: 'Generate QR code',
                icon: Icons.qr_code_2_rounded,
                onPressed: _generate,
              ),
            ] else ...[
              Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _data,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: effectiveBackground,
                      eyeStyle: QrEyeStyle(
                        eyeShape: _eyeShape,
                        color: effectiveForeground,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: _dataShape,
                        color: effectiveForeground,
                      ),
                      gapless: true,
                      embeddedImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
                      embeddedImageStyle: _logoPath != null
                          ? const QrEmbeddedImageStyle(
                              size: Size(48, 48),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  CustomButton(
                    color: theme.colorScheme.primary,
                    height: 48,
                    width: 140,
                    borderColor: Colors.transparent,
                    text: 'Save PNG',
                    icon: Icons.download_rounded,
                    onPressed: _savePng,
                  ),
                  CustomButton(
                    color: theme.colorScheme.secondary,
                    height: 48,
                    width: 120,
                    borderColor: Colors.transparent,
                    text: 'Share',
                    icon: Icons.share_rounded,
                    onPressed: _share,
                  ),
                  CustomButton(
                    color: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurface,
                    height: 48,
                    width: 120,
                    borderColor: Colors.transparent,
                    text: 'New',
                    onPressed: _reset,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TemplateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 18),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ShapeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _BgChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _BgChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.grey.shade400,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ValidityChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
class _ColorPickerDialog extends StatefulWidget {
  final Color initial;

  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick QR color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              color: _color,
              onColorChanged: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Simple hue/saturation color picker using sliders
class ColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({super.key, required this.color, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hsl = HSLColor.fromColor(color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
        ),
        const SizedBox(height: 16),
        Text('Hue', style: theme.textTheme.labelMedium),
        Slider(
          value: hsl.hue,
          max: 360,
          onChanged: (v) {
            onColorChanged(HSLColor.fromAHSL(1, v, hsl.saturation, hsl.lightness).toColor());
          },
        ),
        Text('Saturation', style: theme.textTheme.labelMedium),
        Slider(
          value: hsl.saturation,
          onChanged: (v) {
            onColorChanged(HSLColor.fromAHSL(1, hsl.hue, v, hsl.lightness).toColor());
          },
        ),
        Text('Lightness', style: theme.textTheme.labelMedium),
        Slider(
          value: hsl.lightness,
          onChanged: (v) {
            onColorChanged(HSLColor.fromAHSL(1, hsl.hue, hsl.saturation, v).toColor());
          },
        ),
      ],
    );
  }
}
