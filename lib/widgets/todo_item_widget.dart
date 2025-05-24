import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

/// 個別TODOアイテムのウィジェット
/// これは「フロントエンドの再利用可能コンポーネント」です
/// リスト内の各TODOアイテムの表示を担当します
class TodoItemWidget extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;  // 完了状態切り替えコールバック
  final VoidCallback onDelete;  // 削除コールバック
  final VoidCallback onEdit;    // 編集コールバック

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: ListTile(
        // 完了状態チェックボックス
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        // TODOの内容
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.isCompleted 
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: todo.isCompleted ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        
        // 説明文（あれば表示）
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description!,
                style: TextStyle(
                  decoration: todo.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: todo.isCompleted 
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            // 作成日時・更新日時
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(todo.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (todo.updatedAt != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(todo.updatedAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        
        // アクションボタン
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 編集ボタン
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              tooltip: '編集',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            // 削除ボタン
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              iconSize: 20,
              tooltip: '削除',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        
        // タップで詳細表示（オプション）
        onTap: _showTodoDetail,
        
        // リストタイルの形状
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        
        // 完了済みの場合の背景色
        tileColor: todo.isCompleted 
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : null,
      ),
    );
  }

  /// 日時フォーマット
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // 今日の場合は時刻のみ
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // 昨日の場合
      return '昨日 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // 1週間以内の場合
      return '${difference.inDays}日前';
    } else {
      // それ以前の場合は日付
      return DateFormat('M/d').format(dateTime);
    }
  }

  /// TODO詳細表示（追加機能）
  void _showTodoDetail() {
    // 詳細表示ダイアログ（将来的に実装可能）
    // ここでは編集機能を呼び出し
    onEdit();
  }
} 