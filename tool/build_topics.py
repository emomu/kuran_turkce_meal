#!/usr/bin/env python3
"""Kur'an konu fihristini üretir.

Kullanım:
    python3 tool/build_topics.py            # assets/data/topics.json yazar
    python3 tool/build_topics.py --report   # yalnızca özet basar, dosya yazmaz

Çıktı: assets/data/topics.json
    [{"id": "sabir", "name": "Sabır", "name_en": "Patience",
      "category": "ahlak", "ayah_ids": [...], "core_count": 12,
      "related": ["tevekkul", "zorluk"]}, ...]

İKİ KAYNAK, İKİ İŞ
------------------
Fihrist iki yerden beslenir ve ikisi farklı şeyler yapar:

  1. `topic_bounds.py` — elle yazılmış çekirdek. "Bu ayetler bu konu
     hakkındadır" diyebildiğimiz aralıklar. Listenin başında durur.
  2. Meal metninde terim taraması — çekirdeğin üstüne genişletme. Terimler
     `TOPICS` içinde yazılıdır ve `topic_lexicon.dart`'takilerle aynı
     mantıkta seçilir.

Sıra tesadüf değil: kürasyon önce gelir. Kullanıcı bir konuya girdiğinde ilk
gördüğü ayet, o konuyu kuran ayet olmalı; taramadan gelen isabetli ama ikincil
ayetler altında durur.

YÖNTEM VE SINIRLARI
-------------------
Tarama meal metnindeki kelime geçişlerine bakar ve kürasyonun yerini tutmaz:

  * Kelime geçmeden anlatılan konular kaçar. Bu yüzden çekirdek var.
  * Kelime geçtiği hâlde konuyu kastetmeyen ayetler girer ("gün" her yerde).
    `exclude` bunu daraltır ama tamamen çözmez.
  * Bir ayet birden çok konuya girebilir; bu doğrudur — Bakara 255 hem
    tevhid hem duadır.

Bu yüzden `core_count` yazılır: arayüz çekirdeğin nerede bitip taramanın
nerede başladığını bilir ve kullanıcıya söyleyebilir.

SIRALAMA
--------
Peygamber kıssalarının aksine fihrist MUSHAF sırasına dizilir. Kıssada iniş
sırası anlatının geliştiğini gösterir; fihristte böyle bir gelişim yoktur —
"miras hükümleri"ne bakan kullanıcı Nisâ'yı beklediği yerde arar.
"""

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from topic_bounds import TOPIC_BOUNDS  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
AYAHS = ROOT / "assets" / "data" / "ayahs.json"
SURAHS = ROOT / "assets" / "data" / "surahs.json"
OUT = ROOT / "assets" / "data" / "topics.json"

# Fihrist bölümleri. Sıra arayüzdeki sırayı belirler: inanç ve ibadetten
# başlanır, gündelik hâllerle bitirilir.
CATEGORIES = [
    {"id": "inanc", "name": "İnanç", "name_en": "Belief"},
    {"id": "ibadet", "name": "İbadet", "name_en": "Worship"},
    {"id": "ahlak", "name": "Ahlak", "name_en": "Character"},
    {"id": "iliskiler", "name": "İnsan İlişkileri", "name_en": "Relationships"},
    {"id": "hukuk", "name": "Hukuk ve Toplum", "name_en": "Law and Society"},
    {"id": "ahiret", "name": "Ahiret", "name_en": "Hereafter"},
    {"id": "kainat", "name": "Yaratılış ve Kâinat", "name_en": "Creation"},
    {"id": "haller", "name": "Hâller", "name_en": "States of Being"},
]

# Konular.
#
# `terms`: mealde aranacak Türkçe kökler. Ek almış hâlleri de yakalasın diye
# kök yazılır ("sabr" → "sabrı", "sabrın"). Kelime BAŞI sınırlıdır, sonu değil.
#
# `exclude`: terim geçse de konuyu kastetmeyen kalıplar.
#
# `related`: fihristte "ilgili konular" olarak gösterilir. Tek yönlü yazılır,
# üretimde karşılıklı hâle getirilir.
TOPICS = [
    # --- İNANÇ ---
    {"id": "tevhid", "name": "Tevhid", "name_en": "Oneness of God",
     "category": "inanc", "terms": ["başka ilâh yoktur", "başka tanrı yoktur",
                                    "eşi ve benzeri", "O'ndan başka"],
     "related": ["vahiy", "melekler"]},
    {"id": "melekler", "name": "Melekler", "name_en": "Angels",
     "category": "inanc", "terms": ["melekler ", "meleklere", "Cebrâil", "Cebrail",
                                    "Rûhul"],
     "related": ["vahiy", "kiyamet"]},
    {"id": "kader", "name": "Kader", "name_en": "Divine Decree",
     "category": "inanc", "terms": ["takdir et", "levh-i", "korunmuş bir kitap",
                                    "yazılmadıkça", "bir ölçüye göre"],
     "related": ["tevekkul", "rizik"]},
    {"id": "vahiy", "name": "Vahiy ve Peygamberlik", "name_en": "Revelation",
     "category": "inanc", "terms": ["vahyed", "vahyi", "vahyol", "elçi gönder"],
     "related": ["kuran", "tevhid"]},
    {"id": "seytan", "name": "Şeytan", "name_en": "Satan",
     "category": "inanc", "terms": ["şeytanın adım", "şeytana uy", "İblîs", "İblis",
                                    "vesvese"],
     "related": ["tovbe", "kibir"]},

    # --- İBADET ---
    {"id": "namaz", "name": "Namaz", "name_en": "Prayer",
     "category": "ibadet", "terms": ["namaz kıl", "namazı kıl", "namaza", "namazl"],
     "related": ["dua", "ihlas"]},
    {"id": "zekat", "name": "Zekât ve İnfak", "name_en": "Charity",
     "category": "ibadet", "terms": ["zekât", "zekat", "infak", "sadaka"],
     "related": ["yetim", "merhamet"]},
    {"id": "oruc", "name": "Oruç", "name_en": "Fasting",
     "category": "ibadet", "terms": ["oruç", "Ramazan"],
     "related": ["sabir", "namaz"]},
    {"id": "hac", "name": "Hac", "name_en": "Pilgrimage",
     "category": "ibadet", "terms": ["hac", "Kâbe", "Kabe", "umre", "tavaf",
                                     "ihram", "Safâ"],
     "related": ["namaz", "dua"]},
    {"id": "dua", "name": "Dua", "name_en": "Supplication",
     "category": "ibadet", "terms": ["duâ", "dua ", "duasın", "niyaz", "bana dua"],
     "related": ["namaz", "tevekkul"]},
    {"id": "kuran", "name": "Kur'an", "name_en": "The Qur'an",
     "category": "ibadet", "terms": ["Kur'ân", "Kur'an"],
     "related": ["vahiy", "ilim"]},

    # --- AHLAK ---
    {"id": "sabir", "name": "Sabır", "name_en": "Patience",
     "category": "ahlak", "terms": ["sabred", "sabırl", "sabrın", "sabretti"],
     "related": ["zorluk", "tevekkul"]},
    {"id": "sukur", "name": "Şükür", "name_en": "Gratitude",
     "category": "ahlak", "terms": ["şükred", "şükrün", "şükreder", "nankörlük",
                                    "şükretmez"],
     "related": ["rizik", "kibir"]},
    {"id": "tovbe", "name": "Tövbe ve Bağışlanma", "name_en": "Repentance",
     "category": "ahlak", "terms": ["tövbe", "tevbe", "affed", "bağışlanma dile"],
     "related": ["pismanlik", "merhamet"]},
    {"id": "dogruluk", "name": "Doğruluk", "name_en": "Truthfulness",
     "category": "ahlak", "terms": ["doğru söyle", "ölçüyü", "tartıyı", "ölçüde",
                                    "doğruluktan"],
     "related": ["adalet", "yemin"]},
    {"id": "adalet", "name": "Adalet", "name_en": "Justice",
     "category": "ahlak", "terms": ["adalet", "adâlet", "adil", "âdil",
                                    "insaf"],
     "related": ["haksizlik", "yonetim"]},
    {"id": "merhamet", "name": "Merhamet", "name_en": "Mercy",
     "category": "ahlak", "terms": ["merhamet ed", "birbirine merhamet", "şefkat"],
     "related": ["zekat", "yetim"]},
    {"id": "kibir", "name": "Kibir", "name_en": "Arrogance",
     "category": "ahlak", "terms": ["kibir", "kibirlen", "büyüklen", "böbürlen",
                                    "kurumlan"],
     "related": ["seytan", "sukur"]},
    {"id": "giybet", "name": "Dedikodu ve İftira", "name_en": "Slander",
     "category": "ahlak", "terms": ["gıybet", "iftira at", "alay et", "ayıplama",
                                    "kötü lakap", "koğuculuk"],
     "related": ["dogruluk", "adalet"]},
    {"id": "ofke", "name": "Öfke", "name_en": "Anger",
     "category": "ahlak", "terms": ["öfke", "öfkelen", "hiddet", "kızgınl"],
     "related": ["sabir", "merhamet"]},
    {"id": "ihlas", "name": "İhlâs ve Samimiyet", "name_en": "Sincerity",
     "category": "ahlak", "terms": ["ihlâs", "samimi", "gösteriş", "riya",
                                    "başa kak"],
     "related": ["namaz", "zekat"]},
    {"id": "tevekkul", "name": "Tevekkül", "name_en": "Trust in God",
     "category": "ahlak", "terms": ["tevekkül", "Allah'a güven", "Allah'a dayan",
                                    "vekil olarak"],
     "related": ["kader", "sabir"]},

    # --- İNSAN İLİŞKİLERİ ---
    {"id": "anne_baba", "name": "Anne Baba", "name_en": "Parents",
     "category": "iliskiler", "terms": ["ana baba", "anne baba", "anaya",
                                        "babaya", "ana-baba"],
     "related": ["cocuk", "yasli"]},
    {"id": "evlilik", "name": "Evlilik", "name_en": "Marriage",
     "category": "iliskiler", "terms": ["nikâh", "nikah", "mehir", "eşlerin",
                                        "eş olarak"],
     "related": ["bosanma", "cocuk"]},
    {"id": "bosanma", "name": "Boşanma", "name_en": "Divorce",
     "category": "iliskiler", "terms": ["boşad", "boşan", "talâk", "iddet"],
     "related": ["evlilik", "adalet"]},
    {"id": "cocuk", "name": "Çocuklar", "name_en": "Children",
     "category": "iliskiler", "terms": ["evlât", "evlat", "çocukların", "çocuklarınız",
                                        "süt em"],
     "related": ["anne_baba", "yetim"]},
    {"id": "komsu", "name": "Komşu ve Misafir", "name_en": "Neighbours",
     "category": "iliskiler", "terms": ["komşu", "misafir", "yolda kalmış"],
     "related": ["merhamet", "zekat"]},
    {"id": "yetim", "name": "Yetim ve Yoksul", "name_en": "Orphans and Poor",
     "category": "iliskiler", "terms": ["yetim", "yoksul", "muhtaç", "düşkün"],
     "related": ["zekat", "merhamet"]},
    {"id": "kadin", "name": "Kadın", "name_en": "Women",
     "category": "iliskiler", "terms": ["kadınlar", "kadınlara", "kız çocu"],
     "related": ["evlilik", "miras"]},

    # --- HUKUK VE TOPLUM ---
    {"id": "miras", "name": "Miras", "name_en": "Inheritance",
     "category": "hukuk", "terms": ["miras", "vasiyet", "geriye bırak"],
     "related": ["borc", "adalet"]},
    {"id": "borc", "name": "Borç ve Ticaret", "name_en": "Debt and Trade",
     "category": "hukuk", "terms": ["borç", "alışveriş", "ticaret", "rehin"],
     "related": ["faiz", "dogruluk"]},
    {"id": "faiz", "name": "Faiz", "name_en": "Usury",
     "category": "hukuk", "terms": ["faiz", "ribâ"],
     "related": ["borc", "zekat"]},
    {"id": "yemin", "name": "Yemin ve Söz", "name_en": "Oaths",
     "category": "hukuk", "terms": ["yemin ed", "yeminler", "yemininiz", "ahdini boz"],
     "related": ["dogruluk", "adalet"]},
    {"id": "savas", "name": "Savaş ve Barış", "name_en": "War and Peace",
     "category": "hukuk", "terms": ["savaşın", "savaşan", "cihad", "barışa yanaş",
                                    "sulh"],
     "related": ["adalet", "hicret"]},
    {"id": "yonetim", "name": "Yönetim ve Danışma", "name_en": "Governance",
     "category": "hukuk", "terms": ["emanet", "danış", "istişare", "aralarında şûrâ"],
     "related": ["adalet", "yemin"]},
    {"id": "hicret", "name": "Hicret", "name_en": "Migration",
     "category": "hukuk", "terms": ["hicret", "göç", "yurtlarından"],
     "related": ["savas", "gurbet"]},

    # --- AHİRET ---
    {"id": "olum", "name": "Ölüm", "name_en": "Death",
     "category": "ahiret", "terms": ["ölümü tad", "ecel", "öleceks", "ölüm gel"],
     "related": ["kiyamet", "hesap"]},
    {"id": "kiyamet", "name": "Kıyamet", "name_en": "The Last Day",
     "category": "ahiret", "terms": ["kıyamet gün", "kıyamet kop", "sûra üfür",
                                    "sura üfür"],
     "related": ["hesap", "olum"]},
    {"id": "hesap", "name": "Hesap ve Mîzan", "name_en": "The Reckoning",
     "category": "ahiret", "terms": ["hesaba çek", "hesap gün", "terazi", "mîzan",
                                     "amel defter"],
     "related": ["kiyamet", "cennet"]},
    {"id": "cennet", "name": "Cennet", "name_en": "Paradise",
     "category": "ahiret", "terms": ["cennete gir", "cennet ehli", "cennetlik"],
     "related": ["cehennem", "hesap"]},
    {"id": "cehennem", "name": "Cehennem", "name_en": "Hellfire",
     "category": "ahiret", "terms": ["cehenneme gir", "cehennem ehli", "cehennemlik"],
     "related": ["cennet", "hesap"]},

    # --- YARATILIŞ VE KÂİNAT ---
    {"id": "yaratilis", "name": "Yaratılış", "name_en": "Creation",
     "category": "kainat", "terms": ["topraktan yarat", "nutfe", "çamurdan",
                                     "bir damla", "sizi yarat"],
     "related": ["tabiat", "ilim"]},
    {"id": "tabiat", "name": "Tabiat", "name_en": "Nature",
     "category": "kainat", "terms": ["gece ile gündüz", "gökten su indir", "yıldızlar",
                                     "dağları yürüt", "denizi sizin"],
     "related": ["yaratilis", "rizik"]},
    {"id": "rizik", "name": "Rızık", "name_en": "Provision",
     "category": "kainat", "terms": ["rızık ver", "rızkını", "rızık olarak", "geçiml"],
     "related": ["tevekkul", "sukur"]},
    {"id": "ilim", "name": "İlim", "name_en": "Knowledge",
     "category": "kainat", "terms": ["ilimde", "ilim sahib", "âlimler", "bilenlerle",
                                     "hiç bilenlerle"],
     "related": ["kuran", "yaratilis"]},

    # --- HÂLLER ---
    {"id": "zorluk", "name": "Zorluk", "name_en": "Hardship",
     "category": "haller", "terms": ["zorlukla beraber", "sıkıntı", "güçlük", "darlık",
                                     "imtihan ed", "sizi deneriz"],
     "related": ["sabir", "tevekkul"]},
    {"id": "uzuntu", "name": "Üzüntü", "name_en": "Sorrow",
     "category": "haller", "terms": ["üzül", "üzülme", "hüzn", "hüzün", "keder",
                                     "tasalan"],
     "related": ["zorluk", "yalnizlik"]},
    {"id": "korku", "name": "Korku", "name_en": "Fear",
     "category": "haller", "terms": ["korkmayın", "korkma,", "korku ve", "korkuya"],
     "related": ["tevekkul", "uzuntu"]},
    {"id": "yalnizlik", "name": "Yalnızlık", "name_en": "Loneliness",
     "category": "haller", "terms": ["yalnız bırak", "terk etmedi", "şah damar",
                                     "yanınızdad"],
     "related": ["uzuntu", "dua"]},
    {"id": "hastalik", "name": "Hastalık ve Şifa", "name_en": "Illness",
     "category": "haller", "terms": ["hastal", "hastay", "şifa"],
     "related": ["sabir", "dua"]},
    {"id": "pismanlik", "name": "Pişmanlık", "name_en": "Regret",
     "category": "haller", "terms": ["pişman", "umut kes", "ümit kes", "nedamet"],
     "related": ["tovbe", "uzuntu"]},
    {"id": "haksizlik", "name": "Haksızlığa Uğramak", "name_en": "Injustice",
     "category": "haller", "terms": ["haksızlığa", "haksız yere", "zulme uğra",
                                     "hakkını ye"],
     "related": ["adalet", "sabir"]},
    {"id": "gurbet", "name": "Gurbet", "name_en": "Being Far From Home",
     "category": "haller", "terms": ["yeryüzü geniş", "yurtların", "gurbet",
                                     "yolculuğa"],
     "related": ["hicret", "yalnizlik"]},
    {"id": "basarisizlik", "name": "Başarısızlık", "name_en": "Failure",
     "category": "haller", "terms": ["hoşunuza gitmey", "gevşe", "yılgın",
                                     "umutsuzluğa"],
     "related": ["zorluk", "sabir"]},
    {"id": "yasli", "name": "Yaşlılık", "name_en": "Old Age",
     "category": "haller", "terms": ["ihtiyarl", "yaşlıl", "saç ağar", "ömrü uzat",
                                     "kocam"],
     "related": ["anne_baba", "olum"]},
    {"id": "karar", "name": "Karar Vermek", "name_en": "Making Decisions",
     "category": "haller", "terms": ["karar ver", "azmet", "kesin karar", "furkan"],
     "related": ["tevekkul", "yonetim"]},
]

# Taramanın yakaladığı ama konuyu kastetmeyen kalıplar.
#
# Her biri gözlemle eklendi: üretim çalıştırıldı, çıktı okundu, konuya ait
# olmayan ayet görüldüğünde buraya bir kalıp yazıldı.
EXCLUDE = {
    # "ateş" cehennem dışında da geçer: Mûsâ'nın gördüğü ateş, ateş yakmak.
    "cehennem": [r"ateş(?:i)? gördü", r"bir ateş", r"ateş yak"],
    # "pay" miras dışında ganimet ve nasip anlamında da geçer.
    "miras": [r"pay(?:ı|ınız)? (?:vardır|yoktur)"],
    # "oku" ilim dışında "okunan ayet" anlamında da geçer.
    "ilim": [r"okun(?:an|duğu|ur)"],
    # "eş" evlilik dışında "benzeri, dengi" anlamında geçer.
    "evlilik": [r"eşit", r"eşsiz"],
    # "acı" merhamet değil, azap anlamında da geçer.
    "merhamet": [r"acı(?:klı|lı) (?:bir )?azap", r"acı bir azab"],
    # "korkuya kapılmak" bir anlatı ayrıntısı olabiliyor; korku konusunu
    # kuran ayet "korkmayın" hitabıdır.
    "korku": [r"korku ve açlık"],
}

# Bir konunun taramadan alabileceği en fazla ayet.
#
# Tarama bazı konularda yüzlerce ayet döndürüyor ("ateş" 400'ün üstünde) ve
# o listeler fihrist değil, arama sonucu olur. Kullanıcı bir konuya girdiğinde
# okunabilir bir liste görmeli; daha fazlasını isteyen aramaya gider.
#
# Çekirdek bu sınıra tabi değildir: kürasyonla seçilmiş ayet elenmez.
SCAN_CAP = 40


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def build_regex(terms):
    """Terimleri kelime başı sınırlı tek bir desende birleştirir.

    Sınır yalnızca BAŞTA kurulur: "sabr" terimi "sabrı", "sabrın", "sabreden"
    hâllerini de yakalamalı. Sonda da sınır olsaydı yalnızca yalın hâl
    eşleşirdi ve Türkçede yalın hâl azınlıktır.

    `\\b` kullanılmaz; Python'un kelime karakteri tanımı Türkçe harflerde
    beklendiği gibi çalışmıyor (bkz. build_prophets.py'deki aynı not).
    """
    joined = "|".join(re.escape(t) for t in terms)
    return re.compile(
        rf"(?<![0-9A-Za-zÂÎÛÖÜŞÇĞİâîûöüşçğı])(?:{joined})",
        re.IGNORECASE)


def validate():
    """Veri tutarlılığını üretimden önce denetler.

    Yazım hatası sessizce kaybolur: `topic_bounds.py`'de "sabirr" diye bir
    anahtar hiçbir konuya bağlanmaz ve o konu çekirdeksiz kalır — çıktı yine
    de makul görünür. Aynı şekilde `related` içindeki bir yazım hatası
    arayüzde boş bir bağlantı olur.
    """
    ids = {t["id"] for t in TOPICS}
    cats = {c["id"] for c in CATEGORIES}

    if len(ids) != len(TOPICS):
        raise SystemExit("TOPICS: tekrar eden konu kimliği var")

    for t in TOPICS:
        if t["category"] not in cats:
            raise SystemExit(
                f"{t['id']}: bilinmeyen bölüm '{t['category']}'")
        for r in t["related"]:
            if r not in ids:
                raise SystemExit(f"{t['id']}: bilinmeyen ilgili konu '{r}'")
            if r == t["id"]:
                raise SystemExit(f"{t['id']}: kendisiyle ilişkilendirilmiş")

    for tid in TOPIC_BOUNDS:
        if tid not in ids:
            raise SystemExit(f"topic_bounds: bilinmeyen konu '{tid}'")

    for tid, surahs in TOPIC_BOUNDS.items():
        for sn, ranges in surahs.items():
            for lo, hi in ranges:
                if lo > hi:
                    raise SystemExit(
                        f"topic_bounds: {tid} {sn}:({lo},{hi}) ters aralık")

    for tid in EXCLUDE:
        if tid not in ids:
            raise SystemExit(f"EXCLUDE: bilinmeyen konu '{tid}'")


def mutual_related():
    """`related` bağlarını karşılıklı hâle getirir.

    Elle yazarken tek yön yazmak yeterli olmalı; "sabır → tevekkül" yazan
    kişinin ayrıca "tevekkül → sabır" yazmayı hatırlaması gerekmesin. Tek
    yönlü kalırsa kullanıcı bir yönden gidip geri dönemiyor.
    """
    links = {t["id"]: list(t["related"]) for t in TOPICS}
    for tid, rels in list(links.items()):
        for r in rels:
            if tid not in links[r]:
                links[r].append(tid)
    return links


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", action="store_true",
                        help="Dosya yazmadan yalnızca özet göster")
    args = parser.parse_args()

    validate()

    ayahs = load(AYAHS)
    surahs = {s["number"]: s for s in load(SURAHS)}
    by_id = {a["id"]: a for a in ayahs}
    links = mutual_related()

    results = []
    total_ids = set()

    for t in TOPICS:
        bounds = TOPIC_BOUNDS.get(t["id"]) or {}

        # 1. Çekirdek: elle çizilmiş aralıklar.
        core = []
        for a in ayahs:
            for lo, hi in bounds.get(a["surah_number"], ()):
                if lo <= a["ayah_number"] <= hi:
                    core.append(a)
                    break

        # 2. Genişletme: terim taraması. Çekirdekte olan ayet tekrar girmez.
        pattern = build_regex(t["terms"])
        excludes = [re.compile(e, re.IGNORECASE)
                    for e in EXCLUDE.get(t["id"], [])]
        have = {a["id"] for a in core}

        scanned = []
        for a in ayahs:
            if a["id"] in have:
                continue
            text = a["translation"]
            if not pattern.search(text):
                continue
            # Terim yalnızca dışlanan kalıpta mı geçiyor? Kalıp metinden
            # çıkarılıp yeniden bakılır, böylece hem terimin hem kalıbın
            # geçtiği ayet korunur.
            if excludes:
                stripped = text
                for e in excludes:
                    stripped = e.sub(" ", stripped)
                if not pattern.search(stripped):
                    continue
            scanned.append(a)

        def by_mushaf(a):
            return (a["surah_number"], a["ayah_number"])

        core.sort(key=by_mushaf)
        scanned.sort(key=by_mushaf)

        # Tarama sınırı: en uzun listeler kırpılır. Kırpma mushaf sırasının
        # başından alır — rastgele seçmek yerine öngörülebilir olsun.
        clipped = len(scanned) - SCAN_CAP
        if clipped > 0:
            scanned = scanned[:SCAN_CAP]

        ids = [a["id"] for a in core] + [a["id"] for a in scanned]
        if not ids:
            raise SystemExit(
                f"{t['id']}: hiç ayet bulunamadı. Terimler ya da sınırlar "
                f"yanlış yazılmış olabilir.")

        total_ids.update(ids)

        results.append({
            "id": t["id"],
            "name": t["name"],
            "name_en": t["name_en"],
            "category": t["category"],
            "ayah_ids": ids,
            # Arayüz çekirdeğin nerede bittiğini bilmeli: ilk `core_count`
            # ayet kürasyonla seçilmiştir, gerisi taramadan gelir.
            "core_count": len(core),
            "related": links[t["id"]],
        })

        note = f"  ({clipped} kırpıldı)" if clipped > 0 else ""
        first = by_id[ids[0]]
        print(f"{t['name']:<24} {len(ids):>4} ayet  "
              f"({len(core):>3} çekirdek + {len(scanned):>3} tarama)  "
              f"ilk: {surahs[first['surah_number']]['name']} "
              f"{first['ayah_number']}{note}")

    print(f"\n{len(results)} konu, {len(total_ids)} benzersiz ayet "
          f"({100 * len(total_ids) / len(ayahs):.0f}% kapsam)")

    if args.report:
        print("\n(--report: dosya yazılmadı)")
        return

    payload = {"categories": CATEGORIES, "topics": results}
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
        f.write("\n")
    size = OUT.stat().st_size / 1024
    print(f"\nYazıldı: {OUT.relative_to(ROOT)} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
