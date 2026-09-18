import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Bir ayetteki kelimelerin tilavet içindeki zamanlaması.
///
/// Süreler ayetin kendi ses dosyasının başından ölçülür; her ayet ayrı bir
/// MP3 olduğu için sure başına göre değil ayet başına göre okunur.
class AyahSegments {
  const AyahSegments(this._starts, this._ends);

  /// Kelime başlangıçları (milisaniye), kelime sırasında.
  final Int32List _starts;

  /// Kelime bitişleri (milisaniye).
  final Int32List _ends;

  int get wordCount => _starts.length;

  /// Verilen ana denk gelen kelimenin sırası; hiçbiri değilse null.
  ///
  /// Kelimeler arasında sessizlik olabilir (nefes, durak). O aralıkta null
  /// dönmek vurgunun sönüp yanmasına yol açardı; bunun yerine son okunan
  /// kelime tutulur ve vurgu sıradaki kelimeye kadar yerinde kalır.
  ///
  /// Arama ikili bölmeyle yapılır: tilavet boyunca her karede çağrılır ve
  /// uzun ayetlerde doğrusal tarama ölçülebilir iş çıkarırdı.
  int? wordAt(int positionMs) {
    if (_starts.isEmpty) return null;
    if (positionMs < _starts[0]) return null;

    var low = 0;
    var high = _starts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_starts[mid] <= positionMs) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    // Son kelimenin bitişinden sonrası: ayet bitmiş, vurgu kalkar. Aksi
    // halde ayetler arası boşlukta son kelime yanık kalırdı.
    if (low == _starts.length - 1 && positionMs > _ends[low]) return null;
    return low;
  }
}

/// Tilavet kelime zamanlamalarını paketten okur.
///
/// Paket `assets/data/segments.bin`; biçim `tool/build_segments.py` dosyasının
/// başında tarif edilir. Dosyanın tamamı ayrıştırılmaz: açılışta yalnızca
/// dizin tablosu okunur (kari başına ~75 KB), kelime süreleri ise ayet
/// istendiğinde ilgili birkaç bayttan çözülür.
class SegmentRepository {
  SegmentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const _assetPath = 'assets/data/segments.bin';
  static const _magic = 0x51534547; // 'QSEG'
  static const _supportedVersion = 1;

  /// Yazarken kullanılan zaman adımı; `build_segments.py` içindeki TICK_MS
  /// ile aynı olmalı.
  static const _tickMs = 20;

  ByteData? _data;

  /// Kari kimliği -> (dizin başlangıcı, ayet sayısı).
  final Map<String, _ReciterEntry> _catalogue = {};

  /// Çözülmüş ayetler. Tilavet aynı ayeti saniyede defalarca sorar; her
  /// seferinde baytları yeniden çözmek gereksiz iş olurdu.
  final Map<int, AyahSegments?> _cache = {};

  /// En son hangi kari için önbellek doldurulduğu. Kari değişince önbellek
  /// temizlenir, aksi halde yeni karinin sesine eski zamanlama uygulanırdı.
  String? _cachedReciterId;

  bool _loadFailed = false;

  /// Paket okunmuşsa true. Yükleme başarısızsa uygulama kelime vurgusunu
  /// sessizce kapatır; tilavet çalmaya devam eder.
  bool get isAvailable => _data != null;

  /// Paketi belleğe alır. Birden çok çağrı zararsızdır.
  ///
  /// Hata durumunda istisna fırlatılmaz: zamanlama verisi tilavetin
  /// çalışması için gerekli değil, yalnızca vurguyu zenginleştirir. Paket
  /// bozuksa ya da eksikse kullanıcı sesi yine dinleyebilmeli.
  Future<void> load() async {
    if (_data != null || _loadFailed) return;

    try {
      final bytes = await _bundle.load(_assetPath);
      final header = bytes;

      if (bytes.lengthInBytes < 6 ||
          header.getUint32(0, Endian.big) != _magic ||
          header.getUint8(4) != _supportedVersion) {
        _loadFailed = true;
        return;
      }

      final reciterCount = header.getUint8(5);
      for (var i = 0; i < reciterCount; i++) {
        final base = 6 + i * 32;
        final idBytes = bytes.buffer.asUint8List(
          bytes.offsetInBytes + base,
          24,
        );
        final end = idBytes.indexOf(0);
        final id = String.fromCharCodes(
          end == -1 ? idBytes : idBytes.sublist(0, end),
        );
        _catalogue[id] = _ReciterEntry(
          indexOffset: header.getUint32(base + 24, Endian.little),
          count: header.getUint32(base + 28, Endian.little),
        );
      }

      _data = bytes;
    } catch (_) {
      // Asset yoksa ya da okunamıyorsa vurgu kapalı kalır.
      _loadFailed = true;
    }
  }

  /// Bir ayetin kelime zamanlamaları; veri yoksa null.
  ///
  /// null dönmesi olağandır: hizalama tutmayan birkaç ayet pakete
  /// alınmadı ve her kari her ayeti kapsamayabilir. Çağıran taraf bu
  /// durumda ayet düzeyinde vurguya düşmeli.
  AyahSegments? segmentsFor({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final data = _data;
    if (data == null) return null;

    if (_cachedReciterId != reciterId) {
      _cache.clear();
      _cachedReciterId = reciterId;
    }

    final key = surahNumber * 1000 + ayahNumber;
    if (_cache.containsKey(key)) return _cache[key];

    final result = _lookup(data, reciterId, key);
    _cache[key] = result;
    return result;
  }

  AyahSegments? _lookup(ByteData data, String reciterId, int key) {
    final reciter = _catalogue[reciterId];
    if (reciter == null) return null;

    // Dizin sure/ayet sırasında yazılır; ikili arama ile aranır.
    var low = 0;
    var high = reciter.count - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final entry = reciter.indexOffset + mid * 12;
      final foundKey = data.getUint32(entry, Endian.little);

      if (foundKey == key) {
        final offset = data.getUint32(entry + 4, Endian.little);
        final wordCount = data.getUint32(entry + 8, Endian.little);
        return _read(data, offset, wordCount);
      }
      if (foundKey < key) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  AyahSegments _read(ByteData data, int offset, int wordCount) {
    final starts = Int32List(wordCount);
    final ends = Int32List(wordCount);
    for (var i = 0; i < wordCount; i++) {
      final at = offset + i * 4;
      starts[i] = data.getUint16(at, Endian.little) * _tickMs;
      ends[i] = data.getUint16(at + 2, Endian.little) * _tickMs;
    }
    return AyahSegments(starts, ends);
  }
}

/// Paketteki bir karinin dizin künyesi.
class _ReciterEntry {
  const _ReciterEntry({required this.indexOffset, required this.count});

  final int indexOffset;
  final int count;
}
