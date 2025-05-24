import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../services/design_mode_service.dart';

/// Material Design風TODO追加・編集モーダル
class MaterialTodoModal extends StatefulWidget {
  final Todo? todo; // 編集時のTODO（null の場合は新規作成）

  const MaterialTodoModal({super.key, this.todo});

  @override
  State<MaterialTodoModal> createState() => _MaterialTodoModalState();
}

class _MaterialTodoModalState extends State<MaterialTodoModal>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    
    // Material Design のアニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
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
    
    // フォーカス設定
    Future.delayed(const Duration(milliseconds: 150), () {
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
        return Material(
          color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildMaterialDialog(isDark),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialDialog(bool isDark) {
    return Container(
      width: 420,
      margin: const EdgeInsets.all(32),
      child: Material(
        elevation: MaterialElevations.modal,
        borderRadius: BorderRadius.circular(DesignShapes.materialModalRadius),
        color: isDark 
            ? DesignColors.materialSurfaceDark
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material Design ヘッダー
              _buildMaterialHeader(isDark),
              
              const SizedBox(height: 24),
              
              // Material Design フォーム
              _buildMaterialForm(isDark),
              
              const SizedBox(height: 32),
              
              // Material Design アクション
              _buildMaterialActions(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialHeader(bool isDark) {
    return Row(
      children: [
        // Material Design アイコン
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DesignColors.materialPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
          ),
          child: Icon(
            isEditing ? Icons.edit : Icons.add_task,
            color: DesignColors.materialPrimary,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Material Design タイトル
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'Create New Task',
                style: DesignTextStyles.materialHeadline(isDark),
              ),
              const SizedBox(height: 2),
              Text(
                isEditing ? 'Update your task details' : 'Add a new task to your list',
                style: DesignTextStyles.materialBody(isDark).copyWith(
                  color: DesignColors.materialGray,
                ),
              ),
            ],
          ),
        ),
        
        // 閉じるボタン
        IconButton(
          onPressed: _closeModal,
          icon: Icon(
            Icons.close,
            color: DesignColors.materialGray,
          ),
          style: IconButton.styleFrom(
            backgroundColor: DesignColors.materialGray.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialForm(bool isDark) {
    return Column(
      children: [
        // タイトル入力フィールド
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          style: DesignTextStyles.materialBody(isDark),
          decoration: _buildMaterialInputDecoration(
            'Task Title',
            'Enter your task title',
            Icons.task_alt,
            isDark,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            _descriptionFocusNode.requestFocus();
          },
        ),
        
        const SizedBox(height: 20),
        
        // 説明入力フィールド
        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          style: DesignTextStyles.materialBody(isDark),
          decoration: _buildMaterialInputDecoration(
            'Description (Optional)',
            'Add task details...',
            Icons.notes,
            isDark,
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            _saveTodo();
          },
        ),
      ],
    );
  }

  InputDecoration _buildMaterialInputDecoration(
    String label,
    String hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: DesignColors.materialGray,
        size: 20,
      ),
      labelStyle: DesignTextStyles.materialBody(isDark).copyWith(
        color: DesignColors.materialPrimary,
      ),
      hintStyle: DesignTextStyles.materialBody(isDark).copyWith(
        color: DesignColors.materialGray,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        borderSide: BorderSide(
          color: DesignColors.materialGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        borderSide: BorderSide(
          color: DesignColors.materialGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        borderSide: BorderSide(
          color: DesignColors.materialPrimary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        borderSide: BorderSide(
          color: DesignColors.materialRed,
          width: 1,
        ),
      ),
      filled: true,
      fillColor: isDark 
          ? Colors.white.withOpacity(0.05)
          : DesignColors.materialGray.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _buildMaterialActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // キャンセルボタン
        TextButton(
          onPressed: _closeModal,
          style: TextButton.styleFrom(
            foregroundColor: DesignColors.materialGray,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
            ),
          ),
          child: Text(
            'Cancel',
            style: DesignTextStyles.materialBody(isDark).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 保存ボタン
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTodo,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignColors.materialPrimary,
            foregroundColor: Colors.white,
            elevation: MaterialElevations.button,
            shadowColor: DesignColors.materialPrimary.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEditing ? Icons.update : Icons.add,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Update' : 'Create',
                      style: DesignTextStyles.materialBody(false).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _saveTodo() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: DesignColors.materialRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final todoService = context.read<TodoService>();
      final description = _descriptionController.text.trim();
      final finalDescription = description.isEmpty ? null : description;

      if (isEditing) {
        await todoService.updateTodo(
          widget.todo!.id!,
          title,
          description: finalDescription,
        );
      } else {
        await todoService.createTodo(title, description: finalDescription);
      }

      // 成功のハプティックフィードバック
      HapticFeedback.lightImpact();
      
      _closeModal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DesignColors.materialRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

/// Material Design風TODO編集モーダルを表示
void showMaterialTodoModal(BuildContext context, {Todo? todo}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Todo Modal',
    pageBuilder: (context, animation, secondaryAnimation) {
      return MaterialTodoModal(todo: todo);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
} 