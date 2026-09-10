import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_history.dart';
import 'package:kuran_turkce_meal/features/assistant/data/assistant_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('sohbet geçmişi', () {
    test('boş geçmiş boş liste döner', () {
      expect(AssistantHistory(prefs).load(), isEmpty);
    });

    test('yazılan geçmiş geri okunur', () async {
      final history = AssistantHistory(prefs);
      await history.save(const [
        StoredMessage(isUser: true, text: 'sabır'),
        StoredMessage(
          isUser: false,
          text: 'sabır üzerine 3 ayet buldum.',
          ayahIds: [10, 11],
          allAyahIds: [10, 11, 12],
          note: 'kelime eşleşmesi',
          resultTitle: 'sabır',
          highlightTerms: ['sabr'],
        ),
      ]);

      final loaded = history.load();
      expect(loaded, hasLength(2));
      expect(loaded.first.isUser, isTrue);
      expect(loaded.last.ayahIds, [10, 11]);
      expect(loaded.last.allAyahIds, [10, 11, 12]);
      expect(loaded.last.resultTitle, 'sabır');
      expect(loaded.last.highlightTerms, ['sabr']);
    });

    test('çoklu konu bölümleri de saklanır', () async {
      // Bölümler saklanmazsa çoklu konu cevabı yeniden açılışta bomboş
      // görünür: ayetleri `ayahs` içinde değil, bölümlerin içindedir.
      final history = AssistantHistory(prefs);
      await history.save(const [
        StoredMessage(
          isUser: false,
          text: 'sabır ve şükür konularında bulduklarım:',
          sections: [
            StoredSection(label: 'sabır', ayahIds: [1, 2], totalFound: 40),
            StoredSection(label: 'şükür', ayahIds: [3], totalFound: 12),
          ],
        ),
      ]);

      final loaded = history.load();
      expect(loaded.single.sections, hasLength(2));
      expect(loaded.single.sections.first.label, 'sabır');
      expect(loaded.single.sections.first.ayahIds, [1, 2]);
      expect(loaded.single.sections.first.totalFound, 40);
      expect(loaded.single.sections.last.label, 'şükür');
    });

    test('sınırı aşan geçmişte en eskisi düşer', () async {
      final history = AssistantHistory(prefs);
      await history.save([
        for (var i = 0; i < AssistantHistory.maxMessages + 5; i++)
          StoredMessage(isUser: true, text: 'soru $i'),
      ]);

      final loaded = history.load();
      expect(loaded, hasLength(AssistantHistory.maxMessages));
      // Sondaki korunur, baştaki düşer.
      expect(loaded.last.text, 'soru ${AssistantHistory.maxMessages + 4}');
      expect(loaded.first.text, 'soru 5');
    });

    test('bozuk kayıt boş geçmiş sayılır', () async {
      await prefs.setString('assistant.history.v1', '{bozuk json');
      expect(AssistantHistory(prefs).load(), isEmpty);
    });

    test('bozuk tek girdi diğerlerini düşürmez', () async {
      await prefs.setString(
        'assistant.history.v1',
        '[{"u":true,"t":"iyi"},{"yok":1},{"u":false,"t":"cevap"}]',
      );
      final loaded = AssistantHistory(prefs).load();
      expect(loaded, hasLength(2));
      expect(loaded.first.text, 'iyi');
    });

    test('boş liste kaydı siler', () async {
      final history = AssistantHistory(prefs);
      await history.save(const [StoredMessage(isUser: true, text: 'a')]);
      await history.save(const []);
      expect(history.load(), isEmpty);
    });

    test('temizlenen geçmiş geri gelmez', () async {
      final history = AssistantHistory(prefs);
      await history.save(const [StoredMessage(isUser: true, text: 'a')]);
      await history.clear();
      expect(history.load(), isEmpty);
    });
  });

  group('karşılanamayan sorular', () {
    test('kaydedilen soru geri okunur', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('kuantum fizigi', MissKind.offTopic);

      final entries = stats.load();
      expect(entries, hasLength(1));
      expect(entries.first.query, 'kuantum fizigi');
      expect(entries.first.kind, MissKind.offTopic);
      expect(entries.first.count, 1);
    });

    test('aynı soru tekrarında sayaç artar', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('hac zamani', MissKind.emptyResult);
      await stats.recordMiss('hac zamani', MissKind.emptyResult);
      await stats.recordMiss('hac zamani', MissKind.emptyResult);

      final entries = stats.load();
      expect(entries, hasLength(1));
      expect(entries.first.count, 3);
    });

    test('sık sorulan başa gelir', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('seyrek soru', MissKind.unclear);
      await stats.recordMiss('sik soru', MissKind.unclear);
      await stats.recordMiss('sik soru', MissKind.unclear);

      expect(stats.load().first.query, 'sik soru');
    });

    test('çok kısa girdi sayılmaz', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('ne', MissKind.unclear);
      expect(stats.load(), isEmpty);
    });

    test('çok uzun girdi sayılmaz', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('a' * 200, MissKind.unclear);
      expect(stats.load(), isEmpty);
    });

    test('toplam tekrarları da sayar', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('ilk soru', MissKind.unclear);
      await stats.recordMiss('ilk soru', MissKind.unclear);
      await stats.recordMiss('baska soru', MissKind.offTopic);

      expect(stats.totalMisses, 3);
    });

    test('temizlenen kayıt geri gelmez', () async {
      final stats = AssistantStats(prefs);
      await stats.recordMiss('bir soru', MissKind.unclear);
      await stats.clear();
      expect(stats.load(), isEmpty);
    });
  });
}
