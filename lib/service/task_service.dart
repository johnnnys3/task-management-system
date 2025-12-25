import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/models/task.dart';

class TaskService {
  final CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');

  Future<List<Task>> getTasks({required String userId}) async {
    try {
      QuerySnapshot tasksSnapshot = await tasksCollection.where('userId', isEqualTo: userId).get();
      List<Task> tasks = [];

      for (QueryDocumentSnapshot<Object?> doc in tasksSnapshot.docs) {
        Task task = Task.fromDocumentSnapshot(doc);
        tasks.add(task);
      }

      return tasks;
    } catch (error) {
      print('Error fetching tasks: $error');
      throw Exception('Failed to fetch tasks');
    }
  }

  Future<void> updateTask({
    required String userId,
    required String taskId,
    required Task updatedTask,
    required Task task,
  }) async {
    try {
      await tasksCollection.doc(taskId).update(updatedTask.toMap());
    } catch (error) {
      print('Error updating task: $error');
      throw Exception('Failed to update task');
    }
  }

  Future<void> addTask({required String userId, required Task task}) async {
    try {
      await tasksCollection.add({
        'userId': userId,
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate.toIso8601String(),
        'attachments': task.attachments,
        'isCompleted': task.isCompleted ? 1 : 0,
        'associatedProject': task.associatedProject?.toMap(),
        'assignedMembers': task.assignedMembers,
      });
    } catch (error) {
      print('Error adding task: $error');
      throw Exception('Failed to add task');
    }
  }

  Future<void> deleteTask({required String userId, required String taskId}) async {
    try {
      await tasksCollection.doc(taskId).delete();
    } catch (error) {
      print('Error deleting task: $error');
      throw Exception('Failed to delete task');
    }
  }

 
}
