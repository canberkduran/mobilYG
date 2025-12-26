class Todo {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final int userId;
  final DateTime? dueDate;
  final bool notificationEnabled;
  final String? imagePath;

  Todo({
    this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.userId,
    this.dueDate,
    this.notificationEnabled = false,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'userId': userId,
      'dueDate': dueDate?.toIso8601String(),
      'notificationEnabled': notificationEnabled ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      userId: map['userId'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      notificationEnabled: map['notificationEnabled'] == 1,
      imagePath: map['imagePath'],
    );
  }
}
