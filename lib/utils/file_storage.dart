import '../database/hive_boxes.dart';
import '../models/qr_code_model.dart';
import 'encryption.dart';

class FileStorage {
  static const _encryptionKeySetting = 'encryption_secret';

  static String? get _secret {
    return HiveBoxes.settings.get(_encryptionKeySetting) as String?;
  }

  static Future<void> setEncryptionSecret(String secret) async {
    await HiveBoxes.settings.put(_encryptionKeySetting, secret);
  }

  static Future<void> saveQr(QrCodeModel model, {bool encryptContent = false}) async {
    final box = HiveBoxes.qrHistory;
    if (encryptContent && _secret != null) {
      final encrypted = EncryptionUtil.encrypt(model.content, _secret!);
      final encryptedModel = model.copyWith(
        encryptedContent: encrypted,
        isEncrypted: true,
        content: '',
      );
      await box.putQr(model.id, encryptedModel);
    } else {
      await box.putQr(model.id, model);
    }
  }

  static List<QrCodeModel> getAllQr({String? search}) {
    final list = HiveBoxes.qrHistory.allQr;
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      return list.where((e) {
        final content = e.isEncrypted ? (e.encryptedContent ?? '') : e.content;
        return content.toLowerCase().contains(lower) ||
            e.type.name.toLowerCase().contains(lower);
      }).toList();
    }
    return list;
  }

  static QrCodeModel? getQr(String id) => HiveBoxes.qrHistory.getQr(id);

  static Future<void> deleteQr(String id) async {
    await HiveBoxes.qrHistory.delete(id);
  }

  static Future<void> setFavorite(String id, bool favorite) async {
    final existing = getQr(id);
    if (existing == null) return;
    final updated = existing.copyWith(isFavorite: favorite);
    await HiveBoxes.qrHistory.putQr(id, updated);
  }

  static Future<void> clearAll() async {
    await HiveBoxes.qrHistory.clear();
  }

  static String getDecryptedContent(QrCodeModel model) {
    if (!model.isEncrypted || model.encryptedContent == null || _secret == null) {
      return model.content;
    }
    return EncryptionUtil.decrypt(model.encryptedContent!, _secret!);
  }

  static int get scanCount => HiveBoxes.qrHistory.allQr.where((e) => e.source == QrSource.scan).length;
  static int get generateCount => HiveBoxes.qrHistory.allQr.where((e) => e.source == QrSource.generate).length;

  static int getScanCountForContent(String content) {
    final all = HiveBoxes.qrHistory.allQr;
    final target = content.trim();
    int count = 0;
    for (final e in all) {
      final c = e.isEncrypted ? (e.encryptedContent ?? '') : e.content;
      if (c.trim() == target && e.source == QrSource.scan) {
        count++;
      }
    }
    return count;
  }
}
