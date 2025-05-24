import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../models/todo.dart';
import '../widgets/macos_add_todo_sheet.dart';

/// macOS風TODOアプリのメイン画面
/// ネイティブなmacOS体験を提供します
class MacOSTodoScreen extends StatefulWidget {
  const MacOSTodoScreen({super.key});

  @override
  State<MacOSTodoScreen> createState() => _MacOSTodoScreenState();
}

class _MacOSTodoScreenState extends State<MacOSTodoScreen> {
  TodoFilter _currentFilter = TodoFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: _getFilterIndex(),
            onChanged: (index) {
              setState(() {
                _currentFilter = TodoFilter.values[index];
              });
            },
            items: const [
              SidebarItem(
                leading: MacosIcon(Icons.list),
                label: Text('全て'),
              ),
              SidebarItem(
                leading: MacosIcon(Icons.pending_actions),
                label: Text('未完了'),
              ),
              SidebarItem(
                leading: MacosIcon(Icons.check_circle),
                label: Text('完了済み'),
              ),
            ],
          );
        },
      ),
      child: ContentArea(
        builder: (context, scrollController) {
          return Column(
            children: [
              // macOS風ツールバー
              _buildToolBar(),
              
              // 統計情報
              _buildStatsSection(),
              
              // 検索バー
              _buildSearchSection(),
              
              // TODOリスト
              Expanded(
                child: _buildTodoList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// macOS風ツールバー
  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(
            color: MacosTheme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'TODO Manager',
            style: MacosTheme.of(context).typography.largeTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 完了済み削除ボタン
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              return MacosIconButton(
                icon: const MacosIcon(Icons.clear_all),
                onPressed: todoService.completedCount > 0 
                    ? _deleteCompletedTodos 
                    : null,
              );
            },
          ),
          const SizedBox(width: 8),
          // 新規追加ボタン
          MacosIconButton(
            icon: const MacosIcon(Icons.add),
            onPressed: _showAddTodoSheet,
          ),
        ],
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatsSection() {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MacosTheme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                '全体',
                todoService.totalCount.toString(),
                MacosColors.systemBlue,
              ),
              _buildStatItem(
                '未完了',
                todoService.pendingCount.toString(),
                MacosColors.systemOrange,
              ),
              _buildStatItem(
                '完了',
                todoService.completedCount.toString(),
                MacosColors.systemGreen,
              ),
              _buildStatItem(
                '進捗',
                '${(todoService.completionRate * 100).toInt()}%',
                MacosColors.systemPurple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: MacosTheme.of(context).typography.title2.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MacosTheme.of(context).typography.footnote.copyWith(
            color: MacosTheme.of(context).typography.footnote.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 検索セクション
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MacosSearchField(
        controller: _searchController,
        placeholder: 'TODOを検索...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// TODOリスト
  Widget _buildTodoList() {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        if (todoService.isLoading) {
          return const Center(
            child: ProgressCircle(),
          );
        }

        if (todoService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MacosIcon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  todoService.errorMessage!,
                  style: MacosTheme.of(context).typography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PushButton(
                  controlSize: ControlSize.large,
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
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return _buildTodoItem(todo, todoService);
          },
        );
      },
    );
  }

  /// macOS風TODOアイテム
  Widget _buildTodoItem(Todo todo, TodoService todoService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: MacosListTile(
        leading: MacosCheckbox(
          value: todo.isCompleted,
          onChanged: (_) => todoService.toggleTodoCompletion(todo.id!),
        ),
        title: Text(
          todo.title,
          style: MacosTheme.of(context).typography.body.copyWith(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.isCompleted 
                ? MacosTheme.of(context).typography.body.color?.withOpacity(0.6)
                : null,
          ),
        ),
        subtitle: todo.description != null && todo.description!.isNotEmpty
            ? Text(
                todo.description!,
                style: MacosTheme.of(context).typography.footnote.copyWith(
                  decoration: todo.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosIconButton(
              icon: const MacosIcon(Icons.edit_outlined),
              onPressed: () => _editTodo(todo),
            ),
            MacosIconButton(
              icon: const MacosIcon(Icons.delete_outline),
              onPressed: () => _deleteTodo(todo, todoService),
            ),
          ],
        ),
      ),
    );
  }

  /// 空の状態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(Icons.note_add, size: 64),
          const SizedBox(height: 16),
          Text(
            'TODOがありません\n右上の + ボタンから追加してみましょう',
            style: MacosTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== イベントハンドラー ==========

  int _getFilterIndex() {
    return _currentFilter.index;
  }

  void _showAddTodoSheet() {
    showMacosSheet(
      context: context,
      builder: (_) => const MacOSAddTodoSheet(),
    );
  }

  void _editTodo(Todo todo) {
    showMacosSheet(
      context: context,
      builder: (_) => MacOSAddTodoSheet(todo: todo),
    );
  }

  void _deleteTodo(Todo todo, TodoService todoService) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('TODOを削除'),
        message: Text('「${todo.title}」を削除しますか？'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () {
            Navigator.pop(context);
            todoService.deleteTodo(todo.id!);
          },
          child: const Text('削除'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _deleteCompletedTodos() {
    final completedCount = context.read<TodoService>().completedCount;
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('完了済みTODOを削除'),
        message: Text('$completedCount件の完了済みTODOを削除しますか？'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () {
            Navigator.pop(context);
            context.read<TodoService>().deleteCompletedTodos();
          },
          child: const Text('削除'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }
} 