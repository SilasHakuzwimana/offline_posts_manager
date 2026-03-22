import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/post.dart';

class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  DatabaseException(this.message, [this.originalError]);

  @override
  String toString() => 'DatabaseException: $message';
}

class DatabaseHelper {
  //  Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  //  Constants
  static const String _dbName = 'posts_manager.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'posts';

  // Database initialisation
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTable,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialise database', e);
    }
  }

  //DDL
  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        body       TEXT    NOT NULL,
        author     TEXT    NOT NULL,
        category   TEXT    NOT NULL DEFAULT 'General',
        created_at TEXT    NOT NULL,
        updated_at TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add a new column 'tags' to existing posts table
      await db.execute('ALTER TABLE posts ADD COLUMN tags TEXT DEFAULT ""');
    }
  }

  //  CRUD
  /// CREATE – insert a new post and return its auto-generated id
  Future<int> insertPost(Post post) async {
    try {
      final db = await database;
      // Validate required fields before touching the DB
      if (post.title.trim().isEmpty) {
        throw DatabaseException('Title cannot be empty');
      }
      if (post.body.trim().isEmpty) {
        throw DatabaseException('Body cannot be empty');
      }
      final map = post.toMap()..remove('id'); // let SQLite assign the id
      final id = await db.insert(
        _tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id;
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to insert post', e);
    }
  }

  /// READ ALL – return every post ordered newest-first
  Future<List<Post>> getAllPosts() async {
    try {
      final db = await database;
      final maps = await db.query(_tableName, orderBy: 'created_at DESC');
      return maps.map(Post.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to retrieve posts', e);
    }
  }

  /// READ ONE – fetch a single post by primary key
  Future<Post?> getPostById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Post.fromMap(maps.first);
    } catch (e) {
      throw DatabaseException('Failed to retrieve post with id $id', e);
    }
  }

  /// SEARCH – filter posts by keyword in title or body
  Future<List<Post>> searchPosts(String keyword) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        where: 'title LIKE ? OR body LIKE ? OR author LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
        orderBy: 'created_at DESC',
      );
      return maps.map(Post.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Search failed', e);
    }
  }

  /// UPDATE – save changes to an existing post
  Future<int> updatePost(Post post) async {
    try {
      if (post.id == null) {
        throw DatabaseException('Cannot update a post without an id');
      }
      if (post.title.trim().isEmpty) {
        throw DatabaseException('Title cannot be empty');
      }
      if (post.body.trim().isEmpty) {
        throw DatabaseException('Body cannot be empty');
      }

      final db = await database;
      final rows = await db.update(
        _tableName,
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
      if (rows == 0) {
        throw DatabaseException('Post with id ${post.id} not found');
      }
      return rows;
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to update post', e);
    }
  }

  /// DELETE – remove a post by id
  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      final rows = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows == 0) throw DatabaseException('Post with id $id not found');
      return rows;
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to delete post', e);
    }
  }

  /// Close the database connection (call when app is disposed)
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
