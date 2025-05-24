import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// 洗練されたApple風確認モーダル
class RefinedConfirmationModal extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const RefinedConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'キャンセル',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  State<RefinedConfirmationModal> createState() => _RefinedConfirmationModalState();
}

class _RefinedConfirmationModalState extends State<RefinedConfirmationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // アニメーション設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _opacityAnimation = Tween<double>(
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
        return Stack(
          children: [
            // 背景のブラー効果
            GestureDetector(
              onTap: _closeModal,
              child: Container(
                color: Colors.black.withOpacity(0.4 * _opacityAnimation.value),
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
      width: 320,
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1C1E).withOpacity(0.98) 
            : Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.black.withOpacity(0.04),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 64,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // コンテンツ
            _buildContent(isDark),
            
            // ボタン
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // タイトル
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // メッセージ
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              decoration: TextDecoration.none,
              letterSpacing: 0.1,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    // キャンセルボタンを表示するかどうか
    final showCancelButton = widget.cancelText.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.06) 
                : Colors.black.withOpacity(0.04),
            width: 0.5,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: showCancelButton ? Row(
          children: [
            // キャンセルボタン
            Expanded(
              child: _buildActionButton(
                text: widget.cancelText,
                onPressed: _closeModal,
                isPrimary: false,
                isDestructive: false,
                isDark: isDark,
              ),
            ),
            
            // 区切り線
            Container(
              width: 0.5,
              color: isDark 
                  ? Colors.white.withOpacity(0.06) 
                  : Colors.black.withOpacity(0.04),
            ),
            
            // 確認ボタン
            Expanded(
              child: _buildActionButton(
                text: widget.confirmText,
                onPressed: _handleConfirm,
                isPrimary: true,
                isDestructive: widget.isDestructive,
                isDark: isDark,
              ),
            ),
          ],
        ) : _buildActionButton(
          text: widget.confirmText,
          onPressed: _handleConfirm,
          isPrimary: true,
          isDestructive: widget.isDestructive,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isDestructive,
    required bool isDark,
  }) {
    Color textColor;
    if (isDestructive) {
      textColor = const Color(0xFFFF3B30); // Apple Red
    } else if (isPrimary) {
      textColor = const Color(0xFF007AFF); // Apple Blue
    } else {
      textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: (isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF))
            .withOpacity(0.1),
        highlightColor: (isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF))
            .withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isPrimary ? FontWeight.w500 : FontWeight.w400,
                color: textColor,
                decoration: TextDecoration.none,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _closeModal() async {
    HapticFeedback.lightImpact();
    
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
      widget.onCancel?.call();
    }
  }

  Future<void> _handleConfirm() async {
    HapticFeedback.mediumImpact();
    
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
      widget.onConfirm();
    }
  }
}

/// 洗練された確認モーダルを表示するヘルパー関数
Future<void> showRefinedConfirmationModal(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String cancelText = 'キャンセル',
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return RefinedConfirmationModal(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      );
    },
  );
}

/// 洗練されたエラーモーダルを表示するヘルパー関数
Future<void> showRefinedErrorModal(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'OK',
  VoidCallback? onConfirm,
}) {
  return showRefinedConfirmationModal(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: '', // 空文字列でキャンセルボタンを非表示
    isDestructive: false,
    onConfirm: onConfirm ?? () {},
  );
} 