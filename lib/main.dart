import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/todo_service.dart';
import 'services/design_mode_service.dart';
import 'screens/macos_style_screen.dart';

/// Flutter デスクトップ TODOアプリのメインエントリポイント
/// ここでアプリ全体の設定と初期化を行います
void main() {
  runApp(const TodoApp());
}

/// TODOアプリのルートウィジェット
/// Provider状態管理の設定とテーマの設定を行います
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TodoServiceをアプリ全体で利用可能にする
        ChangeNotifierProvider(create: (context) => TodoService()),
        // デザインモードサービスを追加
        ChangeNotifierProvider(create: (context) => DesignModeService()),
      ],
      child: MaterialApp(
        title: 'TODO Manager - macOS Style',
        debugShowCheckedModeBanner: false,
        
        // macOS風テーマ設定（Material Designベース）
        theme: ThemeData(
          useMaterial3: true,
          // macOS風のカラーパレット
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF), // macOS Blue
            brightness: Brightness.light,
          ),
          // macOS風のタイポグラフィ
          fontFamily: 'SF Pro Display', // macOSのシステムフォント（fallback）
          // デスクトップアプリらしい設定
          visualDensity: VisualDensity.compact,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // macOS風のボタンスタイル
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        
        // ダークテーマ（macOS風）
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A84FF), // macOS Blue Dark
            brightness: Brightness.dark,
          ),
          fontFamily: 'SF Pro Display',
          visualDensity: VisualDensity.compact,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        
        themeMode: ThemeMode.system,
        
        // メイン画面を設定
        home: const MacOSStyleScreen(),
      ),
    );
  }
}
