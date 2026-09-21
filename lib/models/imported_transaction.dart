class ImportedTransaction {
  final String reference;
  final String name;
  final double amount;
  final DateTime date;
  final String type; // e.g. 'DEBIT' or 'CREDIT'
  final String source; // e.g. 'HDFC'

  ImportedTransaction({
    required this.reference,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    required this.source,
  });

  factory ImportedTransaction.fromJson(Map<String, dynamic> json) {
    return ImportedTransaction(
      reference: json['reference']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      type: json['type']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}
