class House {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final List<String> memberIds;
  final Map<String, String> memberNames;

  House({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.memberIds,
    required this.memberNames,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'],
      name: json['name'],
      inviteCode: json['inviteCode'],
      createdBy: json['createdBy'],
      memberIds: List<String>.from(json['memberIds'] ?? []),
      memberNames: Map<String, String>.from(json['memberNames'] ?? {}),
    );
  }
}
