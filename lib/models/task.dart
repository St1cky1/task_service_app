class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final int ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  static DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        final cleanedDate = dateString.replaceAll(RegExp(r'\s\+\d{4}\s\w+$'), '');
        return DateTime.parse(cleanedDate);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      ownerId: json['owner_id'] as int? ?? 0,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
