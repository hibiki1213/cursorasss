import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/todo_service.dart';
import '../services/design_mode_service.dart';
import '../models/todo.dart';
import '../widgets/ios_style_todo_modal.dart';
import '../widgets/refined_confirmation_modal.dart';
import '../widgets/material_todo_modal.dart';
import '../widgets/material_confirmation_modal.dart';
import '../widgets/design_mode_toggle.dart';

/// Material Designベースだが、macOS風スタイルのTODO画面
class MacOSStyleScreen extends StatefulWidget {
  const MacOSStyleScreen({super.key});

  @override
  State<MacOSStyleScreen> createState() => _MacOSStyleScreenState();
}

class _MacOSStyleScreenState extends State<MacOSStyleScreen> {
  TodoFilter _currentFilter = TodoFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // macOS風のカラーパレット
  static const Color macOSBlue = Color(0xFF007AFF);
  static const Color macOSGreen = Color(0xFF28CD41);
  static const Color macOSOrange = Color(0xFFFF9500);
  static const Color macOSPurple = Color(0xFF5856D6);
  static const Color macOSRed = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoService>().initialize();
      context.read<DesignModeService>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        return Scaffold(
          body: Container(
            // グラデーション背景
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: designMode.isMaterialMode
                    ? (isDark
                        ? [
                            DesignColors.materialSurfaceDark,
                            const Color(0xFF1A1A1A),
                            const Color(0xFF0D0D0D),
                          ]
                        : [
                            DesignColors.materialSurface,
                            const Color(0xFFF5F5F5),
                            const Color(0xFFFFFFFF),
                          ])
                    : (isDark
                        ? [
                            const Color(0xFF0A0A0A),
                            const Color(0xFF1A1A1A),
                            const Color(0xFF2A2A2A),
                          ]
                        : [
                            const Color(0xFFF0F4F8),
                            const Color(0xFFE8F2FF),
                            const Color(0xFFF8FAFC),
                          ]),
              ),
            ),
            child: Stack(
              children: [
                // メインコンテンツ
                Padding(
                  padding: const EdgeInsets.only(left: 240), // サイドバー分の余白
                  child: Column(
                    children: [
                      // ツールバー
                      _buildModernToolbar(isDark),
                      
                      // スクロール可能なコンテンツ
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // 統計情報
                              _buildModernStatsSection(isDark),
                              
                              // 検索バー
                              _buildModernSearchSection(isDark),
                              
                              // TODOリスト
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 400,
                                  maxHeight: 600,
                                ),
                                child: _buildModernTodoList(isDark),
                              ),
                              
                              // 下部の余白
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // アイランド風フローティングサイドバー
                _buildFloatingSidebar(isDark),
              ],
            ),
          ),
          
          // Material Design FAB
          floatingActionButton: designMode.isMaterialMode 
              ? _buildMaterialFAB(isDark)
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
  
  /// Material Design FAB
  Widget _buildMaterialFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _showAddTodoDialog,
      backgroundColor: DesignColors.materialPrimary,
      foregroundColor: Colors.white,
      elevation: MaterialElevations.fab,
      icon: const Icon(Icons.add),
      label: Text(
        'Add Task',
        style: DesignTextStyles.materialBody(false).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
      ),
    );
  }

  /// 洗練されたフローティングサイドバー
  Widget _buildFloatingSidebar(bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        if (designMode.isMaterialMode) {
          return _buildMaterialSidebar(isDark);
        }
        
        return Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              // より控えめなアクリル効果
              color: isDark 
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.03),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // ヘッダー
                  _buildRefinedSidebarHeader(isDark),
                  
                  // フィルター項目
                  Expanded(
                    child: _buildRefinedSidebarItems(isDark),
                  ),
                  
                  // フッター
                  _buildRefinedSidebarFooter(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Material Design サイドバー
  Widget _buildMaterialSidebar(bool isDark) {
    return Positioned(
      left: 16,
      top: 16,
      bottom: 16,
      child: Material(
        elevation: MaterialElevations.drawer,
        borderRadius: BorderRadius.circular(DesignShapes.materialCardRadius),
        color: isDark 
            ? DesignColors.materialSurfaceDark
            : Colors.white,
        child: Container(
          width: 240,
          child: Column(
            children: [
              // Material Design ヘッダー
              _buildMaterialSidebarHeader(isDark),
              
              // フィルター項目
              Expanded(
                child: _buildMaterialSidebarItems(isDark),
              ),
              
              // フッター
              _buildMaterialSidebarFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Material Design サイドバーヘッダー
  Widget _buildMaterialSidebarHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Material Design アイコン
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignColors.materialPrimary,
                      DesignColors.materialSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
                  boxShadow: MaterialElevations.getShadow(MaterialElevations.button, isDark: isDark),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const Spacer(),
              
              // デザインモードバッジ
              const DesignModeBadge(),
            ],
          ),
          const SizedBox(height: 16),
          // Material Design タイトル
          Text(
            'Tasks',
            style: DesignTextStyles.materialHeadline(isDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Your productive workspace',
            style: DesignTextStyles.materialBody(isDark).copyWith(
              color: DesignColors.materialGray,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Material Design サイドバー項目
  Widget _buildMaterialSidebarItems(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMaterialSidebarItem(
            Icons.view_list,
            'All Tasks',
            TodoFilter.all,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildMaterialSidebarItem(
            Icons.radio_button_unchecked,
            'Active',
            TodoFilter.pending,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildMaterialSidebarItem(
            Icons.check_circle,
            'Completed',
            TodoFilter.completed,
            isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialSidebarItem(IconData icon, String label, TodoFilter filter, bool isDark) {
    final isSelected = _currentFilter == filter;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? DesignColors.materialPrimary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? DesignColors.materialPrimary
                    : DesignColors.materialGray,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: DesignTextStyles.materialBody(isDark).copyWith(
                    color: isSelected 
                        ? DesignColors.materialPrimary
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Material Design サイドバーフッター
  Widget _buildMaterialSidebarFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // デザインモード切り替えトグル
          const DesignModeToggle(showLabels: false, isCompact: true),
          
          const SizedBox(height: 16),
          
          // 統計情報
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              return Material(
                elevation: MaterialElevations.card,
                borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
                color: isDark 
                    ? Colors.white.withOpacity(0.05)
                    : DesignColors.materialPrimary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Tasks',
                        style: DesignTextStyles.materialCaption(isDark).copyWith(
                          color: DesignColors.materialPrimary,
                        ),
                      ),
                      Text(
                        '${todoService.totalCount}',
                        style: DesignTextStyles.materialSubtitle(isDark).copyWith(
                          color: DesignColors.materialPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// macOS風サイドバー（旧バージョン）
  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // サイドバーヘッダー
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TODO Manager',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          // フィルター項目
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(
                  Icons.list_rounded,
                  '全て',
                  TodoFilter.all,
                  isDark,
                ),
                _buildSidebarItem(
                  Icons.radio_button_unchecked,
                  '未完了',
                  TodoFilter.pending,
                  isDark,
                ),
                _buildSidebarItem(
                  Icons.check_circle_outline,
                  '完了済み',
                  TodoFilter.completed,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 洗練されたサイドバーヘッダー
  Widget _buildRefinedSidebarHeader(bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // アプリアイコン（デザインモードに応じて変更）
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: designMode.isAppleMode 
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(
                        designMode.isAppleMode ? 8 : 12
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (designMode.isAppleMode 
                              ? const Color(0xFF007AFF) 
                              : const Color(0xFF1976D2)).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      designMode.isAppleMode ? Icons.check : Icons.task_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // デザインモードバッジ
                  const DesignModeBadge(),
                ],
              ),
              const SizedBox(height: 12),
              // タイトル（デザインモードに応じてスタイル変更）
              Text(
                'Todo',
                style: designMode.isAppleMode 
                    ? DesignTextStyles.appleTitle(isDark)
                    : DesignTextStyles.materialTitle(isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  /// モダンなサイドバーヘッダー（旧）
  Widget _buildSidebarHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アプリロゴ・アイコン
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          // アプリタイトル
          Text(
            'TODO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            'Manager',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  /// 洗練されたサイドバー項目
  Widget _buildRefinedSidebarItems(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRefinedSidebarItem(
            Icons.circle_outlined,
            '全て',
            TodoFilter.all,
            isDark,
          ),
          const SizedBox(height: 4),
          _buildRefinedSidebarItem(
            Icons.radio_button_unchecked,
            '未完了',
            TodoFilter.pending,
            isDark,
          ),
          const SizedBox(height: 4),
          _buildRefinedSidebarItem(
            Icons.check_circle,
            '完了済み',
            TodoFilter.completed,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedSidebarItem(IconData icon, String label, TodoFilter filter, bool isDark) {
    final isSelected = _currentFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF007AFF).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected 
                  ? const Color(0xFF007AFF)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected 
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  decoration: TextDecoration.none,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 洗練されたサイドバーフッター
  Widget _buildRefinedSidebarFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // デザインモード切り替えトグル
          const DesignModeToggle(showLabels: false, isCompact: true),
          
          const SizedBox(height: 12),
          
          // 統計情報
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '合計',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        decoration: TextDecoration.none,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '${todoService.totalCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, TodoFilter filter, bool isDark) {
    final isSelected = _currentFilter == filter;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() {
              _currentFilter = filter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? macOSBlue.withOpacity(0.8) : macOSBlue)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected 
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected 
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSidebarItem(IconData icon, String label, TodoFilter filter, bool isDark) {
    final isSelected = _currentFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? macOSBlue
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 洗練されたMac風ツールバー
  Widget _buildModernToolbar(bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        if (designMode.isMaterialMode) {
          return _buildMaterialToolbar(isDark);
        }
        
        return Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withOpacity(0.03)
                : Colors.white.withOpacity(0.03),
            border: Border(
              bottom: BorderSide(
                color: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.02),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // 洗練されたタイトルセクション
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'やるべきこと淡々とやって、積み上げていくだけ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        decoration: TextDecoration.none,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 洗練されたアクションボタン
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 完了済み削除ボタン
                  Consumer<TodoService>(
                    builder: (context, todoService, child) {
                      return _buildRefinedIconButton(
                        Icons.clear_all_rounded,
                        '完了済み削除',
                        onPressed: todoService.completedCount > 0 ? _deleteCompletedTodos : null,
                        isDark: isDark,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  
                  // 新規追加ボタン
                  _buildRefinedPrimaryButton(
                    Icons.add_rounded,
                    '新規追加',
                    onPressed: _showAddTodoDialog,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Material Design ツールバー
  Widget _buildMaterialToolbar(bool isDark) {
    return Material(
      elevation: MaterialElevations.card,
      color: isDark 
          ? DesignColors.materialSurfaceDark
          : DesignColors.materialSurface,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            // Material Design headline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear completed button
                Consumer<TodoService>(
                  builder: (context, todoService, child) {
                    return _buildMaterialButton(
                      Icons.clear_all_rounded,
                      'Clear Done',
                      DesignColors.materialGray,
                      onPressed: todoService.completedCount > 0 
                          ? _deleteCompletedTodos 
                          : null,
                      isDark: isDark,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Material Design button
  Widget _buildMaterialButton(
    IconData icon,
    String text,
    Color color,
    {
      required VoidCallback? onPressed,
      required bool isDark,
    }
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        onTap: onPressed,
        child: Container(
          height: DesignShapes.materialMiniButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(onPressed != null ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
            border: Border.all(
              color: color.withOpacity(onPressed != null ? 0.3 : 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed != null 
                    ? color 
                    : color.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: DesignTextStyles.materialBody(isDark).copyWith(
                  color: onPressed != null 
                      ? color 
                      : color.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// macOS風ツールバー
  Widget _buildToolbar(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'TODO リスト',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          
          // 完了済み削除ボタン
          Consumer<TodoService>(
            builder: (context, todoService, child) {
              return IconButton(
                onPressed: todoService.completedCount > 0 
                    ? _deleteCompletedTodos 
                    : null,
                icon: const Icon(Icons.clear_all_rounded),
                tooltip: '完了済みTODOを削除',
              );
            },
          ),
          
          // 新規追加ボタン
          IconButton(
            onPressed: _showAddTodoDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'TODO を追加',
          ),
        ],
      ),
    );
  }

  /// モダンなアイコンボタン
  Widget _buildModernIconButton(IconData icon, String tooltip, {
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }

  /// 洗練されたアイコンボタン
  Widget _buildRefinedIconButton(IconData icon, String tooltip, {
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? (isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6))
                  : (isDark ? Colors.grey[700] : Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }

  /// 洗練されたプライマリボタン
  Widget _buildRefinedPrimaryButton(IconData icon, String text, {
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// モダンなプライマリボタン（旧）
  Widget _buildModernPrimaryButton(IconData icon, String text, {
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 洗練された統計セクション
  Widget _buildModernStatsSection(bool isDark) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Flexible(
                  child: _buildRefinedStatCard(
                    '合計',
                    todoService.totalCount,
                    Icons.circle_outlined,
                    const Color(0xFF8E8E93),
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _buildRefinedStatCard(
                    '未完了',
                    todoService.pendingCount,
                    Icons.radio_button_unchecked,
                    const Color(0xFFFF9500),
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _buildRefinedStatCard(
                    '完了済み',
                    todoService.completedCount,
                    Icons.check_circle,
                    const Color(0xFF34C759),
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _buildRefinedStatCard(
                    '進捗',
                    (todoService.completionRate * 100).toInt(),
                    Icons.trending_up,
                    const Color(0xFF007AFF),
                    isDark,
                    isPercentage: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 洗練されたMac風統計カード
  Widget _buildRefinedStatCard(String title, int count, IconData icon, Color accentColor, bool isDark, {bool isPercentage = false}) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        final borderRadius = designMode.isAppleMode 
            ? DesignShapes.appleCardRadius 
            : DesignShapes.materialCardRadius;
            
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                blurRadius: designMode.isAppleMode ? 8 : 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: designMode.isAppleMode ? 14 : 16,
                    color: accentColor.withOpacity(0.8),
                  ),
                  const Spacer(),
                  Text(
                    isPercentage ? '$count%' : '$count',
                    style: TextStyle(
                      fontSize: designMode.isAppleMode ? 20 : 24,
                      fontWeight: designMode.isAppleMode ? FontWeight.w600 : FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: designMode.isAppleMode 
                    ? DesignTextStyles.appleCaption(isDark)
                    : DesignTextStyles.materialCaption(isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  /// モダンな統計カード（旧）
  Widget _buildModernStatCard(String title, int count, IconData icon, List<Color> gradientColors, bool isDark, {bool isPercentage = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                isPercentage ? '$count%' : '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計情報セクション（旧）
  Widget _buildStatsSection(bool isDark) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('全体', todoService.totalCount.toString(), macOSBlue, isDark),
              _buildStatCard('未完了', todoService.pendingCount.toString(), macOSOrange, isDark),
              _buildStatCard('完了', todoService.completedCount.toString(), macOSGreen, isDark),
              _buildStatCard('進捗', '${(todoService.completionRate * 100).toInt()}%', macOSPurple, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 洗練された検索セクション
  Widget _buildModernSearchSection(bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        if (designMode.isMaterialMode) {
          return _buildMaterialSearchSection(isDark);
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.02)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.05 : 0.01),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: '検索...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  size: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        );
      },
    );
  }
  
  /// Material Design 検索セクション
  Widget _buildMaterialSearchSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Material(
        elevation: MaterialElevations.card,
        borderRadius: BorderRadius.circular(DesignShapes.materialBorderRadius),
        color: isDark 
            ? DesignColors.materialSurfaceDark
            : Colors.white,
        child: TextField(
          controller: _searchController,
          style: DesignTextStyles.materialBody(isDark),
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle: DesignTextStyles.materialBody(isDark).copyWith(
              color: DesignColors.materialGray,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: DesignColors.materialGray,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: DesignColors.materialGray,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
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
            filled: true,
            fillColor: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  /// 検索セクション（旧）
  Widget _buildSearchSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'TODO を検索...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// モダンなTODOリスト
  Widget _buildModernTodoList(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Consumer<TodoService>(
          builder: (context, todoService, child) {
            if (todoService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (todoService.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: isDark ? Colors.red[400] : Colors.red[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'エラーが発生しました',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      todoService.errorMessage!,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredTodos = _getFilteredTodos(todoService.todos);

            if (filteredTodos.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: filteredTodos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildModernTodoItem(filteredTodos[index], isDark);
              },
            );
          },
        ),
      ),
    );
  }

  /// 洗練されたApple風TODO項目
  Widget _buildModernTodoItem(Todo todo, bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        if (designMode.isMaterialMode) {
          return _buildMaterialTodoItem(todo, isDark);
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 1), // 微細な区切り
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.02)
                  : Colors.black.withOpacity(0.02),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.05 : 0.01),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showEditTodoDialog(todo),
              splashColor: const Color(0xFF007AFF).withOpacity(0.1),
              highlightColor: const Color(0xFF007AFF).withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 洗練されたチェックボックス
                    _buildRefinedCheckbox(todo, isDark),
                    
                    const SizedBox(width: 12),
                    
                    // メインコンテンツ
                    Expanded(
                      child: _buildTodoContent(todo, isDark),
                    ),
                    
                    // アクションボタン（ホバー時のみ表示）
                    _buildTodoActions(todo, isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Google Material Design風TODO項目
  Widget _buildMaterialTodoItem(Todo todo, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: MaterialElevations.card,
        borderRadius: BorderRadius.circular(DesignShapes.materialCardRadius),
        color: isDark 
            ? DesignColors.materialSurfaceDark
            : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignShapes.materialCardRadius),
          onTap: () => _showEditTodoDialog(todo),
          splashColor: DesignColors.materialPrimary.withOpacity(0.12),
          highlightColor: DesignColors.materialPrimary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Material Design Checkbox
                    _buildMaterialCheckbox(todo, isDark),
                    
                    const SizedBox(width: 16),
                    
                    // メインコンテンツ
                    Expanded(
                      child: _buildMaterialTodoContent(todo, isDark),
                    ),
                    
                    // Priority indicator
                    _buildPriorityIndicator(todo),
                  ],
                ),
                
                // Actions row
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMaterialAction(
                      Icons.edit,
                      'Edit',
                      DesignColors.materialBlue,
                      () => _showEditTodoDialog(todo),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildMaterialAction(
                      Icons.delete,
                      'Delete',
                      DesignColors.materialRed,
                      () => _deleteTodo(todo),
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 洗練されたチェックボックス
  Widget _buildRefinedCheckbox(Todo todo, bool isDark) {
    return GestureDetector(
      onTap: () => _toggleTodoCompletion(todo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: todo.isCompleted 
              ? const Color(0xFF34C759)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10), // 完全な円
          border: Border.all(
            color: todo.isCompleted 
                ? const Color(0xFF34C759)
                : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
            width: 1.5,
          ),
          boxShadow: todo.isCompleted ? [
            BoxShadow(
              color: const Color(0xFF34C759).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
        child: todo.isCompleted
            ? const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  /// TODO コンテンツ
  Widget _buildTodoContent(Todo todo, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル
        Text(
          todo.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: todo.isCompleted
                ? (isDark ? Colors.grey[600] : Colors.grey[500])
                : (isDark ? Colors.white : Colors.black87),
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            decorationColor: isDark ? Colors.grey[600] : Colors.grey[500],
            letterSpacing: 0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // 説明（もしあれば）
        if (todo.description != null && todo.description!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            todo.description!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: todo.isCompleted
                  ? (isDark ? Colors.grey[700] : Colors.grey[400])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
              decoration: todo.isCompleted 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
              decorationColor: isDark ? Colors.grey[700] : Colors.grey[400],
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  /// Material Design チェックボックス
  Widget _buildMaterialCheckbox(Todo todo, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: () => _toggleTodoCompletion(todo),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: todo.isCompleted 
                ? DesignColors.materialGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: todo.isCompleted 
                  ? DesignColors.materialGreen
                  : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
              width: 2,
            ),
          ),
          child: todo.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
  
  /// Material Design TODO コンテンツ
  Widget _buildMaterialTodoContent(Todo todo, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル - Material Design typography
        Text(
          todo.title,
          style: DesignTextStyles.materialSubtitle(isDark).copyWith(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.isCompleted
                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                : (isDark ? Colors.white : Colors.black87),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // 説明
        if (todo.description != null && todo.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            todo.description!,
            style: DesignTextStyles.materialBody(isDark).copyWith(
              decoration: todo.isCompleted 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
              color: todo.isCompleted
                  ? (isDark ? Colors.grey[600] : Colors.grey[500])
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  /// Priority indicator for Material Design
  Widget _buildPriorityIndicator(Todo todo) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: todo.isCompleted 
            ? DesignColors.materialGreen 
            : DesignColors.materialOrange,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  /// Material Design action button
  Widget _buildMaterialAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: DesignTextStyles.materialCaption(isDark).copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO アクション
  Widget _buildTodoActions(Todo todo, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 編集ボタン
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEditTodoDialog(todo),
              borderRadius: BorderRadius.circular(6),
              child: Icon(
                Icons.edit,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 削除ボタン
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _deleteTodo(todo),
              borderRadius: BorderRadius.circular(6),
              child: Icon(
                Icons.delete_outline,
                size: 14,
                color: isDark ? Colors.red[400] : Colors.red[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// TODOリスト（旧）
  Widget _buildTodoList(bool isDark) {
    return Consumer<TodoService>(
      builder: (context, todoService, child) {
        if (todoService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (todoService.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: macOSRed,
                ),
                const SizedBox(height: 16),
                Text(
                  todoService.errorMessage!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
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
          return _buildEmptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return _buildTodoItem(todo, todoService, isDark);
          },
        );
      },
    );
  }

  /// TODOアイテム
  Widget _buildTodoItem(Todo todo, TodoService todoService, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => todoService.toggleTodoCompletion(todo.id!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : TextDecoration.none,
            color: todo.isCompleted 
                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: todo.description != null && todo.description!.isNotEmpty
            ? Text(
                todo.description!,
                style: TextStyle(
                  decoration: todo.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editTodo(todo),
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTodo(todo),
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState(bool isDark) {
    return Consumer<DesignModeService>(
      builder: (context, designMode, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: designMode.isMaterialMode 
                      ? DesignColors.materialPrimary.withOpacity(0.1)
                      : const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    designMode.isMaterialMode 
                        ? DesignShapes.materialCardRadius
                        : DesignShapes.appleCardRadius
                  ),
                ),
                child: Icon(
                  _currentFilter == TodoFilter.completed 
                      ? (designMode.isMaterialMode ? Icons.task_alt : Icons.check_circle)
                      : (designMode.isMaterialMode ? Icons.add_task : Icons.add_circle),
                  size: 40,
                  color: designMode.isMaterialMode 
                      ? DesignColors.materialPrimary
                      : const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getEmptyMessage(),
                style: designMode.isMaterialMode 
                    ? DesignTextStyles.materialTitle(isDark)
                    : DesignTextStyles.appleTitle(isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                designMode.isMaterialMode 
                    ? 'Tap the + button to create your first task'
                    : '右上の + ボタンから追加してみましょう',
                style: designMode.isMaterialMode 
                    ? DesignTextStyles.materialBody(isDark)
                    : DesignTextStyles.appleBody(isDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== ヘルパーメソッド ==========

  /// フィルタリングされたTODOを取得
  List<Todo> _getFilteredTodos(List<Todo> todos) {
    List<Todo> filteredTodos = todos;
    
    // フィルター適用
    switch (_currentFilter) {
      case TodoFilter.all:
        break;
      case TodoFilter.pending:
        filteredTodos = todos.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.completed:
        filteredTodos = todos.where((todo) => todo.isCompleted).toList();
        break;
    }
    
    // 検索クエリ適用
    if (_searchQuery.isNotEmpty) {
      filteredTodos = filteredTodos.where((todo) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (todo.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    return filteredTodos;
  }

  /// 空の状態のメッセージを取得
  String _getEmptyMessage() {
    if (_searchQuery.isNotEmpty) {
      return '検索結果が見つかりません';
    }
    
    switch (_currentFilter) {
      case TodoFilter.all:
        return 'TODOがありません\n新しいTODOを追加してみましょう';
      case TodoFilter.pending:
        return '未完了のTODOがありません\n素晴らしいです！';
      case TodoFilter.completed:
        return '完了済みのTODOがありません';
    }
  }

  /// TODOの完了状態を切り替え
  void _toggleTodoCompletion(Todo todo) {
    context.read<TodoService>().toggleTodoCompletion(todo.id!);
  }

  /// TODO編集ダイアログを表示
  void _showEditTodoDialog(Todo todo) {
    final designMode = context.read<DesignModeService>();
    if (designMode.isMaterialMode) {
      showMaterialTodoModal(context, todo: todo);
    } else {
      showIOSStyleTodoModal(context, todo: todo);
    }
  }

  /// TODO削除（単一引数版）
  void _deleteTodo(Todo todo) {
    final designMode = context.read<DesignModeService>();
    
    if (designMode.isMaterialMode) {
      showMaterialConfirmationModal(
        context,
        title: 'Delete Task',
        message: 'Are you sure you want to delete "${todo.title}"?\nThis action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          context.read<TodoService>().deleteTodo(todo.id!);
        },
      );
    } else {
      showRefinedConfirmationModal(
        context,
        title: 'TODOを削除',
        message: '「${todo.title}」を削除しますか？\nこの操作は取り消せません。',
        confirmText: '削除',
        cancelText: 'キャンセル',
        isDestructive: true,
        onConfirm: () {
          context.read<TodoService>().deleteTodo(todo.id!);
        },
      );
    }
  }

  // ========== イベントハンドラー ==========

  void _showAddTodoDialog() {
    final designMode = context.read<DesignModeService>();
    if (designMode.isMaterialMode) {
      showMaterialTodoModal(context);
    } else {
      showIOSStyleTodoModal(context);
    }
  }

  void _editTodo(Todo todo) {
    final designMode = context.read<DesignModeService>();
    if (designMode.isMaterialMode) {
      showMaterialTodoModal(context, todo: todo);
    } else {
      showIOSStyleTodoModal(context, todo: todo);
    }
  }

  void _deleteCompletedTodos() {
    final completedCount = context.read<TodoService>().completedCount;
    final designMode = context.read<DesignModeService>();
    
    if (designMode.isMaterialMode) {
      showMaterialConfirmationModal(
        context,
        title: 'Clear Completed Tasks',
        message: 'Delete $completedCount completed tasks?\nThis action cannot be undone.',
        confirmText: 'Delete All',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () {
          context.read<TodoService>().deleteCompletedTodos();
        },
      );
    } else {
      showRefinedConfirmationModal(
        context,
        title: '完了済みTODOを削除',
        message: '$completedCount件の完了済みTODOを削除しますか？\nこの操作は取り消せません。',
        confirmText: '削除',
        cancelText: 'キャンセル',
        isDestructive: true,
        onConfirm: () {
          context.read<TodoService>().deleteCompletedTodos();
        },
      );
    }
  }
} 