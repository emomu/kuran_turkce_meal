/**
 * Okuma planları ekranı — plans_screen.dart.
 *
 * Dört hazır plan: kronolojik 365 / 180 gün, mushaf 30 / 90 gün.
 * Her kartın sağ üstünde planın hangi sıralamayı izlediğini gösteren bir
 * rozet var; iniş sıralı planlarda vurgu renginde. İlerleme çubuğu
 * yalnızca başlanmış planlarda çizilir — boş çubuklar listeyi
 * kalabalıklaştırıyor.
 */
const PLANS = [
  {
    id: 'revelation365',
    revelation: true,
    started: 113,
    days: 365,
    perDay: 17,
    tr: {
      name: 'Bir Yılda Kronolojik',
      desc: "Kur'an'ı indiği sıraya göre bir yılda okuyun. Günde ortalama on yedi ayet; vahyin nasıl geliştiğini adım adım izlersiniz.",
    },
    en: {
      name: 'Chronological in a Year',
      desc: 'Read the Qur’an in the order it was revealed, over a year. About seventeen verses a day; you follow how the revelation unfolded.',
    },
  },
  {
    id: 'revelation180',
    revelation: true,
    days: 180,
    perDay: 35,
    tr: {
      name: 'Altı Ayda Kronolojik',
      desc: 'Aynı kronolojik akış, daha derli toplu bir tempoda. Günde ortalama otuz beş ayet.',
    },
    en: {
      name: 'Chronological in Six Months',
      desc: 'The same chronological flow at a brisker pace. About thirty-five verses a day.',
    },
  },
  {
    id: 'mushaf30',
    revelation: false,
    days: 30,
    perDay: 208,
    tr: {
      name: 'Otuz Günde Hatim',
      desc: 'Mushaf sırasıyla bir ayda hatim. Ramazan için düşünülmüş klasik tempo; günde bir cüz.',
    },
    en: {
      name: 'Complete in Thirty Days',
      desc: 'The Mushaf order in a month. The classic pace, meant for Ramadan; one juz a day.',
    },
  },
  {
    id: 'mushaf90',
    revelation: false,
    days: 90,
    perDay: 70,
    tr: {
      name: 'Üç Ayda Hatim',
      desc: 'Mushaf sırasıyla, acele etmeden. Günde ortalama yetmiş ayet.',
    },
    en: {
      name: 'Complete in Three Months',
      desc: 'The Mushaf order, unhurried. About seventy verses a day.',
    },
  },
]

export function PlansScreen({ lang }) {
  const tr = lang === 'tr'

  return (
    <div className="screen">
      <h3 className="screen__title">{tr ? 'Planlar' : 'Plans'}</h3>
      <p className="screen__subtitle" style={{ marginBottom: 'var(--lg)' }}>
        {tr ? 'Kendi temponda oku' : 'Read at your own pace'}
      </p>

      {PLANS.map((p) => {
        const t = tr ? p.tr : p.en
        const fraction = p.started ? p.started / p.days : 0

        return (
          <div key={p.id} className="plan-card">
            <div className="plan-card__row">
              <span className="plan-card__name">{t.name}</span>
              <span
                className={`plan-card__badge${
                  p.revelation ? ' plan-card__badge--revelation' : ''
                }`}
              >
                {p.revelation
                  ? tr ? 'İniş sırası' : 'Revelation'
                  : tr ? 'Mushaf' : 'Mushaf'}
              </span>
            </div>

            <p className="plan-card__desc">{t.desc}</p>

            <div className="plan-card__stats">
              <span className="plan-card__days">
                {tr ? `${p.days} gün` : `${p.days} days`}
              </span>
              <span>
                {tr ? `· günde ~${p.perDay} ayet` : `· ~${p.perDay} verses a day`}
              </span>
              {p.started && (
                <span className="plan-card__progress">
                  {p.started}/{p.days}
                </span>
              )}
            </div>

            {p.started && (
              <div className="plan-card__bar">
                <i style={{ width: `${fraction * 100}%` }} />
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
