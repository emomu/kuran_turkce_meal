/// Asistanın neyi anlamadığını sayar.
///
/// Konu sözlüğünü büyütmek tahminle yapılıyordu: hangi soruların
/// karşılıksız kaldığını bilmeden hangi konunun eksik olduğu da bilinemez.
/// Bu sayaç o boşluğu doldurur — karşılanamayan soruları biriktirir ve
/// sözlüğün hangi yöne büyümesi gerektiğini söyler.
///
/// MAHREMİYET
/// ----------
/// Sayılan her şey cihazda kalır. Ağ isteği yok, kimlik yok, gönderim yok;
/// uygulamanın hiçbir yerinde bu veriyi dışarı taşıyan bir yol açılmadı.
/// Kullanıcı ayarlardan silebilir. Bir Kur'an uygulamasında insanların ne
/// sorduğu — "borcum var", "boşanıyorum" — mahremdir ve cihazdan çıkmamalı.
///
/// Saklanan soru metni değil, sorunun normalleştirilmiş hâli ve neden
/// karşılanamadığıdır. Geliştirici cihazda bakıp sözlüğe konu ekler;
/// başka bir amacı yok.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bir sorunun neden karşılanamadığı.
enum MissKind {
  /// Hiçbir niyete oturmadı.
  unclear,

  /// Alan dışı sayıldı.
  offTopic,

  /// Niyet çözüldü ama arama sonuç vermedi.
  emptyResult,
}

/// Karşılanamamış bir soru ve kaç kez sorulduğu.
class MissEntry {
  const MissEntry({
    required this.query,
    required this.kind,
    required this.count,
  });

  final String query;
  final MissKind kind;
  final int count;

  Map<String, dynamic> toJson() => {
        'q': query,
        'k': kind.name,
        'c': count,
      };

  static MissEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final query = raw['q'];
    final kindName = raw['k'];
    if (query is! String || kindName is! String) return null;

    final kind = MissKind.values.where((k) => k.name == kindName);
    if (kind.isEmpty) return null;

    return MissEntry(
      query: query,
      kind: kind.first,
      count: raw['c'] is int ? raw['c'] as int : 1,
    );
  }
}

/// Karşılanamayan soruların cihazdaki kaydı.
class AssistantStats {
  const AssistantStats(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'assistant.misses.v1';

  /// Tutulan en fazla farklı soru.
  ///
  /// Sınır olmasa liste sınırsız büyür ve her yazmada tamamı yeniden
  /// serileştirilirdi. İki yüz farklı soru, sözlüğü yönlendirmeye fazlasıyla
  /// yeter; dolduğunda en az sorulan düşer.
  static const maxEntries = 200;

  /// Bir sorunun karşılanamadığını kaydeder.
  ///
  /// Aynı soru ikinci kez gelirse sayaç artar — asıl aranan bu: bir kez
  /// sorulan tuhaf bir cümle değil, tekrar tekrar sorulup karşılık
  /// bulamayan konu.
  Future<void> recordMiss(String normalizedQuery, MissKind kind) async {
    final query = normalizedQuery.trim();
    // Çok kısa girdiler ("ne", "aa") bilgi taşımaz; sayılmaz.
    if (query.length < 3) return;
    // Çok uzun girdiler tek seferlik cümlelerdir ve listeyi şişirir.
    if (query.length > 80) return;

    final entries = load();
    final index = entries.indexWhere((e) => e.query == query);

    if (index >= 0) {
      final existing = entries[index];
      entries[index] = MissEntry(
        query: query,
        kind: kind,
        count: existing.count + 1,
      );
    } else {
      entries.add(MissEntry(query: query, kind: kind, count: 1));
    }

    // Sık sorulan önce; liste dolduysa en az sorulan düşer.
    entries.sort((a, b) => b.count.compareTo(a.count));
    final trimmed =
        entries.length > maxEntries ? entries.sublist(0, maxEntries) : entries;

    await _prefs.setString(
      _key,
      jsonEncode([for (final e in trimmed) e.toJson()]),
    );
  }

  /// Kayıtları sık sorulandan seyreğe verir.
  List<MissEntry> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [for (final e in decoded) ?MissEntry.fromJson(e)];
    } on FormatException {
      return [];
    }
  }

  /// Toplam karşılanamayan soru sayısı (tekrarlar dahil).
  int get totalMisses =>
      load().fold(0, (sum, e) => sum + e.count);

  Future<void> clear() => _prefs.remove(_key);
}
