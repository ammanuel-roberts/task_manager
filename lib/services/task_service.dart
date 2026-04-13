import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import 'package:flutter/material.dart';

class TaskService {
  // Reference to the 'tasks' collection in Firestore
  final CollectionReference tasksRef =
      FirebaseFirestore.instance.collection('tasks');

  // CREATE — add a new task
  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;

    await tasksRef.add({
      'title': title.trim(),
      'isCompleted': false,
      'subtasks': [],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // READ — stream all tasks ordered by creation time
  Stream<List<Task>> streamTasks() {
    return tasksRef.orderBy('createdAt').snapshots().map((snap) {
      List<Task> taskList = [];
      for (var doc in snap.docs) {
        taskList.add(Task.fromMap(doc.id, doc.data() as Map<String, dynamic>));
      }
      return taskList;
    });
  }

  // UPDATE — toggle isCompleted
  Future<void> toggleTask(Task task) async {
    await tasksRef.doc(task.id).update({'isCompleted': !task.isCompleted});
  }

  // UPDATE — save the whole task (used for subtask changes)
  Future<void> updateTask(Task task) async {
    await tasksRef.doc(task.id).update(task.toMap());
  }

  // DELETE — remove a task by id
  Future<void> deleteTask(String id) async {
    await tasksRef.doc(id).delete();
  }
}