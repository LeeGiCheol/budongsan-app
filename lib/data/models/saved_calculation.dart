/// 저장된 계산 결과 모델 (Hive JSON 저장용)
class SavedCalculation {
  final String id;
  final String type; // 'acquisition_tax', 'loan', etc.
  final String title;
  final String subtitle;
  final List<String> tags;
  final Map<String, dynamic> data;
  final DateTime savedAt;

  const SavedCalculation({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.data,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'tags': tags,
        'data': data,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedCalculation.fromMap(Map<dynamic, dynamic> map) {
    return SavedCalculation(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      tags: List<String>.from(map['tags'] as List),
      data: Map<String, dynamic>.from(map['data'] as Map),
      savedAt: DateTime.parse(map['savedAt'] as String),
    );
  }
}
