import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/design_mode_service.dart';

/// デザインモード切り替えトグルスイッチ
class DesignModeToggle extends StatefulWidget {
  final bool showLabels;
  final bool isCompact;

  const DesignModeToggle({
    super.key,
    this.showLabels = true,
    this.isCompact = false,
  });

  @override
  State<DesignModeToggle> createState() => _DesignModeToggleState();
}

class _DesignModeToggleState extends State<DesignModeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // 初期状態を設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final designMode = context.read<DesignModeService>();
      if (designMode.isMaterialMode) {
        _animationController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        return widget.showLabels
            ? _buildFullToggle(designMode, isDark)
            : _buildCompactToggle(designMode, isDark);
      },
    );
  }

  Widget _buildFullToggle(DesignModeService designMode, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Appleアイコン
          _buildModeIcon(
            Icons.apple,
            designMode.isAppleMode,
            'Apple',
            isDark,
          ),
          
          const SizedBox(width: 12),
          
          // トグルスイッチ
          _buildToggleSwitch(designMode, isDark),
          
          const SizedBox(width: 12),
          
          // Materialアイコン
          _buildModeIcon(
            Icons.android,
            designMode.isMaterialMode,
            'Material',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle(DesignModeService designMode, bool isDark) {
    return GestureDetector(
      onTap: () => _toggleDesignMode(designMode),
      child: Container(
        width: 36,
        height: 36,
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
        child: Icon(
          designMode.isAppleMode ? Icons.apple : Icons.android,
          size: 16,
          color: designMode.isAppleMode 
              ? DesignColors.appleBlue
              : DesignColors.materialBlue,
        ),
      ),
    );
  }

  Widget _buildModeIcon(
    IconData icon,
    bool isActive,
    String label,
    bool isDark,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive
                ? (label == 'Apple' ? DesignColors.appleBlue : DesignColors.materialBlue)
                : (isDark ? Colors.grey[600] : Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.grey[600] : Colors.grey[500]),
              decoration: TextDecoration.none,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(DesignModeService designMode, bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _toggleDesignMode(designMode),
          child: Container(
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              color: designMode.isAppleMode
                  ? DesignColors.appleBlue.withOpacity(0.2)
                  : DesignColors.materialBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: designMode.isAppleMode
                    ? DesignColors.appleBlue.withOpacity(0.3)
                    : DesignColors.materialBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // トグルノブ
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  left: designMode.isAppleMode ? 2 : 26,
                  top: 2,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: designMode.isAppleMode
                            ? DesignColors.appleBlue
                            : DesignColors.materialBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        designMode.isAppleMode ? Icons.apple : Icons.android,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleDesignMode(DesignModeService designMode) async {
    // ハプティックフィードバック
    HapticFeedback.lightImpact();
    
    // アニメーション開始
    if (designMode.isAppleMode) {
      await _animationController.forward();
    } else {
      await _animationController.reverse();
    }
    
    // デザインモード切り替え
    await designMode.toggleDesignMode();
    
    // 完了フィードバック
    HapticFeedback.mediumImpact();
  }
}

/// デザインモード表示用のバッジ
class DesignModeBadge extends StatelessWidget {
  const DesignModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: designMode.isAppleMode
                ? DesignColors.appleBlue.withOpacity(0.1)
                : DesignColors.materialBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: designMode.isAppleMode
                  ? DesignColors.appleBlue.withOpacity(0.2)
                  : DesignColors.materialBlue.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                designMode.isAppleMode ? Icons.apple : Icons.android,
                size: 12,
                color: designMode.isAppleMode
                    ? DesignColors.appleBlue
                    : DesignColors.materialBlue,
              ),
              const SizedBox(width: 4),
              Text(
                designMode.isAppleMode ? 'Apple' : 'Material',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: designMode.isAppleMode
                      ? DesignColors.appleBlue
                      : DesignColors.materialBlue,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 