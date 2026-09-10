import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/assistant_intent.dart';
import 'widgets/assistant_ayah_card.dart';

/// Bir asistan cevabının bütün sonuçları.
///
/// Sohbet balonu cevabın özetidir: bir cümle ve ilk birkaç ayet. Altmış
/// sonucu oraya sığdırmak balonu okunmaz hâle getiriyordu — eski "daha fazla
/// göster" düğmesi üç ayet daha ekliyor, kullanıcı yirmi kez basıyordu.
///
/// Liste artık kendi sayfasında: sohbet temiz kalır, sonuçlar da kaydırılıp
/// baştan sona okunabilir.
///
/// Sayfa veriyi sağlayıcıdan değil çağıran mesajdan alır. Sebebi: kullanıcı
/// sohbette ilerledikten sonra eski bir cevabın listesini açabilmeli, oysa
/// sağlayıcıdaki havuz her yeni soruda değişir.
class AssistantResultsScreen extends StatelessWidget {
  const AssistantResultsScreen({
    super.key,
    required this.title,
    required this.ayahs,
    required this.languageCode,
  });

  /// Başlıkta görünen konu: "sabır", "Muhammed", "Bakara".
  final String title;

  final List<AnswerAyah> ayahs;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: canPopRoute(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(
                'assistant.resultCount'.tr(
                  namedArgs: {'count': '${ayahs.length}'},
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: ReadableWidth(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: ayahs.length,
              itemBuilder: (context, index) => AssistantAyahCard(
                answer: ayahs[index],
                languageCode: languageCode,
                showDivider: index < ayahs.length - 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
