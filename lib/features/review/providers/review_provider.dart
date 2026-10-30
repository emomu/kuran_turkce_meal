import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/app_providers.dart';

/// Puan isteğinin durumu ve ne zaman sorulacağı.
///
/// Bağış hatırlatmasıyla aynı duruş: kullanıcı uygulamayı gerçekten
/// kullanmadan sorulmaz, sorulduktan sonra uzun süre susulur. Fark, sorunun
/// *anında* yatıyor — puan, okuma ortasında değil bir şey bitirildiğinde
/// (plan günü, sure) istenir. Memnuniyetin en yüksek olduğu an orası ve
/// kullanıcı zaten bir duraklama noktasında.
///
/// Pencerenin kendisi sistemin: iOS bunu yılda en fazla üç kez gösterir,
/// Android ise kotasını açıklamaz. Bu yüzden "sorduk" kaydı, pencere
/// görünmese bile tutulur; aksi halde sistemin sessizce yuttuğu istekler
/// her bitişte yeniden denenirdi.
///
/// Tüm durum cihazda `SharedPreferences` içinde tutulur.
class ReviewState {
  const ReviewState({
    required this.firstLaunch,
    required this.openCount,
    required this.milestoneCount,
    required this.lastRequestedAt,
    required this.requestCount,
  });

  /// Uygulamanın ilk açıldığı an. Eşik buradan sayılır.
  final DateTime firstLaunch;

  /// Uygulamanın kaç kez açıldığı.
  final int openCount;

  /// Bitirilen plan günü ve sure sayısı.
  final int milestoneCount;

  /// Puanın en son istendiği an.
  final DateTime? lastRequestedAt;

  /// Puanın kaç kez istendiği.
  final int requestCount;

  ReviewState copyWith({
    int? openCount,
    int? milestoneCount,
    DateTime? lastRequestedAt,
    int? requestCount,
  }) {
    return ReviewState(
      firstLaunch: firstLaunch,
      openCount: openCount ?? this.openCount,
      milestoneCount: milestoneCount ?? this.milestoneCount,
      lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
      requestCount: requestCount ?? this.requestCount,
    );
  }
}

/// Puan isteğinin eşikleri.
abstract final class ReviewThresholds {
  /// İlk açılıştan sonra geçmesi gereken süre.
  static const minDays = 7;

  /// Gereken açılış sayısı. Süre tek başına yetmez: kurup unutulmuş bir
  /// uygulama için puan istemek anlamsız.
  static const minOpens = 10;

  /// Gereken bitiş sayısı. Uygulamayı açıp kapatan değil, okuyan kullanıcıya
  /// sorulur.
  static const minMilestones = 3;

  /// İki istek arasında geçmesi gereken süre.
  static const cooldownDays = 120;

  /// Toplam istek sınırı. Üç kez sorulup puan vermeyen kullanıcı vermek
  /// istemiyordur; dördüncü kez sormak ısrar olurdu.
  static const maxRequests = 3;
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _kFirstLaunch = 'review_first_launch';
  static const _kOpenCount = 'review_open_count';
  static const _kMilestoneCount = 'review_milestone_count';
  static const _kLastRequestedAt = 'review_last_requested_at';
  static const _kRequestCount = 'review_request_count';

  static ReviewState _read(SharedPreferences prefs) {
    final firstMs = prefs.getInt(_kFirstLaunch);
    final lastMs = prefs.getInt(_kLastRequestedAt);
    return ReviewState(
      firstLaunch: firstMs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(firstMs),
      openCount: prefs.getInt(_kOpenCount) ?? 0,
      milestoneCount: prefs.getInt(_kMilestoneCount) ?? 0,
      lastRequestedAt:
          lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
      requestCount: prefs.getInt(_kRequestCount) ?? 0,
    );
  }

  /// Açılışta bir kez çağrılır: ilk açılış anını kaydeder ve sayacı artırır.
  void registerAppOpen() {
    if (!_prefs.containsKey(_kFirstLaunch)) {
      _prefs.setInt(_kFirstLaunch, state.firstLaunch.millisecondsSinceEpoch);
    }
    final next = state.openCount + 1;
    state = state.copyWith(openCount: next);
    _prefs.setInt(_kOpenCount, next);
  }

  /// Bir plan günü ya da sure bitirildi.
  void registerMilestone() {
    final next = state.milestoneCount + 1;
    state = state.copyWith(milestoneCount: next);
    _prefs.setInt(_kMilestoneCount, next);
  }

  /// Puan şu an istenmeli mi.
  bool shouldRequest({DateTime? now}) {
    if (state.requestCount >= ReviewThresholds.maxRequests) return false;

    final moment = now ?? DateTime.now();

    final last = state.lastRequestedAt;
    if (last != null &&
        moment.difference(last).inDays < ReviewThresholds.cooldownDays) {
      return false;
    }

    return moment.difference(state.firstLaunch).inDays >=
            ReviewThresholds.minDays &&
        state.openCount >= ReviewThresholds.minOpens &&
        state.milestoneCount >= ReviewThresholds.minMilestones;
  }

  /// İstek sisteme iletildi.
  void markRequested({DateTime? at}) {
    final moment = at ?? DateTime.now();
    final count = state.requestCount + 1;
    state = state.copyWith(lastRequestedAt: moment, requestCount: count);
    _prefs
      ..setInt(_kLastRequestedAt, moment.millisecondsSinceEpoch)
      ..setInt(_kRequestCount, count);
  }
}

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>(
  (ref) => ReviewNotifier(ref.watch(sharedPreferencesProvider)),
);
