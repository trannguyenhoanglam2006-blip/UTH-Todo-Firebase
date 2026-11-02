import 'package:cloud_firestore/cloud_firestore.dart';

// Model: biểu diễn 1 công việc được lưu trên Cloud Firestore.
class TodoTask {
  final String id;
  final String title;
  final String category;
  final DateTime dueDate;
  final bool isDone;
  final DateTime? completedAt;

  const TodoTask({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.isDone,
    required this.completedAt,
  });

  factory TodoTask.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TodoTask(
      id: doc.id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? 'Học tập',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDone: data['isDone'] as bool? ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
