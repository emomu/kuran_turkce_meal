#!/usr/bin/env python3
"""Meal metninden peygamber-ayet eşleştirmesi üretir.

Kullanım:
    python3 tool/build_prophets.py            # assets/data/prophets.json yazar
    python3 tool/build_prophets.py --report   # yalnızca özet basar, dosya yazmaz

Çıktı: assets/data/prophets.json
    [{"id": "musa", "name": "Mûsâ", "name_en": "Moses",
      "ayah_ids": [123, ...], "mention_ids": [123, ...]}, ...]

İKİ LİSTE, İKİ İHTİYAÇ
----------------------
`ayah_ids` kıssa akışıdır: peygamberin anlatıldığı ayetler. Kıssa ekranı bunu
okur; hitap ayetleri buraya girmez çünkü onların konusu kıssa değildir.

`mention_ids` ise anılma listesidir: adın ya da ona yönelen hitabın geçtiği
her ayet. Arama ve asistan bunu okur. Kullanıcı "Muhammed" arattığında kıssa
değil, "onun geçtiği ayetler" bekler — "Ey Muhammed! Sana soruyorlar" da
buna dahildir.

Diğer peygamberlerde iki liste aynıdır; ayrım yalnızca kendisine hitap edilen
Hz. Muhammed'de anlam kazanır (10 kıssa ayeti, 139 anılma).

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
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from story_bounds import STORY_BOUNDS  # noqa: E402

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
# `exclude`: ad doğru yazılmış olsa da peygamberi kastetmeyen kalıplar. Yalnızca
# kıssa listesini (`ayah_ids`) daraltır; anılma listesine karışmaz.
#
# `mention_extra`: adın kendisi geçmese de o peygamberi kasteden hitaplar.
# Yalnızca anılma listesine (`mention_ids`) eklenir.
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
    # 107 geçişin 86'sı bu kalıptadır; hitap ayetleri kıssa listesinden elenir,
    # geriye adının ayetin kendisinde anıldığı yerler kalır.
    #
    # Anılma listesi (`mention_ids`) ise tersini yapar: hitaplar oraya girer.
    # Kur'an ona çoğunlukla adıyla değil sıfatıyla seslenir — "Ey Peygamber",
    # "Ey Rasûl", "Ey örtüsüne bürünen" — ve mealde bu hitaplar çoğu kez
    # parantez içinde "(Ey Muhammed)" diye açılır. Kullanıcı "Muhammed"
    # arattığında bu ayetleri de bekler; aramanın 10 sonuç dönmesi bir
    # eksiklikti.
    {"id": "muhammed", "name": "Muhammed", "name_en": "Muhammad",
     "patterns": [r"Muhammed"],
     "exclude": [r"[EeYy]y\s+Muhammed", r"\(\s*ey\s+Muhammed[^)]*\)",
                 r"\(Muhammed\)", r"[EeYy]y\s+Peygamber"],
     "mention_extra": [
         r"[Ee]y\s+[Pp]eygamber",
         r"[Ee]y\s+[Rr]es[uû]l",
         r"[Ee]y\s+[Rr]as[uû]l",
         r"[Ee]y\s+[Nn]eb[iî]",
         r"[Ee]y\s+örtüsüne\s+bürünen",
         r"[Ee]y\s+bürünüp\s+sarınan",
         r"[Ee]y\s+müzzemmil",
         r"[Ee]y\s+müddessir",
         r"(?<![0-9A-Za-zÂÎÛÖÜŞÇĞİâîûöüşçğı])Ahmed"
         r"(?![0-9A-Za-zÂÎÛÖÜŞÇĞİâîûöüşçğı])",
     ]},
]


def validate_bounds(prophets):
    """Sınır dosyasındaki kimlikleri ve aralıkları denetler.

    Yazım hatası sessizce kaybolur: `"musaa"` diye bir anahtar hiçbir
    peygambere bağlanmaz ve kıssa eskisi gibi eksik kalır. Aynı şekilde
    ters bir aralık (30, 20) hiçbir ayet eklemez. İkisi de burada durur.
    """
    ids = {p["id"] for p in prophets}

    # Hârûn iki kez Mûsâ'nın bloklarını yanlışlıkla devraldı ve payı 24'ten
    # 213'e çıktı; ikisi de gözden kaçtı çünkü çıktı hâlâ makul görünüyordu.
    # Bir peygamberin sınırlardan gelen payı gerçekçi bir tavanı aşarsa
    # üretim durur.
    max_bound_ayahs = {"harun": 40}
    for pid, surahs in STORY_BOUNDS.items():
        if pid not in ids:
            raise SystemExit(f"story_bounds: bilinmeyen peygamber '{pid}'")
        for sn, ranges in surahs.items():
            for lo, hi in ranges:
                if lo > hi:
                    raise SystemExit(
                        f"story_bounds: {pid} {sn}:({lo},{hi}) ters aralık")

        cap = max_bound_ayahs.get(pid)
        if cap is not None:
            span = sum(hi - lo + 1
                       for ranges in surahs.values()
                       for lo, hi in ranges)
            if span > cap:
                raise SystemExit(
                    f"story_bounds: {pid} sınırları {span} ayet kapsıyor, "
                    f"tavan {cap}. Başka bir peygamberin bloğu yanlışlıkla "
                    f"buraya yazılmış olabilir.")


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

    validate_bounds(PROPHETS)

    ayahs = load(AYAHS)
    surahs = {s["number"]: s for s in load(SURAHS)}

    results = []
    total_ids = set()

    for p in PROPHETS:
        pattern = build_regex(p["patterns"])
        excludes = [re.compile(e) for e in p["exclude"]]
        extras = [re.compile(e) for e in p.get("mention_extra", [])]

        matched = []    # kıssa: ad, hitap kalıpları elendikten sonra da duruyor
        mentioned = []  # anılma: ad ya da hitap, herhangi bir biçimde geçiyor
        for a in ayahs:
            text = a["translation"]
            hasName = bool(pattern.search(text))
            hasExtra = any(e.search(text) for e in extras)

            # Anılma listesi geniştir: ad geçiyorsa ya da ona yönelen bir
            # hitap varsa ayet buraya girer. `exclude` burada uygulanmaz;
            # elenen kalıpların çoğu ("Ey Muhammed!") tam da aranan şeydir.
            if hasName or hasExtra:
                mentioned.append(a)

            if not hasName:
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
        # Kıssa sınırları tanımlıysa aralık bütünüyle eklenir.
        #
        # Ad taraması kıssanın *nerede anıldığını* bulur, *nerede başlayıp
        # bittiğini* bulamaz: anlatı sürerken ad tekrarlanmaz ve o ayetler
        # düşer. Meryem 16-35 tek bir anlatıdır ama taramaya yalnızca dört
        # ayeti girer; doğum sahnesi görünmez. `story_bounds.py` o boşluğu
        # elle çizilmiş sınırlarla kapatır.
        bounds = STORY_BOUNDS.get(p["id"]) or {}
        if bounds:
            have = {a["id"] for a in matched}
            for a in ayahs:
                if a["id"] in have:
                    continue
                for lo, hi in bounds.get(a["surah_number"], ()):
                    if lo <= a["ayah_number"] <= hi:
                        matched.append(a)
                        break

        def byRevelation(a):
            return (surahs[a["surah_number"]]["revelation_order"],
                    a["ayah_number"])

        # Anılma listesi kıssayı kapsar: sınırlarla eklenen ayetler oraya da
        # girmeli, yoksa "kıssası 100 ayet ama 41 ayette anılıyor" gibi
        # kendini yalanlayan bir künye çıkar.
        seen = {a["id"] for a in mentioned}
        mentioned.extend(a for a in matched if a["id"] not in seen)

        matched.sort(key=byRevelation)
        mentioned.sort(key=byRevelation)

        ids = [a["id"] for a in matched]
        mention_ids = [a["id"] for a in mentioned]
        total_ids.update(ids)

        entry = {
            "id": p["id"],
            "name": p["name"],
            "name_en": p["name_en"],
            "ayah_ids": ids,
        }
        # İki liste aynıysa ikincisi yazılmaz: 25 peygamberin 24'ünde aynılar
        # ve dosyayı iki katına çıkarmanın anlamı yok. Okuyan taraf alan
        # yoksa kıssa listesine düşer.
        if mention_ids != ids:
            entry["mention_ids"] = mention_ids
        results.append(entry)

        first = surahs[matched[0]["surah_number"]]
        extra = (f"  (+{len(mention_ids) - len(ids)} anılma)"
                 if mention_ids != ids else "")
        print(f"{p['name']:<12} {len(ids):>4} ayet  "
              f"{len({a['surah_number'] for a in matched}):>3} sure  "
              f"ilk: {first['name']} ({first['revelation_order']}. iniş)"
              f"{extra}")

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
