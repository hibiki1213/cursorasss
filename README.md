# Cursorasss - Flutter Desktop App

[![Flutter](https://img.shields.io/badge/Flutter-3.32.0-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.0-blue?logo=dart)](https://dart.dev)
[![macOS](https://img.shields.io/badge/Platform-macOS-black?logo=apple)](https://developer.apple.com/macos/)

## 📱 概要

Flutterを使用したクロスプラットフォームデスクトップアプリケーションです。
macOS、Windows、Linuxでネイティブに動作します。

## ✨ 特徴

- 🖥️ **デスクトップファースト設計** - デスクトップ環境に最適化されたUI/UX
- 🎯 **クロスプラットフォーム** - macOS、Windows、Linux対応
- 🔥 **ホットリロード** - 開発効率を向上させる高速な開発サイクル
- 🎨 **Material Design** - 美しく一貫性のあるUI

## 🛠️ 技術スタック

- **フレームワーク**: Flutter 3.32.0
- **言語**: Dart 3.8.0
- **UI**: Material Design
- **対応プラットフォーム**: macOS, Windows, Linux

## 🚀 開発環境のセットアップ

### 必要な環境
- Flutter SDK 3.32.0+
- Dart SDK 3.8.0+
- macOS 12.0+ (macOS開発の場合)
- Xcode 12.0+ (macOS開発の場合)

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone <repository-url>
   cd cursorasss
   ```

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **デスクトップサポートの有効化**
   ```bash
   flutter config --enable-macos-desktop
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   ```

## 🏃‍♂️ 実行方法

### macOSで実行
```bash
flutter run -d macos
```

### Windowsで実行
```bash
flutter run -d windows
```

### Linuxで実行
```bash
flutter run -d linux
```

### ビルド方法

#### macOSアプリのビルド
```bash
flutter build macos
```

#### Windowsアプリのビルド
```bash
flutter build windows
```

#### Linuxアプリのビルド
```bash
flutter build linux
```

## 📁 プロジェクト構造

```
cursorasss/
├── lib/
│   └── main.dart              # メインアプリケーション
├── macos/                     # macOS固有の設定
├── windows/                   # Windows固有の設定
├── linux/                     # Linux固有の設定
├── test/                      # テストファイル
├── pubspec.yaml              # 依存関係とプロジェクト設定
└── README.md                 # このファイル
```

## 🧪 テスト

```bash
flutter test
```

## 🔧 トラブルシューティング

### よくある問題

1. **デスクトップサポートが有効でない場合**
   ```bash
   flutter config --enable-macos-desktop
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   ```

2. **依存関係の問題**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **環境の確認**
   ```bash
   flutter doctor -v
   ```

## 📝 開発ガイドライン

- **コードスタイル**: Dartの標準的なコードスタイルに従う
- **テスト**: 新機能には適切なテストを追加
- **コミット**: 明確で簡潔なコミットメッセージを使用

## 🤝 貢献

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. コミット (`git commit -m 'Add some amazing feature'`)
4. プッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 🔗 参考リンク

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Desktop Support](https://docs.flutter.dev/development/platform-integration/desktop)
- [Dart Language](https://dart.dev/)
- [Material Design](https://material.io/design)
