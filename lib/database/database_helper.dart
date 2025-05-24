import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/todo.dart';

/// データベース管理クラス
/// これは「バックエンドのデータアクセス層」です
/// アプリとSQLiteデータベースの間を仲介します
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  /// シングルトンパターン：アプリ全体で1つのインスタンスのみ
  DatabaseHelper._privateConstructor();
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._privateConstructor();
    return _instance!;
  }

  /// データベースインスタンスの取得
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// データベースの初期化
  /// アプリ起動時に1回だけ実行される
  Future<Database> _initDatabase() async {
    // デスクトップ環境でSQLiteを使用するための初期化
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // データベースファイルの保存先を取得
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'todo_app.db');
    
    print('データベースパス: $path'); // デバッグ用

    // データベースを開く（存在しない場合は作成）
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase, // 初回作成時のテーブル作成
    );
  }

  /// データベーステーブルの作成
  /// これは「データベーススキーマ」の定義です
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
    
    print('TODOテーブルが作成されました'); // デバッグ用
  }

  // ========== CRUD操作（Create, Read, Update, Delete）==========

  /// 新しいTODOを作成（Create）
  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    
    // 現在時刻を設定
    final todoWithTimestamp = todo.copyWith(
      createdAt: DateTime.now(),
    );
    
    int id = await db.insert('todos', todoWithTimestamp.toMap());
    print('TODOが作成されました: ID=$id, タイトル=${todo.title}'); // デバッグ用
    return id;
  }

  /// 全てのTODOを取得（Read）
  Future<List<Todo>> getAllTodos() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      orderBy: 'createdAt DESC', // 作成日時の降順でソート
    );

    print('${maps.length}件のTODOを取得しました'); // デバッグ用
    
    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  /// 特定のTODOを取得
  Future<Todo?> getTodoById(int id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Todo.fromMap(maps.first);
    }
    return null;
  }

  /// TODOを更新（Update）
  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    
    // 更新時刻を設定
    final updatedTodo = todo.copyWith(
      updatedAt: DateTime.now(),
    );
    
    int count = await db.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    
    print('TODOが更新されました: ID=${todo.id}, タイトル=${todo.title}'); // デバッグ用
    return count;
  }

  /// TODOを削除（Delete）
  Future<int> deleteTodo(int id) async {
    final db = await database;
    
    int count = await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('TODOが削除されました: ID=$id'); // デバッグ用
    return count;
  }

  /// 完了状態を切り替え
  Future<int> toggleTodoStatus(int id) async {
    final todo = await getTodoById(id);
    if (todo != null) {
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );
      return await updateTodo(updatedTodo);
    }
    return 0;
  }

  /// 完了済みTODOの一括削除
  Future<int> deleteCompletedTodos() async {
    final db = await database;
    
    int count = await db.delete(
      'todos',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
    
    print('$count件の完了済みTODOが削除されました'); // デバッグ用
    return count;
  }

  /// データベースを閉じる
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 