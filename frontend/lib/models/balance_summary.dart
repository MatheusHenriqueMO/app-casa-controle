class BalanceSummary {
  final double totalMonth;
  final Map<String, double> totalByCategory;
  final Map<String, double> paidByMember;
  final Map<String, double> owedByMember;
  final List<DebtSettlement> settlements;

  BalanceSummary({
    required this.totalMonth,
    required this.totalByCategory,
    required this.paidByMember,
    required this.owedByMember,
    required this.settlements,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      totalMonth: double.parse(json['totalMonth'].toString()),
      totalByCategory: (json['totalByCategory'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, double.parse(v.toString()))),
      paidByMember: (json['paidByMember'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, double.parse(v.toString()))),
      owedByMember: (json['owedByMember'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, double.parse(v.toString()))),
      settlements: (json['settlements'] as List? ?? [])
          .map((e) => DebtSettlement.fromJson(e))
          .toList(),
    );
  }
}

class DebtSettlement {
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;
  final double amount;

  DebtSettlement({
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.amount,
  });

  factory DebtSettlement.fromJson(Map<String, dynamic> json) {
    return DebtSettlement(
      fromUid: json['fromUid'],
      fromName: json['fromName'],
      toUid: json['toUid'],
      toName: json['toName'],
      amount: double.parse(json['amount'].toString()),
    );
  }
}
