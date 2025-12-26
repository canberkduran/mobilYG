import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/todo_model.dart';
import '../services/notification_service.dart';

class UpdateTodoScreen extends StatefulWidget {
  final Todo todo;

  const UpdateTodoScreen({super.key, required this.todo});

  @override
  State<UpdateTodoScreen> createState() => _UpdateTodoScreenState();
}

class _UpdateTodoScreenState extends State<UpdateTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime? _selectedDueDate;
  late bool _notificationEnabled;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(
      text: widget.todo.description,
    );
    _selectedDueDate = widget.todo.dueDate;
    _notificationEnabled = widget.todo.notificationEnabled;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _updateTodo() async {
    if (_formKey.currentState!.validate()) {
      final updatedTodo = Todo(
        id: widget.todo.id,
        title: _titleController.text,
        description: _descriptionController.text,
        isCompleted: widget.todo.isCompleted,
        userId: widget.todo.userId,
        dueDate: _selectedDueDate,
        notificationEnabled: _notificationEnabled,
      );

      // Cancel old notification if it exists
      if (widget.todo.id != null) {
        await NotificationService()
            .cancelNotification(widget.todo.id!.hashCode);
      }

      // Schedule new notification if enabled
      if (_notificationEnabled && _selectedDueDate != null) {
        final notificationTime =
            _selectedDueDate!.subtract(const Duration(days: 1));
        if (notificationTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleNotification(
            id: updatedTodo.id!.hashCode,
            title: 'Todo Reminder',
            body: '${updatedTodo.title} is due tomorrow!',
            scheduledDate: notificationTime,
          );
        }
      }

      await DatabaseHelper.instance.updateTodo(updatedTodo);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _deleteTodo() async {
    // Cancel notification if it exists
    if (widget.todo.id != null) {
      await NotificationService()
          .cancelNotification(widget.todo.id!.hashCode);
    }
    await DatabaseHelper.instance.deleteTodo(widget.todo.id!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Todo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Todo'),
                  content: const Text(
                    'Are you sure you want to delete this todo?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTodo();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDueDate == null
                          ? 'Select Due Date'
                          : 'Due: ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}',
                    ),
                    onPressed: () => _selectDate(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDueDate != null)
                    CheckboxListTile(
                      title: const Text('Enable Notification Reminder'),
                      subtitle:
                          const Text('You will be notified 1 day before'),
                      value: _notificationEnabled,
                      onChanged: (bool? value) {
                        setState(() {
                          _notificationEnabled = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'UPDATE TODO',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
