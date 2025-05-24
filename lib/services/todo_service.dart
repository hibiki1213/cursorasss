import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/todo.dart';

/// TODOビジネスロジック管理クラス
/// これは「バックエンドのサービス層」です
/// データベース操作とUI状態管理を仲介します
class TodoService extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // アプリの状態を保持するプロパティ
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 外部からアクセスするためのゲッター
  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 統計情報のゲッター
  int get totalCount => _todos.length;
  int get completedCount => _todos.where((todo) => todo.isCompleted).length;
  int get pendingCount => _todos.where((todo) => !todo.isCompleted).length;
  double get completionRate => 
      totalCount > 0 ? completedCount / totalCount : 0.0;

  /// 初期化：アプリ起動時にデータベースからTODOを読み込み
  Future<void> initialize() async {
    await loadTodos();
  }

  /// 全てのTODOを読み込み（フロントエンドに表示するため）
  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();
    
    try {
      _todos = await _databaseHelper.getAllTodos();
      print('✅ ${_todos.length}件のTODOを読み込みました');
      _notifyListeners();
    } catch (e) {
      _setError('TODOの読み込みに失敗しました: $e');
      print('❌ TODO読み込みエラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 新しいTODOを作成
  Future<bool> createTodo(String title, {String? description}) async {
    _clearError();
    
    // 入力値検証（バリデーション）
    if (title.trim().isEmpty) {
      _setError('タイトルを入力してください');
      return false;
    }

    try {
      final newTodo = Todo(
        title: title.trim(),
        description: description?.trim(),
        createdAt: DateTime.now(),
      );

      int id = await _databaseHelper.insertTodo(newTodo);
      
      // ローカル状態を更新（データベースから再読み込みせずに効率化）
      final todoWithId = newTodo.copyWith(id: id);
      _todos.insert(0, todoWithId); // 先頭に追加
      
      print('✅ TODO作成成功: $title');
      _notifyListeners();
      return true;
    } catch (e) {
      _setError('TODOの作成に失敗しました: $e');
      print('❌ TODO作成エラー: $e');
      return false;
    }
  }

  /// TODOの完了状態を切り替え
  Future<bool> toggleTodoCompletion(int todoId) async {
    _clearError();
    
    try {
      await _databaseHelper.toggleTodoStatus(todoId);
      
      // ローカル状態を更新
      final index = _todos.indexWhere((todo) => todo.id == todoId);
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
          updatedAt: DateTime.now(),
        );
        
        print('✅ TODO状態変更: ID=$todoId, 完了=${_todos[index].isCompleted}');
        _notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('TODOの状態変更に失敗しました: $e');
      print('❌ TODO状態変更エラー: $e');
    }
    return false;
  }

  /// TODOを更新
  Future<bool> updateTodo(int todoId, String title, {String? description}) async {
    _clearError();
    
    // 入力値検証
    if (title.trim().isEmpty) {
      _setError('タイトルを入力してください');
      return false;
    }

    try {
      final index = _todos.indexWhere((todo) => todo.id == todoId);
      if (index != -1) {
        final updatedTodo = _todos[index].copyWith(
          title: title.trim(),
          description: description?.trim(),
          updatedAt: DateTime.now(),
        );

        await _databaseHelper.updateTodo(updatedTodo);
        _todos[index] = updatedTodo;
        
        print('✅ TODO更新成功: $title');
        _notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('TODOの更新に失敗しました: $e');
      print('❌ TODO更新エラー: $e');
    }
    return false;
  }

  /// TODOを削除
  Future<bool> deleteTodo(int todoId) async {
    _clearError();
    
    try {
      await _databaseHelper.deleteTodo(todoId);
      
      // ローカル状態から削除
      _todos.removeWhere((todo) => todo.id == todoId);
      
      print('✅ TODO削除成功: ID=$todoId');
      _notifyListeners();
      return true;
    } catch (e) {
      _setError('TODOの削除に失敗しました: $e');
      print('❌ TODO削除エラー: $e');
      return false;
    }
  }

  /// 完了済みTODOを一括削除
  Future<bool> deleteCompletedTodos() async {
    _clearError();
    
    try {
      await _databaseHelper.deleteCompletedTodos();
      
      // ローカル状態から完了済みTODOを削除
      final completedCount = _todos.where((todo) => todo.isCompleted).length;
      _todos.removeWhere((todo) => todo.isCompleted);
      
      print('✅ 完了済みTODO一括削除: ${completedCount}件');
      _notifyListeners();
      return true;
    } catch (e) {
      _setError('完了済みTODOの削除に失敗しました: $e');
      print('❌ 完了済みTODO削除エラー: $e');
      return false;
    }
  }

  /// フィルタリング機能
  List<Todo> getFilteredTodos(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return _todos;
      case TodoFilter.pending:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return _todos.where((todo) => todo.isCompleted).toList();
    }
  }

  /// 検索機能
  List<Todo> searchTodos(String query) {
    if (query.trim().isEmpty) return _todos;
    
    final lowerQuery = query.toLowerCase();
    return _todos.where((todo) {
      return todo.title.toLowerCase().contains(lowerQuery) ||
             (todo.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ========== 内部ヘルパーメソッド ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    // リソースのクリーンアップ
    _databaseHelper.close();
    super.dispose();
  }
}

/// TODOフィルタリング用の列挙型
enum TodoFilter {
  all,        // 全て
  pending,    // 未完了
  completed,  // 完了済み
} 