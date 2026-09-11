import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_typography.dart';

/// Kabuk dışı keşif ekranlarının üst çubuğu.
///
/// Material'ın `AppBar`'ı yerine kullanılır: o, yükseklik gölgesi ve kendi
/// geri düğmesi davranışıyla gelir; buradaki geri ise [popOrHome] olmalı —
/// bu ekranlara derin bağlantıyla doğrudan gelindiğinde yığın boştur ve düz
/// bir `pop` kullanıcıyı boş ekranda bırakırdı.
class TopicAppBar extends StatelessWidget {
  const TopicAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safe = MediaQuery.paddingOf(context);

    return Container(
      height: 48,
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: Insets.xs + safe.left,
        right: Insets.xs + safe.right,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => popOrHome(context),
            tooltip: 'common.back'.tr(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          // Geri düğmesinin karşılığı: başlık gerçekten ortada dursun.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
