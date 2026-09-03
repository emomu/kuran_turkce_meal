// Uygulama içindeki yasal metinlerden mağaza formu için HTML sayfaları üretir.
//
// Kullanım:
//   dart run tool/build_privacy_html.dart
//
// Çıktı: store/privacy-policy.html, store/terms.html
//
// Mağazalar gizlilik politikasının herkese açık bir URL'de bulunmasını ister.
// Metnin tek kaynağı lib/features/legal/data/legal_texts.dart olsun diye
// sayfalar oradan üretilir; metin değişince bu araç yeniden çalıştırılır ve
// iki yer birbirinden ayrışmaz.

import 'dart:io';

import '../lib/features/legal/data/legal_texts.dart';

void main() {
  _write(
    'store/privacy-policy.html',
    trTitle: 'Gizlilik Politikası — Kur\'an Meal',
    enTitle: 'Privacy Policy — Kur\'an Meal',
    tr: LegalTexts.privacy('tr'),
    en: LegalTexts.privacy('en'),
  );

  _write(
    'store/terms.html',
    trTitle: 'Kullanım Şartları — Kur\'an Meal',
    enTitle: 'Terms of Use — Kur\'an Meal',
    tr: LegalTexts.terms('tr'),
    en: LegalTexts.terms('en'),
  );

  stdout.writeln('store/privacy-policy.html ve store/terms.html yazıldı.');
}

void _write(
  String path, {
  required String trTitle,
  required String enTitle,
  required String tr,
  required String en,
}) {
  final html = '''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$trTitle</title>
<style>
  :root { color-scheme: light dark; }
  body {
    max-width: 42rem;
    margin: 0 auto;
    padding: 2rem 1.25rem 4rem;
    font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #faf9f6;
    color: #1c1b18;
  }
  @media (prefers-color-scheme: dark) {
    body { background: #14130f; color: #f0eee8; }
    hr { border-color: #33312b; }
  }
  h1 { font-size: 1.75rem; letter-spacing: -0.02em; }
  h2 { font-size: 1.1rem; margin-top: 2rem; }
  hr { border: 0; border-top: 1px solid #ddd9d0; margin: 3rem 0; }
  code, .lang { opacity: 0.6; font-size: 0.85rem; }
</style>
</head>
<body>
${_render(tr)}
<hr>
<section lang="en">
${_render(en)}
</section>
</body>
</html>
''';

  File(path).writeAsStringSync(html);
}

/// Basit işaretlemeyi (# başlık, - madde, **kalın**) HTML'e çevirir.
String _render(String source) {
  final buffer = StringBuffer();

  for (final rawBlock in source.trim().split(RegExp(r'\n\s*\n'))) {
    final block = rawBlock.trim();
    if (block.isEmpty) continue;

    if (block.startsWith('## ')) {
      buffer.writeln('<h2>${_inline(block.substring(3).trim())}</h2>');
    } else if (block.startsWith('# ')) {
      buffer.writeln('<h1>${_inline(block.substring(2).trim())}</h1>');
    } else if (block.startsWith('- ')) {
      buffer.writeln('<ul>');
      for (final line in block.split('\n')) {
        final item = line.trim();
        if (!item.startsWith('- ')) continue;
        buffer.writeln('  <li>${_inline(item.substring(2).trim())}</li>');
      }
      buffer.writeln('</ul>');
    } else {
      buffer.writeln('<p>${_inline(block.replaceAll('\n', ' '))}</p>');
    }
  }

  return buffer.toString();
}

String _inline(String text) {
  final escaped = text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  return escaped.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (m) => '<strong>${m.group(1)}</strong>',
  );
}
