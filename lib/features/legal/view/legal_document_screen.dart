import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/responsive_layout.dart';

/// Gizlilik politikası, kullanım şartları ve kaynak bildirimi ekranı.
///
/// Metinler basit bir işaretleme diliyle yazılır (`#` başlık, `-` madde,
/// `**kalın**`) ve burada temanın tipografisiyle çizilir. Tam bir markdown
/// paketi eklenmedi: kullanılan biçimler bir avuç kadar ve yasal metnin
/// okunaklı olması için sayfa düzeni üzerinde doğrudan denetim gerekiyor.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: theme.textTheme.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          // Hukuki metin uzun soluklu bir okuma; yatayda satır uzunluğu
          // ayet metniyle aynı sınıra oturur.
          padding: centeredContentPadding(
            context,
            maxWidth: ContentWidth.reading,
            top: Insets.md,
            bottom: MediaQuery.paddingOf(context).bottom + Insets.xxl,
          ),
          children: _render(context, body),
        ),
      ),
    );
  }

  /// İşaretlenmiş metni widget listesine çevirir.
  List<Widget> _render(BuildContext context, String source) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    // Paragraflar boş satırla ayrılır; madde listeleri tek blok sayılır.
    for (final rawBlock in source.trim().split(RegExp(r'\n\s*\n'))) {
      final block = rawBlock.trim();
      if (block.isEmpty) continue;

      if (block.startsWith('# ')) {
        widgets
          ..add(Text(
            block.substring(2).trim(),
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28),
          ))
          ..add(const SizedBox(height: Insets.md));
        continue;
      }

      if (block.startsWith('## ')) {
        widgets
          ..add(const SizedBox(height: Insets.sm))
          ..add(Text(
            block.substring(3).trim(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ))
          ..add(const SizedBox(height: Insets.xs));
        continue;
      }

      // Madde listesi — her satır ayrı bir madde.
      if (block.startsWith('- ')) {
        for (final line in block.split('\n')) {
          final item = line.trim();
          if (!item.startsWith('- ')) continue;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(
                left: Insets.xs,
                bottom: Insets.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: Insets.xs),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      _inline(context, item.substring(2).trim()),
                      style: _bodyStyle(theme),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        widgets.add(const SizedBox(height: Insets.xs));
        continue;
      }

      // Düz paragraf. Kaynaktaki satır sarmaları kaldırılır, metin ekran
      // genişliğine göre yeniden sarılsın.
      widgets
        ..add(Text.rich(
          _inline(context, block.replaceAll('\n', ' ')),
          style: _bodyStyle(theme),
        ))
        ..add(const SizedBox(height: Insets.sm));
    }

    return widgets;
  }

  TextStyle? _bodyStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(height: 1.55);

  /// `**kalın**` işaretlemesini çözer.
  TextSpan _inline(BuildContext context, String text) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    return TextSpan(children: spans);
  }
}
