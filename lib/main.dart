import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

// TaskMate - simple student version.
// This file has most of the app code in one place so it is easier to read.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TaskMateApp());
}

class TaskMateApp extends StatelessWidget {
  const TaskMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      ),
      home: const StartPage(),
    );
  }
}

// This page checks if the user is logged in or not.
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return HomePage(user: snapshot.data!);
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool isLogin = true;
  bool rememberMe = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadSavedEmail();
  }

  Future<void> loadSavedEmail() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String savedEmail = preferences.getString('savedEmail') ?? '';

    if (savedEmail.isNotEmpty) {
      setState(() {
        emailController.text = savedEmail;
        rememberMe = true;
      });
    }
  }

  Future<void> saveEmailIfNeeded(String email) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    if (rememberMe) {
      await preferences.setString('savedEmail', email);
    } else {
      await preferences.remove('savedEmail');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => loading = true);

    try {
      await saveEmailIfNeeded(email);

      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential result =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await result.user!.updateDisplayName(name);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set({
          'name': name,
          'email': email,
          'createdAt': DateTime.now(),
        });
      }
    } on FirebaseAuthException catch (error) {
      showMessage(error.message ?? 'Something went wrong');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt, size: 80, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  'TaskMate',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const Text('Smart Task Manager'),
                const SizedBox(height: 30),
                Text(
                  isLogin ? 'LOGIN' : 'REGISTER',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (!isLogin)
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!isLogin && (value == null || value.trim().isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                if (!isLogin) const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                CheckboxListTile(
                  value: rememberMe,
                  title: const Text('Remember my email'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() => rememberMe = value ?? false);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const CircularProgressIndicator()
                      : Text(isLogin ? 'Login' : 'Create Account'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Do not have account? Register'
                        : 'Already have account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchText = '';

  // These are the Jira style stages.
  // A task starts in To Do, then moves step by step until Done.
  List<String> taskStatuses = ['To Do', 'In Progress', 'In Review', 'Done'];

  CollectionReference<Map<String, dynamic>> get taskCollection {
    return FirebaseFirestore.instance.collection('tasks');
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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
