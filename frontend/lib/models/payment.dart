class Payment {
  final String id;
  final String houseId;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;
  final double amount;
  final DateTime date;

  Payment({
    required this.id,
    required this.houseId,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.amount,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      houseId: json['houseId'],
      fromUid: json['fromUid'],
      fromName: json['fromName'],
      toUid: json['toUid'],
      toName: json['toName'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['date']),
    );
  }
}
