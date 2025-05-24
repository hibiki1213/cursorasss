import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

/// iOS/macOS風TODO追加・編集モーダル
class IOSStyleTodoModal extends StatefulWidget {
  final Todo? todo; // 編集時のTODO（null の場合は新規作成）

  const IOSStyleTodoModal({super.key, this.todo});

  @override
  State<IOSStyleTodoModal> createState() => _IOSStyleTodoModalState();
}

class _IOSStyleTodoModalState extends State<IOSStyleTodoModal>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    
    // アニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // 編集モードの場合、既存値を設定
    if (isEditing) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
    }
    
    // アニメーション開始
    _animationController.forward();
    
    // 少し遅れてフォーカスを設定
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // 背景のブラー効果
            GestureDetector(
              onTap: _closeModal,
              child: Container(
                color: Colors.black.withOpacity(0.5 * _opacityAnimation.value),
                child: const SizedBox.expand(),
              ),
            ),
            
            // モーダル本体
            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: _buildModalContent(isDark),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalContent(bool isDark) {
    return Container(
      width: 400,
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20), // iOS風の角丸
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          _buildHeader(isDark),
          
          // コンテンツ
          _buildContent(isDark),
          
          // フッター（ボタン）
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          // タイトル
          Expanded(
            child: Text(
              isEditing ? 'TODOを編集' : '新しいTODOを追加',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          
          // 閉じるボタン
          GestureDetector(
            onTap: _closeModal,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[800] 
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル入力
          Text(
            'タイトル',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          _buildIOSTextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            placeholder: 'TODOのタイトルを入力',
            isDark: isDark,
            onSubmitted: (_) {
              _descriptionFocusNode.requestFocus();
            },
          ),
          
          const SizedBox(height: 20),
          
          // 説明入力
          Text(
            '説明（オプション）',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          _buildIOSTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            placeholder: '詳細な説明を入力',
            isDark: isDark,
            maxLines: 4,
            onSubmitted: (_) {
              _saveTodo();
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required bool isDark,
    int maxLines = 1,
    Function(String)? onSubmitted,
  }) {
    // 複数行の場合は独自のプレースホルダーを実装
    if (maxLines > 1) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // テキストフィールド（プレースホルダーなし）
            CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: maxLines,
              onSubmitted: onSubmitted,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.2, // プレースホルダーと同じline-heightを指定
              ),
              placeholder: null, // プレースホルダーを無効化
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            // カスタムプレースホルダー（ValueListenableBuilderで監視）
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                // テキストが空の場合のみ表示
                if (value.text.isEmpty) {
                  return Positioned(
                    left: 16,
                    top: 18, // テキストの実際の描画位置に合わせて微調整
                    child: IgnorePointer(
                      child: Text(
                        placeholder,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 16,
                          decoration: TextDecoration.none,
                          height: 1.2, // line-heightを明示的に指定
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }
    
    // 単一行の場合は従来通り
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        placeholder: placeholder,
        placeholderStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          fontSize: 16,
        ),
        decoration: const BoxDecoration(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          // キャンセルボタン
          Expanded(
            child: _buildIOSButton(
              text: 'キャンセル',
              onPressed: _isLoading ? null : _closeModal,
              isPrimary: false,
              isDark: isDark,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 保存ボタン
          Expanded(
            child: _buildIOSButton(
              text: isEditing ? '更新' : '追加',
              onPressed: _isLoading ? null : _saveTodo,
              isPrimary: true,
              isDark: isDark,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required bool isDark,
    bool isLoading = false,
  }) {
    final Color backgroundColor = isPrimary
        ? const Color(0xFF007AFF) // iOS Blue
        : (isDark ? Colors.grey[800]! : Colors.grey[200]!);
        
    final Color textColor = isPrimary
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: onPressed == null 
              ? backgroundColor.withOpacity(0.5) 
              : backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : const Color(0xFF007AFF),
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onPressed == null 
                        ? textColor.withOpacity(0.5) 
                        : textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _closeModal() async {
    if (_isLoading) return;
    
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('タイトルを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // ハプティックフィードバック
    HapticFeedback.lightImpact();

    final todoService = context.read<TodoService>();
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
      // 成功のハプティックフィードバック
      HapticFeedback.mediumImpact();
      await _closeModal();
    } else {
      // エラーのハプティックフィードバック
      HapticFeedback.heavyImpact();
      final errorMessage = todoService.errorMessage ?? 
          (isEditing ? 'TODOの更新に失敗しました' : 'TODOの追加に失敗しました');
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// iOS/macOS風モーダルを表示するヘルパー関数
Future<void> showIOSStyleTodoModal(BuildContext context, {Todo? todo}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false, // 背景タップで閉じないように
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return IOSStyleTodoModal(todo: todo);
    },
  );
} 