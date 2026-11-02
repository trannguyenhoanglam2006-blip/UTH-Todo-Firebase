import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_task.dart';

// Service: chỉ phụ trách đọc/ghi công việc lên Firestore.
class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  // snapshots() theo dõi thay đổi REALTIME, không cần bấm nút tải lại.
  Stream<List<TodoTask>> watchTasks(String uid) {
    return _collection(uid).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(TodoTask.fromDoc).toList();
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  Future<void> addTask(
    String uid, {
    required String title,
    required String category,
    required DateTime dueDate,
  }) async {
    await _collection(uid).add({
      'title': title.trim(),
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
      'isDone': false,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editTask(
    String uid,
    String taskId, {
    required String title,
    required String category,
    required DateTime dueDate,
  }) async {
    await _collection(uid).doc(taskId).update({
      'title': title.trim(),
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
    });
  }

  Future<void> setDone(String uid, TodoTask task, bool done) async {
    await _collection(uid).doc(task.id).update({
      'isDone': done,
      // Lưu lúc hoàn thành để thống kê chính xác theo ngày trong tuần.
      'completedAt': done ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _collection(uid).doc(taskId).delete();
  }
}
