import { useState } from 'react'
import { Reveal } from '../components/Reveal'
import {
  IconHeart,
  IconCoffee,
  IconBank,
  IconCopy,
  IconExternal,
  IconCheck,
} from '../components/Icons'
import { activeDonationChannels } from '../data/links'

/** Kanal kimliğine göre ikon. */
const channelIcon = {
  buymeacoffee: IconCoffee,
  papara: IconHeart,
  iban: IconBank,
}

/**
 * Destek bölümü.
 *
 * Sitenin tonu sakin tutuldu: aciliyet dili, sayaç ya da hedef çubuğu yok.
 * Uygulamanın kendi bağış ekranıyla aynı duruş — bir mushaf uygulamasında
 * bağış isteği, kampanya afişi gibi durmamalı.
 *
 * Karşılığında hiçbir şey vaat edilmez; bu bir tercih değil, uygulamanın
 * Google Play'deki gönüllü bağış istisnasının şartı.
 */
export function Support({ t }) {
  if (activeDonationChannels.length === 0) return null

  return (
    <section className="section" id="support">
      <div className="shell">
        <Reveal className="support">
          <span className="eyebrow">
            <IconHeart size={13} style={{ verticalAlign: '-2px', marginRight: 4 }} />
            {t.nav.support}
          </span>
          <h2 className="section-title" style={{ marginTop: 8 }}>
            {t.supportTitle}
          </h2>
          <p className="section-lede">{t.supportLede}</p>

          <div className="support__channels">
            {activeDonationChannels.map((channel) => (
              <Channel
                key={channel.id}
                channel={channel}
                label={t.supportChannels[channel.id]}
                copiedLabel={t.supportCopied}
              />
            ))}
          </div>

          <p className="support__note">{t.supportNote}</p>
        </Reveal>
      </div>
    </section>
  )
}

/**
 * Tek bir bağış yolu.
 *
 * Bağlantı kanalları yeni sekmede açılır; hesap numarası kanalları panoya
 * kopyalanır ve iki saniye "kopyalandı" gösterir. Geri bildirim olmadan
 * kopyalama sessiz kalır ve kullanıcı düğmeye tekrar basar.
 */
function Channel({ channel, label, copiedLabel }) {
  const [copied, setCopied] = useState(false)
  const Icon = channelIcon[channel.id] ?? IconHeart

  if (channel.kind === 'copy') {
    // Alıcı adı da kopyalanır: bankalar havalede ad ile IBAN'ın eşleşmesini
    // istiyor, yalnızca numarayı kopyalayan kullanıcı adı ayrıca aramak
    // zorunda kalıyordu.
    const clipboardText = channel.holder
      ? `${channel.value}\n${channel.holder}`
      : channel.value

    const copy = async () => {
      try {
        await navigator.clipboard.writeText(clipboardText)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      } catch {
        // Pano izni yoksa (http üzerinden açılmış bir sayfa gibi) metin
        // zaten ekranda duruyor; kullanıcı elle seçebilir.
      }
    }

    return (
      <button className="support__channel" onClick={copy} type="button">
        <span className="support__channel-icon">
          <Icon size={18} />
        </span>
        <span className="support__channel-text">
          <span className="support__channel-title">{label.title}</span>
          <span className="support__channel-value">{channel.value}</span>
          {channel.holder && (
            <span className="support__channel-holder">
              {label.holderLabel} {channel.holder}
            </span>
          )}
        </span>
        <span className="support__channel-action">
          {copied ? <IconCheck size={16} /> : <IconCopy size={16} />}
          {copied ? copiedLabel : label.action}
        </span>
      </button>
    )
  }

  return (
    <a
      className="support__channel"
      href={channel.value}
      target="_blank"
      rel="noreferrer"
    >
      <span className="support__channel-icon">
        <Icon size={18} />
      </span>
      <span className="support__channel-text">
        <span className="support__channel-title">{label.title}</span>
        <span className="support__channel-value">{label.subtitle}</span>
      </span>
      <span className="support__channel-action">
        <IconExternal size={15} />
        {label.action}
      </span>
    </a>
  )
}
