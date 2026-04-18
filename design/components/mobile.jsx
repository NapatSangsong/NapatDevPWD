// mobile.jsx — Napat Dev mobile Home screen
// Uses the iOS frame's device chrome (status bar + home indicator) but with custom content

const { useState: useMState } = React;

function MobileHome() {
  return (
    <div style={{
      width: 340, height: 672, borderRadius: 44, overflow: 'hidden',
      position: 'relative', background: 'var(--card-solid)',
      boxShadow: 'var(--shadow-phone)',
      fontFamily: 'var(--font-sans)',
      WebkitFontSmoothing: 'antialiased',
    }}>
      {/* background tint */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'var(--phone-bg)',
      }} />

      {/* Status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, zIndex: 20,
        height: 44, display: 'flex', alignItems: 'center',
        justifyContent: 'space-between', padding: '0 22px 0 28px',
      }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--status-ink)', letterSpacing: 0.2 }}>11:14</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, color: 'var(--status-ink)' }}>
          {/* cellular */}
          <svg width="16" height="10" viewBox="0 0 17 11"><rect x="0" y="7" width="3" height="4" rx="0.6" fill="currentColor"/><rect x="4.5" y="5" width="3" height="6" rx="0.6" fill="currentColor"/><rect x="9" y="2.5" width="3" height="8.5" rx="0.6" fill="currentColor"/><rect x="13.5" y="0" width="3" height="11" rx="0.6" fill="currentColor"/></svg>
          {/* wifi */}
          <svg width="14" height="10" viewBox="0 0 15 11"><path d="M7.5 3c2 0 3.8.8 5.2 2.1l.9-1A9 9 0 007.5 1a9 9 0 00-6.1 3.1l.9 1A7.5 7.5 0 017.5 3z" fill="currentColor"/><path d="M7.5 6.2c1.2 0 2.3.5 3 1.2l.9-.9A5.5 5.5 0 007.5 4.8c-1.5 0-2.8.6-3.9 1.7l.9.9c.8-.7 1.8-1.2 3-1.2z" fill="currentColor"/><circle cx="7.5" cy="9.2" r="1.2" fill="currentColor"/></svg>
          {/* battery */}
          <svg width="24" height="11" viewBox="0 0 25 12"><rect x="0.5" y="0.5" width="21" height="10.5" rx="3" stroke="currentColor" strokeOpacity="0.4" fill="none"/><rect x="2" y="2" width="18" height="7.5" rx="1.5" fill="currentColor"/><path d="M23 4v3.5c.7-.2 1.2-.9 1.2-1.75S23.7 4.2 23 4z" fill="currentColor" fillOpacity="0.4"/></svg>
        </div>
      </div>

      {/* Content */}
      <div style={{
        position: 'relative', zIndex: 2,
        paddingTop: 56,
        height: '100%',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Header */}
        <div style={{ padding: '6px 20px 14px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--muted)' }}>
              <div style={{
                width: 22, height: 22, borderRadius: 6,
                background: 'linear-gradient(135deg, #5b7cfa, #8aa1ff)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width="11" height="11" viewBox="0 0 16 16"><path d="M3 7l5-4 5 4v6H3V7z" fill="#fff"/></svg>
              </div>
            </div>
            <div style={{ fontSize: 30, fontWeight: 700, letterSpacing: -0.6, color: 'var(--ink)', marginTop: 6 }}>Home</div>
            <div style={{ fontSize: 13, color: 'var(--muted)', fontWeight: 500 }}>Martinez Family</div>
          </div>
          <button style={{
            width: 34, height: 34, borderRadius: '50%', border: 'none',
            background: 'linear-gradient(180deg, #6d8bfc, #4e6df0)',
            color: '#fff', cursor: 'pointer',
            boxShadow: '0 4px 10px rgba(78,109,240,0.35)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {Icon.plus(14, '#fff')}
          </button>
        </div>

        {/* Quick tiles */}
        <div style={{ padding: '0 16px 12px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <QuickTile
            brand="harbor"
            label="Harbor"
            subline="luca_martinez@fast…"
            meta="password"
            dots
          />
          <QuickTile
            brand="basin"
            label="Citibank Visa"
            subline="4242 4242"
            meta="number"
            dots
          />
        </div>

        {/* Favorites list */}
        <div style={{
          margin: '4px 16px 0', borderRadius: 14,
          background: 'var(--card)',
          boxShadow: '0 0 0 0.5px var(--hairline), 0 1px 2px rgba(0,0,0,0.04)',
          overflow: 'hidden',
          flex: 1,
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '10px 14px', borderBottom: '0.5px solid var(--hairline)',
          }}>
            <div style={{
              width: 18, height: 18, borderRadius: 5,
              background: '#f5a524', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="10" height="10" viewBox="0 0 16 16"><path d="M8 2l1.8 3.8L14 6.4l-3 2.9.7 4.2L8 11.5 4.3 13.5 5 9.3l-3-2.9 4.2-.6L8 2z" fill="#fff"/></svg>
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--ink)', flex: 1 }}>Favorites</div>
            {Icon.chevDown(11, 'var(--muted)')}
          </div>
          {MOBILE_HOME.favorites.map((f, i) => (
            <div key={f.id} style={{
              display: 'flex', alignItems: 'center', gap: 11,
              padding: '9px 14px',
              borderBottom: i < MOBILE_HOME.favorites.length - 1 ? '0.5px solid var(--hairline)' : 'none',
            }}>
              <BrandMark seed={f.brand} size={30} radius={7} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--ink)' }}>{f.name}</div>
                <div style={{
                  fontSize: 11.5, color: 'var(--muted)',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{f.user}</div>
              </div>
              <div style={{ color: 'var(--muted-2)' }}>{Icon.people(13)}</div>
            </div>
          ))}
        </div>

        {/* Generator card — original feature tied to the Generator tab */}
        <div style={{ padding: '10px 16px 0' }}>
          <div style={{
            borderRadius: 14,
            background: 'var(--card)',
            boxShadow: '0 0 0 0.5px var(--hairline), 0 1px 2px rgba(0,0,0,0.04)',
            padding: '12px 14px',
            position: 'relative', overflow: 'hidden',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 28, height: 28, borderRadius: 7,
                background: 'var(--accent-soft)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                {Icon.key(15, 'var(--accent-ink)')}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 10.5, color: 'var(--accent-ink)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.4 }}>Generator</div>
                <div style={{
                  fontFamily: 'var(--font-mono)', fontSize: 14, fontWeight: 500,
                  color: 'var(--ink)', marginTop: 3, letterSpacing: 0.3,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>Fern8-Cliff!ride-42</div>
              </div>
              <button style={{
                border: 'none', background: 'var(--surface-3)', color: 'var(--ink-2)',
                width: 28, height: 28, borderRadius: 7, cursor: 'pointer', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {Icon.copy(13, 'var(--ink-2)')}
              </button>
            </div>
          </div>
        </div>

        {/* Tab bar */}
        <div style={{
          marginTop: 12,
          paddingBottom: 22,
          display: 'flex', justifyContent: 'space-around',
          borderTop: '0.5px solid var(--hairline)',
          background: 'var(--chrome)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
        }}>
          <TabItem icon={Icon.home(22, 'var(--ink)')} label="Home" active />
          <TabItem icon={Icon.list(22, 'var(--muted-2)')} label="Items" />
          <TabItem icon={Icon.search(20, 'var(--muted-2)')} label="Search" />
          <TabItem icon={Icon.key(22, 'var(--muted-2)')} label="Generator" />
        </div>

        {/* Home indicator */}
        <div style={{
          position: 'absolute', bottom: 6, left: 0, right: 0, display: 'flex', justifyContent: 'center',
        }}>
          <div style={{ width: 120, height: 4, borderRadius: 2, background: 'rgba(0,0,0,0.35)' }} />
        </div>
      </div>
    </div>
  );
}

function QuickTile({ brand, label, subline, meta, dots }) {
  return (
    <div style={{
      padding: '10px 12px', borderRadius: 12,
      background: 'var(--card)',
      boxShadow: '0 0 0 0.5px var(--hairline), 0 1px 2px rgba(0,0,0,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
        <BrandMark seed={brand} size={18} radius={4} />
        <div style={{ fontSize: 11.5, fontWeight: 600, color: 'var(--ink)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</div>
      </div>
      <div style={{ fontSize: 10.5, color: 'var(--accent-ink)', fontWeight: 600, marginTop: 8 }}>{meta}</div>
      <div style={{
        fontSize: 12, color: 'var(--ink)', marginTop: 1,
        fontFamily: dots ? 'var(--font-mono)' : undefined,
        letterSpacing: dots ? 1.5 : 0,
      }}>
        {dots && meta === 'password' ? '•••••••••' : subline}
      </div>
    </div>
  );
}

function TabItem({ icon, label, active }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
      padding: '6px 8px',
      color: active ? 'var(--ink)' : 'var(--muted-2)',
    }}>
      {icon}
      <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: 0.1 }}>{label}</div>
      {active && <div style={{ width: 22, height: 2, borderRadius: 1, background: 'var(--ink)', marginTop: 1 }} />}
    </div>
  );
}

Object.assign(window, { MobileHome });
