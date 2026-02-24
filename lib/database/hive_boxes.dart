import 'package:hive_flutter/hive_flutter.dart';
import '../models/qr_code_model.dart';

class HiveBoxes {
  static const String qrHistoryBox = 'qr_history';
  static const String settingsBox = 'settings';
  static const String pinBox = 'pin_storage';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(qrHistoryBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(pinBox);
  }

  static Box get qrHistory => Hive.box(qrHistoryBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get pin => Hive.box(pinBox);
}

extension QrHistoryBox on Box {
  List<QrCodeModel> get allQr {
    final list = <QrCodeModel>[];
    for (final e in values) {
      if (e is! Map) continue;
      try {
        list.add(QrCodeModel.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return list;
  }

  Future<void> putQr(String key, QrCodeModel model) async {
    await put(key, model.toJson());
  }

  QrCodeModel? getQr(String key) {
    final v = get(key);
    if (v == null || v is! Map) return null;
    try {
      return QrCodeModel.fromJson(Map<String, dynamic>.from(v as Map));
    } catch (_) {
      return null;
    }
  }
}
