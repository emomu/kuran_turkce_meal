import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';

/// Sure listesini ada göre süzen alan.
///
/// Ayrı bir arama ekranı yerine listenin başına konur: 114 sure arasından
/// birini bulmak bir arama değil, bir süzme işi. Kullanıcı yazdıkça liste
/// kısalır, ekran değişmez ve aradığını bulunca doğrudan dokunur.
///
/// "Ara" sekmesinden farkı burada net: o sekme ayet *metninde* arar ve
/// sonuçları başka bir ekranda gösterir; bu alan yalnızca sure künyelerine
/// bakar ve mevcut listeyi yerinde daraltır.
class SurahSearchField extends ConsumerStatefulWidget {
  const SurahSearchField({super.key});

  @override
  ConsumerState<SurahSearchField> createState() => _SurahSearchFieldState();
}

class _SurahSearchFieldState extends ConsumerState<SurahSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Metin sağlayıcıda tutulur; alan yeniden kurulduğunda (sekme değişimi)
    // kullanıcının yazdığı geri yüklenir.
    _controller = TextEditingController(text: ref.read(surahQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(surahQueryProvider.notifier).state = '';
    // Klavye kapanır: kullanıcı temizlediyse listeye bakmak istiyordur.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(surahQueryProvider);

    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(surahQueryProvider.notifier).state = value,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'home.searchSurah'.tr(),
        // Alanın görünümü temadan gelir (gömülü yüzey, yuvarlak köşe,
        // odaklanınca vurgu çerçevesi). Burada elle çerçeve tanımlanmaz:
        // "Ara" sekmesindeki alan da aynı temayı kullanıyor ve ikisi
        // birbirinden ayrı görünmemeli.
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        // Temizleme yalnızca yazı varken görünür; boş alanda duran bir
        // çarpı, dokunulacak bir şey varmış izlenimi verir.
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _clear,
              ),
      ),
    );
  }
}
