#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tilavet kelime zamanlamalarını uygulamanın asset biçimine dönüştürür.

Tilavet çalarken okunan kelimenin vurgulanabilmesi için her kelimenin ses
dosyası içindeki başlangıç/bitiş anı gerekir. Kari kayıtları (EveryAyah) bu
bilgiyi vermez; yalnızca ayet başına bir MP3 sunar. Bu araç, aynı kayıtlar
üzerinde hizalama yapılmış açık veriyi alıp uygulamanın ayet bloklarına
uydurur.

Kullanım (proje kökünden):
    python3 tool/build_segments.py

Girdiler
--------
tool/segments_data/<kari>.json
    quran-align çıktısı. Depoya dahil DEĞİLDİR (~28 MB); ilk çalıştırmadan
    önce indirin:

        curl -L -o /tmp/quran-align.zip \
          https://github.com/cpfair/quran-align/releases/download/release-2016-11-24/quran-align-data-2016-11-24.zip
        unzip -o /tmp/quran-align.zip -d tool/segments_data/

assets/data/ayahs.json
    Uygulamanın ayet verisi; kelime hizalaması buna göre yapılır.

Çıktı
-----
assets/data/segments.bin — ikili paket (bkz. BİÇİM)
assets/data/segments_meta.json — kari kapsamı ve sürüm künyesi

Neden ikili
-----------
JSON olarak beş kari ~5 MB tutuyordu ve açılışta ayrıştırma maliyeti
vardı. Zamanlamalar yalnızca artan tamsayılardır; ikili paket aynı veriyi
~1.7 MB'a indirir ve uygulama yalnızca çalan ayetin birkaç baytını okur —
dosyanın tamamı belleğe alınmaz.

Süreler milisaniye yerine TICK_MS adımıyla saklanır. En kısa kelime 250 ms
(binde birlik uç 20 ms) olduğu için 20 ms'lik yuvarlama vurguda
görünmez, ama alanı yarıya indirir: u32 yerine u16 yeter.

BİÇİM
-----
Başlık:
    magic   4s   'QSEG'
    version u8   1
    reciter u8   pakette kaç kari var
Her kari için künye (sabit 32 bayt):
    id      24s  kari kimliği (utf-8, sıfır dolgulu)
    offset  u32  bu karinin dizin tablosunun dosya içindeki yeri
    count   u32  ayet sayısı
Dizin (her ayet için 12 bayt, sure/ayet sırasında):
    key     u32  surah * 1000 + ayah
    off     u32  segment verisinin yeri
    n       u32  kelime sayısı
Segment verisi (kelime başına 4 bayt):
    start   u16  TICK_MS'in katı olarak süre
    end     u16  TICK_MS'in katı olarak süre

LİSANS
------
Zamanlama verisi cpfair/quran-align'dan gelir ve Creative Commons
Attribution 4.0 ile dağıtılır; kaynağın belirtilmesini şart koşar.
Ayarlar ekranındaki atıf satırı bu şartı karşılar
(settings.segmentsAttribution), kaldırmayın.
"""

import json
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = os.path.join(HERE, 'segments_data')
AYAHS = os.path.join(ROOT, 'assets', 'data', 'ayahs.json')
OUT_BIN = os.path.join(ROOT, 'assets', 'data', 'segments.bin')
OUT_META = os.path.join(ROOT, 'assets', 'data', 'segments_meta.json')

# Kelime bölme kuralı ayet verisiyle aynı olmalı: kök analizinde kullanılan
# bölücü buraya da uygulanır, aksi halde kelime indeksleri kayardı.
sys.path.insert(0, HERE)
from build_roots import split_words  # noqa: E402

# Uygulamadaki kari kimliği -> quran-align dosya adı.
#
# Bitrate'i uyuşmayan iki kayıt var (Husary, Abdul Basit). Zamanlama aynı
# kayıttan çıkarıldığı için bitrate farkı süreleri değiştirmez: aynı
# performansın farklı sıkıştırması. Kimlikler lib/data/models/reciter.dart
# ile birebir aynı tutulmalı.
RECITERS = {
    'alafasy': 'Alafasy_128kbps',
    'husary': 'Husary_64kbps',
    'abdulbasit': 'Abdul_Basit_Murattal_64kbps',
    'sudais': 'Abdurrahmaan_As-Sudais_192kbps',
    'minshawi': 'Minshawy_Murattal_128kbps',
}

VERSION = 1
ID_LEN = 24

# Zamanlama çözünürlüğü. Süreler bu adımın katı olarak saklanır; okuyucu
# tarafı geri çarpar. Değer değişirse okuyucudaki karşılığı da değişmeli
# (bkz. lib/data/repositories/segment_repository.dart).
TICK_MS = 20


def load_alignment(path):
    """quran-align çıktısını (sure, ayet) -> [(start_ms, end_ms)] sözlüğüne çevirir.

    Kaynak biçiminde her segment [ilk_kelime, son_kelime_sonrası, başlangıç,
    bitiş] dörtlüsüdür; bir segment birden çok kelimeyi kapsayabilir (kari
    kelimeleri bitiştirmişse). Vurgulama kelime başına yapıldığı için
    çok kelimeli segmentler kelimelere bölünür: süre kelime sayısına eşit
    paylaştırılır. Bu bir tahmindir, ama vurgunun kelime atlamasından
    iyidir.
    """
    out = {}
    for entry in read_entries(path):
        words = {}
        for seg in entry['segments']:
            first, after_last, start, end = seg[0], seg[1], seg[2], seg[3]
            span = max(1, after_last - first)
            step = (end - start) / span
            for k in range(span):
                words[first + k] = (
                    int(start + step * k),
                    int(start + step * (k + 1)),
                )
        if not words:
            continue
        count = max(words) + 1
        # Tanınmayan kelime varsa (hizalayıcı atlamışsa) boşluk bırakmak
        # yerine bir öncekinin bitişine sıfır uzunlukta oturtulur; okuyucu
        # tarafı böylece her indekste bir değer bulur.
        prev_end = 0
        seq = []
        for i in range(count):
            if i in words:
                s, e = words[i]
            else:
                s = e = prev_end

            # Kaynak veride birkaç bozuk segment var: bitişi başlangıcından
            # önce ya da bir öncekinin gerisinde. Zaman ekseni geri sarsaydı
            # vurgu o kelimede sıçrardı; sıra zorlanır ve süre en az sıfıra
            # çekilir.
            s = max(s, prev_end)
            e = max(e, s)
            prev_end = e
            seq.append((s, e))
        out[(entry['surah'], entry['ayah'])] = seq
    return out


def read_entries(path):
    """Hizalama dosyasını okur; kirlenmiş dosyaları kurtarır.

    Yayınlanan veri setinde bir dosya (Sudais) bozuk: hizalayıcının çökme
    günlüğü JSON'un başına karışmış. Dosya satır satır denenir ve geçerli
    JSON dizisini taşıyan satır kullanılır. Bu, kaynağı elle düzeltmek
    zorunda kalmamak içindir — indirme komutu her çalıştığında aynı bozuk
    dosya gelir.
    """
    with open(path, encoding='utf-8', errors='replace') as f:
        raw = f.read()

    try:
        return json.loads(raw)
    except ValueError:
        pass

    for line in raw.split('\n'):
        line = line.strip()
        if not line.startswith('['):
            continue
        try:
            entries = json.loads(line)
        except ValueError:
            continue
        if isinstance(entries, list) and entries:
            return entries

    raise SystemExit('Okunamayan hizalama dosyası: %s' % path)


def block_segments(ayah, align):
    """Bir ayet bloğunun kelime zamanlamalarını döndürür.

    Tek ayetlik blokta hizalama doğrudan kullanılır. Birleşik bloklarda
    (bir meal bloğu birden çok ayeti karşılar) blok tek bir ses gibi
    çalınmaz — her ayetin kendi MP3'ü vardır ve arka arkaya dizilir. Bu
    yüzden zamanlamalar birleştirilmez; her ayetin kendi zaman ekseni
    korunur ve okuyucu tarafı çalan ayetin dilimini kullanır.

    Dönen değer: {ayet_numarası: [(start, end), ...]} — hizalama tutmayan
    ayetler atlanır.
    """
    sn = ayah['surah_number']
    lines = ayah['arabic'].split('\n')
    nums = list(range(ayah['ayah_number'], ayah['end_ayah_number'] + 1))

    # Birleşik blokta satır sayısı ayet sayısını vermelidir; vermiyorsa
    # hizalama güvenilmez, blok tamamen atlanır. Yanlış vurgu, vurgusuzluktan
    # kötüdür.
    if len(lines) != len(nums):
        return {}, len(nums)

    out = {}
    skipped = 0
    for num, line in zip(nums, lines):
        seq = align.get((sn, num))
        if seq is None:
            skipped += 1
            continue
        # Kelime sayısı tutmuyorsa vurgu kayar; o ayet atlanır ve uygulama
        # o ayette ayet düzeyinde vurguya düşer.
        if len(seq) != len(split_words(line)):
            skipped += 1
            continue
        out[num] = seq
    return out, skipped


def main():
    if not os.path.isdir(DATA):
        sys.exit(
            'Girdi klasörü yok: %s\n'
            'Dosya başındaki indirme komutunu çalıştırın.' % DATA
        )

    with open(AYAHS, encoding='utf-8') as f:
        ayahs = json.load(f)

    packed = {}
    meta_reciters = []

    for rid, filename in RECITERS.items():
        path = os.path.join(DATA, filename + '.json')
        if not os.path.exists(path):
            print('  atlandı (dosya yok): %s' % filename)
            continue

        align = load_alignment(path)
        entries = []
        skipped = 0
        for a in ayahs:
            seqs, miss = block_segments(a, align)
            skipped += miss
            for num, seq in seqs.items():
                entries.append((a['surah_number'] * 1000 + num, seq))

        entries.sort(key=lambda e: e[0])
        packed[rid] = entries

        total = sum(a['end_ayah_number'] - a['ayah_number'] + 1 for a in ayahs)
        covered = len(entries)
        print(
            '  %-12s %5d/%d ayet (%%%.2f), atlanan %d'
            % (rid, covered, total, 100.0 * covered / total, skipped)
        )
        meta_reciters.append({
            'id': rid,
            'source': filename,
            'ayahCount': covered,
            'coverage': round(100.0 * covered / total, 2),
        })

    if not packed:
        sys.exit('Hiçbir kari verisi bulunamadı.')

    write_binary(packed)

    with open(OUT_META, 'w', encoding='utf-8') as f:
        json.dump(
            {
                'version': VERSION,
                'source': 'cpfair/quran-align release-2016-11-24',
                'license': 'CC BY 4.0',
                'reciters': meta_reciters,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    size = os.path.getsize(OUT_BIN)
    print('\nYazıldı: %s (%.2f MB)' % (OUT_BIN, size / 1024.0 / 1024.0))
    print('Yazıldı: %s' % OUT_META)


def to_ticks(ms):
    """Milisaniyeyi TICK_MS adımına yuvarlar ve u16 sınırına sıkıştırır.

    Sınırı aşan tek durum çok uzun ayetlerin sonudur (u16 ile ~21 dakika);
    kaynak veride en uzun ayet 259 saniye olduğu için pratikte
    erişilmez. Yine de taşma sessizce sarmasın diye kırpılır.
    """
    return min(65535, int(round(ms / float(TICK_MS))))


def write_binary(packed):
    """Paketi dosya başındaki BİÇİM bölümüne göre yazar."""
    ids = sorted(packed)

    header = struct.pack('<4sBB', b'QSEG', VERSION, len(ids))
    # Künye tablosu sabit boyutlu: baştan yerleri hesaplanabilsin diye.
    directory_start = len(header) + len(ids) * 32

    index_blobs = []
    data_blobs = []

    cursor = directory_start
    # Önce her karinin dizin tablosu, sonra segment verisi gelir. İki geçiş
    # gerekir: dizin, veri konumlarını içerir.
    data_start = directory_start + sum(len(packed[i]) * 12 for i in ids)

    data_cursor = data_start
    catalogue = []

    for rid in ids:
        entries = packed[rid]
        catalogue.append((rid, cursor, len(entries)))

        index = bytearray()
        data = bytearray()
        for key, seq in entries:
            index += struct.pack('<III', key, data_cursor + len(data), len(seq))
            for start, end in seq:
                data += struct.pack(
                    '<HH', to_ticks(start), to_ticks(end)
                )

        index_blobs.append(bytes(index))
        data_blobs.append(bytes(data))
        cursor += len(index)
        data_cursor += len(data)

    out = bytearray(header)
    for rid, offset, count in catalogue:
        out += struct.pack(
            '<%dsII' % ID_LEN, rid.encode('utf-8')[:ID_LEN], offset, count
        )
    for blob in index_blobs:
        out += blob
    for blob in data_blobs:
        out += blob

    with open(OUT_BIN, 'wb') as f:
        f.write(out)


if __name__ == '__main__':
    main()
