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

  /// Keşfet: tek kutunun neleri aradığı ve fihristin ne olduğu.
  ///
  /// Depolama anahtarı `search` kaldı: ekran yeniden kurulmuş olsa da turu
  /// izlemiş kullanıcıya yeniden göstermek, ona yeni bir şey öğretmez.
  search('tour_seen_search'),

  /// Asistan: ne yaptığı ve — daha önemlisi — ne yapmadığı.
  assistant('tour_seen_assistant'),

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

/// O an ekranda açık olan tanıtım katmanları.
///
/// Tur karartması [Overlay]'e konur, ama sekmeli kabuğun asistan düğmesi o
/// katmanın dışında — kabuğun kendi `Scaffold`'unda — çizilir ve karartmanın
/// üstünde parlak kalır. Görüntü kirliliğinin ötesinde: düğme basılabilir
/// durumda kalıyor ve tur yarıda kesilebiliyordu.
///
/// Hangi turun açık olduğu tutulur, yalnızca bir sayı değil: "ipuçlarını
/// tekrar göster" bütün turları sıfırlıyor ve her sekmenin `TourHost`'u kendi
/// katmanını açıyor. Sayaç tutulsaydı, kullanıcı ayarlardayken bile ana
/// ekranın kapanmamış turu yüzünden sayaç sıfırdan büyük kalır ve düğme her
/// sekmede gizlenirdi. Düğmeyi gizleyen ekran, kendi turunun kimliğini sorar.
class ActiveToursNotifier extends StateNotifier<Set<TourId>> {
  ActiveToursNotifier() : super(const {});

  void show(TourId tour) => state = {...state, tour};

  void hide(TourId tour) => state = {...state}..remove(tour);
}

final activeToursProvider =
    StateNotifierProvider<ActiveToursNotifier, Set<TourId>>(
      (ref) => ActiveToursNotifier(),
    );

/// [tour] o an ekranda açık mı.
///
/// Tur boyunca gizlenmesi gereken öğeler (asistan düğmesi) bunu dinler —
/// kendi ekranının turunu sorarak, başka bir sekmede açık kalmış tur onları
/// etkilemesin.
final isTourActiveProvider = Provider.family<bool, TourId>(
  (ref, tour) => ref.watch(activeToursProvider).contains(tour),
);
