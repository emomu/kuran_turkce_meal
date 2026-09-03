import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';

/// Uygulamada tanıtılabilecek turlar.
///
/// Her tur kendi ekranında, kullanıcı oraya ilk kez geldiğinde bir kez
/// gösterilir. Tümünü açılışta arka arkaya göstermek yerine ekranına
/// bölmek bilinçli: kullanıcı bir özelliği ancak onu kullanacağı yerde
/// öğrenirse hatırlar. Açılışta beş ekranlık bir tanıtım izletmek ise
/// çoğunlukla "geç" tuşuna basılarak biter.
enum TourId {
  /// Ana ekran: sıralama ve günün ayeti.
  home('tour_seen_home'),

  /// Okuma ekranı: basılı tutma, sure sonu, punto ayarı.
  reader('tour_seen_reader'),

  /// Arama ekranı: nerede aradığı ve nasıl yazılacağı.
  search('tour_seen_search'),

  /// Planlar ekranı: planın ne olduğu ve nasıl işlediği.
  plans('tour_seen_plans'),

  /// Kök analizi: kökün ne anlama geldiği ve listenin ne gösterdiği.
  roots('tour_seen_roots');

  const TourId(this.storageKey);

  /// SharedPreferences anahtarı.
  final String storageKey;
}

/// Hangi turların gösterildiğini tutar.
///
/// Durum cihazda saklanır; tur bir kez izlendikten sonra bir daha
/// açılmaz. Ayarlardan sıfırlanabilir — kullanıcı ipuçlarını yeniden
/// görmek isteyebilir ya da uygulamayı bir başkasına gösteriyordur.
class TourNotifier extends StateNotifier<Set<TourId>> {
  TourNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Set<TourId> _read(SharedPreferences prefs) {
    return {
      for (final tour in TourId.values)
        if (prefs.getBool(tour.storageKey) ?? false) tour,
    };
  }

  /// [tour] daha önce gösterildi mi.
  bool hasSeen(TourId tour) => state.contains(tour);

  /// Turu görüldü olarak işaretler.
  void markSeen(TourId tour) {
    if (state.contains(tour)) return;
    state = {...state, tour};
    _prefs.setBool(tour.storageKey, true);
  }

  /// Tüm turları yeniden gösterilebilir hale getirir.
  void resetAll() {
    state = const {};
    for (final tour in TourId.values) {
      _prefs.remove(tour.storageKey);
    }
  }
}

final tourProvider = StateNotifierProvider<TourNotifier, Set<TourId>>(
  (ref) => TourNotifier(ref.watch(sharedPreferencesProvider)),
);
