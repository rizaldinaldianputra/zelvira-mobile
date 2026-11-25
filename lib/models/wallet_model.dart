class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final int points;
  final String description;
  final String? referenceId;
  final String status;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.points,
    required this.description,
    this.referenceId,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      referenceId: json['referenceId'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class WalletResponse {
  final double balance;
  final int points;
  final List<WalletTransaction> recentTransactions;

  WalletResponse({
    required this.balance,
    required this.points,
    required this.recentTransactions,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    var list = json['recentTransactions'] as List? ?? [];
    List<WalletTransaction> transactionsList = list.map((i) => WalletTransaction.fromJson(i)).toList();

    return WalletResponse(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      points: json['points'] ?? 0,
      recentTransactions: transactionsList,
    );
  }
}
