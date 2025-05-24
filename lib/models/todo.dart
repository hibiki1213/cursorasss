/// TODOアイテムのデータモデル
/// これは「データベースのテーブル構造」と「アプリで使うデータ」を定義します
class Todo {
  final int? id;           // データベースの主キー（新規作成時はnull）
  final String title;      // TODOのタイトル
  final String? description; // TODOの詳細説明（オプション）
  final bool isCompleted;  // 完了状態
  final DateTime createdAt; // 作成日時
  final DateTime? updatedAt; // 更新日時

  const Todo({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// データベースから取得したMapをTodoオブジェクトに変換
  /// これは「データベース → アプリ」の変換処理
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'],
      isCompleted: map['isCompleted'] == 1, // SQLiteでは真偽値は0/1で保存
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  /// Todoオブジェクトをデータベース保存用のMapに変換
  /// これは「アプリ → データベース」の変換処理
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0, // SQLiteでは真偽値は0/1で保存
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Todoオブジェクトをコピーして、一部のプロパティを変更
  /// 状態更新時に使用（Dartでは不変オブジェクトが推奨）
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        isCompleted.hashCode;
  }
} 