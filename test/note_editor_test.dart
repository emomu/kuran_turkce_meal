import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/data/models/ayah.dart';
import 'package:kuran_turkce_meal/features/reader/widgets/note_editor_sheet.dart';

import 'helpers/localized_app.dart';

/// Not yazma yaprağı.
void main() async {
  await TestApp.ensureInitialized();

  const ayah = Ayah(
    id: 3,
    surahNumber: 2,
    ayahNumber: 3,
    translation: 'Onlar ki gaybe iman edip namazı dürüst kılarlar',
  );

  Future<String?> pumpEditor(
    WidgetTester tester, {
    String? initialNote,
  }) async {
    String? saved;
    var called = false;
    await TestApp.pump(
      tester,
      NoteEditorSheet(
        ayah: ayah,
        surahName: 'Bakara',
        initialNote: initialNote,
        onSave: (value) {
          saved = value;
          called = true;
        },
      ),
    );
    return called ? saved : null;
  }

  testWidgets('ayetin meali başlıkta bağlam olarak gösterilir',
      (tester) async {
    await pumpEditor(tester);
    // Kullanıcı hangi ayete yazdığını görmeden not alamamalı.
    expect(find.textContaining('gaybe iman'), findsOneWidget);
    expect(find.text('Bakara · 3. ayet'), findsOneWidget);
  });

  testWidgets('yeni notta başlık "Not ekle", mevcut notta "Notu düzenle"',
      (tester) async {
    await pumpEditor(tester);
    expect(find.text('Not ekle'), findsOneWidget);

    await pumpEditor(tester, initialNote: 'eski not');
    expect(find.text('Notu düzenle'), findsOneWidget);
  });

  testWidgets('boş notta kaydet düğmesi sönük ve devre dışı', (tester) async {
    var saveCalled = false;
    await TestApp.pump(
      tester,
      NoteEditorSheet(
        ayah: ayah,
        surahName: 'Bakara',
        initialNote: null,
        onSave: (_) => saveCalled = true,
      ),
    );

    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Kaydet'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, lessThan(0.5));

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(saveCalled, isFalse);
  });

  testWidgets('metin yazılınca kaydet düğmesi etkinleşir', (tester) async {
    await TestApp.pump(
      tester,
      NoteEditorSheet(
        ayah: ayah,
        surahName: 'Bakara',
        initialNote: null,
        onSave: (_) {},
      ),
    );

    await tester.enterText(find.byType(TextField), 'düşüncem');
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Kaydet'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 1.0);
  });

  testWidgets('kaydedilen metnin baş/son boşlukları kırpılır', (tester) async {
    String? saved;
    await TestApp.pump(
      tester,
      NoteEditorSheet(
        ayah: ayah,
        surahName: 'Bakara',
        initialNote: null,
        onSave: (value) => saved = value,
      ),
    );

    await tester.enterText(find.byType(TextField), '  bir düşünce  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(saved, 'bir düşünce');
  });

  testWidgets('silme yalnızca mevcut notta görünür ve onay ister',
      (tester) async {
    // Yeni notta silme seçeneği olmamalı.
    await pumpEditor(tester);
    expect(find.text('Notu sil'), findsNothing);

    String? saved = 'değişmedi';
    await TestApp.pump(
      tester,
      NoteEditorSheet(
        ayah: ayah,
        surahName: 'Bakara',
        initialNote: 'eski not',
        onSave: (value) => saved = value,
      ),
    );
    expect(find.text('Notu sil'), findsOneWidget);

    await tester.tap(find.text('Notu sil'));
    await tester.pumpAndSettle();

    // Onay istenmeli; dokunur dokunmaz silinmemeli.
    expect(find.text('Bu ayetteki not kalıcı olarak silinecek.'),
        findsOneWidget);
    expect(saved, 'değişmedi');

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(saved, 'değişmedi');
  });

  testWidgets('yazma alanı odak çerçevesi çizmez', (tester) async {
    await pumpEditor(tester);
    // Kalın odak halkası bu ölçekte arayüzün en baskın öğesi oluyordu;
    // kabuk gömülü bir yüzeyle çiziliyor.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.border, InputBorder.none);
    expect(field.decoration?.focusedBorder, InputBorder.none);
    expect(field.decoration?.filled, isFalse);
  });
}
