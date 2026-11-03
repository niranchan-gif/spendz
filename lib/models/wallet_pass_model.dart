class WalletPassModel {
  final String id;
  final String title;
  final String passType; // 'qr_code', 'barcode', 'event_ticket', 'boarding_pass', 'membership', 'loyalty'
  final String encryptedCodePath; // Column 'encrypted_code_path' in DB
  final String codeFormat; // 'QR_CODE', 'CODE_128', 'AZTEC', 'PDF_417'
  final String? issuer;
  final DateTime? validUntil;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletPassModel({
    required this.id,
    required this.title,
    this.passType = 'qr_code',
    required this.encryptedCodePath,
    this.codeFormat = 'QR_CODE',
    this.issuer,
    this.validUntil,
    this.notes,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility alias for UI
  String get codeData => encryptedCodePath;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'pass_type': passType,
      'encrypted_code_path': encryptedCodePath,
      'code_format': codeFormat,
      'issuer': issuer,
      'valid_until': validUntil?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WalletPassModel.fromMap(Map<String, dynamic> map) {
    return WalletPassModel(
      id: map['id'],
      title: map['title'] ?? '',
      passType: map['pass_type'] ?? 'qr_code',
      encryptedCodePath: map['encrypted_code_path'] ?? map['code_data'] ?? '',
      codeFormat: map['code_format'] ?? 'QR_CODE',
      issuer: map['issuer'],
      validUntil: map['valid_until'] != null ? DateTime.tryParse(map['valid_until']) : null,
      notes: map['notes'],
      isFavorite: map['is_favorite'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  WalletPassModel copyWith({
    String? id,
    String? title,
    String? passType,
    String? encryptedCodePath,
    String? codeFormat,
    String? issuer,
    DateTime? validUntil,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletPassModel(
      id: id ?? this.id,
      title: title ?? this.title,
      passType: passType ?? this.passType,
      encryptedCodePath: encryptedCodePath ?? this.encryptedCodePath,
      codeFormat: codeFormat ?? this.codeFormat,
      issuer: issuer ?? this.issuer,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef WalletPass = WalletPassModel;
