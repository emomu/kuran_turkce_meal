# Fihrist kartı görselleri — üretim promptları

Keşfet ekranındaki 56 konu kartı için görsel üretimi. Midjourney, DALL·E,
Firefly ya da Figma'nın kendi üreticisiyle kullanılabilir.

## Neden bu yön

Referans alınan uygulamalarda kartlarda fotoğraflı insan yüzleri ve kitap
kapakları var. Burada o yol izlenmedi, iki sebeple:

**İçerik.** İslami görsel gelenekte canlı tasviri tartışmalıdır. Soyut
geometri, hat estetiği, ışık ve doğa bu gelenekte yerleşik bir dildir ve
hiçbir kullanıcıyı dışarıda bırakmaz.

**Özgünlük.** Uygulama App Store'da 4.3(a) (benzer konsept) gerekçesiyle
reddedildi. Başka bir uygulamanın görsel dilini birebir almak o iddiayı
güçlendirir. Kendi görsel dilimizi kurmak hem doğru hem gerekli.

## Teknik gereksinimler

- **Oran:** 16:10 (kart en/boy oranı 1.65)
- **Çözünürlük:** en az 1024×640, @3x için 1560×960
- **Format:** PNG, şeffaf değil
- **Metin YOK** — konu adı uygulama tarafından üstüne yazılıyor
- Görselin **sol yarısı sakin** olmalı; başlık ve sayı oraya düşüyor
- Koyu ve açık temada da okunmalı: aşırı parlak alan olmasın

## Ortak stil eki

Her prompta eklenecek:

```
minimal abstract geometric composition, flat vector illustration,
muted desaturated palette, soft matte texture, no text, no letters,
no human figures, no faces, no animals, generous negative space on the
left half, subtle grain, calm and contemplative mood, editorial poster
aesthetic
```

## Bölüm renkleri

Görseller kart renginin üstüne biniyor; üreticiye baskın renk olarak bunu ver.

| Bölüm | Açık tema | Koyu tema | Renk karakteri |
|---|---|---|---|
| İnanç | `#4A6B7C` | `#2E4551` | soğuk mavi-gri |
| İbadet | `#3F6B54` | `#2A4638` | tezhip yeşili |
| Ahlak | `#7C6545` | `#52432E` | sıcak kahve |
| İnsan İlişkileri | `#8A5A5F` | `#5C3C3F` | kırık bordo |
| Hukuk ve Toplum | `#5A5A78` | `#3C3C50` | mürekkep moru |
| Ahiret | `#6B4F6B` | `#473547` | derin mor |
| Yaratılış ve Kâinat | `#4A7068` | `#2F4945` | çam yeşili |
| Hâller | `#7A6A52` | `#514637` | kum beji |

---

# Konu promptları

## İnanç — #4A6B7C

**Tevhid**
> a single luminous point at the centre of concentric geometric rings, radiating
> outward, deep slate blue background, islamic geometric pattern influence

**Melekler**
> overlapping translucent wing-like arcs made of thin geometric lines, light
> passing through, cool blue-grey

**Kader**
> a single thread woven through a grid of points, some points lit, deep blue

**Vahiy ve Peygamberlik**
> a beam of light descending through layered geometric planes, dust motes,
> slate blue

**Şeytan**
> a fractured geometric pattern with one dark spiral pulling inward, muted
> blue-grey with a single darker accent

## İbadet — #3F6B54

**Namaz**
> repeating arched mihrab silhouettes receding into depth, warm green, soft
> directional light from above

**Zekât ve İnfak**
> an open geometric vessel with shapes flowing outward to smaller forms,
> muted green

**Oruç**
> a crescent of negative space carved from a solid field, dawn gradient,
> deep green

**Hac**
> concentric circles of small geometric marks orbiting a dark cubic centre,
> muted green

**Dua**
> two open arc shapes rising toward a soft light source, warm green

**Kur'an**
> layered horizontal planes suggesting open pages, light between them, deep
> green, no visible script

## Ahlak — #7C6545

**Sabır**
> a slow geometric gradient of stacked horizontal bands, one band slightly
> shifted, warm earth brown

**Şükür**
> radiating lines expanding from a small dense cluster, warm ochre

**Tövbe ve Bağışlanma**
> a dark field opening into light along a curved seam, warm brown

**Doğruluk**
> a perfectly balanced geometric scale abstracted to two aligned forms, ochre

**Adalet**
> two equal geometric masses on a level horizontal axis, warm brown

**Merhamet**
> a soft circular gradient enclosing a smaller form, warm amber

**Kibir**
> a tall narrow form casting a disproportionate shadow, muted brown

**Dedikodu ve İftira**
> tangled thin lines spreading from a point and dissolving, muted brown

**Öfke**
> sharp angular shards contained within a circular boundary, dark ochre

**İhlâs ve Samimiyet**
> a single clear form with no ornament, centred, warm neutral brown

**Tevekkül**
> a small form resting on a large stable curve, warm earth tones

## İnsan İlişkileri — #8A5A5F

**Anne Baba**
> two large arcs sheltering a smaller one, muted rose-brown

**Evlilik**
> two interlocking geometric forms sharing an edge, soft burgundy

**Boşanma**
> two forms separating with a soft gradient between, muted rose

**Çocuklar**
> small geometric forms growing in scale along a gentle curve, warm rose

**Komşu ve Misafir**
> two adjacent geometric dwellings sharing a wall, muted terracotta

**Yetim ve Yoksul**
> an open hand shape abstracted to geometric planes, soft rose-brown

**Kadın**
> a tall elegant geometric form with flowing linear detail, muted burgundy

## Hukuk ve Toplum — #5A5A78

**Miras**
> a large form dividing into proportional smaller parts, ink purple

**Borç ve Ticaret**
> two forms exchanging position along a horizontal line, muted indigo

**Faiz**
> a spiral growing disproportionately large, contained, dark indigo

**Yemin ve Söz**
> a knot of two lines held firm, ink purple

**Savaş ve Barış**
> angular forms on the left resolving into soft rounded ones on the right,
> muted indigo

**Yönetim ve Danışma**
> a circle of equal points connected by thin lines, ink purple

**Hicret**
> a path of geometric marks leading from a dense cluster toward open space,
> indigo

## Ahiret — #6B4F6B

**Ölüm**
> a horizon line where a form passes from solid to transparent, deep muted
> purple

**Kıyamet**
> a geometric field breaking apart into drifting fragments, dark violet

**Hesap ve Mîzan**
> a precise balance abstracted to two suspended forms, deep purple

**Cennet**
> layered gardens abstracted to horizontal bands with flowing lines between,
> soft violet with a warm light source

**Cehennem**
> dense converging angular lines, dark plum, restrained not violent

## Yaratılış ve Kâinat — #4A7068

**Yaratılış**
> a single point expanding into structured complexity, deep teal-green

**Tabiat**
> layered mountain and water forms in flat geometric planes, pine green

**Rızık**
> geometric rain falling onto a receiving surface, muted green

**İlim**
> an expanding lattice of connected points growing in density, deep teal

## Hâller — #7A6A52

**Zorluk**
> a narrow passage between two heavy forms opening to light, sand beige

**Üzüntü**
> soft descending gradient with a single lighter horizontal band, muted sand

**Korku**
> a small form within a large dark field, one edge lit, warm grey-beige

**Yalnızlık**
> a single point in generous empty space, subtle warm gradient, sand

**Hastalık ve Şifa**
> a broken line rejoining with a soft glow at the seam, warm beige

**Pişmanlık**
> a path doubling back on itself, soft sand tones

**Haksızlığa Uğramak**
> an off-balance composition with one form pressed to an edge, muted beige

**Gurbet**
> a small form at the far edge of a wide open field, warm sand, distant horizon

**Başarısızlık**
> a fallen form with a rising gradient behind it, warm neutral

**Yaşlılık**
> concentric rings like tree growth, warm weathered beige

**Karar Vermek**
> a single path branching into two, one slightly brighter, sand tones

---

## Figma iş akışı

1. Görselleri üret (yukarıdaki promptlar + ortak stil eki)
2. Figma'da 1560×960 frame aç, görseli yerleştir
3. Üstüne bölüm renginde `%35` opaklıkta bir katman koy — görseller
   birbirinden farklı çıkacak, bu katman onları tek sisteme bağlar
4. Sol yarıya soldan sağa koyu→şeffaf gradyan ekle (metin okunurluğu)
5. `topics/<konu_id>.png` olarak dışa aktar (@1x, @2x, @3x)

Konu kimlikleri `assets/data/topics.json` içinde.

## Uygulama tarafı

Görseller gelince kart yapısı değişmeli: [topic_card.dart](../../lib/features/discover/widgets/topic_card.dart)
şu an düz renk kullanıyor. Görsel eklendiğinde `Stack` gerekir — altta görsel,
üstünde renk katmanı ve gradyan, en üstte metin.

Not: 56 görsel @3x ile uygulama boyutunu ciddi büyütür (kabaca 15-25 MB).
Bir alternatif, yalnızca 8 bölüm için birer görsel üretip aynı bölümün
konularında paylaştırmak — hem sekiz kat küçük hem de bölüm kimliğini
güçlendirir.

---

# Dosya adlandırma

Dosya adı **`topics.json` içindeki konu kimliğiyle birebir aynı** olmalı.
Kod görseli bu kimlikle arıyor; bir harf bile farklı olursa kart görselsiz
kalır (çökmez, düz renge düşer).

Kurallar:

- Küçük harf, Türkçe karakter yok, boşluk yok (`ş`→`s`, `ç`→`c`, `ı`→`i`)
- Birden çok kelime varsa alt çizgi: `anne_baba.png`
- Uzantı `.png`
- Konu adı değil **kimlik** kullanılır: "Dedikodu ve İftira" → `giybet.png`

## Klasör yapısı

```
assets/images/topics/
├── sabir.png          # @1x — 1024×640
├── 2.0x/
│   └── sabir.png      # @2x — 2048×1280
└── 3.0x/
    └── sabir.png      # @3x — 3072×1920
```

Flutter çözünürlüğü klasör adından okur; dosya adı üç klasörde de aynı kalır.

## Tam liste (56 dosya)


**İnanç**

```
tevhid.png            # Tevhid
melekler.png          # Melekler
kader.png             # Kader
vahiy.png             # Vahiy ve Peygamberlik
seytan.png            # Şeytan
```

**İbadet**

```
namaz.png             # Namaz
zekat.png             # Zekât ve İnfak
oruc.png              # Oruç
hac.png               # Hac
dua.png               # Dua
kuran.png             # Kur'an
```

**Ahlak**

```
sabir.png             # Sabır
sukur.png             # Şükür
tovbe.png             # Tövbe ve Bağışlanma
dogruluk.png          # Doğruluk
adalet.png            # Adalet
merhamet.png          # Merhamet
kibir.png             # Kibir
giybet.png            # Dedikodu ve İftira
ofke.png              # Öfke
ihlas.png             # İhlâs ve Samimiyet
tevekkul.png          # Tevekkül
```

**İnsan İlişkileri**

```
anne_baba.png         # Anne Baba
evlilik.png           # Evlilik
bosanma.png           # Boşanma
cocuk.png             # Çocuklar
komsu.png             # Komşu ve Misafir
yetim.png             # Yetim ve Yoksul
kadin.png             # Kadın
```

**Hukuk ve Toplum**

```
miras.png             # Miras
borc.png              # Borç ve Ticaret
faiz.png              # Faiz
yemin.png             # Yemin ve Söz
savas.png             # Savaş ve Barış
yonetim.png           # Yönetim ve Danışma
hicret.png            # Hicret
```

**Ahiret**

```
olum.png              # Ölüm
kiyamet.png           # Kıyamet
hesap.png             # Hesap ve Mîzan
cennet.png            # Cennet
cehennem.png          # Cehennem
```

**Yaratılış ve Kâinat**

```
yaratilis.png         # Yaratılış
tabiat.png            # Tabiat
rizik.png             # Rızık
ilim.png              # İlim
```

**Hâller**

```
zorluk.png            # Zorluk
uzuntu.png            # Üzüntü
korku.png             # Korku
yalnizlik.png         # Yalnızlık
hastalik.png          # Hastalık ve Şifa
pismanlik.png         # Pişmanlık
haksizlik.png         # Haksızlığa Uğramak
gurbet.png            # Gurbet
basarisizlik.png      # Başarısızlık
yasli.png             # Yaşlılık
karar.png             # Karar Vermek
```

## Denetim

Görselleri koyduktan sonra eksik/fazla var mı diye:

```bash
python3 - <<'EOF'
import json, os
ids = {t['id'] for t in json.load(open('assets/data/topics.json'))['topics']}
d = 'assets/images/topics'
files = {f[:-4] for f in os.listdir(d) if f.endswith('.png')} if os.path.isdir(d) else set()
print('eksik :', sorted(ids - files) or 'yok')
print('fazla :', sorted(files - ids) or 'yok')
EOF
```

Ayrıca `pubspec.yaml` içindeki `assets:` bölümüne eklenmeli:

```yaml
    - assets/images/topics/
    - assets/images/topics/2.0x/
    - assets/images/topics/3.0x/
```
