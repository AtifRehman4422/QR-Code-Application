import '../models/qr_code_model.dart';

/// Categorize QR content type (offline, no network).
QrType categorizeQrContent(String content) {
  final lower = content.trim().toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return QrType.link;
  if (lower.startsWith('wifi:') || lower.startsWith('wpa') || lower.contains('ssid=')) return QrType.wifi;
  if (lower.startsWith('mailto:')) return QrType.email;
  if (lower.startsWith('tel:')) return QrType.phone;
  if (lower.startsWith('smsto:') || lower.startsWith('sms:')) return QrType.sms;
  if (lower.contains('begin:vcard') || lower.contains('mecard:')) return QrType.contact;
  if (lower.contains('bitcoin:') || lower.contains('ethereum:') || lower.contains('paypal')) return QrType.payment;
  return QrType.text;
}

String getQrTypeDisplayName(QrType type) {
  switch (type) {
    case QrType.link: return 'Link';
    case QrType.wifi: return 'Wi‑Fi';
    case QrType.contact: return 'Contact';
    case QrType.text: return 'Text';
    case QrType.email: return 'Email';
    case QrType.phone: return 'Phone';
    case QrType.sms: return 'SMS';
    case QrType.payment: return 'Payment';
    case QrType.other: return 'Other';
  }
}
