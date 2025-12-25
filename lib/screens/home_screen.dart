import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/database_helper.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Todos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
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
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  subtitle: Text(
                    todo.description,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
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
