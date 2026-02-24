import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/qr_code_model.dart';
import '../utils/file_storage.dart';
import '../utils/qr_scanner.dart';
import '../utils/qr_generator.dart';
import '../widgets/custom_button.dart';
import '../widgets/qr_card.dart';

class ScanScreen extends StatefulWidget {
  final bool autoPickFromGallery;
  const ScanScreen({super.key, this.autoPickFromGallery = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  String? _lastResult;
  bool _scanned = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoPickFromGallery) {
        _scanFromGallery();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final list = capture.barcodes;
    if (list.isEmpty) return;
    final code = list.first.rawValue;
    if (code == null || code.isEmpty) return;
    _scanned = true;
    setState(() => _lastResult = code);
    final type = categorizeQrContent(code);
    final model = QrCodeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: code,
      type: type,
      source: QrSource.scan,
      timestamp: DateTime.now(),
    );
    await FileStorage.saveQr(model);
  }

  void _reset() {
    setState(() {
      _lastResult = null;
      _scanned = false;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (kIsWeb) {
        Get.snackbar('Not supported', 'Gallery scanning is not supported on Web');
        return;
      }
      final BarcodeCapture? capture = await _controller.analyzeImage(picked.path);
      if (capture != null) {
        await _onDetect(capture);
      } else {
        Get.snackbar('No QR found', 'Selected image does not contain a QR code');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to read image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_lastResult != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan result'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reset,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QrCard(
                model: QrCodeModel(
                  id: '',
                  content: _lastResult!,
                  type: categorizeQrContent(_lastResult!),
                  source: QrSource.scan,
                  timestamp: DateTime.now(),
                ),
                displayContent: _lastResult!,
                isDark: isDark,
                analyticsCount: FileStorage.getScanCountForContent(_lastResult!),
              ),
              if (categorizeQrContent(_lastResult!).name == 'wifi') ...[
                const SizedBox(height: 8),
                if (parseWifiSsid(_lastResult!) != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.wifi_rounded),
                      label: Text('SSID: ${parseWifiSsid(_lastResult!)}'),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                _lastResult!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (_lastResult!.trim().toLowerCase().startsWith('http'))
                    CustomButton(
                      color: theme.colorScheme.primary,
                      height: 44,
                      width: 120,
                      borderColor: Colors.transparent,
                      text: 'Open link',
                      icon: Icons.open_in_browser,
                      onPressed: () => _openUrl(_lastResult!),
                    ),
                  if (_lastResult!.trim().toLowerCase().startsWith('tel:'))
                    CustomButton(
                      color: theme.colorScheme.primary,
                      height: 44,
                      width: 110,
                      borderColor: Colors.transparent,
                      text: 'Call',
                      icon: Icons.call_rounded,
                      onPressed: () async {
                        final uri = Uri.parse(_lastResult!.trim());
                        await launchUrl(uri);
                      },
                    ),
                  if (_lastResult!.trim().toLowerCase().startsWith('mailto:'))
                    CustomButton(
                      color: theme.colorScheme.primary,
                      height: 44,
                      width: 110,
                      borderColor: Colors.transparent,
                      text: 'Email',
                      icon: Icons.email_rounded,
                      onPressed: () async {
                        final uri = Uri.parse(_lastResult!.trim());
                        await launchUrl(uri);
                      },
                    ),
                  if (_lastResult!.trim().toLowerCase().startsWith('sms:') ||
                      _lastResult!.trim().toLowerCase().startsWith('smsto:'))
                    CustomButton(
                      color: theme.colorScheme.primary,
                      height: 44,
                      width: 110,
                      borderColor: Colors.transparent,
                      text: 'SMS',
                      icon: Icons.sms_rounded,
                      onPressed: () async {
                        final uri = Uri.parse(_lastResult!.trim());
                        await launchUrl(uri);
                      },
                    ),
                  CustomButton(
                    color: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurface,
                    height: 44,
                    width: 100,
                    borderColor: Colors.transparent,
                    text: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _lastResult!));
                      Get.snackbar('Copied', 'Content copied to clipboard');
                    },
                  ),
                  CustomButton(
                    color: theme.colorScheme.secondary,
                    height: 44,
                    width: 100,
                    borderColor: Colors.transparent,
                    text: 'Share',
                    icon: Icons.share_rounded,
                    onPressed: () => Share.share(_lastResult!),
                  ),
                  CustomButton(
                    color: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurface,
                    height: 44,
                    width: 100,
                    borderColor: Colors.transparent,
                    text: 'Scan again',
                    onPressed: _reset,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search_rounded),
            tooltip: 'Scan from image',
            onPressed: _scanFromGallery,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.all(48),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Text(
              'Point your camera at a QR code',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
