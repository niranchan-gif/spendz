class WalletCardModel {
  final String id;
  final String nickname;
  final String issuerName;
  final String cardholderName;
  final String maskedNumber;
  final String lastFour;
  final int expiryMonth;
  final int expiryYear;
  final String cardType; // 'debit', 'credit', 'atm', 'membership', 'loyalty', 'custom'
  final String cardNetwork; // 'visa', 'mastercard', 'rupay', 'amex', 'other'
  final String themeGradient; // e.g., 'emerald', 'midnight', 'obsidian', 'amethyst', 'crimson'
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletCardModel({
    required this.id,
    required this.nickname,
    required this.issuerName,
    required this.cardholderName,
    required this.maskedNumber,
    required this.lastFour,
    required this.expiryMonth,
    required this.expiryYear,
    this.cardType = 'credit',
    this.cardNetwork = 'visa',
    this.themeGradient = 'emerald',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'issuer_name': issuerName,
      'cardholder_name': cardholderName,
      'masked_number': maskedNumber,
      'last_four': lastFour,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'card_type': cardType,
      'card_network': cardNetwork,
      'theme_gradient': themeGradient,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WalletCardModel.fromMap(Map<String, dynamic> map) {
    return WalletCardModel(
      id: map['id'],
      nickname: map['nickname'] ?? '',
      issuerName: map['issuer_name'] ?? '',
      cardholderName: map['cardholder_name'] ?? '',
      maskedNumber: map['masked_number'] ?? '•••• •••• •••• ••••',
      lastFour: map['last_four'] ?? '',
      expiryMonth: map['expiry_month'] ?? 1,
      expiryYear: map['expiry_year'] ?? 30,
      cardType: map['card_type'] ?? 'credit',
      cardNetwork: map['card_network'] ?? 'visa',
      themeGradient: map['theme_gradient'] ?? 'emerald',
      isFavorite: map['is_favorite'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  WalletCardModel copyWith({
    String? id,
    String? nickname,
    String? issuerName,
    String? cardholderName,
    String? maskedNumber,
    String? lastFour,
    int? expiryMonth,
    int? expiryYear,
    String? cardType,
    String? cardNetwork,
    String? themeGradient,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletCardModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      issuerName: issuerName ?? this.issuerName,
      cardholderName: cardholderName ?? this.cardholderName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      lastFour: lastFour ?? this.lastFour,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardType: cardType ?? this.cardType,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      themeGradient: themeGradient ?? this.themeGradient,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

typedef WalletCard = WalletCardModel;

