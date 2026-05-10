import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  TaskFilter _filter = TaskFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    var filtered = tasks;

    filtered = switch (_filter) {
      TaskFilter.all => filtered,
      TaskFilter.today => filtered.where((task) => task.isToday && !task.isCompleted).toList(),
      TaskFilter.upcoming => filtered.where((task) => task.isUpcoming).toList(),
      TaskFilter.completed => filtered.where((task) => task.isCompleted).toList(),
    };

    if (_query.trim().isNotEmpty) {
      final query = _query.toLowerCase();
      filtered = filtered.where((task) => task.title.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  Future<void> _openTaskForm([TaskModel? task]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(userId: widget.user.uid, task: task),
      ),
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This will permanently delete "${task.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await ReminderService.instance.cancelTaskReminder(task.id);
    await _taskService.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName?.trim();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TaskMate', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              displayName == null || displayName.isEmpty ? 'Smart Task Manager' : 'Hi, $displayName',
              style: const TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _authService.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.watchTasks(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load tasks: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          final visibleTasks = _applyFilters(tasks);
          final completedCount = tasks.where((task) => task.isCompleted).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _SummaryCard(total: tasks.length, completed: completedCount),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search tasks by title',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 16),
              FilterChipBar(selected: _filter, onChanged: (filter) => setState(() => _filter = filter)),
              const SizedBox(height: 12),
              if (visibleTasks.isEmpty)
                const _EmptyState()
              else
                ...visibleTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onToggleComplete: (completed) async {
                        await _taskService.setCompleted(task, completed);
                        if (completed) {
                          await ReminderService.instance.cancelTaskReminder(task.id);
                        } else {
                          await ReminderService.instance.scheduleTaskReminder(task.copyWith(isCompleted: false));
                        }
                      },
                      onEdit: () => _openTaskForm(task),
                      onDelete: () => _deleteTask(task),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final remaining = total - completed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: Colors.white, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today is a good day to finish tasks.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('$remaining remaining • $completed completed', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: AppTheme.muted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No tasks found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Tap the + button to add your first task.', style: TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }
}
