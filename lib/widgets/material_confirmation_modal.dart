import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/design_mode_service.dart';

/// Material Design風確認モーダル
class MaterialConfirmationModal extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const MaterialConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  State<MaterialConfirmationModal> createState() => _MaterialConfirmationModalState();
}

class _MaterialConfirmationModalState extends State<MaterialConfirmationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Material Design のアニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // アニメーション開始
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
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
      width: 380,
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
            children: [
              // Material Design ヘッダー
              _buildMaterialHeader(isDark),
              
              const SizedBox(height: 20),
              
              // Material Design コンテンツ
              _buildMaterialContent(isDark),
              
              const SizedBox(height: 24),
              
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.isDestructive 
                ? DesignColors.materialRed.withOpacity(0.12)
                : DesignColors.materialOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
          ),
          child: Icon(
            widget.isDestructive ? Icons.delete_forever : Icons.help_outline,
            color: widget.isDestructive 
                ? DesignColors.materialRed
                : DesignColors.materialOrange,
            size: 24,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Material Design タイトル
        Expanded(
          child: Text(
            widget.title,
            style: DesignTextStyles.materialHeadline(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialContent(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.message,
        style: DesignTextStyles.materialBody(isDark).copyWith(
          color: DesignColors.materialGray,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMaterialActions(bool isDark) {
    // キャンセルボタンを表示するかどうか
    final showCancelButton = widget.cancelText.isNotEmpty;
    
    if (showCancelButton) {
      // 2つのボタン
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
              widget.cancelText,
              style: DesignTextStyles.materialBody(isDark).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 確認ボタン
          ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isDestructive 
                  ? DesignColors.materialRed
                  : DesignColors.materialPrimary,
              foregroundColor: Colors.white,
              elevation: MaterialElevations.button,
              shadowColor: (widget.isDestructive 
                  ? DesignColors.materialRed
                  : DesignColors.materialPrimary).withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isDestructive ? Icons.delete : Icons.check,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.confirmText,
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
    } else {
      // 単一のボタン
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: _confirm,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.confirmText,
                style: DesignTextStyles.materialBody(false).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _closeModal() {
    HapticFeedback.lightImpact();
    
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCancel?.call();
      }
    });
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirm();
      }
    });
  }
}

/// Material Design風確認モーダルを表示
void showMaterialConfirmationModal(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String cancelText = 'Cancel',
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Confirmation',
    pageBuilder: (context, animation, secondaryAnimation) {
      return MaterialConfirmationModal(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

/// Material Design風エラーモーダルを表示
void showMaterialErrorModal(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'OK',
  VoidCallback? onConfirm,
}) {
  showMaterialConfirmationModal(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: '', // キャンセルボタンを非表示
    onConfirm: onConfirm ?? () {},
    isDestructive: true,
  );
} 