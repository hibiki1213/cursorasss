import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

/// TODO追加・編集ダイアログ
/// これは「フロントエンドのモーダルUI」です
/// 新規作成と編集の両方に対応します
class AddTodoDialog extends StatefulWidget {
  final Todo? todo; // 編集時のTODO（null の場合は新規作成）

  const AddTodoDialog({super.key, this.todo});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // 編集モードかどうか
  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合、既存値を設定
    if (isEditing) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'TODOを編集' : '新しいTODOを追加'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル入力フィールド
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル *',
                hintText: 'TODOのタイトルを入力',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 説明入力フィールド
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（オプション）',
                hintText: '詳細な説明を入力',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
      actions: [
        // キャンセルボタン
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        
        // 保存ボタン
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTodo,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '更新' : '追加'),
        ),
      ],
    );
  }

  /// TODOを保存
  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final todoService = context.read<TodoService>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    if (isEditing) {
      // 編集モード
      success = await todoService.updateTodo(
        widget.todo!.id!,
        title,
        description: description.isEmpty ? null : description,
      );
    } else {
      // 新規作成モード
      success = await todoService.createTodo(
        title,
        description: description.isEmpty ? null : description,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 成功時はダイアログを閉じる
      if (mounted) {
        Navigator.pop(context);
        
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'TODOを更新しました' : 'TODOを追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // エラー時はエラーメッセージを表示
      if (mounted) {
        final errorMessage = todoService.errorMessage ?? 
            (isEditing ? 'TODOの更新に失敗しました' : 'TODOの追加に失敗しました');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 