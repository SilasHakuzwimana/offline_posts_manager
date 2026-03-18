
# Offline Posts Manager

> **Flutter Lab 5** — Individual Assignment
>
> Mobile Application Systems & Design

A Flutter application that lets media company staff **create, read, update, and delete posts entirely offline** using a local SQLite database. No internet connection required ever.

## Screenshots

> *Add your app screenshots here after running the app on a device or emulator.*

## Features

| # | Feature                  | Details                                                         |
| - | ------------------------ | --------------------------------------------------------------- |
| 1 | **View all posts** | Scrollable card list with real-time search and category filters |
| 2 | **Read a post**    | Full detail screen with author, timestamps, and category badge  |
| 3 | **Create a post**  | Validated form — title, author, category dropdown, and content |
| 4 | **Edit a post**    | Same form screen, pre-populated with existing data              |
| 5 | **Delete a post**  | Confirmation dialog before permanent removal                    |
| 6 | **100% Offline**   | All data lives in a local SQLite `.db`file on the device      |

## Project Structure

```
offline_posts_manager/
├── pubspec.yaml
└── lib/
    ├── main.dart                      # App entry point & MaterialApp theme
    ├── models/
    │   └── post.dart                  # Post data model (toMap / fromMap / copyWith)
    ├── database/
    │   └── database_helper.dart       # SQLite singleton — CRUD + exception handling
    └── screens/
        ├── home_screen.dart           # Post list, search bar, category chips, delete
        ├── post_detail_screen.dart    # Read-only SliverAppBar detail view
        └── post_form_screen.dart      # Shared Create / Edit form with validation
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.2   # SQLite engine for Flutter (Android, iOS, Desktop)
  path: ^1.9.0      # Cross-platform file path building
  intl: ^0.19.0     # Date/time formatting in the UI
  cupertino_icons: ^1.0.6
```

| Package     | Why it's needed                                                                                |
| ----------- | ---------------------------------------------------------------------------------------------- |
| `sqflite` | Provides a full SQLite implementation with async APIs so DB I/O never blocks the UI thread     |
| `path`    | Builds the correct OS-specific path to the `.db`file using `join(getDatabasesPath(), ...)` |
| `intl`    | Formats `DateTime`values into readable strings like `Mar 18, 2026 · 9:00 AM`              |

## Database Schema

**Database file:** `posts_manager.db`

**Table:** `posts`

| Column         | Type    | Constraint                | Purpose                          |
| -------------- | ------- | ------------------------- | -------------------------------- |
| `id`         | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique row identifier            |
| `title`      | TEXT    | NOT NULL                  | Post headline                    |
| `body`       | TEXT    | NOT NULL                  | Post content                     |
| `author`     | TEXT    | NOT NULL                  | Name of the author               |
| `category`   | TEXT    | DEFAULT 'General'         | Content category                 |
| `created_at` | TEXT    | NOT NULL                  | ISO-8601 creation timestamp      |
| `updated_at` | TEXT    | NOT NULL                  | ISO-8601 last-modified timestamp |

## CRUD Operations

| Operation | SQL                      | `sqflite`API       | App Method                              |
| --------- | ------------------------ | -------------------- | --------------------------------------- |
| Create    | `INSERT INTO posts`    | `db.insert()`      | `DatabaseHelper.insertPost(post)`     |
| Read all  | `SELECT * FROM posts`  | `db.query()`       | `DatabaseHelper.getAllPosts()`        |
| Read one  | `SELECT WHERE id = ?`  | `db.query(where:)` | `DatabaseHelper.getPostById(id)`      |
| Search    | `SELECT WHERE LIKE ?`  | `db.query(where:)` | `DatabaseHelper.searchPosts(keyword)` |
| Update    | `UPDATE posts SET ...` | `db.update()`      | `DatabaseHelper.updatePost(post)`     |
| Delete    | `DELETE WHERE id = ?`  | `db.delete()`      | `DatabaseHelper.deletePost(id)`       |

## Exception Handling

A custom `DatabaseException` class wraps all errors so the UI always receives one consistent type:

```dart
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  DatabaseException(this.message, [this.originalError]);
}
```

| Scenario                       | Strategy                                                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------------------------- |
| DB not initialised             | `_initDatabase()`wraps `openDatabase()`in try/catch and throws `DatabaseException`                |
| Insert / Update / Delete fails | Each CRUD method catches `SqfliteDatabaseException`and rethrows as `DatabaseException`              |
| Invalid data                   | Two-layer check: FormField validators in the UI**and**null/empty guards inside `DatabaseHelper` |
| Row not found                  | `update()`and `delete()`check `rowsAffected == 0`and throw with a descriptive message             |
| Corrupted timestamp            | `Post.fromMap()`uses `DateTime.tryParse()`with a `?? DateTime.now()`fallback                      |

All UI screens catch `DatabaseException` and display the message via a `SnackBar`.

## Async & Flutter's Threading Model

Flutter runs on a single UI thread (Isolate). The `sqflite` package executes all SQL on a **background thread** and returns `Future<T>`, so the UI stays responsive:

```dart
Future<List<Post>> getAllPosts() async {
  final db = await database;         // await the DB connection
  final maps = await db.query(       // await the SELECT query
    'posts',
    orderBy: 'created_at DESC',
  );
  return maps.map(Post.fromMap).toList();
}
```

`setState()` is called after each `await` so the UI rebuilds only when data is ready.

## Getting Started

### Prerequisites

* Flutter SDK `>=3.0.0`
* Dart SDK `>=3.0.0`
* Android emulator / iOS simulator / physical device

### Run the app

```bash
# 1. Clone the repository
git clone https://github.com/SilasHakuzwimanaE/offline_posts_manager.git
cd offline_posts_manager

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run
```

The app seeds **3 sample posts** on first launch so the list is never empty.

## Architecture Notes

* **`DatabaseHelper` is a Singleton** — only one instance exists, preventing multiple simultaneous connections to the same SQLite file.
* **`Post.copyWith()`** enables immutable updates — a new object is created with changed fields rather than mutating the original (idiomatic Flutter).
* **`PostFormScreen` is shared** for both Create and Edit — when `post == null` it creates; otherwise it pre-fills and updates. Eliminates duplication and keeps validation in one place.

## Submission Checklist

* [ ] GitHub repository with all source code pushed
* [ ] `pubspec.yaml` includes `sqflite`, `path`, `intl`
* [ ] `DatabaseHelper` singleton implements all CRUD operations
* [ ] `Post` model has `toMap()`, `fromMap()`, `copyWith()`
* [ ] `HomeScreen` — list, search, category filter, delete
* [ ] `PostDetailScreen` — read-only detail view
* [ ] `PostFormScreen` — handles both Create and Edit
* [ ] Delete uses a confirmation dialog
* [ ] All DB calls wrapped in try/catch with `DatabaseException`
* [ ] Form validation prevents empty / too-short fields
* [ ] PDF with scanned handwritten answers + screenshots submitted

## License

This project is submitted as coursework for educational purposes.
