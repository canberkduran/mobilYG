import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/database_helper.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import 'add_todo_screen.dart';
import 'update_todo_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  void _refreshTodos() {
    setState(() {
      _todosFuture = DatabaseHelper.instance.getTodos(widget.user.id!);
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Todos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final todos = snapshot.data ?? [];

          if (todos.isEmpty) {
            return Center(
              child: Text(
                'No todos yet. Add one!',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              final isOverdue = todo.dueDate != null &&
                  todo.dueDate!.isBefore(DateTime.now()) &&
                  !todo.isCompleted;
              final isDueSoon = todo.dueDate != null &&
                  todo.dueDate!.difference(DateTime.now()).inDays <= 1 &&
                  todo.dueDate!.isAfter(DateTime.now()) &&
                  !todo.isCompleted;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.1)
                    : isDueSoon
                        ? Colors.orange.withValues(alpha: 0.1)
                        : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    todo.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        todo.description,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (todo.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(todo.dueDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isOverdue
                                    ? Colors.red
                                    : isDueSoon
                                        ? Colors.orange
                                        : Colors.grey[600],
                                fontWeight: isOverdue || isDueSoon
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isOverdue)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (isDueSoon && !isOverdue)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'DUE SOON',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Checkbox(
                    value: todo.isCompleted,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) async {
                      final updatedTodo = Todo(
                        id: todo.id,
                        title: todo.title,
                        description: todo.description,
                        isCompleted: value!,
                        userId: todo.userId,
                        dueDate: todo.dueDate,
                        notificationEnabled: todo.notificationEnabled,
                      );
                      await DatabaseHelper.instance.updateTodo(updatedTodo);
                      _refreshTodos();
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateTodoScreen(todo: todo),
                      ),
                    );
                    _refreshTodos();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoScreen(userId: widget.user.id!),
            ),
          );
          _refreshTodos();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
