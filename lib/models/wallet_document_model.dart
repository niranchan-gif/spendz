class WalletDocumentModel {
  final String id;
  final String documentName;
  final String
  category; // 'aadhaar', 'pan', 'driving_license', 'passport', 'debit_card', 'credit_card', 'insurance', 'rc', 'college_id', 'certificate', 'other'
  final String? description;
  final String encryptedFilePath;
  final String? thumbnailPath;
  final String mimeType; // 'application/pdf', 'image/jpeg', 'image/png'
  final int fileSize;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final bool isFavorite;
  final String? maskedIdentifier;
  final String? holderName;
  final String? encryptedFields;
  final String attachmentType; // 'none', 'image', 'pdf', 'scanned_pdf'
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletDocumentModel({
    required this.id,
    required this.documentName,
    required this.category,
    this.description,
    this.encryptedFilePath = '',
    this.thumbnailPath,
    this.mimeType = 'image/jpeg',
    this.fileSize = 0,
    this.issueDate,
    this.expiryDate,
    this.isFavorite = false,
    this.maskedIdentifier,
    this.holderName,
    this.encryptedFields,
    this.attachmentType = 'none',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAttachment => encryptedFilePath.isNotEmpty;

  String get documentTitle => documentName;
  String get documentType => category;

  bool get isPdf => mimeType.toLowerCase().contains('pdf');
  bool get isImage => mimeType.toLowerCase().contains('image');

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
      'masked_identifier': maskedIdentifier,
      'holder_name': holderName,
      'encrypted_fields': encryptedFields,
      'attachment_type': attachmentType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WalletDocumentModel.fromMap(Map<String, dynamic> map) {
    return WalletDocumentModel(
      id: map['id'] ?? '',
      documentName: map['document_name'] ?? '',
      category: map['category'] ?? 'other',
      description: map['description'],
      encryptedFilePath: map['encrypted_file_path'] ?? '',
      thumbnailPath: map['thumbnail_path'],
      mimeType: map['mime_type'] ?? 'image/jpeg',
      fileSize: map['file_size'] ?? 0,
      issueDate: map['issue_date'] != null
          ? DateTime.tryParse(map['issue_date'])
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'])
          : null,
      isFavorite: map['is_favorite'] == 1,
      maskedIdentifier: map['masked_identifier'],
      holderName: map['holder_name'],
      encryptedFields: map['encrypted_fields'],
      attachmentType:
          map['attachment_type'] ??
          (map['encrypted_file_path'] != null &&
                  (map['encrypted_file_path'] as String).isNotEmpty
              ? 'image'
              : 'none'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
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
    String? maskedIdentifier,
    String? holderName,
    String? encryptedFields,
    String? attachmentType,
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
      maskedIdentifier: maskedIdentifier ?? this.maskedIdentifier,
      holderName: holderName ?? this.holderName,
      encryptedFields: encryptedFields ?? this.encryptedFields,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef WalletDocument = WalletDocumentModel;
