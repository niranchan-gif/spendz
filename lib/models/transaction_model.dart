class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'expense', 'income', 'transfer'
  final String? categoryId;
  final String? subcategory;
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final String? notes;
  final String source; // 'manual', 'bank_email', 'statement'
  final String? bankName;
  final String? referenceId;
  final double owedAmount; // Amount expected back for split expenses
  final int expectedPayments;
  final int linkedPayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    this.subcategory,
    this.merchant,
    this.description,
    required this.date,
    this.paymentMethod,
    this.notes,
    required this.source,
    this.bankName,
    this.referenceId,
    this.owedAmount = 0.0,
    this.expectedPayments = 0,
    this.linkedPayments = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'subcategory': subcategory,
      'merchant': merchant,
      'description': description,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'source': source,
      'bank_name': bankName,
      'reference_id': referenceId,
      'owed_amount': owedAmount,
      'expected_payments': expectedPayments,
      'linked_payments': linkedPayments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['category_id'],
      subcategory: map['subcategory'],
      merchant: map['merchant'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      source: map['source'],
      bankName: map['bank_name'],
      referenceId: map['reference_id'],
      owedAmount: map['owed_amount'] ?? 0.0,
      expectedPayments: map['expected_payments'] ?? 0,
      linkedPayments: map['linked_payments'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? categoryId,
    String? subcategory,
    String? merchant,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? source,
    String? bankName,
    String? referenceId,
    double? owedAmount,
    int? expectedPayments,
    int? linkedPayments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      bankName: bankName ?? this.bankName,
      referenceId: referenceId ?? this.referenceId,
      owedAmount: owedAmount ?? this.owedAmount,
      expectedPayments: expectedPayments ?? this.expectedPayments,
      linkedPayments: linkedPayments ?? this.linkedPayments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
