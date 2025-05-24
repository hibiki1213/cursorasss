import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// デザインモード
enum DesignMode {
  apple,    // Apple Human Interface Guidelines
  material, // Google Material Design
}

/// デザインモード管理サービス
class DesignModeService extends ChangeNotifier {
  static const String _designModeKey = 'design_mode';
  
  DesignMode _currentMode = DesignMode.apple;
  
  DesignMode get currentMode => _currentMode;
  
  bool get isAppleMode => _currentMode == DesignMode.apple;
  bool get isMaterialMode => _currentMode == DesignMode.material;
  
  /// 初期化
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_designModeKey);
      
      if (savedMode != null) {
        _currentMode = DesignMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => DesignMode.apple,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('デザインモード初期化エラー: $e');
    }
  }
  
  /// デザインモードを切り替え
  Future<void> toggleDesignMode() async {
    try {
      _currentMode = _currentMode == DesignMode.apple 
          ? DesignMode.material 
          : DesignMode.apple;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_designModeKey, _currentMode.toString());
      
      notifyListeners();
      
      debugPrint('🎨 デザインモード切り替え: ${_currentMode.name}');
    } catch (e) {
      debugPrint('デザインモード切り替えエラー: $e');
    }
  }
  
  /// 特定のデザインモードに設定
  Future<void> setDesignMode(DesignMode mode) async {
    if (_currentMode == mode) return;
    
    try {
      _currentMode = mode;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_designModeKey, _currentMode.toString());
      
      notifyListeners();
      
      debugPrint('🎨 デザインモード設定: ${_currentMode.name}');
    } catch (e) {
      debugPrint('デザインモード設定エラー: $e');
    }
  }
}

/// デザインモード用のカラーパレット
class DesignColors {
  // Apple Colors
  static const appleBlue = Color(0xFF007AFF);
  static const appleGreen = Color(0xFF34C759);
  static const appleRed = Color(0xFFFF3B30);
  static const appleOrange = Color(0xFFFF9500);
  static const applePurple = Color(0xFF5856D6);
  static const appleGray = Color(0xFF8E8E93);
  
  // Material Colors - Google's vibrant palette
  static const materialBlue = Color(0xFF1976D2);
  static const materialBlueAccent = Color(0xFF2196F3);
  static const materialGreen = Color(0xFF4CAF50);
  static const materialGreenAccent = Color(0xFF8BC34A);
  static const materialRed = Color(0xFFF44336);
  static const materialRedAccent = Color(0xFFFF5722);
  static const materialOrange = Color(0xFFFF9800);
  static const materialOrangeAccent = Color(0xFFFFC107);
  static const materialPurple = Color(0xFF9C27B0);
  static const materialPurpleAccent = Color(0xFF673AB7);
  static const materialTeal = Color(0xFF009688);
  static const materialIndigo = Color(0xFF3F51B5);
  static const materialGray = Color(0xFF757575);
  
  // Material Design surface colors
  static const materialSurface = Color(0xFFFAFAFA);
  static const materialSurfaceDark = Color(0xFF121212);
  static const materialPrimary = Color(0xFF6200EE);
  static const materialSecondary = Color(0xFF03DAC6);
}

/// デザインモード用のテキストスタイル
class DesignTextStyles {
  // Apple Typography
  static TextStyle appleTitle(bool isDark) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.white : Colors.black87,
    letterSpacing: 0.3,
    decoration: TextDecoration.none,
  );
  
  static TextStyle appleBody(bool isDark) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: isDark ? Colors.grey[400] : Colors.grey[600],
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );
  
  static TextStyle appleCaption(bool isDark) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: isDark ? Colors.grey[500] : Colors.grey[600],
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );
  
  // Material Typography - Google's bold approach
  static TextStyle materialHeadline(bool isDark) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: isDark ? Colors.white : Colors.black87,
    letterSpacing: 0.25,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
  );
  
  static TextStyle materialTitle(bool isDark) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: isDark ? Colors.white : Colors.black87,
    letterSpacing: 0.15,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
  );
  
  static TextStyle materialSubtitle(bool isDark) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.grey[300] : Colors.grey[800],
    letterSpacing: 0.15,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
  );
  
  static TextStyle materialBody(bool isDark) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: isDark ? Colors.grey[300] : Colors.grey[700],
    letterSpacing: 0.25,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
    height: 1.43,
  );
  
  static TextStyle materialCaption(bool isDark) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: isDark ? Colors.grey[400] : Colors.grey[600],
    letterSpacing: 0.4,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
  );
  
  static TextStyle materialOverline(bool isDark) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.grey[500] : Colors.grey[600],
    letterSpacing: 1.5,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
  );
}

/// デザインモード用の形状・寸法
class DesignShapes {
  // Apple Shapes
  static const double appleBorderRadius = 8.0;
  static const double appleCardRadius = 12.0;
  static const double appleModalRadius = 16.0;
  static const double appleButtonHeight = 36.0;
  
  // Material Shapes - Google's bold geometry
  static const double materialBorderRadius = 16.0;
  static const double materialCardRadius = 20.0;
  static const double materialModalRadius = 28.0;
  static const double materialButtonHeight = 56.0;
  static const double materialFabSize = 56.0;
  static const double materialMiniButtonHeight = 36.0;
}

/// Material Designのエレベーション（影の深さ）
class MaterialElevations {
  static const double surface = 0.0;
  static const double card = 2.0;
  static const double button = 3.0;
  static const double fab = 6.0;
  static const double bottomSheet = 8.0;
  static const double modal = 12.0;
  static const double drawer = 16.0;
  
  static List<BoxShadow> getShadow(double elevation, {bool isDark = false}) {
    if (elevation == 0) return [];
    
    final double opacity = isDark ? 0.6 : 0.15;
    final double blur = elevation * 2;
    final double spread = elevation * 0.5;
    
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: Offset(0, elevation),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(opacity * 0.3),
        blurRadius: blur * 0.5,
        offset: Offset(0, elevation * 0.5),
      ),
    ];
  }
} 