class Todo {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final int userId;

  Todo({
    this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'userId': userId,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      userId: map['userId'],
    );
  }
}
