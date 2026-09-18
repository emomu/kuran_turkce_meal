#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kelime bölme kuralının beklenen çıktısını test verisine yazar.

Vurgunun doğru kelimede durması, üretim aracındaki bölücü ile ekrandaki
bölücünün aynı sonucu vermesine bağlı. İkisi ayrı dillerde yazıldığı için
eşitlik ancak karşılaştırılarak korunabilir: bu araç `tool/` tarafının
sonucunu dosyaya yazar, `test/arabic_word_split_test.dart` Dart tarafını ona
karşı doğrular.

Ayet metni değiştiğinde ya da bölme kuralı elden geçtiğinde yeniden
çalıştırın:
    python3 tool/dump_word_splits.py

Çıktı
-----
test/data/word_splits.json — [{ "t": ayet satırı, "n": kelime sayısı }, ...]
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
AYAHS = os.path.join(ROOT, 'assets', 'data', 'ayahs.json')
OUT = os.path.join(ROOT, 'test', 'data', 'word_splits.json')

sys.path.insert(0, HERE)
from build_roots import split_words  # noqa: E402


def main():
    with open(AYAHS, encoding='utf-8') as f:
        ayahs = json.load(f)

    rows = []
    for ayah in ayahs:
        # Birleşik bloklarda her ayet ayrı satırdır; bölme satır satır
        # yapılır, tıpkı zamanlama üretiminde olduğu gibi.
        for line in ayah['arabic'].split('\n'):
            rows.append({'t': line, 'n': len(split_words(line))})

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False)

    print('Yazıldı: %s (%d satır)' % (OUT, len(rows)))


if __name__ == '__main__':
    main()
