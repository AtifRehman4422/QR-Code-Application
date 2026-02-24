enum QrType {
  link,
  wifi,
  contact,
  text,
  email,
  phone,
  sms,
  payment,
  other,
}

enum QrSource { scan, generate }

class QrCodeModel {
  final String id;
  final String content;
  final QrType type;
  final QrSource source;
  final DateTime timestamp;
  final String? encryptedContent;
  final bool isEncrypted;
  final String? category;
  final bool isFavorite;
  final List<String>? tags;
  final DateTime? expiresAt;

  QrCodeModel({
    required this.id,
    required this.content,
    required this.type,
    required this.source,
    required this.timestamp,
    this.encryptedContent,
    this.isEncrypted = false,
    this.category,
    this.isFavorite = false,
    this.tags,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.name,
        'source': source.name,
        'timestamp': timestamp.toIso8601String(),
        'encryptedContent': encryptedContent,
        'isEncrypted': isEncrypted,
        'category': category,
        'isFavorite': isFavorite,
        'tags': tags,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory QrCodeModel.fromJson(Map<String, dynamic> json) => QrCodeModel(
        id: json['id'] as String,
        content: json['content'] as String,
        type: QrType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => QrType.other,
        ),
        source: QrSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => QrSource.scan,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        encryptedContent: json['encryptedContent'] as String?,
        isEncrypted: json['isEncrypted'] as bool? ?? false,
        category: json['category'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
        expiresAt: (json['expiresAt'] as String?) != null ? DateTime.parse(json['expiresAt'] as String) : null,
      );

  QrCodeModel copyWith({
    String? id,
    String? content,
    QrType? type,
    QrSource? source,
    DateTime? timestamp,
    String? encryptedContent,
    bool? isEncrypted,
    String? category,
    bool? isFavorite,
    List<String>? tags,
    DateTime? expiresAt,
  }) =>
      QrCodeModel(
        id: id ?? this.id,
        content: content ?? this.content,
        type: type ?? this.type,
        source: source ?? this.source,
        timestamp: timestamp ?? this.timestamp,
        encryptedContent: encryptedContent ?? this.encryptedContent,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        category: category ?? this.category,
        isFavorite: isFavorite ?? this.isFavorite,
        tags: tags ?? this.tags,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}
