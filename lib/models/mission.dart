enum MissionType {
  dailyDiary,
  wordLearning,
  streak,
  review,
  conversation,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int targetValue;
  final int currentValue;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int experiencePoints;
  final bool isDaily;
  final DateTime? resetDate;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.experiencePoints = 10,
    this.isDaily = false,
    this.resetDate,
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'experiencePoints': experiencePoints,
      'isDaily': isDaily,
      'resetDate': resetDate?.toIso8601String(),
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: MissionType.values.firstWhere((e) => e.name == json['type']),
      targetValue: json['targetValue'],
      currentValue: json['currentValue'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      isCompleted: json['isCompleted'] ?? false,
      experiencePoints: json['experiencePoints'] ?? 10,
      isDaily: json['isDaily'] ?? false,
      resetDate: json['resetDate'] != null ? DateTime.parse(json['resetDate']) : null,
    );
  }

  Mission copyWith({
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    DateTime? completedAt,
    bool? isCompleted,
    int? experiencePoints,
    DateTime? resetDate,
  }) {
    return Mission(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      isDaily: isDaily,
      resetDate: resetDate ?? this.resetDate,
    );
  }
}