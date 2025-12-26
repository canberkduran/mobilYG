import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/todo_model.dart';
import '../services/notification_service.dart';

class AddTodoScreen extends StatefulWidget {
  final int userId;

  const AddTodoScreen({super.key, required this.userId});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _notificationEnabled = false;

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

  void _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      final todo = Todo(
        title: _titleController.text,
        description: _descriptionController.text,
        userId: widget.userId,
        dueDate: _selectedDueDate,
        notificationEnabled: _notificationEnabled,
      );

      final todoId = await DatabaseHelper.instance.createTodo(todo);

      if (_notificationEnabled && _selectedDueDate != null) {
        // Schedule notification 1 day before due date
        final notificationTime =
            _selectedDueDate!.subtract(const Duration(days: 1));
        if (notificationTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleNotification(
            id: todoId.hashCode,
            title: 'Todo Reminder',
            body: '${todo.title} is due tomorrow!',
            scheduledDate: notificationTime,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Todo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                    onPressed: _saveTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SAVE TODO',
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
