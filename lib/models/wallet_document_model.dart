class WalletDocumentModel {
  final String id;
  final String documentName;
  final String category; // 'aadhaar', 'pan', 'driving_license', 'passport', 'rc', 'insurance', 'college_id', 'certificate', 'other'
  final String? description;
  final String encryptedFilePath;
  final String? thumbnailPath;
  final String mimeType; // 'application/pdf', 'image/jpeg', 'image/png'
  final int fileSize;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletDocumentModel({
    required this.id,
    required this.documentName,
    required this.category,
    this.description,
    required this.encryptedFilePath,
    this.thumbnailPath,
    required this.mimeType,
    this.fileSize = 0,
    this.issueDate,
    this.expiryDate,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_name': documentName,
      'category': category,
      'description': description,
      'encrypted_file_path': encryptedFilePath,
      'thumbnail_path': thumbnailPath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WalletDocumentModel.fromMap(Map<String, dynamic> map) {
    return WalletDocumentModel(
      id: map['id'],
      documentName: map['document_name'] ?? '',
      category: map['category'] ?? 'other',
      description: map['description'],
      encryptedFilePath: map['encrypted_file_path'] ?? '',
      thumbnailPath: map['thumbnail_path'],
      mimeType: map['mime_type'] ?? 'image/jpeg',
      fileSize: map['file_size'] ?? 0,
      issueDate: map['issue_date'] != null ? DateTime.tryParse(map['issue_date']) : null,
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date']) : null,
      isFavorite: map['is_favorite'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  WalletDocumentModel copyWith({
    String? id,
    String? documentName,
    String? category,
    String? description,
    String? encryptedFilePath,
    String? thumbnailPath,
    String? mimeType,
    int? fileSize,
    DateTime? issueDate,
    DateTime? expiryDate,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletDocumentModel(
      id: id ?? this.id,
      documentName: documentName ?? this.documentName,
      category: category ?? this.category,
      description: description ?? this.description,
      encryptedFilePath: encryptedFilePath ?? this.encryptedFilePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef WalletDocument = WalletDocumentModel;

