import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasks => _firestore.collection('tasks');

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _tasks.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(TaskModel.fromDoc).toList();
      tasks.sort((a, b) => a.dueAt.compareTo(b.dueAt));
      return tasks;
    });
  }

  Future<String> addTask(TaskModel task) async {
    final document = await _tasks.add(task.toMap());
    return document.id;
  }

  Future<void> updateTask(TaskModel task) {
    return _tasks.doc(task.id).update(task.toMap());
  }

  Future<void> setCompleted(TaskModel task, bool completed) {
    return _tasks.doc(task.id).update({'isCompleted': completed});
  }

  Future<void> deleteTask(String taskId) {
    return _tasks.doc(taskId).delete();
  }
}
