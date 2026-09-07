import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/theme/app_theme.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuran_turkce_meal/features/audio/providers/audio_provider.dart';
import 'package:kuran_turkce_meal/features/audio/widgets/audio_download_sheet.dart';
import 'package:kuran_turkce_meal/features/audio/widgets/audio_player_bar.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/ayah_tile.dart';

import 'helpers/localized_app.dart';

const _ayah = Ayah(
  id: 1,
  surahNumber: 96,
  ayahNumber: 1,
  translation: 'Yaratan Rabbinin adıyla oku.',
);

const _prefs = ReaderPreferences();

Future<void> _pumpTile(WidgetTester tester, {required bool isPlaying}) =>
    TestApp.pump(
      tester,
      SingleChildScrollView(
        child: AyahTile(
          ayah: _ayah,
          prefs: _prefs,
          mark: null,
          isPlaying: isPlaying,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
      theme: AppTheme.light,
    );

/// Ayet karesinin dış kabındaki süslemeyi bulur.
BoxDecoration _tileDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byType(AyahTile),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  group('çalan ayet vurgusu', () {
    testWidgets('ayet karesine kenarlık çizilmez', (tester) async {
      // Çalan ayet yalnızca zemin rengiyle belirtilir. Kenarlık denendi ve
      // kaldırıldı: tilavet ilerledikçe her ayette sırayla beliren dikey bir
      // şerit, sakin kalması gereken okuma akışında fazla göze çarpıyordu.
      await _pumpTile(tester, isPlaying: true);
      expect(_tileDecoration(tester).border, isNull);
    });

    testWidgets('çalan ayetin zemini hafifçe renklenir', (tester) async {
      await _pumpTile(tester, isPlaying: false);
      final idle = _tileDecoration(tester).color;

      await _pumpTile(tester, isPlaying: true);
      final playing = _tileDecoration(tester).color;

      expect(idle, isNot(playing));
      // Tilavet boyunca ekranda kalacak; göz yormayacak kadar hafif olmalı.
      expect(playing!.a, lessThan(0.1));
    });

    testWidgets('metin her iki durumda da okunur', (tester) async {
      await _pumpTile(tester, isPlaying: true);
      expect(find.text('Yaratan Rabbinin adıyla oku.'), findsOneWidget);
    });
  });

  group('indirme boyutu biçimi', () {
    test('bir megabaytın altı kilobayt gösterir', () {
      expect(formatBytes(512 * 1024), '512 KB');
    });

    test('küçük megabaytlarda ondalık gösterir', () {
      expect(formatBytes((2.5 * 1024 * 1024).round()), '2.5 MB');
    });

    test('büyük değerlerde tam sayıya yuvarlar', () {
      // Kullanıcı "37,4 MB" ile "38 MB" arasında karar vermiyor; kabaca ne
      // kadar yer tutacağını bilmek istiyor.
      expect(formatBytes(38 * 1024 * 1024), '38 MB');
    });
  });

  group('tilavet çubuğu görünürlüğü', () {
    /// Çubuğu, sesin verilen durumda olduğu sahte bir kapsayıcıyla çizer.
    Future<void> pumpBar(
      WidgetTester tester, {
      required AudioState state,
      int? surahNumber,
    }) async {
      await TestApp.pump(
        tester,
        ProviderScope(
          overrides: [
            audioProvider.overrideWith((ref) => _FakeAudioNotifier(state)),
          ],
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AudioPlayerBar(surahNumber: surahNumber),
            ),
          ),
        ),
        theme: AppTheme.light,
      );
    }

    testWidgets('ses kapalıyken çubuk çizilmez', (tester) async {
      await pumpBar(tester, state: const AudioState());
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('ses çalarken duraklat düğmesi görünür', (tester) async {
      await pumpBar(
        tester,
        state: const AudioState(
          surahNumber: 96,
          currentAyahNumber: 1,
          isPlaying: true,
        ),
      );
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('duraklatılmışken çal düğmesi görünür', (tester) async {
      await pumpBar(
        tester,
        state: const AudioState(surahNumber: 96, currentAyahNumber: 1),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('sure numarası verilmezse her surede görünür', (tester) async {
      // Kabuktaki kullanım: kullanıcı hangi sekmede olursa olsun çalan sesi
      // durdurabilmeli.
      await pumpBar(
        tester,
        state: const AudioState(surahNumber: 68, currentAyahNumber: 3),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('başka sure çalarken okuma ekranı çubuğu gizler', (
      tester,
    ) async {
      // Okuma ekranındaki kullanım: 96. sureyi okurken 68. surenin
      // kontrollerini göstermek kafa karıştırır.
      await pumpBar(
        tester,
        state: const AudioState(surahNumber: 68, currentAyahNumber: 3),
        surahNumber: 96,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('okunan sure çalarken okuma ekranı çubuğu gösterir', (
      tester,
    ) async {
      await pumpBar(
        tester,
        state: const AudioState(surahNumber: 96, currentAyahNumber: 3),
        surahNumber: 96,
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}

/// Sabit bir durumu yayan sahte oynatıcı.
///
/// Gerçek [AudioNotifier] açılışta bir [AudioPlayer] kurar; test ortamında
/// platform kanalı bulunmadığı için bu widget testlerinde kullanılamaz.
class _FakeAudioNotifier extends StateNotifier<AudioState>
    implements AudioNotifier {
  _FakeAudioNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
