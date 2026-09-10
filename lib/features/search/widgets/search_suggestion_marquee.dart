import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../shared/widgets/pressable.dart';

/// Arama kutusu boşken ne yazılabileceğini gösteren kayan öneri şeridi.
///
/// Boş bir arama ekranı kullanıcıya yalnızca "bir şey yaz" der; neyin
/// çalıştığını söylemez. Bu şerit üç satırda örnek gösterir: bir konu, bir
/// ayet referansı, bir peygamber adı. Kullanıcı okumak zorunda değil —
/// göz ucuyla bakınca da aramanın kelimeden fazlasını anladığı görünür.
///
/// Satırlar farklı hızlarda ve zıt yönlerde akar. Aynı hızda aynı yöne
/// aksalardı üç şerit tek bir blok gibi okunur, hareket de mekanikleşirdi;
/// kayma farkı şeride derinlik veriyor.
///
/// Dokunulabilir: bir öneriye basmak onu arama kutusuna yazar. Süs değil,
/// kısayol.

/// Tek bir kayan satır.
class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow({
    required this.items,
    required this.duration,
    required this.reverse,
    required this.onTap,
  });

  final List<String> items;

  /// Şeridin bir turu tamamlaması süresi. Uzun süre = yavaş akış.
  final Duration duration;

  /// Sağdan sola değil soldan sağa aksın.
  final bool reverse;

  final void Function(String) onTap;

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  /// Tek kopyanın ölçülen genişliği. Kaydırma buna göre yapılır; ölçülene
  /// kadar şerit yerinde durur (bir kare).
  double? _rowWidth;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Liste iki kez yan yana çizilir: biri ekrandan çıkarken diğeri girer,
    // böylece akış kesintisiz görünür. Tek kopya olsaydı şerit bitince
    // boşluk kalır ve baştan zıplardı.
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in widget.items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _SuggestionChip(
              label: item,
              onTap: () => widget.onTap(item),
            ),
          ),
      ],
    );

    return SizedBox(
      height: 36,
      child: ClipRect(
        // Şerit ekrandan geniştir; `OverflowBox` genişlik sınırını kaldırır,
        // `ClipRect` de taşan kısmı keser. Bu ikisi olmadan Flutter satırı
        // ekrana sığdırmaya çalışıp taşma uyarısı çiziyordu.
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Kaydırma içeriğin kendi genişliğine göre yapılır: tam bir
              // kopya kadar kayınca ikinci kopya birincinin yerine oturur
              // ve döngü görünmez olur. Ekran genişliğine göre kaydırmak
              // her turda sıçramaya yol açıyordu.
              final width = _rowWidth ?? 0;
              final t = widget.reverse
                  ? _controller.value - 1
                  : -_controller.value;
              return Transform.translate(
                offset: Offset(t * width, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ölçüm yalnızca ilk kopyada yapılır; ikincisi onun eşi.
                _MeasureSize(
                  onChange: (size) {
                    if (_rowWidth == size.width) return;
                    // Ölçü çizim sırasında gelir; kareyi bozmamak için
                    // sonraki kareye bırakılır.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _rowWidth = size.width);
                    });
                  },
                  child: row,
                ),
                row,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Çocuğunun ölçüsünü çizim sonrası bildiren yardımcı.
///
/// Kayan şeridin kaç piksel kayacağı ancak içerik çizildikten sonra
/// bilinebilir; `LayoutBuilder` bunu vermez çünkü o ebeveynin sınırlarını
/// söyler, çocuğun gerçek genişliğini değil.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final void Function(Size) onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRender(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRender renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRender extends RenderProxyBox {
  _MeasureSizeRender(this.onChange);

  void Function(Size) onChange;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _old) return;
    _old = size;
    onChange(size);
  }
}

/// Şeritteki tek bir öneri.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

/// Üç katlı kayan öneri şeridi.
class SearchSuggestionMarquee extends StatelessWidget {
  const SearchSuggestionMarquee({
    super.key,
    required this.languageCode,
    required this.onPick,
  });

  final String languageCode;

  /// Bir öneriye dokunulduğunda çağrılır; metin arama kutusuna yazılır.
  final void Function(String) onPick;

  /// Konu örnekleri — aramanın kelime eşleşmesi yaptığını gösterir.
  static const _topicsTr = [
    'sabır', 'adalet', 'rahmet', 'tövbe', 'şükür', 'namaz',
    'yetim', 'komşu', 'ilim', 'sözünde durmak',
  ];
  static const _topicsEn = [
    'patience', 'justice', 'mercy', 'repentance', 'gratitude', 'prayer',
    'orphan', 'neighbour', 'knowledge', 'keeping promises',
  ];

  /// Referans örnekleri — sayıyla doğrudan ayete gidilebildiğini gösterir.
  /// Biçim çeşitliliği bilinçli: iki nokta, boşuk ve sure adı hepsi çalışır.
  static const _refsTr = [
    '2:255', 'Yâsîn 2', '36:1', 'Bakara 255', 'Kehf 10', '18:60',
    'Fâtiha', '112', 'Rahmân 13', 'Mülk 1',
  ];
  static const _refsEn = [
    '2:255', 'Ya-Sin 2', '36:1', 'Al-Baqarah 255', 'Al-Kahf 10', '18:60',
    'Al-Fatihah', '112', 'Ar-Rahman 13', 'Al-Mulk 1',
  ];

  /// Peygamber adları — kıssa ekranına götüren aramayı gösterir.
  static const _prophetsTr = [
    'Yûsuf', 'Mûsâ', 'İbrâhim', 'Nûh', 'Îsâ', 'Meryem',
    'Süleyman', 'Lût', 'Yûnus', 'Muhammed',
  ];
  static const _prophetsEn = [
    'Joseph', 'Moses', 'Abraham', 'Noah', 'Jesus', 'Mary',
    'Solomon', 'Lot', 'Jonah', 'Muhammad',
  ];

  @override
  Widget build(BuildContext context) {
    final en = languageCode == 'en';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Üç satır üç ayrı arama biçimini örnekler: konu, referans, kişi.
        // Hızlar birbirinin katı değil — öyle olsaydı satırlar düzenli
        // aralıklarla hizalanır ve göz bunu bir desen olarak yakalardı.
        _MarqueeRow(
          items: en ? _topicsEn : _topicsTr,
          duration: const Duration(seconds: 26),
          reverse: false,
          onTap: onPick,
        ),
        const SizedBox(height: 8),
        _MarqueeRow(
          items: en ? _refsEn : _refsTr,
          duration: const Duration(seconds: 33),
          reverse: true,
          onTap: onPick,
        ),
        const SizedBox(height: 8),
        _MarqueeRow(
          items: en ? _prophetsEn : _prophetsTr,
          duration: const Duration(seconds: 29),
          reverse: false,
          onTap: onPick,
        ),
      ],
    );
  }
}
