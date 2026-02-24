import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Generate QR image bytes for export (offline).
Future<ui.Image?> qrToImage({
  required String data,
  required double size,
  Color foreground = const Color(0xFF000000),
  Color background = const Color(0xFFFFFFFF),
}) async {
  try {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) return null;
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter(
      data: data,
      version: qrCode.typeNumber,
      gapless: true,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: foreground),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foreground,
      ),
    );
    final picData = await painter.toImageData(size);
    if (picData == null) return null;
    final bytes = Uint8List.view(
      picData.buffer,
      picData.offsetInBytes,
      picData.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Parse Wi-Fi QR payload for display (e.g. SSID).
String? parseWifiSsid(String content) {
  final lower = content.trim().toLowerCase();
  if (!lower.startsWith('wifi:')) return null;
  final rest = content.substring(5);
  for (final part in rest.split(';')) {
    if (part.toLowerCase().startsWith('s:') || part.toLowerCase().startsWith('ssid:')) {
      return part.contains(':') ? part.substring(part.indexOf(':') + 1).trim() : part.substring(2).trim();
    }
  }
  return null;
}
