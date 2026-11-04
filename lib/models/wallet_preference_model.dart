class WalletPreferenceModel {
  final String key;
  final String value;

  WalletPreferenceModel({required this.key, required this.value});

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value};
  }

  factory WalletPreferenceModel.fromMap(Map<String, dynamic> map) {
    return WalletPreferenceModel(
      key: map['key'] ?? '',
      value: map['value'] ?? '',
    );
  }

  WalletPreferenceModel copyWith({String? key, String? value}) {
    return WalletPreferenceModel(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}

typedef WalletPreferences = WalletPreferenceModel;
