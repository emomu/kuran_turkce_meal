import { useState } from 'react'
import quran from '../data/quran.json'
import { IconSwap, IconChevron, IconPlay } from '../components/Icons'
import { StatusBar } from './StatusBar'
import { IconBook, IconSearch, IconCalendar, IconBookmark, IconSettings } from '../components/Icons'

/**
 * Hero'daki telefon.
 *
 * "Ekranlar" bölümündeki telefonla aynı store'u paylaşmıyor: iki telefon
 * ekranda aynı anda görünmüyor ama ziyaretçi aşağı indiğinde hero'da
 * bıraktığı ekranı değil turun başlangıcını görmeli. Bu yüzden hero'nun
 * yalnızca sıralama düğmesini çalıştıran küçük bir yerel durumu var.
 */
export function HeroPhone({ lang }) {
  const [byRevelation, setByRevelation] = useState(true)
  const tr = lang === 'tr'

  const list = [...quran.surahs]
    .sort((a, b) => (byRevelation ? a.revelationOrder - b.revelationOrder : a.number - b.number))
    .slice(0, 9)

  return (
    <div className="phone">
      <div className="phone__screen">
        <div className="phone__island" />
        <StatusBar />


        <div className="screen">
          <h3 className="screen__title">{tr ? "Kur'an" : 'Qur’an'}</h3>
          <p className="screen__subtitle">{tr ? 'Türkçe meal' : 'Turkish translation'}</p>

          <div className="card-continue">
            <div className="card-continue__row">
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="card-continue__label">{tr ? 'KALDIĞIN YER' : 'LAST READ'}</div>
                <div className="card-continue__name">{tr ? 'Alak' : 'Al-Alaq'}</div>
                <div className="card-continue__meta">
                  {tr ? '5. ayet · 19 ayetten' : 'verse 5 · of 19'}
                </div>
              </div>
              <span className="card-continue__play">
                <IconPlay size={20} />
              </span>
            </div>
            <div className="card-continue__bar">
              <i style={{ width: '26%' }} />
            </div>
          </div>

          <div className="card-verse">
            <div className="card-verse__label">{tr ? 'GÜNÜN AYETİ' : 'VERSE OF THE DAY'}</div>
            <p className="card-verse__text">
              {tr
                ? 'İnsana bilmediği şeyleri öğretti'
                : 'Taught man what he did not know'}
            </p>
            <div className="card-verse__source">
              {tr ? 'Alak · 5. ayet' : 'Al-Alaq · verse 5'}
            </div>
          </div>

          <div className="list-head">
            <span className="list-head__title">{tr ? 'Sureler' : 'Surahs'}</span>
            <button
              type="button"
              className="order-toggle"
              onClick={() => setByRevelation((v) => !v)}
            >
              <IconSwap size={14} />
              {byRevelation
                ? tr ? 'İniş sırası' : 'Revelation'
                : tr ? 'Mushaf sırası' : 'Mushaf'}
            </button>
          </div>

          <div style={{ marginTop: 4 }}>
            {list.map((s) => (
              <div key={s.number} className="surah-row">
                <span className="surah-row__no">
                  {byRevelation ? s.revelationOrder : s.number}
                </span>
                <span className="surah-row__body">
                  <span className="surah-row__name">{tr ? s.name : s.nameEn}</span>
                  <span className="surah-row__meta">
                    {tr ? s.meaning : s.meaningEn} ·{' '}
                    {s.place === 'mekke' ? (tr ? 'Mekke' : 'Meccan') : tr ? 'Medine' : 'Medinan'} ·{' '}
                    {tr ? `${s.ayahCount} ayet` : `${s.ayahCount} verses`}
                  </span>
                </span>
                <IconChevron size={17} className="surah-row__chevron" />
              </div>
            ))}
          </div>
        </div>

        {/* Hero'daki sekme çubuğu görsel; tur "Ekranlar" bölümünde. */}
        <nav className="tabbar" aria-hidden="true">
          {[
            [IconBook, tr ? 'Oku' : 'Read', true],
            [IconSearch, tr ? 'Ara' : 'Search'],
            [IconCalendar, tr ? 'Planlar' : 'Plans'],
            [IconBookmark, tr ? 'Kayıtlar' : 'Saved'],
            [IconSettings, tr ? 'Ayarlar' : 'Settings'],
          ].map(([Icon, label, active]) => (
            <span
              key={label}
              className={`tabbar__item${active ? ' tabbar__item--active' : ''}`}
            >
              <Icon size={21} />
              <span>{label}</span>
            </span>
          ))}
        </nav>
      </div>
    </div>
  )
}
