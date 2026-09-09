import { useEffect, useRef, useState } from 'react'

/**
 * Görünüme girince içeriği yumuşakça yükselten sarmalayıcı.
 *
 * IntersectionObserver tek seferlik: bölüm bir kez göründükten sonra
 * gözlem bırakılıyor, sayfa yukarı kaydırıldığında animasyon tekrarlanmıyor.
 */
export function Reveal({ children, as: Tag = 'div', delay = 0, className = '', ...rest }) {
  const ref = useRef(null)
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true)
          io.disconnect()
        }
      },
      { threshold: 0.12, rootMargin: '0px 0px -40px' },
    )

    io.observe(el)
    return () => io.disconnect()
  }, [])

  return (
    <Tag
      ref={ref}
      // Dışarıdan gelen sınıf korunur; `reveal` üstüne eklenir.
      className={`reveal${visible ? ' is-visible' : ''}${className ? ` ${className}` : ''}`}
      style={{ transitionDelay: `${delay}ms` }}
      {...rest}
    >
      {children}
    </Tag>
  )
}
