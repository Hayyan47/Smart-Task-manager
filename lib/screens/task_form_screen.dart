import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../services/reminder_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, required this.userId, this.task});

  final String userId;
  final TaskModel? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService();

  late DateTime _dueAt;
  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.study;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    _dueAt = task?.dueAt ?? DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? TaskCategory.study;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDate: _dueAt,
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(picked.year, picked.month, picked.day, _dueAt.hour, _dueAt.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dueAt.hour, minute: _dueAt.minute),
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(_dueAt.year, _dueAt.month, _dueAt.day, picked.hour, picked.minute);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueAt: _dueAt,
          priority: _priority,
          category: _category,
        );
        await _taskService.updateTask(updatedTask);
        await ReminderService.instance.cancelTaskReminder(updatedTask.id);
        await ReminderService.instance.scheduleTaskReminder(updatedTask);
      } else {
        final newTask = TaskModel(
          id: '',
          userId: widget.userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueAt: _dueAt,
          priority: _priority,
          category: _category,
          isCompleted: false,
          createdAt: DateTime.now(),
        );
        final id = await _taskService.addTask(newTask);
        await ReminderService.instance.scheduleTaskReminder(newTask.copyWith(id: id));
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save task: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Add Task')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Task title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today,
                      label: 'Due Date',
                      value: DateFormat('MMM d, yyyy').format(_dueAt),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule,
                      label: 'Due Time',
                      value: DateFormat('h:mm a').format(_dueAt),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority', prefixIcon: Icon(Icons.flag_outlined)),
                items: TaskPriority.values
                    .map((priority) => DropdownMenuItem(value: priority, child: Text(priority.label)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value ?? TaskPriority.medium),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.folder_outlined)),
                items: TaskCategory.values
                    .map((category) => DropdownMenuItem(value: category, child: Text(category.label)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? TaskCategory.study),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTask,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'SAVE CHANGES' : 'CREATE TASK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                  const SizedBox(height: 4),
                  Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
