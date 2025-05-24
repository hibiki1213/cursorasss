import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../models/todo.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_dialog.dart';

/// TODOアプリのメイン画面
/// これは「フロントエンドのメインUI」です
/// ユーザーが操作する全ての画面要素を含みます
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  TodoFilter _currentFilter = TodoFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // アプリ起動時にTODOデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoService>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // アプリバー（上部のヘッダー）
      appBar: AppBar(
        title: const Text(
          'TODO Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        // アクションボタン（右上）
        actions: [
          // 完了済みTODO一括削除ボタン
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              final hasCompleted = todoService.completedCount > 0;
              return IconButton(
                onPressed: hasCompleted ? _deleteCompletedTodos : null,
                icon: const Icon(Icons.clear_all),
                tooltip: '完了済みを削除',
              );
            },
          ),
          // 設定ボタン（将来的に追加）
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'アプリ情報',
          ),
        ],
      ),

      // メインコンテンツ
      body: Column(
        children: [
          // 統計情報パネル
          _buildStatsPanel(),
          
          // 検索バー
          _buildSearchBar(),
          
          // フィルタータブ
          _buildFilterTabs(),
          
          // TODOリスト
          Expanded(
            child: _buildTodoList(),
          ),
        ],
      ),

      // フローティングアクションボタン（新規TODO追加）
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        tooltip: '新しいTODOを追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 統計情報パネル
  Widget _buildStatsPanel() {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                '全体',
                todoService.totalCount.toString(),
                Icons.list_alt,
                Colors.blue,
              ),
              _buildStatItem(
                '未完了',
                todoService.pendingCount.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatItem(
                '完了',
                todoService.completedCount.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                '進捗',
                '${(todoService.completionRate * 100).toInt()}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 統計情報の個別アイテム
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 検索バー
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'TODOを検索...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// フィルタータブ
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<TodoFilter>(
        segments: const [
          ButtonSegment(
            value: TodoFilter.all,
            label: Text('全て'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(
            value: TodoFilter.pending,
            label: Text('未完了'),
            icon: Icon(Icons.pending),
          ),
          ButtonSegment(
            value: TodoFilter.completed,
            label: Text('完了'),
            icon: Icon(Icons.check),
          ),
        ],
        selected: {_currentFilter},
        onSelectionChanged: (Set<TodoFilter> newSelection) {
          setState(() {
            _currentFilter = newSelection.first;
          });
        },
      ),
    );
  }

  /// TODOリスト
  Widget _buildTodoList() {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        // ローディング中
        if (todoService.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('TODOを読み込み中...'),
              ],
            ),
          );
        }

        // エラー表示
        if (todoService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  todoService.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => todoService.loadTodos(),
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }

        // TODOリストを取得（フィルター + 検索）
        List<Todo> todos = todoService.getFilteredTodos(_currentFilter);
        if (_searchQuery.isNotEmpty) {
          todos = todoService.searchTodos(_searchQuery);
          todos = todos.where((todo) {
            switch (_currentFilter) {
              case TodoFilter.all:
                return true;
              case TodoFilter.pending:
                return !todo.isCompleted;
              case TodoFilter.completed:
                return todo.isCompleted;
            }
          }).toList();
        }

        // 空の状態
        if (todos.isEmpty) {
          return _buildEmptyState();
        }

        // TODOリスト表示
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return TodoItemWidget(
              todo: todo,
              onToggle: () => todoService.toggleTodoCompletion(todo.id!),
              onDelete: () => _deleteTodo(todo),
              onEdit: () => _editTodo(todo),
            );
          },
        );
      },
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (_searchQuery.isNotEmpty) {
      message = '「$_searchQuery」に該当するTODOが見つかりません';
      icon = Icons.search_off;
    } else {
      switch (_currentFilter) {
        case TodoFilter.all:
          message = 'まだTODOがありません\n下のボタンから追加してみましょう';
          icon = Icons.note_add;
          break;
        case TodoFilter.pending:
          message = '未完了のTODOはありません\n素晴らしいです！';
          icon = Icons.check_circle;
          break;
        case TodoFilter.completed:
          message = '完了したTODOはありません';
          icon = Icons.pending_actions;
          break;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== イベントハンドラー ==========

  /// 新規TODO追加ダイアログを表示
  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTodoDialog(),
    );
  }

  /// TODO編集ダイアログを表示
  void _editTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(todo: todo),
    );
  }

  /// TODO削除確認
  void _deleteTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TODOを削除'),
        content: Text('「${todo.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TodoService>().deleteTodo(todo.id!);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 完了済みTODO一括削除確認
  void _deleteCompletedTodos() {
    final completedCount = context.read<TodoService>().completedCount;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完了済みTODOを削除'),
        content: Text('$completedCount件の完了済みTODOを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TodoService>().deleteCompletedTodos();
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 検索クリア
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  /// アプリ情報表示
  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TODO Manager'),
        content: const Text(
          'Flutter デスクトップアプリの学習用TODOアプリです。\n\n'
          '機能：\n'
          '• TODO作成・編集・削除\n'
          '• 完了状態管理\n'
          '• フィルタリング\n'
          '• 検索機能\n'
          '• ローカルデータベース',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
} 