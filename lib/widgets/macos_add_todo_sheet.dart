import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:macos_ui/macos_ui.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

/// macOS風TODO追加・編集シート
class MacOSAddTodoSheet extends StatefulWidget {
  final Todo? todo; // 編集時のTODO（null の場合は新規作成）

  const MacOSAddTodoSheet({super.key, this.todo});

  @override
  State<MacOSAddTodoSheet> createState() => _MacOSAddTodoSheetState();
}

class _MacOSAddTodoSheetState extends State<MacOSAddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
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
    return MacosSheet(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Text(
                isEditing ? 'TODOを編集' : '新しいTODOを追加',
                style: MacosTheme.of(context).typography.largeTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
              // タイトル入力
              Text(
                'タイトル',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8),
              MacosTextField(
                controller: _titleController,
                placeholder: 'TODOのタイトルを入力',
                autofocus: true,
              ),
              const SizedBox(height: 16),
              
              // 説明入力
              Text(
                '説明（オプション）',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8),
              MacosTextField(
                controller: _descriptionController,
                placeholder: '詳細な説明を入力',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  PushButton(
                    controlSize: ControlSize.large,
                    onPressed: _isLoading ? null : _saveTodo,
                    child: _isLoading
                        ? const ProgressCircle(radius: 8)
                        : Text(isEditing ? '更新' : '追加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTodo() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('タイトルを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final todoService = context.read<TodoService>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    if (isEditing) {
      success = await todoService.updateTodo(
        widget.todo!.id!,
        title,
        description: description.isEmpty ? null : description,
      );
    } else {
      success = await todoService.createTodo(
        title,
        description: description.isEmpty ? null : description,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      final errorMessage = todoService.errorMessage ?? 
          (isEditing ? 'TODOの更新に失敗しました' : 'TODOの追加に失敗しました');
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const FlutterLogo(size: 56),
        title: const Text('エラー'),
        message: Text(message),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ),
    );
  }
} 