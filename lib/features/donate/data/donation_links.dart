/// Bağış kanalları.
///
/// Tek bir yerde durur ki bağlantı değiştiğinde arayüzün hiçbir yerine
/// dokunmak gerekmesin. Uygulama bunları yalnızca açar; hiçbir ödeme akışı
/// uygulamanın içinde çalışmaz.
///
/// Google Play'in ödeme politikası, dinî ve manevi içerik için yapılan
/// **gönüllü** katkıları Play Faturalandırma zorunluluğunun dışında tutar.
/// İstisnanın koşulu, katkı karşılığında uygulama içinde hiçbir şey
/// verilmemesidir: reklam kaldırma, ek özellik, ek içerik yok. Bu dosyaya
/// bir "destekçi ayrıcalığı" eklenecek olursa istisna düşer ve bağış artık
/// dijital ürün satışı sayılır.
library;

import 'package:flutter/foundation.dart';

/// Bağışın nasıl yapılacağı.
enum DonationKind {
  /// Tarayıcıda açılan bir bağış sayfası.
  link,

  /// Panoya kopyalanan bir hesap numarası (IBAN gibi).
  copy,
}

/// Kullanıcıya sunulan tek bir bağış yolu.
class DonationChannel {
  const DonationChannel({
    required this.id,
    required this.kind,
    required this.value,
    this.holder,
    this.enabled = true,
  });

  /// Çeviri anahtarlarının kökü: `donate.channel.<id>.title` ve
  /// `donate.channel.<id>.subtitle`.
  final String id;

  final DonationKind kind;

  /// [DonationKind.link] için açılacak adres, [DonationKind.copy] için
  /// panoya kopyalanacak metin.
  final String value;

  /// Hesap sahibinin adı. Yalnızca [DonationKind.copy] kanallarında anlamlı.
  ///
  /// Havalede alıcı adının IBAN'la eşleşmesi isteniyor; adı göstermeyen bir
  /// ekran, kullanıcıyı bankada ad aramaya zorlar ve eşleşmediğinde banka
  /// işlemi reddedebilir.
  final String? holder;

  /// Kapalı kanallar listede hiç görünmez. Henüz hesabı açılmamış bir
  /// kanalı koda yazıp kapalı bırakmak, sonradan tek satırla açmayı sağlar.
  final bool enabled;

  String get titleKey => 'donate.channel.$id.title';
  String get subtitleKey => 'donate.channel.$id.subtitle';
}


abstract final class DonationLinks {
  static const channels = <DonationChannel>[
    DonationChannel(
      id: 'buymeacoffee',
      kind: DonationKind.link,
      value: 'https://buymeacoffee.com/emomu',
      enabled: true,
    ),
    DonationChannel(
      id: 'papara',
      kind: DonationKind.link,
      value: 'https://ppr.ist/KULLANICI_ADINIZ',
      enabled: false,
    ),
    DonationChannel(
      id: 'iban',
      kind: DonationKind.copy,
      value: 'TR07 0001 0090 1003 0726 1050 10',
      holder: 'Emirhan Soylu',
      enabled: true,
    ),
  ];

  /// Testlerin kanal listesini değiştirebilmesi için.
  ///
  /// Bağış özelliğinin tamamı "en az bir kanal açık mı" sorusuna bağlı;
  /// hatırlatma mantığı da kanallar kapalıyken hiç çalışmıyor. Testin bu
  /// koşulu kurabilmesi gerekiyor, yoksa eşikler hiç sınanamaz.
  static List<DonationChannel>? _override;

  /// Görünecek kanallar.
  static List<DonationChannel> get active =>
      (_override ?? channels).where((c) => c.enabled).toList(growable: false);

  /// Hiçbir kanal yapılandırılmamışsa bağış özelliği baştan sona kapanır:
  /// ayarlardaki satır, ana ekrandaki kart ve hatırlatma bildirimi çizilmez.
  static bool get isConfigured => active.isNotEmpty;

  /// Yalnızca testler için: kanal listesini geçici olarak değiştirir.
  /// `null` vermek gerçek listeye döner.
  @visibleForTesting
  static void debugOverrideChannels(List<DonationChannel>? channels) {
    _override = channels;
  }
}
