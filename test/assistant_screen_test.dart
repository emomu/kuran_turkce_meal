import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_intent.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_message.dart';
import 'package:kuran_turkce_meal/features/assistant/view/widgets/assistant_message_bubble.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';

import 'helpers/localized_app.dart';

/// Sohbet balonunun çizimi.
///
/// Ekranın tamamı veritabanı ister; balon istemez. Asistanın görünen
/// tarafındaki asıl sözleşme burada sınanıyor: cevap metni, ayet kartları
/// ve uyarı notu ekranda gerçekten çıkıyor mu.
void main() async {
  await TestApp.ensureInitialized();
  setUp(TestApp.reset);

  const ayah = Ayah(
    id: 262,
    surahNumber: 2,
    ayahNumber: 255,
    translation: 'Allah, kendisinden başka hiçbir ilah bulunmayandır.',
  );

  Future<void> pumpBubble(
    WidgetTester tester,
    AssistantMessage message,
  ) async {
    // Çeviri dosyaları diskten gerçek I/O ile okunur; sahte zamanlayıcı
    // bunu beklemez, bu yüzden ilk kare runAsync içinde çizilir.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: TestApp.wrap(
            AssistantMessageBubble(
              message: message,
              languageCode: 'tr',
              onAction: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  testWidgets('kullanıcı mesajı ekranda görünür', (tester) async {
    await pumpBubble(
      tester,
      const AssistantMessage(
        id: 0,
        author: MessageAuthor.user,
        text: 'sabır hakkında ne diyor',
      ),
    );
    expect(find.text('sabır hakkında ne diyor'), findsOneWidget);
  });

  testWidgets('cevap ayeti tam metniyle gösterilir', (tester) async {
    // Ayet kısaltılmaz: dini metinde yarım cümle anlamı bozar.
    await pumpBubble(
      tester,
      const AssistantMessage(
        id: 1,
        author: MessageAuthor.assistant,
        text: 'Bakara 255:',
        ayahs: [AnswerAyah(ayah: ayah, surahName: 'Bakara')],
      ),
    );

    expect(find.text('Bakara 255:'), findsOneWidget);
    expect(find.text(ayah.translation), findsOneWidget);
    // Kart, ayetin künyesini kendi biçiminde taşır: sure adı, ayırıcı,
    // ayet numarası. Arama sonuçlarıyla aynı görünsün diye böyle kuruldu.
    expect(find.text('Bakara · 255. ayet'), findsOneWidget);
  });

  testWidgets('uyarı notu ayetlerin altında çizilir', (tester) async {
    await pumpBubble(
      tester,
      const AssistantMessage(
        id: 2,
        author: MessageAuthor.assistant,
        text: 'sabır üzerine 3 ayet buldum.',
        ayahs: [AnswerAyah(ayah: ayah, surahName: 'Bakara')],
        note: 'Bu ayetler kelime eşleşmesiyle bulundu.',
      ),
    );
    expect(find.text('Bu ayetler kelime eşleşmesiyle bulundu.'),
        findsOneWidget);
  });

  testWidgets('eylem düğmeleri çizilir', (tester) async {
    await pumpBubble(
      tester,
      const AssistantMessage(
        id: 3,
        author: MessageAuthor.assistant,
        text: 'Kehf suresi 110 ayettir.',
        actions: [
          AssistantAction(
            label: 'Kehf suresini aç',
            kind: AssistantActionKind.navigate,
            route: '/sure/18',
          ),
        ],
      ),
    );
    expect(find.text('Kehf suresini aç'), findsOneWidget);
  });

  testWidgets('ayetsiz cevap ayet kartı çizmez', (tester) async {
    // Alan dışı ve hüküm cevapları hiçbir ayet göstermemeli; aksi hâlde
    // reddedilen bir soruya ayet iliştirilmiş olurdu.
    await pumpBubble(
      tester,
      const AssistantMessage(
        id: 4,
        author: MessageAuthor.assistant,
        text: 'Ben yalnızca Kur\'an meali üzerine yardımcı olabiliyorum.',
      ),
    );
    expect(find.text(ayah.translation), findsNothing);
  });

  testWidgets('eyleme dokunuş geri çağrıyı tetikler', (tester) async {
    AssistantAction? tapped;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: TestApp.wrap(
            AssistantMessageBubble(
              message: const AssistantMessage(
                id: 5,
                author: MessageAuthor.assistant,
                text: 'Devamı var.',
                actions: [
                  AssistantAction(
                    label: 'Tümünü gör (60)',
                    kind: AssistantActionKind.openAll,
                  ),
                ],
              ),
              languageCode: 'tr',
              onAction: (a, _) => tapped = a,
            ),
          ),
        ),
      );
      await tester.pump();
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tümünü gör (60)'));
    await tester.pumpAndSettle();

    expect(tapped?.kind, AssistantActionKind.openAll);
  });
}
