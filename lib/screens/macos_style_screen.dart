import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../models/todo.dart';
import '../widgets/ios_style_todo_modal.dart';

/// Material Designベースだが、macOS風スタイルのTODO画面
class MacOSStyleScreen extends StatefulWidget {
  const MacOSStyleScreen({super.key});

  @override
  State<MacOSStyleScreen> createState() => _MacOSStyleScreenState();
}

class _MacOSStyleScreenState extends State<MacOSStyleScreen> {
  TodoFilter _currentFilter = TodoFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // macOS風のカラーパレット
  static const Color macOSBlue = Color(0xFF007AFF);
  static const Color macOSGreen = Color(0xFF28CD41);
  static const Color macOSOrange = Color(0xFFFF9500);
  static const Color macOSPurple = Color(0xFF5856D6);
  static const Color macOSRed = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: Row(
        children: [
          // サイドバー
          _buildSidebar(isDark),
          
          // メインコンテンツ
          Expanded(
            child: Column(
              children: [
                // ツールバー
                _buildToolbar(isDark),
                
                // 統計情報
                _buildStatsSection(isDark),
                
                // 検索バー
                _buildSearchSection(isDark),
                
                // TODOリスト
                Expanded(
                  child: _buildTodoList(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// macOS風サイドバー
  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // サイドバーヘッダー
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TODO Manager',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          // フィルター項目
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(
                  Icons.list_rounded,
                  '全て',
                  TodoFilter.all,
                  isDark,
                ),
                _buildSidebarItem(
                  Icons.radio_button_unchecked,
                  '未完了',
                  TodoFilter.pending,
                  isDark,
                ),
                _buildSidebarItem(
                  Icons.check_circle_outline,
                  '完了済み',
                  TodoFilter.completed,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, TodoFilter filter, bool isDark) {
    final isSelected = _currentFilter == filter;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() {
              _currentFilter = filter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? macOSBlue.withOpacity(0.8) : macOSBlue)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected 
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected 
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// macOS風ツールバー
  Widget _buildToolbar(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'TODO リスト',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          
          // 完了済み削除ボタン
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              return IconButton(
                onPressed: todoService.completedCount > 0 
                    ? _deleteCompletedTodos 
                    : null,
                icon: const Icon(Icons.clear_all_rounded),
                tooltip: '完了済みTODOを削除',
              );
            },
          ),
          
          // 新規追加ボタン
          IconButton(
            onPressed: _showAddTodoDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'TODO を追加',
          ),
        ],
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatsSection(bool isDark) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('全体', todoService.totalCount.toString(), macOSBlue, isDark),
              _buildStatCard('未完了', todoService.pendingCount.toString(), macOSOrange, isDark),
              _buildStatCard('完了', todoService.completedCount.toString(), macOSGreen, isDark),
              _buildStatCard('進捗', '${(todoService.completionRate * 100).toInt()}%', macOSPurple, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 検索セクション
  Widget _buildSearchSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'TODO を検索...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// TODOリスト
  Widget _buildTodoList(bool isDark) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        if (todoService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (todoService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: macOSRed,
                ),
                const SizedBox(height: 16),
                Text(
                  todoService.errorMessage!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
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

        // TODOリストを取得
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

        if (todos.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return _buildTodoItem(todo, todoService, isDark);
          },
        );
      },
    );
  }

  /// TODOアイテム
  Widget _buildTodoItem(Todo todo, TodoService todoService, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => todoService.toggleTodoCompletion(todo.id!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.isCompleted 
                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: todo.description != null && todo.description!.isNotEmpty
            ? Text(
                todo.description!,
                style: TextStyle(
                  decoration: todo.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editTodo(todo),
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTodo(todo, todoService),
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_rounded,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'TODO がありません\n右上の + ボタンから追加してみましょう',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== イベントハンドラー ==========

  void _showAddTodoDialog() {
    showIOSStyleTodoModal(context);
  }

  void _editTodo(Todo todo) {
    showIOSStyleTodoModal(context, todo: todo);
  }

  void _deleteTodo(Todo todo, TodoService todoService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TODO を削除'),
        content: Text('「${todo.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              todoService.deleteTodo(todo.id!);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _deleteCompletedTodos() {
    final completedCount = context.read<TodoService>().completedCount;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完了済み TODO を削除'),
        content: Text('$completedCount件の完了済み TODO を削除しますか？'),
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
} 