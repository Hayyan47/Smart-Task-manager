import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';

const Color mainBlue = taskMatePurple;
const Color lightBlue = Color(0xFFF0E6FF);
const Color darkText = Color(0xFF111827);
const Color greyText = Color(0xFF64748B);
const Color pageBackground = Color(0xFFFAF8FF);

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
  String selectedMenuOption = 'All Tasks';
  List<String> categoryOptions = ['Study', 'Work', 'Personal'];

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

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool matchesSelectedMenu(Map<String, dynamic> data) {
    String status = getTaskStatus(data);
    DateTime dueDate = readDate(data['dueDate']);

    if (selectedMenuOption == 'Today') {
      return isSameDay(dueDate, DateTime.now());
    }

    if (selectedMenuOption == 'High Priority') {
      return data['priority'] == 'High';
    }

    if (selectedMenuOption.startsWith('Category: ')) {
      String category = selectedMenuOption.replaceFirst('Category: ', '');
      return data['category'] == category;
    }

    if (selectedMenuOption == 'Completed') {
      return status == 'Done';
    }

    return true;
  }

  String menuSubtitle() {
    if (selectedMenuOption == 'Today') return 'Tasks due today';
    if (selectedMenuOption == 'High Priority') return 'Important tasks first';
    if (selectedMenuOption.startsWith('Category: ')) {
      String category = selectedMenuOption.replaceFirst('Category: ', '');
      return '$category category tasks';
    }
    if (selectedMenuOption == 'Completed') return 'Finished task list';
    return 'All your tasks in one place';
  }

  void selectMenuOption(String option) {
    setState(() {
      selectedMenuOption = option;
    });
    Navigator.pop(context);
  }

  void selectCategory(String category) {
    setState(() {
      selectedMenuOption = 'Category: $category';
    });
  }

  Future<void> openProfileInformation() async {
    User currentUser = FirebaseAuth.instance.currentUser ?? widget.user;
    final nameController = TextEditingController(
      text: currentUser.displayName ?? '',
    );
    final emailController = TextEditingController(
      text: currentUser.email ?? 'No email found',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profile Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: mainBlue.withValues(alpha: 0.28)),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person_rounded,
                            size: 54, color: mainBlue),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Profile Photo Frame',
                        style: TextStyle(
                          color: mainBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Photo URL upload removed',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: greyText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Gmail / Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
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
                String name = nameController.text.trim();

                await currentUser.updateDisplayName(name);
                await currentUser.reload();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
  }

  void openProfileFromMenu() {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        openProfileInformation();
      }
    });
  }

  Future<void> openCategoryPicker() async {
    String? category = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                for (String category in categoryOptions)
                  ListTile(
                    leading:
                        const Icon(Icons.category_rounded, color: mainBlue),
                    title: Text(category),
                    trailing: selectedMenuOption == 'Category: $category'
                        ? const Icon(Icons.check_circle, color: mainBlue)
                        : null,
                    onTap: () => Navigator.pop(context, category),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: greyText),
                  title: const Text('Show All Tasks'),
                  onTap: () => Navigator.pop(context, 'All Tasks'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (category == null) return;

    if (category == 'All Tasks') {
      setState(() => selectedMenuOption = 'All Tasks');
    } else {
      selectCategory(category);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterTasks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks,
  ) {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> result = [];

    for (var task in tasks) {
      Map<String, dynamic> data = task.data();
      String title = (data['title'] ?? '').toString().toLowerCase();
      bool matchesSearch = title.contains(searchText.toLowerCase());
      bool matchesMenu = matchesSelectedMenu(data);

      if (matchesSearch && matchesMenu) {
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
      backgroundColor: pageBackground,
      drawer: buildMenuDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(132),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [taskMatePurple, Color(0xFF8E2BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 18),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          tooltip: 'Open menu',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu_rounded,
                              color: Colors.white),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 72,
                    width: 82,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/taskmate_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.checklist_rounded,
                            color: taskMatePurple, size: 38);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'TaskMate Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menuSubtitle(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      tooltip: 'Logout',
                      onPressed: logout,
                      icon:
                          const Icon(Icons.logout_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: taskMatePurple.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded,
                          color: mainBlue, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedMenuOption,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            menuSubtitle(),
                            style:
                                const TextStyle(color: greyText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search task by title',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeaderChip(
                      icon: Icons.today,
                      text: 'Today',
                      selected: selectedMenuOption == 'Today',
                      onTap: () => setState(() => selectedMenuOption = 'Today'),
                    ),
                    const SizedBox(width: 8),
                    _HeaderChip(
                      icon: Icons.flag,
                      text: 'Priority',
                      selected: selectedMenuOption == 'High Priority',
                      onTap: () =>
                          setState(() => selectedMenuOption = 'High Priority'),
                    ),
                    const SizedBox(width: 8),
                    _HeaderChip(
                      icon: Icons.category,
                      text: 'Category',
                      selected: selectedMenuOption.startsWith('Category: '),
                      onTap: openCategoryPicker,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: openCategoryPicker,
                  icon: const Icon(Icons.category_rounded),
                  label: Text(
                    selectedMenuOption.startsWith('Category: ')
                        ? selectedMenuOption
                        : 'Choose Category',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mainBlue,
                    minimumSize: const Size(double.infinity, 46),
                    side: const BorderSide(color: mainBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                return LayoutBuilder(
                  builder: (context, boardSize) {
                    double columnWidth;

                    if (boardSize.maxWidth >= 900) {
                      // On laptop/web, show all four boards wide across the screen.
                      columnWidth = (boardSize.maxWidth - 48) / 4;
                    } else {
                      // On phone, one board should almost fill the screen width.
                      columnWidth = boardSize.maxWidth - 32;
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 70),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (String status in taskStatuses)
                            buildStatusColumn(status, allTasks, columnWidth),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        onPressed: () => openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget buildMenuDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [taskMatePurple, Color(0xFF8E2BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/taskmate_logo.png',
                      height: 74,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.task_alt_rounded,
                            color: Colors.white, size: 42);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'TaskMate Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quickly open the task view you need',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _MenuItem(
              icon: Icons.dashboard_rounded,
              label: 'All Tasks',
              selected: selectedMenuOption == 'All Tasks',
              onTap: () => selectMenuOption('All Tasks'),
            ),
            _MenuItem(
              icon: Icons.account_circle_rounded,
              label: 'Profile Information',
              selected: false,
              onTap: openProfileFromMenu,
            ),
            _MenuItem(
              icon: Icons.today_rounded,
              label: 'Today',
              selected: selectedMenuOption == 'Today',
              onTap: () => selectMenuOption('Today'),
            ),
            _MenuItem(
              icon: Icons.flag_rounded,
              label: 'High Priority',
              selected: selectedMenuOption == 'High Priority',
              onTap: () => selectMenuOption('High Priority'),
            ),
            _MenuItem(
              icon: Icons.school_rounded,
              label: 'Study Category',
              selected: selectedMenuOption == 'Category: Study',
              onTap: () => selectMenuOption('Category: Study'),
            ),
            _MenuItem(
              icon: Icons.work_rounded,
              label: 'Work Category',
              selected: selectedMenuOption == 'Category: Work',
              onTap: () => selectMenuOption('Category: Work'),
            ),
            _MenuItem(
              icon: Icons.person_rounded,
              label: 'Personal Category',
              selected: selectedMenuOption == 'Category: Personal',
              onTap: () => selectMenuOption('Category: Personal'),
            ),
            _MenuItem(
              icon: Icons.check_circle_rounded,
              label: 'Completed',
              selected: selectedMenuOption == 'Completed',
              onTap: () => selectMenuOption('Completed'),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: mainBlue),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusColumn(
      String status,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allTasks,
      double columnWidth) {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> statusTasks = [];

    for (var task in allTasks) {
      if (getTaskStatus(task.data()) == status) {
        statusTasks.add(task);
      }
    }

    return SizedBox(
      width: columnWidth,
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color chipColor = selected ? mainBlue : lightBlue;
    Color itemColor = selected ? Colors.white : mainBlue;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: itemColor),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? mainBlue : greyText),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? mainBlue : darkText,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedTileColor: lightBlue,
      onTap: onTap,
    );
  }
}
