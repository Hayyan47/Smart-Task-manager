import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';

// Home Screen designed as the task management/problem solving part.
// User can add tasks, search tasks, and move tasks between boards.
// Firebase function used here for logout:
// signOut()
// Firestore is used here to save task data.
// This screen also contains the simple Jira style task board.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = '';

  // These are the Jira style stages.
  // A task starts in To Do, then moves step by step until Done.
  List<String> taskStatuses = ['To Do', 'In Progress', 'In Review', 'Done'];

  CollectionReference<Map<String, dynamic>> get taskCollection {
    return FirebaseFirestore.instance.collection('tasks');
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    await taskCollection.doc(taskId).delete();
  }

  Future<void> moveTask(String taskId, String newStatus) async {
    // This solves the Jira style movement problem.
    // When a task is moved by swipe or dropdown,
    // its board/status is updated in Firebase.
    await taskCollection.doc(taskId).update({
      'status': newStatus,
      'completed': newStatus == 'Done',
    });
  }

  String nextStatus(String currentStatus) {
    int index = taskStatuses.indexOf(currentStatus);

    if (index < taskStatuses.length - 1) {
      return taskStatuses[index + 1];
    }

    return currentStatus;
  }

  String previousStatus(String currentStatus) {
    int index = taskStatuses.indexOf(currentStatus);

    if (index > 0) {
      return taskStatuses[index - 1];
    }

    return currentStatus;
  }

  void swipeTask(String taskId, String currentStatus, bool moveForward) {
    String newStatus;

    if (moveForward) {
      newStatus = nextStatus(currentStatus);
    } else {
      newStatus = previousStatus(currentStatus);
    }

    if (newStatus != currentStatus) {
      moveTask(taskId, newStatus);
    }
  }

  // Old tasks may not have a status field, so this function gives them a default status.
  String getTaskStatus(Map<String, dynamic> data) {
    if (data['status'] != null) {
      return data['status'];
    }

    if (data['completed'] == true) {
      return 'Done';
    }

    return 'To Do';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterTasks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks,
  ) {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> result = [];

    for (var task in tasks) {
      Map<String, dynamic> data = task.data();
      String title = (data['title'] ?? '').toString().toLowerCase();
      bool matchesSearch = title.contains(searchText.toLowerCase());

      if (matchesSearch) {
        result.add(task);
      }
    }

    result.sort((a, b) {
      DateTime first = readDate(a.data()['dueDate']);
      DateTime second = readDate(b.data()['dueDate']);
      return first.compareTo(second);
    });

    return result;
  }

  DateTime readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.now();
  }

  Color statusColor(String status) {
    if (status == 'To Do') return const Color(0xFF64748B);
    if (status == 'In Progress') return const Color(0xFF1D4ED8);
    if (status == 'In Review') return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TaskMate',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Smart Task Board',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard_customize_rounded,
                        color: Colors.white, size: 34),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'TaskMate Smart Task Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search task',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: taskCollection
                  .where('userId', isEqualTo: widget.user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading tasks'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks =
                    filterTasks(snapshot.data!.docs);

                // This makes a simple board.
                // The columns go from left to right:
                // To Do -> In Progress -> In Review -> Done.
                // Swipe task card right to move forward.
                // Swipe task card left to move backward.
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (String status in taskStatuses)
                        buildStatusColumn(status, allTasks),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget buildStatusColumn(String status,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks) {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> statusTasks = [];

    for (var task in allTasks) {
      if (getTaskStatus(task.data()) == status) {
        statusTasks.add(task);
      }
    }

    return SizedBox(
      width: 300,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: statusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$status (${statusTasks.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Swipe card right/left to move',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: statusTasks.isEmpty
                    ? const Center(child: Text('No tasks here'))
                    : ListView(
                        children: [
                          for (var task in statusTasks) buildTaskCard(task),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskCard(QueryDocumentSnapshot<Map<String, dynamic>> task) {
    Map<String, dynamic> data = task.data();
    String status = getTaskStatus(data);

    return GestureDetector(
      // Basic gesture:
      // Swipe right = move to next board.
      // Swipe left = move to previous board.
      onHorizontalDragEnd: (details) {
        double swipeSpeed = details.primaryVelocity ?? 0;

        if (swipeSpeed < -200) {
          swipeTask(task.id, status, true);
        } else if (swipeSpeed > 200) {
          swipeTask(task.id, status, false);
        }
      },
      child: buildTaskCardDesign(task),
    );
  }

  Widget buildTaskCardDesign(QueryDocumentSnapshot<Map<String, dynamic>> task) {
    Map<String, dynamic> data = task.data();
    DateTime dueDate = readDate(data['dueDate']);
    String status = getTaskStatus(data);

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      openTaskForm(taskId: task.id, oldData: data);
                    } else if (value == 'delete') {
                      deleteTask(task.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Text(
              data['description'] ?? '',
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Text(
              'Due: ${DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            Text(
              'Priority: ${data['priority']} | Category: ${data['category']}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Move task to',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                DropdownMenuItem(
                    value: 'In Progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                DropdownMenuItem(value: 'Done', child: Text('Done')),
              ],
              onChanged: (value) {
                if (value != null) {
                  moveTask(task.id, value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openTaskForm(
      {String? taskId, Map<String, dynamic>? oldData}) async {
    final titleController =
        TextEditingController(text: oldData?['title'] ?? '');
    final descriptionController =
        TextEditingController(text: oldData?['description'] ?? '');

    String priority = oldData?['priority'] ?? 'Medium';
    String category = oldData?['category'] ?? 'Study';
    String status = oldData == null ? 'To Do' : getTaskStatus(oldData);
    DateTime dueDate = oldData == null
        ? DateTime.now().add(const Duration(days: 1))
        : readDate(oldData['dueDate']);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(taskId == null ? 'Add Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (value) {
                        priority = value ?? 'Medium';
                      },
                      decoration: const InputDecoration(labelText: 'Priority'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: const [
                        DropdownMenuItem(value: 'Study', child: Text('Study')),
                        DropdownMenuItem(value: 'Work', child: Text('Work')),
                        DropdownMenuItem(
                            value: 'Personal', child: Text('Personal')),
                      ],
                      onChanged: (value) {
                        category = value ?? 'Study';
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const [
                        DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                        DropdownMenuItem(
                            value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'In Review', child: Text('In Review')),
                        DropdownMenuItem(value: 'Done', child: Text('Done')),
                      ],
                      onChanged: (value) {
                        status = value ?? 'To Do';
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Due: ${DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              initialDate: dueDate,
                            );

                            if (pickedDate != null) {
                              setDialogState(() {
                                dueDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  dueDate.hour,
                                  dueDate.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                        TextButton(
                          onPressed: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                  hour: dueDate.hour, minute: dueDate.minute),
                            );

                            if (pickedTime != null) {
                              setDialogState(() {
                                dueDate = DateTime(
                                  dueDate.year,
                                  dueDate.month,
                                  dueDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String title = titleController.text.trim();
                    String description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    Map<String, dynamic> taskData = {
                      'userId': widget.user.uid,
                      'title': title,
                      'description': description,
                      'priority': priority,
                      'category': category,
                      'status': status,
                      'dueDate': dueDate,
                      'completed': status == 'Done',
                      'createdAt': oldData?['createdAt'] ?? DateTime.now(),
                    };

                    if (taskId == null) {
                      await taskCollection.add(taskData);
                    } else {
                      await taskCollection.doc(taskId).update(taskData);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }
}
