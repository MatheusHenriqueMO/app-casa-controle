class Expense {
  final String id;
  final String houseId;
  final String description;
  final double amount;
  final String category;
  final String paidByUid;
  final String paidByName;
  final List<String> splitWith;
  final DateTime date;
  final DateTime createdAt;
  final bool isFixed;

  Expense({
    required this.id,
    required this.houseId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidByUid,
    required this.paidByName,
    required this.splitWith,
    required this.date,
    required this.createdAt,
    this.isFixed = false,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      houseId: json['houseId'],
      description: json['description'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      paidByUid: json['paidByUid'],
      paidByName: json['paidByName'],
      splitWith: List<String>.from(json['splitWith'] ?? []),
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      isFixed: json['isFixed'] == true,
    );
  }
}

const List<String> kCategories = [
  'Alimentação',
  'Mercado',
  'Aluguel',
  'Conta de luz',
  'Conta de água',
  'Internet',
  'Transporte',
  'Saúde',
  'Lazer',
  'Outros',
];

const Map<String, String> kCategoryIcons = {
  'Alimentação': '🍽️',
  'Mercado': '🛒',
  'Aluguel': '🏠',
  'Conta de luz': '💡',
  'Conta de água': '💧',
  'Internet': '📶',
  'Transporte': '🚗',
  'Saúde': '💊',
  'Lazer': '🎉',
  'Outros': '📦',
};
