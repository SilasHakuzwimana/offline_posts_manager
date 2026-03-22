// Defines the Post data model and its serialization to/from SQLite

class Post {
  final int? id;
  final String title;
  final String body;
  final String author;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a Post into a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'author': author,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a Post from a Map (SQLite row)
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      author: map['author'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // copyWith for immutable updates
  Post copyWith({
    int? id,
    String? title,
    String? body,
    String? author,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      author: author ?? this.author,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Post(id: $id, title: $title, author: $author, category: $category)';
}
