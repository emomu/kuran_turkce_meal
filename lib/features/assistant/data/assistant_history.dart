/// Sohbeti cihazda saklar.
///
/// Asistan kapatılıp açıldığında konuşma kaybolursa, kullanıcı her seferinde
/// sıfırdan başlar: sorduğu soruyu, gösterilen ayeti, "daha fazla" diyeceği
/// listeyi bulamaz. Arama kutusundan farkı da burada silinir.
///
/// NE SAKLANIR
/// -----------
/// Mesajın kendisi değil, yeniden kurulabilecek en küçük hâli. Ayet
/// metinleri saklanmaz — zaten veritabanında var ve orada güncel. Yalnızca
/// kimlikleri tutulur, açılışta veritabanından tazelenir. Böylece meal
/// güncellenirse eski metin ekranda kalmaz ve saklanan veri küçük olur.
///
/// SINIR
/// -----
/// Son [maxMessages] mesaj tutulur. Sohbet sınırsız büyürse hem açılış
/// yavaşlar hem kullanıcı kendi geçmişinde kaybolur. Eski mesajlar sessizce
/// düşer; kullanıcı zaten onlara dönmüyor.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Çoklu konu cevabındaki bir bölümün saklanabilir hâli.
///
/// Bölüm başlıkları olmadan iki konunun ayetleri tek listeye karışır ve
/// cevabın karşılaştırma yanı kaybolur; bu yüzden başlık da saklanır.
class StoredSection {
  const StoredSection({
    required this.label,
    required this.ayahIds,
    required this.totalFound,
  });

  final String label;
  final List<int> ayahIds;
  final int totalFound;

  Map<String, dynamic> toJson() => {
        'l': label,
        'a': ayahIds,
        'n': totalFound,
      };

  static StoredSection? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final label = raw['l'];
    if (label is! String) return null;

    final ids = raw['a'];
    return StoredSection(
      label: label,
      ayahIds: ids is List ? [for (final v in ids) if (v is int) v] : const [],
      totalFound: raw['n'] is int ? raw['n'] as int : 0,
    );
  }
}

/// Saklanan tek bir mesaj.
///
/// Ekrandaki [AssistantMessage] değil onun kaydedilebilir izi: ayetler
/// kimliğe indirgenmiş, eylemler atılmıştır. Eylemler cevaptan yeniden
/// türetilebilir olduğu için saklanmaz — saklansaydı, uygulama güncellenince
/// eski bir rotaya götüren ölü bir düğme kalırdı.
class StoredMessage {
  const StoredMessage({
    required this.isUser,
    required this.text,
    this.ayahIds = const [],
    this.allAyahIds = const [],
    this.note,
    this.resultTitle,
    this.highlightTerms = const [],
    this.sections = const [],
  });

  final bool isUser;
  final String text;

  /// Balonda gösterilen ayetlerin kimlikleri.
  final List<int> ayahIds;

  /// "Tümünü gör" listesinin kimlikleri.
  final List<int> allAyahIds;

  final String? note;
  final String? resultTitle;
  final List<String> highlightTerms;

  /// Çoklu konu cevabının bölümleri. Boşsa cevap tek parçadır.
  final List<StoredSection> sections;

  Map<String, dynamic> toJson() => {
        'u': isUser,
        't': text,
        if (ayahIds.isNotEmpty) 'a': ayahIds,
        if (allAyahIds.isNotEmpty) 'l': allAyahIds,
        if (note != null) 'n': note,
        if (resultTitle != null) 'r': resultTitle,
        if (highlightTerms.isNotEmpty) 'h': highlightTerms,
        if (sections.isNotEmpty)
          's': [for (final s in sections) s.toJson()],
      };

  /// Bozuk bir kayıt tüm geçmişi düşürmemeli; okunamayan alan atlanır.
  static StoredMessage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['t'];
    if (text is! String) return null;

    return StoredMessage(
      isUser: raw['u'] == true,
      text: text,
      ayahIds: _intList(raw['a']),
      allAyahIds: _intList(raw['l']),
      note: raw['n'] is String ? raw['n'] as String : null,
      resultTitle: raw['r'] is String ? raw['r'] as String : null,
      highlightTerms: _stringList(raw['h']),
      sections: _sectionList(raw['s']),
    );
  }

  static List<StoredSection> _sectionList(Object? raw) {
    if (raw is! List) return const [];
    return [for (final v in raw) ?StoredSection.fromJson(v)];
  }

  static List<int> _intList(Object? raw) {
    if (raw is! List) return const [];
    return [for (final v in raw) if (v is int) v];
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [for (final v in raw) if (v is String) v];
  }
}

/// Sohbet geçmişinin cihazdaki karşılığı.
class AssistantHistory {
  const AssistantHistory(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'assistant.history.v1';

  /// Saklanan en fazla mesaj sayısı.
  ///
  /// Kırk mesaj yirmi soru-cevap turu demektir; bir oturumda buna
  /// ulaşılmaz, birkaç oturumda ulaşılır ve o noktada en eskisi zaten
  /// ilgisizdir.
  static const maxMessages = 40;

  /// Geçmişi okur. Bozuk kayıt boş geçmiş sayılır.
  List<StoredMessage> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return [
        for (final entry in decoded) ?StoredMessage.fromJson(entry),
      ];
    } on FormatException {
      // Eski sürümden kalan ya da yarım yazılmış kayıt. Kullanıcıya hata
      // göstermenin anlamı yok; sohbet boş açılır.
      return const [];
    }
  }

  /// Geçmişi yazar. Son [maxMessages] mesaj tutulur.
  Future<void> save(List<StoredMessage> messages) async {
    if (messages.isEmpty) {
      await clear();
      return;
    }

    final trimmed = messages.length > maxMessages
        ? messages.sublist(messages.length - maxMessages)
        : messages;

    await _prefs.setString(
      _key,
      jsonEncode([for (final m in trimmed) m.toJson()]),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}
