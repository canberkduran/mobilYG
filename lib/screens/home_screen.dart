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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          final allTodos = snapshot.data ?? [];

          final todos = allTodos.where((todo) {
            final query = _searchQuery.toLowerCase();
            return todo.title.toLowerCase().contains(query) ||
                todo.description.toLowerCase().contains(query);
          }).toList();

          final totalTodos = allTodos.length;
          final completedTodos = allTodos.where((t) => t.isCompleted).length;
          final progress = totalTodos == 0 ? 0.0 : completedTodos / totalTodos;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Todos',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              if (totalTodos > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$completedTodos/$totalTodos Completed',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              Expanded(
                child: todos.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No todos yet. Add one!'
                              : 'No todos found matching "$_searchQuery"',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: todos.length,
                        itemBuilder: (context, index) {
                          final todo = todos[index];
                          final isOverdue =
                              todo.dueDate != null &&
                              todo.dueDate!.isBefore(DateTime.now()) &&
                              !todo.isCompleted;
                          final isDueSoon =
                              todo.dueDate != null &&
                              todo.dueDate!.difference(DateTime.now()).inDays <=
                                  1 &&
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
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(todo.dueDate!),
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
                                    notificationEnabled:
                                        todo.notificationEnabled,
                                  );
                                  await DatabaseHelper.instance.updateTodo(
                                    updatedTodo,
                                  );
                                  _refreshTodos();
                                },
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateTodoScreen(todo: todo),
                                  ),
                                );
                                _refreshTodos();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
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
