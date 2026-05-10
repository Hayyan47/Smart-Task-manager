import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';

// Home Screen
// Firebase function used here for logout:
// signOut()
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
    await taskCollection.doc(taskId).update({
      'status': newStatus,
      'completed': newStatus == 'Done',
    });
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
    if (status == 'To Do') return Colors.grey;
    if (status == 'In Progress') return Colors.blue;
    if (status == 'In Review') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate Board'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search task',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => searchText = value);
              },
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

                if (allTasks.isEmpty) {
                  return const Center(
                      child: Text('No tasks yet. Press + to add task.'));
                }

                // This makes a simple Jira/Kanban board.
                // Every status gets its own list.
                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    for (String status in taskStatuses)
                      buildStatusList(status, allTasks),
                  ],
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

  Widget buildStatusList(String status,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks) {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> statusTasks = [];

    for (var task in allTasks) {
      if (getTaskStatus(task.data()) == status) {
        statusTasks.add(task);
      }
    }

    return Card(
      margin: const EdgeInsets.all(12),
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
                Text(
                  '$status (${statusTasks.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (statusTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No tasks here'),
              )
            else
              for (var task in statusTasks) buildTaskCard(task),
          ],
        ),
      ),
    );
  }

  Widget buildTaskCard(QueryDocumentSnapshot<Map<String, dynamic>> task) {
    Map<String, dynamic> data = task.data();
    DateTime dueDate = readDate(data['dueDate']);
    String status = getTaskStatus(data);

    return Card(
      color: const Color(0xFFF9FAFB),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            Text(data['description'] ?? ''),
            const SizedBox(height: 6),
            Text('Due: ${DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)}'),
            Text(
                'Priority: ${data['priority']} | Category: ${data['category']}'),
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
