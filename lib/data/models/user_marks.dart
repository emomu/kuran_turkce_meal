/// Kullanıcının bir ayete iliştirdiği işaretler: yer imi, vurgu, not.
///
/// Üçü tek tabloda tutulur çünkü hepsi aynı ayete bağlıdır ve okuma ekranı
/// bunları tek sorguda ister. Ayrı tablolar üç ayrı JOIN demek olurdu.
class AyahMark {
  const AyahMark({
    required this.ayahId,
    this.isBookmarked = false,
    this.highlightColor,
    this.note,
    required this.updatedAt,
  });

  final int ayahId;
  final bool isBookmarked;

  /// Vurgu renginin ARGB değeri. Vurgu yoksa null.
  final int? highlightColor;

  /// Kullanıcının serbest metin notu.
  final String? note;

  final DateTime updatedAt;

  bool get hasNote => note != null && note!.trim().isNotEmpty;
  bool get isHighlighted => highlightColor != null;

  /// Kayıt tamamen boşsa silinebilir — üç işaretin hiçbiri kalmamış demektir.
  bool get isEmpty => !isBookmarked && !isHighlighted && !hasNote;

  AyahMark copyWith({
    bool? isBookmarked,
    int? Function()? highlightColor,
    String? Function()? note,
  }) => AyahMark(
    ayahId: ayahId,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    highlightColor: highlightColor != null
        ? highlightColor()
        : this.highlightColor,
    note: note != null ? note() : this.note,
    updatedAt: DateTime.now(),
  );

  factory AyahMark.fromMap(Map<String, Object?> map) => AyahMark(
    ayahId: map['ayah_id']! as int,
    isBookmarked: (map['is_bookmarked']! as int) == 1,
    highlightColor: map['highlight_color'] as int?,
    note: map['note'] as String?,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
  );

  Map<String, Object?> toMap() => {
    'ayah_id': ayahId,
    'is_bookmarked': isBookmarked ? 1 : 0,
    'highlight_color': highlightColor,
    'note': note,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };
}
