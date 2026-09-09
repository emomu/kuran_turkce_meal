import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookmarks/view/bookmarks_screen.dart';
import '../../features/donate/view/donate_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/legal/data/legal_texts.dart';
import '../../features/legal/view/legal_document_screen.dart';
import '../../features/plans/view/plan_detail_screen.dart';
import '../../features/plans/view/plans_screen.dart';
import '../../features/prophets/view/prophet_ayahs_screen.dart';
import '../../features/reader/view/reader_screen.dart';
import '../../features/search/view/search_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/splash/view/splash_screen.dart';
import 'app_shell.dart';

/// Uygulamanın yönlendirme tablosu.
///
/// Beş sekme birer dal olarak tanımlanır; her dal kendi gezinme yığınını
/// tutar (StatefulShellRoute), böylece kullanıcı sekmeler arasında geçerken
/// bulunduğu yeri kaybetmez.
///
/// Okuma ve plan detayı kabuğun dışındaki köklere konur — bu ekranlar tam
/// yüksekliği kullanır ve sekme çubuğu görünmez.
///
/// Açılış ekranı da kabuğun dışındadır ve başlangıç konumudur. Ana sayfa
/// `/` yolunda kalır; bildirimden ve derin bağlantıdan gelen yönlendirmeler
/// bu yolu kullanıyor, açılışı `/` yapmak onları bozardı.
final appRouter = GoRouter(
  initialLocation: _splashPath,

  // Araçtan ve kısayoldan gelen bağlantılar burada uygulama içi yola
  // çevrilir.
  //
  // Android araçları uygulamayı `ACTION_VIEW` ile açıyor; bu, eklentinin
  // kendi akışı değil işletim sisteminin normal derin bağlantı akışı, o
  // yüzden bağlantı doğrudan yönlendiriciye düşüyor. Burada karşılanmasaydı
  // (ve karşılanmıyordu) kullanıcı araca dokunduğunda "Sayfa bulunamadı:
  // homewidget://sure/9?ayet=93" ekranını görüyordu.
  redirect: (context, state) => widgetRouteOf(state.uri),

  routes: [
    GoRoute(
      path: _splashPath,
      builder: (context, state) => const SplashScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ara',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/planlar',
              builder: (context, state) => const PlansScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/kayitlar',
              builder: (context, state) => const BookmarksScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ayarlar',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Okuma ekranı. `ayet` sorgu parametresi verilirse o ayete konumlanır;
    // arama sonucundan, yer iminden ve bildirimden bu yolla gelinir.
    GoRoute(
      path: '/sure/:surahNumber',
      builder: (context, state) {
        final surahNumber =
            int.tryParse(state.pathParameters['surahNumber'] ?? '');
        if (surahNumber == null || surahNumber < 1 || surahNumber > 114) {
          return _RouteError(message: 'reader.invalidSurah'.tr());
        }

        return ReaderScreen(
          surahNumber: surahNumber,
          initialAyah: int.tryParse(state.uri.queryParameters['ayet'] ?? ''),
        );
      },
    ),

    // Yasal metinler. Mağazalar gizlilik politikasına uygulama içinden
    // erişilebilmesini ister; metinler pakete gömülü olduğu için bu ekranlar
    // internet olmadan da açılır.
    GoRoute(
      path: '/gizlilik',
      builder: (context, state) => LegalDocumentScreen(
        title: 'settings.privacy'.tr(),
        body: LegalTexts.privacy(context.locale.languageCode),
      ),
    ),

    GoRoute(
      path: '/kosullar',
      builder: (context, state) => LegalDocumentScreen(
        title: 'settings.terms'.tr(),
        body: LegalTexts.terms(context.locale.languageCode),
      ),
    ),

    GoRoute(
      path: '/kaynaklar',
      builder: (context, state) => LegalDocumentScreen(
        title: 'settings.sources'.tr(),
        body: LegalTexts.sources(context.locale.languageCode),
      ),
    ),

    // Bir peygamberin anıldığı ayetler, iniş sırasına göre.
    GoRoute(
      path: '/kissa/:prophetId',
      builder: (context, state) => ProphetAyahsScreen(
        prophetId: state.pathParameters['prophetId']!,
      ),
    ),

    // Bağış ekranı. Bildirimden de bu yola gelinir (bkz.
    // `scheduleDonationReminder` yükü).
    GoRoute(
      path: '/destek',
      builder: (context, state) => const DonateScreen(),
    ),

    GoRoute(
      path: '/ses-hakkinda',
      builder: (context, state) => LegalDocumentScreen(
        title: 'audio.about'.tr(),
        body: LegalTexts.audioInfo(context.locale.languageCode),
      ),
    ),

    GoRoute(
      path: '/plan/:planId',
      builder: (context, state) => PlanDetailScreen(
        planId: state.pathParameters['planId']!,
      ),
    ),
  ],
  errorBuilder: (context, state) =>
      _RouteError(
        message: 'error.pageNotFound'.tr(args: ['${state.uri}']),
      ),
);

/// Açılış ekranının yolu.
const _splashPath = '/acilis';

/// Geride kapatılabilir bir ekran var mı.
///
/// `PopScope.canPop` bunu bekler: yığın boşken sistem geri jesti uygulamayı
/// kapatmak yerine [popOrHome] ile ana sayfaya dönebilsin.
///
/// Yönlendirici yoksa `true` döner. Ekranlar tek başlarına da (parça
/// testlerinde, önizlemede) çizilebiliyor; orada geri davranışını kısıtlamak
/// yerine olağan `Navigator` akışına bırakmak doğrusu.
bool canPopRoute(BuildContext context) =>
    GoRouter.maybeOf(context)?.canPop() ?? true;

/// Kabuk dışı bir ekrandan geri döner.
///
/// Bu ekranlara (okuma, plan detayı) iki yoldan gelinir: uygulama içinden
/// itilerek — geride bir yığın vardır ve olağan `pop` doğru davranır — ya da
/// araçtan, bildirimden veya derin bağlantıdan doğrudan açılarak. İkinci
/// durumda `go` yığını sıfırladığı için geride hiçbir şey kalmaz; düz bir
/// `pop` ekranı boşaltıp kullanıcıyı çıkmaza sokuyordu.
///
/// Yığın boşsa ana sayfaya düşülür: araçtan gelen kullanıcı geri dediğinde
/// uygulamadan atılmak yerine uygulamanın içinde kalır.
void popOrHome(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    Navigator.of(context).maybePop();
    return;
  }
  if (router.canPop()) {
    router.pop();
  } else {
    router.go('/');
  }
}

/// Araç şemasıyla gelen bir bağlantıyı uygulama içi yola çevirir.
///
/// Araç değilse `null` döner ve yönlendirici olağan akışına devam eder.
///
/// Şema karşılaştırması küçük harf üzerinden yapılır: Android, manifest'te
/// `homeWidget` yazsanız da şemayı küçülterek `homewidget` biçiminde
/// iletiyor. Büyük/küçük harfe duyarlı karşılaştırma bu yüzden Android'de
/// hiç eşleşmiyordu.
String? widgetRouteOf(Uri uri) {
  if (uri.scheme.toLowerCase() != _widgetScheme) return null;

  // Yol, şemadan sonraki kısımdır. `homeWidget://sure/9` bağlantısında ilk
  // parça host olarak ayrışır, bu yüzden host ve path birleştirilir.
  final path = uri.host.isEmpty ? uri.path : '/${uri.host}${uri.path}';
  if (path.isEmpty || path == '/') return '/';

  // Sorgu korunmalı: ayet numarası orada taşınıyor, düşerse araç sureyi
  // açar ama ayete konumlanmaz.
  return uri.query.isEmpty ? path : '$path?${uri.query}';
}

/// Araçların, kısayolların ve hızlı ayarlar karesinin kullandığı şema.
const _widgetScheme = 'homewidget';

class _RouteError extends StatelessWidget {
  const _RouteError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/'),
                child: Text('common.goHome'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
