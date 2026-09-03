#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kuran kök verisini uygulamanın asset biçimine dönüştürür.

Kullanım (proje kökünden):
    python3 tool/build_roots.py

Girdiler
--------
tool/roots_data/quran-morphology.txt
    Quranic Arabic Corpus 0.4 morfolojik çözümlemesi. Depoya dahil DEĞİLDİR
    (6 MB); ilk çalıştırmadan önce indirin:

        curl -L -o tool/roots_data/quran-morphology.txt \
          https://raw.githubusercontent.com/mustafa0x/quran-morphology/master/quran-morphology.txt

tool/roots_data/roots_tr_merged.json
    Türkçe kök anlamları (Kuran-Rehberi reposundan birleştirildi).
tool/roots_data/missing_tr.json
    Korpusta olup sözlükte bulunmayan 57 kökün elle yazılmış anlamı.
tool/roots_data/synonyms_tr.json
    Sık köklerin eş anlamlı ve çekimli karşılıkları. Meal içi vurgulama
    kökün Türkçe karşılığını metinde arar; tek karşılık ("söylemek")
    mealdeki çekimi ("derler") yakalayamıyordu.
tool/roots_data/word-translations-tr.json
    Lemma (kelime) çevirileri.
assets/data/ayahs.json
    Uygulamanın mevcut ayet verisi; kelime hizalaması buna göre yapılır.

Çıktı
-----
assets/data/roots.json — { version, source, letters, roots[], words[] }

LİSANS
------
Morfoloji verisi Quranic Arabic Corpus'tan gelir; GPL ile dağıtılır ve
kaynağın belirtilmesini şart koşar. Uygulamada Ayarlar ekranının altındaki
atıf satırı bu şartı karşılar (roots.sourceLabel), kaldırmayın.
"""
import json, os, re, collections

# Yollar proje köküne göredir; betik tool/ içinden de çalıştırılabilsin diye
# kök, bu dosyanın konumundan türetilir.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'tool', 'roots_data')

MORPH = os.path.join(DATA, 'quran-morphology.txt')
AYAHS = os.path.join(ROOT, 'assets', 'data', 'ayahs.json')
OUT   = os.path.join(ROOT, 'assets', 'data', 'roots.json')

# ---------------------------------------------------------------- yardımcılar

# Yuvarlak tenvin: bu işaretten sonra gelen yalın elif/ya ayrı kelime değildir.
ROUND_TANWEEN = re.compile('[ࣰࣱࣲ]')
# Sadece elif/ya + duraklama işaretlerinden oluşan artık parça.
TANWEEN_TAIL = re.compile('^[اى][ؐ-ؚۖ-ࣰۭ-ࣿ]*$')

HARAKAT = re.compile('[ؐ-ًؚ-ٰٟۖ-ࣰۭ-ࣿـ]')

def strip_harakat(s: str) -> str:
    """Harekeleri ve duraklama işaretlerini atar, iskeleti bırakır."""
    return HARAKAT.sub('', s)

def normalize_letters(s: str) -> str:
    """Hemze ve elif varyantlarını tek biçime indirger."""
    for a, b in (('آ','ا'), ('أ','ا'), ('إ','ا'),
                 ('ٱ','ا'), ('ؤ','ء'), ('ئ','ء'),
                 ('ى','ي'), ('ة','ه')):
        s = s.replace(a, b)
    return s

def split_words(text: str):
    """Ayet metnini kelimelere böler, tenvin artığını önceki kelimeye yapıştırır."""
    out = []
    for tok in text.split():
        if out and ROUND_TANWEEN.search(out[-1]) and TANWEEN_TAIL.match(tok):
            out[-1] += tok
        else:
            out.append(tok)
    return out

# Arap harfi -> fonetik latin karşılığı (arama için).
# Birden çok karşılık verilebilir; kullanıcı hangisini yazarsa yazsın bulsun.
TRANSLIT = {
    'ء': ['', 'a', 'e'],          # ء hemze
    'ا': ['a', 'e', ''],          # ا elif
    'ب': ['b'],                   # ب be
    'ت': ['t'],                   # ت te
    'ث': ['s', 'th'],             # ث se
    'ج': ['c', 'j'],              # ج cim
    'ح': ['h'],                   # ح ha
    'خ': ['h', 'kh', 'x'],        # خ hı
    'د': ['d'],                   # د dal
    'ذ': ['z', 'dh'],             # ذ zel
    'ر': ['r'],                   # ر re
    'ز': ['z'],                   # ز ze
    'س': ['s'],                   # س sin
    'ش': ['s', 'sh', 'ş'],        # ش şın
    'ص': ['s'],                   # ص sad
    'ض': ['d', 'dh'],             # ض dad
    'ط': ['t'],                   # ط tı
    'ظ': ['z', 'zh'],             # ظ zı
    'ع': ['', 'a'],               # ع ayn
    'غ': ['g', 'gh', 'ğ'],        # غ gayn
    'ف': ['f'],                   # ف fe
    'ق': ['k', 'q'],              # ق kaf
    'ك': ['k'],                   # ك kef
    'ل': ['l'],                   # ل lam
    'م': ['m'],                   # م mim
    'ن': ['n'],                   # ن nun
    'ه': ['h'],                   # ه he
    'و': ['v', 'w', 'u', 'o'],    # و vav
    'ي': ['y', 'i'],              # ي ye
}

# Harf adları — arayüzdeki harf filtresi bunları etiket olarak gösterir.
LETTER_NAMES = {
    'ء': 'hemze', 'ا': 'elif', 'ب': 'be',  'ت': 'te',
    'ث': 'se',    'ج': 'cim',  'ح': 'ha',  'خ': 'hı',
    'د': 'dal',   'ذ': 'zel',  'ر': 're',  'ز': 'ze',
    'س': 'sin',   'ش': 'şın',  'ص': 'sad', 'ض': 'dad',
    'ط': 'tı',    'ظ': 'zı',   'ع': 'ayn', 'غ': 'gayn',
    'ف': 'fe',    'ق': 'kaf',  'ك': 'kef', 'ل': 'lam',
    'م': 'mim',   'ن': 'nun',  'ه': 'he',  'و': 'vav',
    'ي': 'ye',
}

# Harekeli metni Türkçe okunuşa çevirmek için ünsüz karşılıkları.
# Amaç bilimsel transkripsiyon değil, kullanıcının klavyeden yazacağı biçim:
# رَسُول -> "resul", كِتاب -> "kitab".
READING = {
    'ء': '', 'ا': 'a', 'ب': 'b', 'ت': 't', 'ث': 's', 'ج': 'c',
    'ح': 'h', 'خ': 'h', 'د': 'd', 'ذ': 'z', 'ر': 'r', 'ز': 'z',
    'س': 's', 'ش': 'ş', 'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z',
    'ع': '',  'غ': 'g', 'ف': 'f', 'ق': 'k', 'ك': 'k', 'ل': 'l',
    'م': 'm', 'ن': 'n', 'ه': 'h', 'و': 'v', 'ي': 'y',
    'ى': 'a', 'ة': 'e', 'ٱ': 'a', 'أ': 'a', 'إ': 'i', 'آ': 'a',
    'ؤ': 'v', 'ئ': 'y',
}
# Hareke -> sesli harf.
VOWELS = {
    'َ': 'e',  # fetha
    'ُ': 'u',  # damme
    'ِ': 'i',  # kesra
    'ً': 'en', # fethateyn
    'ٌ': 'un', # dammeteyn
    'ٍ': 'in', # kesrateyn
    'ٰ': 'a',  # hançer elif
}
SKIP = {'ْ', 'ّ'}  # sükun, şedde (şedde ünsüzü ikizler ama arama için gereksiz)

def turkish_reading(lemma: str) -> str:
    """
    Harekeli lemmayı kabaca Türkçe okunuşa çevirir.

    Uzun ünlüler ayrıca ele alınır: damme+vav "û", kesra+ya "î" sesidir;
    harf harf çevrilseydi "resûl" yerine "resuvl" çıkardı.
    """
    out = []
    i = 0
    chars = [c for c in lemma if c not in SKIP]
    while i < len(chars):
        ch = chars[i]
        nxt = chars[i + 1] if i + 1 < len(chars) else ''
        # Uzun ünlü çiftleri.
        if ch == 'ُ' and nxt == 'و':
            out.append('u'); i += 2; continue
        if ch == 'ِ' and nxt == 'ي':
            out.append('i'); i += 2; continue
        if ch == 'َ' and nxt in ('ا', 'ى', 'ٰ'):
            out.append('a'); i += 2; continue
        if ch in VOWELS:
            out.append(VOWELS[ch]); i += 1; continue
        if ch in READING:
            out.append(READING[ch]); i += 1; continue
        if HARAKAT.match(ch):
            i += 1; continue
        out.append(ch); i += 1
    s = ''.join(out)
    # Aynı harfin ardışık tekrarını sadeleştir ("ss" -> "s").
    s = re.sub(r'(.)\1+', r'\1', s)
    return s


def translit_variants(root: str, cap: int = 24):
    """Kökün olası latin yazımlarını üretir. 'rsl', 'rasul' değil — iskelet."""
    combos = ['']
    for ch in root:
        opts = TRANSLIT.get(ch, [ch])
        nxt = []
        for pre in combos:
            for o in opts:
                nxt.append(pre + o)
        combos = nxt
        if len(combos) > cap * 8:
            combos = combos[:cap * 8]
    seen, out = set(), []
    for c in combos:
        if c and c not in seen:
            seen.add(c)
            out.append(c)
    return out[:cap]

# ---------------------------------------------------------------- veri okuma

def load_tr_dict():
    d = {}
    d.update(json.load(open(os.path.join(DATA, 'roots_tr_merged.json'), encoding='utf-8')))
    d.update(json.load(open(os.path.join(DATA, 'missing_tr.json'), encoding='utf-8')))
    # En sık köklerin anlamları eş anlamlılarla genişletilir. Meal içi
    # vurgulama kökün Türkçe karşılığını metinde arar; tek karşılık
    # ("söylemek") mealdeki çekimi ("dediler") yakalayamıyordu.
    d.update(json.load(open(os.path.join(DATA, 'synonyms_tr.json'), encoding='utf-8')))
    return d

def load_lemma_tr():
    wt = json.load(open(os.path.join(DATA, 'word-translations-tr.json'), encoding='utf-8'))
    raw = wt.get('translations', {})
    # Lemma anahtarları harekeli; hareketsiz biçimle de erişilebilsin.
    out = {}
    for k, v in raw.items():
        out[k] = v
        out.setdefault(normalize_letters(strip_harakat(k)), v)
    return out

def load_morphology():
    """(surah, ayah) -> [ {w, form, root, lemma, pos}, ... ]"""
    verses = collections.defaultdict(dict)
    for line in open(MORPH, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line:
            continue
        parts = line.split('\t')
        if len(parts) < 4:
            continue
        loc, form, tag, feat = parts[0], parts[1], parts[2], parts[3]
        try:
            s, v, w, seg = map(int, loc.split(':'))
        except ValueError:
            continue
        slot = verses[(s, v)].setdefault(w, {'form': '', 'root': None,
                                             'lemma': None, 'pos': None})
        slot['form'] += form
        rm = re.search(r'ROOT:([^|]+)', feat)
        if rm and not slot['root']:
            slot['root'] = rm.group(1)
            slot['pos'] = tag
        lm = re.search(r'LEM:([^|]+)', feat)
        if lm and not slot['lemma'] and rm:
            slot['lemma'] = lm.group(1)
    return verses

# ---------------------------------------------------------------- hizalama

def align(app_words, corpus_words):
    """
    Uygulama metnindeki kelimeleri korpus kelimeleriyle eşler.
    Dönen liste app_words ile aynı uzunlukta; her eleman korpus indeksi ya da None.

    Sayılar eşitse birebir eşlenir. Değilse iskelet karşılaştırmasıyla
    ilerlenir: uyuşmayan yerde kelimeler birleştirilerek denenir, çünkü
    fark daima bitişik/ayrı yazım kaynaklı (örn. "مَا لَآ" ~ "مَالَآ").
    """
    n, m = len(app_words), len(corpus_words)
    if n == m:
        return list(range(m))

    def skel(x):
        return normalize_letters(strip_harakat(x))

    a = [skel(x) for x in app_words]
    c = [skel(x) for x in corpus_words]
    res = [None] * n
    i = j = 0
    while i < n and j < m:
        if a[i] == c[j]:
            res[i] = j; i += 1; j += 1; continue
        # app tarafında bölünmüş: birkaç app kelimesi tek korpus kelimesi
        merged = a[i]
        k = i
        matched = False
        while k + 1 < n and len(merged) < len(c[j]):
            k += 1
            merged += a[k]
            if merged == c[j]:
                for t in range(i, k + 1):
                    res[t] = j
                i = k + 1; j += 1; matched = True; break
        if matched:
            continue
        # korpus tarafında bölünmüş: tek app kelimesi birkaç korpus kelimesi
        merged = c[j]
        k = j
        matched = False
        while k + 1 < m and len(merged) < len(a[i]):
            k += 1
            merged += c[k]
            if merged == a[i]:
                res[i] = j
                i += 1; j = k + 1; matched = True; break
        if matched:
            continue
        # eşleşmedi; ikisini de ilerlet
        res[i] = j
        i += 1; j += 1
    return res

# ---------------------------------------------------------------- ana akış

def main():
    tr = load_tr_dict()
    lemma_tr = load_lemma_tr()
    morph = load_morphology()
    ayahs = json.load(open(AYAHS, encoding='utf-8'))

    root_occurrences = collections.defaultdict(list)  # root -> [word_index]
    root_lemmas = collections.defaultdict(collections.Counter)
    words_out = []
    stats = collections.Counter()

    for a in ayahs:
        sn = a['surah_number']
        lines = a['arabic'].split('\n')
        verse_nums = list(range(a['ayah_number'], a['end_ayah_number'] + 1))
        if len(lines) != len(verse_nums):
            # Beklenmedik; bloğu tek ayet gibi ele al.
            stats['satir_uyusmazligi'] += 1
            lines = ['\n'.join(lines)]
            verse_nums = verse_nums[:1]

        for vn, line in zip(verse_nums, lines):
            app_words = split_words(line)
            cmap = morph.get((sn, vn), {})
            corpus = [cmap[k] for k in sorted(cmap)]
            mapping = align(app_words, [c['form'] for c in corpus])

            for wi, (word, ci) in enumerate(zip(app_words, mapping)):
                if ci is None or ci >= len(corpus):
                    stats['eslesmeyen_kelime'] += 1
                    continue
                info = corpus[ci]
                if not info['root']:
                    continue
                root = info['root']
                idx = len(words_out)
                words_out.append({
                    's': sn,             # sure
                    'v': vn,             # ayet
                    'w': wi,             # ayet içindeki kelime sırası (0 tabanlı)
                    'a': word,           # uygulama metnindeki Arapça kelime
                    'r': root,           # kök
                    'l': info['lemma'] or '',
                })
                root_occurrences[root].append(idx)
                if info['lemma']:
                    root_lemmas[root][info['lemma']] += 1
                stats['kokler_eslesti'] += 1

    # Kök kayıtları
    roots_out = []
    for root, occ in sorted(root_occurrences.items(), key=lambda x: -len(x[1])):
        skeleton = normalize_letters(root)
        # En sık 4 türev kelimenin Türkçe okunuşu — "resul", "kitab" gibi
        # kullanıcının klavyeden yazacağı biçimler aramaya girsin.
        readings = []
        for lem, _ in root_lemmas[root].most_common(4):
            rd = turkish_reading(lem)
            if len(rd) >= 2 and rd not in readings:
                readings.append(rd)
        roots_out.append({
            'r': root,                                  # Arapça kök
            'n': normalize_letters(strip_harakat(root)),# normalize kök (arama)
            'm': tr.get(root, ''),                      # Türkçe anlam
            'c': len(occ),                              # geçiş sayısı
            'o': occ,                                   # words[] indeksleri
            't': translit_variants(skeleton),           # fonetik iskelet yazımlar
            'k': readings,                              # Türkçe okunuşlar
            'L': sorted({c for c in skeleton}),         # içerdiği harfler
        })

    payload = {
        'version': 1,
        'source': 'Quranic Arabic Corpus 0.4 (GPL) — corpus.quran.com',
        'letters': [{'a': ch, 'n': name} for ch, name in
                    sorted(LETTER_NAMES.items(), key=lambda x: x[0])],
        'roots': roots_out,
        'words': words_out,
    }

    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))

    size = os.path.getsize(OUT) / 1024 / 1024
    print(f'✓ {len(roots_out)} kök, {len(words_out)} kelime → {OUT} ({size:.2f} MB)')
    withtr = sum(1 for r in roots_out if r['m'])
    print(f'  Türkçe anlamı olan kök: {withtr}/{len(roots_out)} '
          f'(%{withtr/len(roots_out)*100:.1f})')
    for k, v in sorted(stats.items()):
        print(f'  {k}: {v}')

if __name__ == '__main__':
    main()
