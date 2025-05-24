import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import 'refined_confirmation_modal.dart';

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
      width: 380,
      margin: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1C1E).withOpacity(0.95) 
            : Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16), // より控えめな角丸
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 80,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            _buildRefinedHeader(isDark),
            
            // コンテンツ
            _buildRefinedContent(isDark),
            
            // フッター（ボタン）
            _buildRefinedFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRefinedHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.01)
            : Colors.black.withOpacity(0.005),
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.black.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEditing ? 'TODOを編集' : '新しいTODOを追加',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
                decoration: TextDecoration.none,
                letterSpacing: 0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _closeModal,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark 
                    ? Colors.white.withOpacity(0.8) 
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル入力
          Text(
            'タイトル',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              decoration: TextDecoration.none,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildRefinedTextField(
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              decoration: TextDecoration.none,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildRefinedTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            placeholder: '詳細な説明を入力',
            isDark: isDark,
            maxLines: 4,
            onSubmitted: (_) {
              _saveTodo();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required bool isDark,
    int maxLines = 1,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: maxLines > 1 ? Stack(
        children: [
          // テキストフィールド（プレースホルダーなし）
          CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            onSubmitted: onSubmitted,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.3,
              letterSpacing: 0.2,
            ),
            placeholder: null,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          // カスタムプレースホルダー
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return Positioned(
                  left: 16,
                  top: 16,
                  child: IgnorePointer(
                    child: Text(
                      placeholder,
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ) : CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black87,
          letterSpacing: 0.2,
        ),
        placeholder: placeholder,
        placeholderStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: const BoxDecoration(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildRefinedFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.005)
            : Colors.black.withOpacity(0.002),
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.03) 
                : Colors.black.withOpacity(0.02),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // キャンセルボタン
          Expanded(
            child: _buildRefinedButton(
              text: 'キャンセル',
              onPressed: _isLoading ? null : _closeModal,
              isPrimary: false,
              isDark: isDark,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 保存ボタン
          Expanded(
            child: _buildRefinedButton(
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

  Widget _buildRefinedButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required bool isDark,
    bool isLoading = false,
  }) {
    final Color backgroundColor = isPrimary
        ? const Color(0xFF007AFF)
        : (isDark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.03));
        
    final Color textColor = isPrimary
        ? Colors.white
        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8));

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: onPressed == null 
              ? backgroundColor.withOpacity(0.5) 
              : backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: !isPrimary ? Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.04),
            width: 0.5,
          ) : null,
          boxShadow: isPrimary ? [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onPressed == null 
                        ? textColor.withOpacity(0.5) 
                        : textColor,
                    decoration: TextDecoration.none,
                    letterSpacing: 0.2,
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
    showRefinedErrorModal(
      context,
      title: 'エラー',
      message: message,
      confirmText: 'OK',
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