/**
 * İkonlar. Uygulamada Material Icons (rounded) kullanılıyor; buradakiler
 * aynı ikonların sadeleştirilmiş SVG karşılıkları.
 *
 * İkon kütüphanesi kurulmadı: gereken ikon sayısı az ve hepsi
 * `currentColor` alıyor, tema değişince doğru renge geçiyor.
 */

const base = {
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.7,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
}

function Svg({ size = 20, children, ...rest }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true" {...base} {...rest}>
      {children}
    </svg>
  )
}

export const IconBook = (p) => (
  <Svg {...p}>
    <path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H10a2 2 0 0 1 2 2v13a2 2 0 0 0-2-2H5.5A1.5 1.5 0 0 1 4 15.5Z" />
    <path d="M20 5.5A1.5 1.5 0 0 0 18.5 4H14a2 2 0 0 0-2 2v13a2 2 0 0 1 2-2h4.5a1.5 1.5 0 0 0 1.5-1.5Z" />
  </Svg>
)

export const IconSearch = (p) => (
  <Svg {...p}>
    <circle cx="11" cy="11" r="6.5" />
    <path d="m16 16 4 4" />
  </Svg>
)

export const IconCalendar = (p) => (
  <Svg {...p}>
    <rect x="3.5" y="5" width="17" height="15.5" rx="3" />
    <path d="M3.5 9.5h17M8 3.5V6m8-2.5V6" />
  </Svg>
)

export const IconBookmark = (p) => (
  <Svg {...p}>
    <path d="M6.5 4.5h11a1 1 0 0 1 1 1v14l-6.5-4-6.5 4v-14a1 1 0 0 1 1-1Z" />
  </Svg>
)

export const IconSettings = (p) => (
  <Svg {...p}>
    <circle cx="12" cy="12" r="3" />
    <path d="M19.4 14.5a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5v.2a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-1-1.5 1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.5-1 1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3H9a1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8V9a1.6 1.6 0 0 0 1.5 1h.2a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1Z" />
  </Svg>
)

export const IconSwap = (p) => (
  <Svg {...p}>
    <path d="M7.5 4v16m0 0-3.2-3.2M7.5 20l3.2-3.2M16.5 20V4m0 0-3.2 3.2M16.5 4l3.2 3.2" />
  </Svg>
)

export const IconChevron = (p) => (
  <Svg {...p}>
    <path d="m9.5 5.5 6.5 6.5-6.5 6.5" />
  </Svg>
)

export const IconBack = (p) => (
  <Svg {...p}>
    <path d="M19 12H5m0 0 6-6m-6 6 6 6" />
  </Svg>
)

export const IconPlay = (p) => (
  <Svg {...p} fill="currentColor" stroke="none">
    <path d="M8 5.6a1 1 0 0 1 1.5-.9l8.4 5.4a1 1 0 0 1 0 1.7L9.5 17.3A1 1 0 0 1 8 16.4Z" />
  </Svg>
)

/* Okuma ekranındaki dinleme düğmesi — Icons.headphones_outlined. */
export const IconHeadphones = (p) => (
  <Svg {...p}>
    <path d="M4 15v-3a8 8 0 0 1 16 0v3" />
    <path d="M4 14.5h2a1.5 1.5 0 0 1 1.5 1.5v2.5A1.5 1.5 0 0 1 6 20H5a1 1 0 0 1-1-1Z" />
    <path d="M20 14.5h-2a1.5 1.5 0 0 0-1.5 1.5v2.5A1.5 1.5 0 0 0 18 20h1a1 1 0 0 0 1-1Z" />
  </Svg>
)

export const IconTextSize = (p) => (
  <Svg {...p}>
    <path d="M3 7V5h9v2M7.5 5v14M13.5 12v-1.5H21V12M17.2 10.5V19" />
  </Svg>
)

export const IconSun = (p) => (
  <Svg {...p}>
    <circle cx="12" cy="12" r="4.2" />
    <path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.2 5.2l1.5 1.5M17.3 17.3l1.5 1.5M18.8 5.2l-1.5 1.5M6.7 17.3l-1.5 1.5" />
  </Svg>
)

export const IconMoon = (p) => (
  <Svg {...p}>
    <path d="M20 14.4A8.5 8.5 0 0 1 9.6 4 8.5 8.5 0 1 0 20 14.4Z" />
  </Svg>
)

export const IconRoot = (p) => (
  <Svg {...p}>
    <circle cx="12" cy="5" r="2.2" />
    <circle cx="5" cy="18.5" r="2.2" />
    <circle cx="12" cy="18.5" r="2.2" />
    <circle cx="19" cy="18.5" r="2.2" />
    <path d="M12 7.2v3.3m0 0H5v5.8m7-5.8h7v5.8m-7-5.8v5.8" />
  </Svg>
)

export const IconAudio = (p) => (
  <Svg {...p}>
    <path d="M4 10v4M8 6.5v11M12 3.5v17M16 7.5v9M20 10.5v3" />
  </Svg>
)

export const IconNote = (p) => (
  <Svg {...p}>
    <path d="M13.5 4H6.5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-7" />
    <path d="M16.8 3.6a1.9 1.9 0 0 1 2.7 2.7L13.8 12l-3.4.7.7-3.4Z" />
  </Svg>
)

export const IconLock = (p) => (
  <Svg {...p}>
    <rect x="4.5" y="10" width="15" height="10.5" rx="2.5" />
    <path d="M8 10V7.5a4 4 0 0 1 8 0V10" />
  </Svg>
)

export const IconCheck = (p) => (
  <Svg {...p}>
    <path d="m5 12.5 4.5 4.5L19 7" />
  </Svg>
)

export const IconPlus = (p) => (
  <Svg {...p}>
    <path d="M12 5v14M5 12h14" />
  </Svg>
)

export const IconApple = (p) => (
  <Svg {...p} fill="currentColor" stroke="none">
    <path d="M16.4 12.7c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.9-1.4-.1-2.8.9-3.5.9-.7 0-1.9-.9-3.1-.8-1.6 0-3 .9-3.8 2.4-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7c1.3 0 2.1-1.1 2.9-2.3.9-1.3 1.3-2.6 1.3-2.6s-2.5-1-2.5-3.8ZM14.2 5.8c.6-.8 1-1.9.9-3-.9 0-2 .6-2.7 1.4-.6.7-1.1 1.8-.9 2.9 1 0 2-.5 2.7-1.3Z" />
  </Svg>
)

export const IconPlayStore = (p) => (
  <Svg {...p} fill="currentColor" stroke="none">
    <path d="M3.9 2.4a1.4 1.4 0 0 0-.6 1.2v16.8a1.4 1.4 0 0 0 .6 1.2l.1.1 9.4-9.6v-.2Z" />
    <path d="m16.6 15.3-3.2-3.2v-.2l3.2-3.2.1.1 3.8 2.2c1.1.6 1.1 1.7 0 2.3Z" opacity=".85" />
    <path d="m16.7 15.4-3.3-3.3-9.5 9.6c.4.4 1 .4 1.6.1Z" opacity=".7" />
    <path d="M4 2.3c-.1 0-.1 0 0 0l9.4 9.5 3.3-3.3-11.1-6.3c-.6-.3-1.2-.3-1.6.1Z" opacity=".95" />
  </Svg>
)

export const IconGithub = (p) => (
  <Svg {...p} fill="currentColor" stroke="none">
    <path d="M12 2.2a10 10 0 0 0-3.2 19.5c.5.1.7-.2.7-.5v-1.8c-2.8.6-3.4-1.3-3.4-1.3-.4-1.2-1.1-1.5-1.1-1.5-.9-.6.1-.6.1-.6 1 .1 1.5 1 1.5 1 .9 1.5 2.4 1.1 3 .8a2.2 2.2 0 0 1 .6-1.4c-2.2-.2-4.6-1.1-4.6-5a3.9 3.9 0 0 1 1-2.7 3.6 3.6 0 0 1 .1-2.7s.9-.3 2.8 1a9.5 9.5 0 0 1 5 0c1.9-1.3 2.8-1 2.8-1a3.6 3.6 0 0 1 .1 2.7 3.9 3.9 0 0 1 1 2.7c0 3.9-2.4 4.8-4.6 5a2.5 2.5 0 0 1 .7 1.9v2.8c0 .3.2.6.7.5A10 10 0 0 0 12 2.2Z" />
  </Svg>
)

export const IconHeart = (p) => (
  <Svg {...p}>
    <path d="M12 20.3s-7.3-4.5-7.3-9.4a4 4 0 0 1 7.3-2.3 4 4 0 0 1 7.3 2.3c0 4.9-7.3 9.4-7.3 9.4Z" />
  </Svg>
)

export const IconCoffee = (p) => (
  <Svg {...p}>
    <path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4Z" />
    <path d="M16 10.5h1.8a2.2 2.2 0 0 1 0 4.4H16" />
    <path d="M7 3v2.5M11 3v2.5" />
  </Svg>
)

export const IconBank = (p) => (
  <Svg {...p}>
    <path d="M3.5 9.5 12 4.5l8.5 5" />
    <path d="M5.5 9.5v8M10 9.5v8M14 9.5v8M18.5 9.5v8" />
    <path d="M3.5 19.5h17" />
  </Svg>
)

export const IconCopy = (p) => (
  <Svg {...p}>
    <rect x="9" y="9" width="11" height="11" rx="2" />
    <path d="M15 6.5V5a1.5 1.5 0 0 0-1.5-1.5h-8A1.5 1.5 0 0 0 4 5v8a1.5 1.5 0 0 0 1.5 1.5H6" />
  </Svg>
)

export const IconExternal = (p) => (
  <Svg {...p}>
    <path d="M14 4.5h5.5V10" />
    <path d="M19.5 4.5 11 13" />
    <path d="M18 14v4.5a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10" />
  </Svg>
)
