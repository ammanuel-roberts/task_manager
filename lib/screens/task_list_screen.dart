import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController taskInput = TextEditingController();
  final TaskService service = TaskService();

  // Track which tasks are expanded to show subtasks
  Set<String> expandedTasks = {};

  @override
  void dispose() {
    taskInput.dispose();
    super.dispose();
  }

  // Add a new task to Firestore
  void addTask() {
    String title = taskInput.text.trim();
    if (title.isEmpty) return;
    service.addTask(title);
    taskInput.clear();
  }

  // Toggle the completion checkbox
  void toggleDone(Task task) {
    service.toggleTask(task);
  }

  // Show a confirm dialog then delete
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: const Text('This will permanently remove the task.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                service.deleteTask(id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Add a subtask to a task
  void addSubtask(Task task, String subTitle) {
    if (subTitle.trim().isEmpty) return;
    List<Map<String, dynamic>> updated = List.from(task.subtasks);
    updated.add({'title': subTitle.trim(), 'done': false});
    service.updateTask(task.copyWith(subtasks: updated));
  }

  // Remove a subtask from a task
  void removeSubtask(Task task, int index) {
    List<Map<String, dynamic>> updated = List.from(task.subtasks);
    updated.removeAt(index);
    service.updateTask(task.copyWith(subtasks: updated));
  }

  // Show a small dialog to type a subtask name
  void showAddSubtaskDialog(Task task) {
    TextEditingController subInput = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Subtask'),
          content: TextField(
            controller: subInput,
            decoration: const InputDecoration(hintText: 'Subtask name...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                addSubtask(task, subInput.text);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Build the subtask list shown under a task
  Widget buildSubtasks(Task task) {
    if (task.subtasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Text(
          'No subtasks yet.',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      );
    }

    List<Widget> rows = [];
    for (int i = 0; i < task.subtasks.length; i++) {
      String subTitle = task.subtasks[i]['title'] ?? '';
      rows.add(
        Row(
          children: [
            const SizedBox(width: 32),
            const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(subTitle, style: const TextStyle(fontSize: 14))),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => removeSubtask(task, i),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  // Build one task card
  Widget buildTaskTile(Task task) {
    bool isOpen = expandedTasks.contains(task.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          ListTile(
            // Checkbox on the left
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) => toggleDone(task),
            ),
            // Task title — strikethrough when done
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            // Expand and Delete buttons on the right
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      if (isOpen) {
                        expandedTasks.remove(task.id);
                      } else {
                        expandedTasks.add(task.id);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => confirmDelete(task.id),
                ),
              ],
            ),
          ),

          // Show subtasks when expanded
          if (isOpen)
            Column(
              children: [
                buildSubtasks(task),
                TextButton.icon(
                  onPressed: () => showAddSubtaskDialog(task),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add subtask'),
                ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Input row at the top
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskInput,
                    decoration: const InputDecoration(
                      hintText: 'New task name...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          // Live task list from Firestore
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: service.streamTasks(),
              builder: (context, snapshot) {
                // State 1: still connecting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // State 2: something went wrong
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<Task> tasks = snapshot.data ?? [];

                // State 3: no tasks yet
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks yet — add one above!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // State 4: show the list
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return buildTaskTile(tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}