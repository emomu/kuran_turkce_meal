import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/topic.dart';

/// Konu fihristine erişim. Salt okunur.
///
/// Veri asset'ten belleğe alınır (~34 KB). `ProphetRepository` ile aynı
/// gerekçeyle SQLite'a konmadı: kayıt sayısı 56 ve her biri yalnızca bir
/// kimlik listesi taşıyor. Veritabanına almak bir tablo, bir göç adımı ve
/// sorgu maliyeti getirir, karşılığında hiçbir şey vermezdi.
///
/// Ayetlerin kendisi yine veritabanından çekilir; burada tutulan yalnızca
/// hangi ayetin hangi konuya ait olduğu.
class TopicRepository {
  TopicRepository();

  static const _assetPath = 'assets/data/topics.json';

  List<Topic>? _topics;
  List<TopicCategory>? _categories;
  Future<void>? _loading;

  bool get isLoaded => _topics != null;

  /// Veriyi belleğe alır. Birden çok kez çağrılsa da tek kez çalışır.
  Future<void> ensureLoaded() {
    if (_topics != null) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(raw) as Map<String, Object?>;

    _categories = (map['categories']! as List)
        .cast<Map<String, Object?>>()
        .map(TopicCategory.fromMap)
        .toList();

    _topics = (map['topics']! as List)
        .cast<Map<String, Object?>>()
        .map(Topic.fromMap)
        .toList();
  }

  /// Tüm konular. Veri dosyasındaki sırayla döner (bölüm sırası).
  List<Topic> get all => _topics ?? const [];

  /// Tüm bölümler, fihristte görünecekleri sırayla.
  List<TopicCategory> get categories => _categories ?? const [];

  /// Kimliğe göre konu; bulunamazsa null.
  Topic? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Bir bölümün konuları, veri sırasını koruyarak.
  List<Topic> inCategory(String categoryId) =>
      all.where((t) => t.categoryId == categoryId).toList();

  /// Bir konunun ilgili konuları, çözülmüş hâlde.
  ///
  /// Çözülemeyen kimlik atlanır: veri yeniden üretildiğinde bir konu
  /// kaldırılmış olabilir ve arayüzde boş bir bağlantı görünmemeli.
  List<Topic> relatedTo(Topic topic) {
    final result = <Topic>[];
    for (final id in topic.relatedIds) {
      final t = byId(id);
      if (t != null) result.add(t);
    }
    return result;
  }

  /// Yazılan metne uyan konular.
  ///
  /// [fold] ad karşılaştırma biçimi; sure adı ve peygamber adı eşleştirmesiyle
  /// aynı katlamayı kullanabilmek için dışarıdan verilir — "sukur" da
  /// "Şükür"ü bulmalı.
  ///
  /// Tek harf de aranır: fihrist gezilen bir liste, aranan bir dizin değil.
  /// Kullanıcı yazdıkça liste daralır ve boş sorguda hepsi durur; peygamber
  /// aramasındaki üç harf eşiği burada engel olurdu.
  ///
  /// Başlangıç eşleşmesi içerme eşleşmesinin önüne konur: "borç" yazan
  /// kullanıcı "Borç ve Ticaret"i listenin başında görmeli, "Borçlanma"ya
  /// değinen bir başka konunun altında değil.
  List<Topic> search(String input, {required String Function(String) fold}) {
    final needle = fold(input).trim();
    if (needle.isEmpty) return all;

    final starts = <Topic>[];
    final contains = <Topic>[];

    for (final t in all) {
      final name = fold(t.name);
      final nameEn = fold(t.nameEn);

      if (name.startsWith(needle) || nameEn.startsWith(needle)) {
        starts.add(t);
      } else if (name.contains(needle) || nameEn.contains(needle)) {
        contains.add(t);
      }
    }

    return [...starts, ...contains];
  }
}
