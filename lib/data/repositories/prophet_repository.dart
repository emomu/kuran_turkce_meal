import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/prophet.dart';

/// Peygamber-ayet eşleştirmesine erişim. Salt okunur.
///
/// Veri asset'ten belleğe alınır (~8 KB). SQLite'a konmadı: kayıt sayısı 25 ve
/// her biri yalnızca bir kimlik listesi taşıyor. Veritabanına almak bir tablo,
/// bir göç adımı ve sorgu maliyeti getirir, karşılığında hiçbir şey vermezdi.
///
/// Ayetlerin kendisi yine veritabanından çekilir; burada tutulan yalnızca
/// hangi ayetin hangi kıssaya ait olduğu.
class ProphetRepository {
  ProphetRepository();

  static const _assetPath = 'assets/data/prophets.json';

  List<Prophet>? _prophets;
  Future<void>? _loading;

  bool get isLoaded => _prophets != null;

  /// Veriyi belleğe alır. Birden çok kez çağrılsa da tek kez çalışır.
  Future<void> ensureLoaded() {
    if (_prophets != null) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, Object?>>();
    _prophets = list.map(Prophet.fromMap).toList();
  }

  /// Tüm peygamberler. Veri dosyasındaki sırayla döner (geleneksel sıra).
  List<Prophet> get all => _prophets ?? const [];

  /// Kimliğe göre peygamber; bulunamazsa null.
  Prophet? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Yazılan ada karşılık gelen peygamber.
  ///
  /// [fold] ad karşılaştırma biçimi; arama tarafındaki sure adı eşleştirmesiyle
  /// aynı katlamayı kullanabilmek için dışarıdan verilir — "musa" da "Mûsâ"yı
  /// bulmalı.
  ///
  /// Tam eşleşme aranır, bulunamazsa başlangıç eşleşmesine düşülür. Başlangıç
  /// eşleşmesi en kısa adı seçer: "yu" yazan kullanıcıya Yûnus mu Yûsuf mu
  /// verileceği belirsizdir ve kısa olanı seçmek kararı öngörülebilir kılar.
  Prophet? byName(String input, {required String Function(String) fold}) {
    final needle = fold(input);
    if (needle.length < 3) return null;

    for (final p in all) {
      if (fold(p.name) == needle || fold(p.nameEn) == needle) return p;
    }

    Prophet? best;
    for (final p in all) {
      final matches = fold(p.name).startsWith(needle) ||
          fold(p.nameEn).startsWith(needle);
      if (!matches) continue;
      if (best == null || p.name.length < best.name.length) best = p;
    }
    return best;
  }
}
