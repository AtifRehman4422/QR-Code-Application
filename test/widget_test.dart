// Basic Flutter widget test for QR Scanner app.

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/main.dart';

void main() {
  testWidgets('QR Scanner app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QRScannerApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // App should show splash then home; expect QR Scanner title or main content
    expect(find.text('QR Scanner'), findsWidgets);
  });
}
