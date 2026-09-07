#!/usr/bin/env python3
"""Meal metninden peygamber-ayet eşleştirmesi üretir.

Kullanım:
    python3 tool/build_prophets.py            # assets/data/prophets.json yazar
    python3 tool/build_prophets.py --report   # yalnızca özet basar, dosya yazmaz

Çıktı: assets/data/prophets.json
    [{"id": "musa", "name": "Mûsâ", "name_en": "Moses",
      "ayah_ids": [123, 124, ...]}, ...]

YÖNTEM VE SINIRLARI
-------------------
Eşleştirme meal metnindeki ad geçişlerine bakar. Bu, kürasyonun yerini tutmaz;
taslak üretir. Bilinen sınırlar:

  * Adı geçmeyen ayetler kaçar. Bir kıssa birkaç ayet sürer ama ad yalnızca
    ilkinde anılır; "o dedi ki" ile devam eden ayetler bu taramaya girmez.
  * Dolaylı anılan peygamberler kaçar ("Ey Peygamber", "o elçi", "Rasûl").
  * Bir ayette birden çok peygamber anılabilir; ayet her birinin listesine
    girer, bu doğrudur.

Büyük/küçük harf DUYARLI aranır ve bu bilinçlidir: mealde peygamber adları
büyük harfle yazılır, aynı kökten sıradan kelimeler küçük harfle. "salih amel"
(79 ayet) ile "Sâlih" peygamber (16 ayet) ancak böyle ayrılabiliyor.

Yazım tutarsızlıkları veride mevcut ("Nuh"/"Nûh", "Lut"/"Lût",
"Yakub"/"Yakup"); her ad için tüm varyantlar aranır.
"""

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AYAHS = ROOT / "assets" / "data" / "ayahs.json"
SURAHS = ROOT / "assets" / "data" / "surahs.json"
OUT = ROOT / "assets" / "data" / "prophets.json"

# Peygamberler. Sıra Kur'an anlatısındaki geleneksel sıralamadır; arayüzde
# kronolojik sıralama iniş sırasına göre yapıldığı için buradaki sıra yalnızca
# liste görünümünü etkiler.
#
# `patterns`: mealde geçen yazım varyantları. Kelime sınırıyla aranır, bu
# yüzden ekli hâller ("Mûsâ'ya", "Mûsâ'nın") da yakalanır — kesme işareti
# kelime sınırı sayılır.
#
# `exclude`: ad doğru yazılmış olsa da peygamberi kastetmeyen kalıplar.
PROPHETS = [
    {"id": "adem", "name": "Âdem", "name_en": "Adam",
     "patterns": [r"Âdem", r"Adem"], "exclude": []},
    {"id": "idris", "name": "İdrîs", "name_en": "Idris",
     "patterns": [r"İdrîs", r"İdris"], "exclude": []},
    {"id": "nuh", "name": "Nûh", "name_en": "Noah",
     "patterns": [r"Nûh", r"Nuh"], "exclude": []},
    {"id": "hud", "name": "Hûd", "name_en": "Hud",
     "patterns": [r"Hûd", r"Hud"], "exclude": [r"Hudeybiye"]},
    {"id": "salih", "name": "Sâlih", "name_en": "Salih",
     "patterns": [r"Sâlih", r"Salih"], "exclude": []},
    {"id": "ibrahim", "name": "İbrâhim", "name_en": "Abraham",
     "patterns": [r"İbrâhim", r"İbrahim"], "exclude": []},
    {"id": "lut", "name": "Lût", "name_en": "Lot",
     "patterns": [r"Lût", r"Lut"], "exclude": []},
    {"id": "ismail", "name": "İsmâil", "name_en": "Ishmael",
     "patterns": [r"İsmâil", r"İsmail"], "exclude": []},
    {"id": "ishak", "name": "İshak", "name_en": "Isaac",
     "patterns": [r"İshâk", r"İshak"], "exclude": []},
    {"id": "yakub", "name": "Yakûb", "name_en": "Jacob",
     "patterns": [r"Yakûb", r"Yakub", r"Yakup", r"Yâkub"], "exclude": []},
    {"id": "yusuf", "name": "Yûsuf", "name_en": "Joseph",
     "patterns": [r"Yûsuf", r"Yusuf"], "exclude": []},
    {"id": "eyyub", "name": "Eyyûb", "name_en": "Job",
     "patterns": [r"Eyyûb", r"Eyyub", r"Eyyup"], "exclude": []},
    {"id": "suayb", "name": "Şuayb", "name_en": "Shu'ayb",
     "patterns": [r"Şuayb"], "exclude": []},
    {"id": "musa", "name": "Mûsâ", "name_en": "Moses",
     "patterns": [r"Mûsâ", r"Musa", r"Mûsa"], "exclude": []},
    {"id": "harun", "name": "Hârûn", "name_en": "Aaron",
     "patterns": [r"Hârûn", r"Harun"], "exclude": []},
    {"id": "davud", "name": "Dâvûd", "name_en": "David",
     "patterns": [r"Dâvûd", r"Davud", r"Davut"], "exclude": []},
    {"id": "suleyman", "name": "Süleyman", "name_en": "Solomon",
     "patterns": [r"Süleyman"], "exclude": []},
    {"id": "ilyas", "name": "İlyâs", "name_en": "Elijah",
     "patterns": [r"İlyâs", r"İlyas"], "exclude": []},
    {"id": "elyesa", "name": "Elyesa", "name_en": "Elisha",
     "patterns": [r"Elyesa"], "exclude": []},
    {"id": "yunus", "name": "Yûnus", "name_en": "Jonah",
     "patterns": [r"Yûnus", r"Yunus"], "exclude": []},
    {"id": "zulkifl", "name": "Zülkifl", "name_en": "Dhul-Kifl",
     "patterns": [r"Zülkifl"], "exclude": []},
    {"id": "zekeriya", "name": "Zekeriyyâ", "name_en": "Zechariah",
     "patterns": [r"Zekeriyyâ", r"Zekeriya"], "exclude": []},
    {"id": "yahya", "name": "Yahyâ", "name_en": "John",
     "patterns": [r"Yahyâ", r"Yahya"], "exclude": []},
    {"id": "isa", "name": "Îsâ", "name_en": "Jesus",
     "patterns": [r"Îsâ", r"İsa", r"Îsa"], "exclude": []},
    # Hz. Muhammed özel bir durum: mealde adı çoğunlukla çevirmenin eklediği
    # "Ey Muhammed!" hitabında geçer ve o ayetlerin konusu kıssa değildir.
    # 107 geçişin 86'sı bu kalıptadır; hitap ayetleri elenir, geriye adının
    # ayetin kendisinde anıldığı yerler kalır.
    {"id": "muhammed", "name": "Muhammed", "name_en": "Muhammad",
     "patterns": [r"Muhammed"],
     "exclude": [r"[EeYy]y\s+Muhammed", r"\(\s*ey\s+Muhammed[^)]*\)",
                 r"\(Muhammed\)", r"[EeYy]y\s+Peygamber"]},
]


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def build_regex(patterns):
    """Ad varyantlarını tek bir kelime-sınırlı desende birleştirir."""
    # (?<![\w]) ... (?![\w]) kelime sınırı yerine kullanılır: Python'un \b
    # ifadesi Türkçe harflerde beklendiği gibi çalışmıyor ("Mûsâ" sonundaki
    # â bir kelime karakteri sayılmıyor ve sınır yanlış yere düşüyor).
    joined = "|".join(patterns)
    return re.compile(rf"(?<![0-9A-Za-zÂÎÛÖÜŞÇĞİâîûöüşçğı])(?:{joined})"
                      rf"(?![0-9A-Za-zÂÎÛÖÜŞÇĞİâîûöüşçğı])")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", action="store_true",
                        help="Dosya yazmadan yalnızca özet göster")
    args = parser.parse_args()

    ayahs = load(AYAHS)
    surahs = {s["number"]: s for s in load(SURAHS)}

    results = []
    total_ids = set()

    for p in PROPHETS:
        pattern = build_regex(p["patterns"])
        excludes = [re.compile(e) for e in p["exclude"]]

        matched = []
        for a in ayahs:
            text = a["translation"]
            if not pattern.search(text):
                continue
            # Ad yalnızca dışlanan kalıpta mı geçiyor? Dışlanan kalıplar
            # metinden çıkarılıp yeniden bakılır: "Ey Muhammed! Sana
            # soruyorlar" elenirken, adın ayetin kendisinde de anıldığı bir
            # ayet ("Muhammed ancak bir elçidir") korunur.
            if excludes:
                stripped = text
                for e in excludes:
                    stripped = e.sub(" ", stripped)
                if not pattern.search(stripped):
                    continue
            matched.append(a)

        if not matched:
            continue

        # Ayetler iniş sırasına göre dizilir: kronolojik gösterimin temeli bu.
        # Aynı sure içinde ayet numarası sırası korunur.
        matched.sort(key=lambda a: (
            surahs[a["surah_number"]]["revelation_order"],
            a["ayah_number"],
        ))

        ids = [a["id"] for a in matched]
        total_ids.update(ids)

        results.append({
            "id": p["id"],
            "name": p["name"],
            "name_en": p["name_en"],
            "ayah_ids": ids,
        })

        first = surahs[matched[0]["surah_number"]]
        print(f"{p['name']:<12} {len(ids):>4} ayet  "
              f"{len({a['surah_number'] for a in matched}):>3} sure  "
              f"ilk: {first['name']} ({first['revelation_order']}. iniş)")

    print(f"\n{len(results)} peygamber, {len(total_ids)} benzersiz ayet")

    if args.report:
        print("\n(--report: dosya yazılmadı)")
        return

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=1)
        f.write("\n")
    size = OUT.stat().st_size / 1024
    print(f"\nYazıldı: {OUT.relative_to(ROOT)} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
