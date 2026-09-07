import 'package:flutter_test/flutter_test.dart';

/// Ses çalarken listenin çalan ayeti ne zaman takip edeceği.
///
/// Okuma ekranındaki `_followPlayingAyah` ile aynı kural. Karar tek bir
/// eşiğe indiği için burada saf mantık olarak sınanır; gerçek kaydırmanın
/// kendisi `ScrollablePositionedList`'in işi ve widget testinde ölçülemiyor
/// (liste yalnızca gerçek bir düzen geçişinde konum bildirir).
///
/// Kuşak üstten %10, alttan %65: ayet bu aralıktayken göz onu zaten görüyor
/// ve liste kımıldamamalı. Dışına çıktığında kaydırılır.
bool isComfortable(double leadingEdge) =>
    leadingEdge >= 0.10 && leadingEdge <= 0.65;

void main() {
  group('takip kuşağı', () {
    test('ekranın üst çeyreğindeki ayet rahat sayılır', () {
      // Otomatik kaydırmanın hedefi (0.25) kuşağın içinde olmalı; olmasaydı
      // her kaydırma bir sonrakini tetikler ve liste sonsuz kayardı.
      expect(isComfortable(0.25), isTrue);
    });

    test('ekranın ortasındaki ayet rahat sayılır', () {
      expect(isComfortable(0.5), isTrue);
    });

    test('üst kenara yapışmış ayet için kaydırılır', () {
      // Ayet ekranın en tepesindeyse okuma alanı altında kalmıştır;
      // kullanıcı sıradaki satırları göremez.
      expect(isComfortable(0.02), isFalse);
    });

    test('alt yarıya inen ayet için kaydırılır', () {
      // Ayet dibe değene kadar beklenmez: o noktada tilavet zaten görünmeyen
      // bir satırdan devam ediyor olurdu.
      expect(isComfortable(0.8), isFalse);
    });

    test('ekranın dışına çıkmış ayet için kaydırılır', () {
      expect(isComfortable(1.2), isFalse);
      expect(isComfortable(-0.3), isFalse);
    });

    test('kuşak sınırları kapsayıcı', () {
      expect(isComfortable(0.10), isTrue);
      expect(isComfortable(0.65), isTrue);
    });

    test('kaydırma hedefi kuşağın ortasına yakın', () {
      // 0.25 seçildi: üstte başlık için pay bırakır, altta okunacak metin
      // kalır. Kuşağın tam kenarında olsaydı küçük bir kayma bile yeni bir
      // kaydırma tetiklerdi.
      const target = 0.25;
      expect(target, greaterThan(0.10));
      expect(target, lessThan(0.65));
    });
  });
}
