#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ayet metnindeki yuvarlak tenvinleri standart tenvinlere çevirir.

Kullanım (proje kökünden):
    python3 tool/normalize_tanween.py            # ne değişeceğini gösterir
    python3 tool/normalize_tanween.py --write    # dosyayı günceller

NEDEN
-----
Metin, tenvinin idgam/ihfa ile okunduğu yerlerde yuvarlak tenvin
işaretlerini kullanır (U+08F0, U+08F1, U+08F2). Bu işaretler Unicode'a
2012'de eklendi; ondan önce üretilmiş mushaf fontları onları içermez ve
o karakteri boş kutu (tofu) olarak çizer.

Somut etki: KFGQPC fontlarıyla 6179 ayetin 3506'sında kutu çıkıyordu.

NE KAYBEDİLİYOR
---------------
Yuvarlak tenvin tecvid bilgisi taşır: tenvinin sonraki harfle idgam mı
ihfa mı olacağını gösterir. Standart tenvine çevrildiğinde bu ayrım
silinir — harfler doğru okunur ama mushafın verdiği okuma ipucu gider.

Bu yüzden dönüşüm veriye kalıcı yazılır ve kararı geri almak için
`git revert` gerekir; çalışma anında yapılmaz.

KELİME SINIRI
-------------
Yuvarlak tenvinden sonra gelen yalın elif/ya ayrı bir kelime gibi
yazılır ama tek kelimedir: `هُدࣰ ى` → "hüden". Dönüşüm sırasında aradaki
boşluk da kaldırılır, yoksa kelime ikiye bölünür ve tilavet kelime
vurgusunun hizalaması kayar (`assets/data/segments.bin` kelime sırasına
göre adreslenir).

Boşluk kaldırılmasaydı 6179 ayetin 1731'inde kelime sayısı değişirdi.
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AYAHS = os.path.join(ROOT, 'assets', 'data', 'ayahs.json')

# Yuvarlak tenvin -> standart karşılığı.
TANWEEN = {
    'ࣰ': 'ً',  # fethatan
    'ࣱ': 'ٌ',  # dammatan
    'ࣲ': 'ٍ',  # kesratan
}

# Yuvarlak tenvin + boşluk + (elif ya da elif maksûre). Boşluk kelimeyi
# bölmüş gibi görünür ama tek kelimedir; dönüşümde boşluk da yutulur.
SPLIT_TAIL = re.compile(
    '([{}]) (?=[اى])'.format(''.join(TANWEEN))
)


def convert(text: str) -> str:
    """Bir ayet metnini dönüştürür."""
    # Önce kopuk kuyruk birleştirilir, sonra kalan tenvinler çevrilir.
    # Sıra önemli: ters yapılsaydı desen artık eşleşmezdi.
    text = SPLIT_TAIL.sub(lambda m: TANWEEN[m.group(1)], text)
    return ''.join(TANWEEN.get(c, c) for c in text)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--write',
        action='store_true',
        help='değişikliği dosyaya yaz (varsayılan: yalnızca rapor)',
    )
    args = parser.parse_args()

    with open(AYAHS, encoding='utf-8') as f:
        ayahs = json.load(f)

    changed = 0
    marks = 0
    joins = 0
    sample = None

    for ayah in ayahs:
        original = ayah.get('arabic')
        if not original:
            continue
        marks += sum(original.count(c) for c in TANWEEN)
        joins += len(SPLIT_TAIL.findall(original))

        converted = convert(original)
        if converted != original:
            changed += 1
            if sample is None:
                sample = (ayah['surah_number'], ayah['ayah_number'],
                          original, converted)
            if args.write:
                ayah['arabic'] = converted

    print(f'Yuvarlak tenvin işareti : {marks}')
    print(f'Birleştirilen kuyruk    : {joins}')
    print(f'Etkilenen ayet          : {changed} / {len(ayahs)}')

    if sample:
        surah, number, before, after = sample
        print()
        print(f'Örnek — {surah}:{number}')
        print(f'  önce : {before[:60]}')
        print(f'  sonra: {after[:60]}')

    if args.write:
        with open(AYAHS, 'w', encoding='utf-8') as f:
            json.dump(ayahs, f, ensure_ascii=False, separators=(',', ':'))
        print()
        print(f'Yazıldı: {AYAHS}')
        print('Sonra çalıştırın: python3 tool/build_roots.py')
    else:
        print()
        print('Yazmak için: python3 tool/normalize_tanween.py --write')

    return 0


if __name__ == '__main__':
    sys.exit(main())
