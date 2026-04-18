// desktop.jsx — Napat Dev three-pane vault window
// Custom chrome to match the three-pane layout from the reference image

const { useState, useMemo } = React;

function TrafficLights() {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#ff5f57', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }} />
      <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#febc2e', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }} />
      <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#28c840', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }} />
    </div>
  );
}

// ── Leftmost sidebar (vault + profile) ─────────────────────────
function VaultSidebar() {
  return (
    <div style={{
      width: 200, flexShrink: 0,
      padding: '10px 10px 12px',
      display: 'flex', flexDirection: 'column', gap: 14,
      background: 'var(--sidebar-grad)',
      borderRight: '0.5px solid var(--hairline)',
      position: 'relative',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', height: 28, gap: 10 }}>
        <TrafficLights />
      </div>

      {/* Vault picker */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '7px 8px 7px 8px', borderRadius: 10,
        background: 'var(--card)',
        boxShadow: 'inset 0 0 0 0.5px var(--hairline), 0 1px 2px rgba(0,0,0,0.04)',
      }}>
        <div style={{
          width: 22, height: 22, borderRadius: 6,
          background: 'linear-gradient(135deg, #5b7cfa, #8aa1ff)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.5)',
        }}>
          <svg width="12" height="12" viewBox="0 0 16 16" fill="none">
            <path d="M3 7l5-4 5 4v6H3V7z" fill="#fff"/>
            <circle cx="8" cy="9" r="1.5" fill="#5b7cfa"/>
          </svg>
        </div>
        <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--ink)', flex: 1 }}>Napat Workspace</div>
        {Icon.chevDown(10, 'var(--muted)')}
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <SideRow icon={Icon.user(13, 'var(--muted-2)')} label="Profile" />
        <SideRow icon={Icon.people(13, 'var(--muted-2)')} label="Family" />
        <SideRow icon={Icon.vault(13, 'var(--muted-2)')} label="Personal" />
        <SideRow icon={Icon.tag(13, 'var(--muted-2)')} label="Tags" />
      </div>

      <div style={{ marginTop: 'auto', fontSize: 10.5, color: 'var(--muted-2)', letterSpacing: 0.3, textTransform: 'uppercase', paddingLeft: 6 }}>
        Shared with me
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2, marginTop: -8 }}>
        <SideRow icon={<Dot c="#f5a524" />} label="Design team" />
        <SideRow icon={<Dot c="#16a34a" />} label="Ops" />
        <SideRow icon={<Dot c="#8b5cf6" />} label="Clients" />
      </div>
    </div>
  );
}

function SideRow({ icon, label, active }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      height: 26, padding: '0 8px', borderRadius: 8,
      background: active ? 'rgba(15,23,42,0.06)' : 'transparent',
      fontSize: 12.5, color: 'var(--ink-2)', fontWeight: 500,
      cursor: 'default',
    }}>
      <div style={{ width: 14, display: 'flex', justifyContent: 'center' }}>{icon}</div>
      <span>{label}</span>
    </div>
  );
}
function Dot({ c }) {
  return <div style={{ width: 8, height: 8, borderRadius: '50%', background: c }} />;
}

// ── Toolbar row (nav arrows + search + new) ────────────────────
function Toolbar({ query, setQuery }) {
  return (
    <div style={{
      height: 44, display: 'flex', alignItems: 'center', gap: 10,
      padding: '0 10px',
      borderBottom: '0.5px solid var(--hairline)',
      background: 'var(--chrome)',
      backdropFilter: 'blur(20px)',
      WebkitBackdropFilter: 'blur(20px)',
    }}>
      <div style={{ display: 'flex', gap: 2 }}>
        <IconBtn>{Icon.chevL(13, 'var(--muted)')}</IconBtn>
        <IconBtn>{Icon.chevR(13, 'var(--muted-2)')}</IconBtn>
      </div>

      <div style={{
        flex: 1, height: 28, display: 'flex', alignItems: 'center', gap: 8,
        padding: '0 10px', borderRadius: 8,
        background: 'var(--card)',
        boxShadow: 'inset 0 0 0 0.5px var(--hairline-strong), 0 1px 1px rgba(0,0,0,0.03)',
      }}>
        {Icon.search(12, 'var(--muted-2)')}
        <input
          value={query}
          onChange={e => setQuery(e.target.value)}
          placeholder="Search in Napat Workspace"
          style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontSize: 12.5, color: 'var(--ink)', fontFamily: 'var(--font-sans)',
          }}
        />
        <kbd style={{
          fontSize: 10, color: 'var(--muted-2)', fontFamily: 'var(--font-mono)',
          padding: '1px 5px', borderRadius: 4,
          background: 'var(--surface-3)',
        }}>⌘F</kbd>
      </div>

      <IconBtn>
        <div style={{ position: 'relative' }}>
          {Icon.bell(14, 'var(--ink-2)')}
          <div style={{ position: 'absolute', top: -1, right: -1, width: 6, height: 6, borderRadius: '50%', background: '#e11d48', boxShadow: '0 0 0 1.5px var(--card-solid)' }} />
        </div>
      </IconBtn>

      <button style={{
        height: 28, padding: '0 12px', borderRadius: 8, border: 'none',
        background: 'linear-gradient(180deg, #6d8bfc, #4e6df0)',
        color: '#fff', fontSize: 12.5, fontWeight: 600,
        display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
        whiteSpace: 'nowrap', flexShrink: 0,
        boxShadow: 'inset 0 0.5px 0 rgba(255,255,255,0.3), 0 1px 2px rgba(78,109,240,0.4)',
      }}>
        {Icon.plus(11, '#fff')} New Item
      </button>
    </div>
  );
}

function IconBtn({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 28, height: 28, borderRadius: 7, border: 'none',
      background: 'transparent', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}
    onMouseEnter={e => e.currentTarget.style.background = 'rgba(15,23,42,0.06)'}
    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
      {children}
    </button>
  );
}

// ── Item list (middle pane) ────────────────────────────────────
function ItemList({ items, selectedId, onSelect, query }) {
  const filtered = useMemo(() => {
    if (!query) return items;
    const q = query.toLowerCase();
    return items.filter(e => e.name.toLowerCase().includes(q) || e.user.toLowerCase().includes(q));
  }, [items, query]);

  // group by letter
  const grouped = useMemo(() => {
    const groups = {};
    for (const it of filtered) (groups[it.group] ||= []).push(it);
    return groups;
  }, [filtered]);

  return (
    <div style={{
      width: 290, flexShrink: 0,
      borderRight: '0.5px solid var(--hairline)',
      display: 'flex', flexDirection: 'column',
      background: 'var(--list-bg)',
    }}>
      {/* category header */}
      <div style={{
        height: 40, display: 'flex', alignItems: 'center', gap: 8,
        padding: '0 14px', borderBottom: '0.5px solid var(--hairline)',
      }}>
        {Icon.grid(13, 'var(--muted)')}
        <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--ink)', whiteSpace: 'nowrap' }}>All Categories</div>
        {Icon.chevDown(10, 'var(--muted-2)')}
        <div style={{ flex: 1 }} />
        <IconBtn>{Icon.filter(13, 'var(--muted)')}</IconBtn>
        <IconBtn>{Icon.sort(13, 'var(--muted)')}</IconBtn>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '4px 0' }}>
        {Object.entries(grouped).map(([letter, list]) => (
          <div key={letter}>
            <div style={{
              padding: '10px 14px 4px',
              fontSize: 10.5, fontWeight: 700, color: 'var(--muted-2)',
              letterSpacing: 0.3,
            }}>{letter}</div>
            {list.map(it => (
              <ItemRow
                key={it.id}
                entry={it}
                selected={it.id === selectedId}
                onClick={() => onSelect(it.id)}
              />
            ))}
          </div>
        ))}
        {filtered.length === 0 && (
          <div style={{ padding: 24, textAlign: 'center', color: 'var(--muted-2)', fontSize: 12 }}>
            No items match "{query}".
          </div>
        )}
      </div>
    </div>
  );
}

function ItemRow({ entry, selected, onClick }) {
  return (
    <div onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '7px 10px', margin: '0 6px', borderRadius: 8,
      background: selected ? 'linear-gradient(180deg, #6d8bfc, #4e6df0)' : 'transparent',
      color: selected ? '#fff' : 'var(--ink)',
      cursor: 'pointer',
      boxShadow: selected ? '0 2px 8px rgba(78,109,240,0.25)' : 'none',
    }}
    onMouseEnter={e => { if (!selected) e.currentTarget.style.background = 'rgba(15,23,42,0.04)'; }}
    onMouseLeave={e => { if (!selected) e.currentTarget.style.background = 'transparent'; }}
    >
      <BrandMark seed={entry.brand} size={30} radius={7} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap',
          overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{entry.name}</div>
        <div style={{
          fontSize: 11.5, opacity: selected ? 0.8 : 0.6,
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{entry.user}</div>
      </div>
    </div>
  );
}

// ── Detail pane ────────────────────────────────────────────────
function DetailPane({ entry, revealed, setRevealed, density }) {
  const pad = density === 'dense' ? 14 : 22;
  if (!entry) return null;

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: 'var(--card-solid)', minWidth: 0 }}>
      {/* detail toolbar */}
      <div style={{
        height: 40, display: 'flex', alignItems: 'center', gap: 12,
        padding: '0 14px', borderBottom: '0.5px solid var(--hairline)',
      }}>
        <BrandMark seed={entry.brand} size={18} radius={4} />
        <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--ink)', display: 'flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap' }}>
          <span>{entry.kind === 'Document' ? 'Document' : 'Login'}</span>
          {Icon.chevDown(10, 'var(--muted-2)')}
        </div>
        <div style={{ flex: 1 }} />
        <ToolbarAction icon={Icon.share(13)} label="Share" />
        <ToolbarAction icon={Icon.edit(13)} label="Edit" />
        <IconBtn>{Icon.dots(14, 'var(--muted)')}</IconBtn>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: `${pad}px ${pad+6}px` }}>
        {/* Hero */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 16,
          paddingBottom: density === 'dense' ? 12 : 18,
        }}>
          <BrandMark seed={entry.brand} size={58} radius={13} />
          <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.3 }}>{entry.name.split('(')[0].trim()}</div>
        </div>

        {entry.kind === 'Document' ? (
          <DocumentBody entry={entry} />
        ) : (
          <LoginBody entry={entry} revealed={revealed} setRevealed={setRevealed} density={density} />
        )}

        <div style={{
          marginTop: density === 'dense' ? 18 : 28,
          display: 'flex', alignItems: 'center', gap: 8,
          color: 'var(--muted)', fontSize: 12,
        }}>
          {Icon.chevR(10, 'var(--muted)')}
          <span>Last edited Monday, December 11, 2023 at 7:17:03 p.m.</span>
        </div>
      </div>
    </div>
  );
}

function ToolbarAction({ icon, label }) {
  return (
    <button style={{
      height: 28, padding: '0 10px', borderRadius: 7, border: 'none',
      background: 'transparent', cursor: 'pointer',
      display: 'flex', alignItems: 'center', gap: 6,
      fontSize: 12, color: 'var(--ink-2)', fontWeight: 500,
    }}
    onMouseEnter={e => e.currentTarget.style.background = 'rgba(15,23,42,0.06)'}
    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
      {icon}{label}
    </button>
  );
}

function LoginBody({ entry, revealed, setRevealed, density }) {
  const gap = density === 'dense' ? 6 : 10;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap }}>
      <Field label="username" value={entry.user} copy />
      <FieldRow label="passkey" right={
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'var(--muted)', fontSize: 12 }}>
          <span>created Dec 11, 2023</span>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: '#efe9ee', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="11" height="11" viewBox="0 0 16 16" fill="none"><circle cx="6" cy="8" r="3" stroke="#8a6e90" strokeWidth="1.5"/><path d="M9 8h6v2m-3-2v2" stroke="#8a6e90" strokeWidth="1.5"/></svg>
          </div>
        </div>
      } />
      <FieldRow label="password" right={
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <PasswordField revealed={revealed} onToggle={() => setRevealed(v => !v)} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11.5, color: 'var(--muted)' }}>
            <span style={{ color: 'var(--good)', fontWeight: 600 }}>Excellent</span>
            <div style={{
              width: 14, height: 14, borderRadius: '50%', background: 'var(--good)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {Icon.check(9, '#fff')}
            </div>
          </div>
        </div>
      } />
      <Field label="website" value="https://aperio.design" link />
    </div>
  );
}

function DocumentBody({ entry }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <FieldRow label="file" right={
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--ink)' }}>
          <div style={{ width: 22, height: 22, borderRadius: 5, background: '#f3ede2', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="11" height="11" viewBox="0 0 16 16" fill="none"><path d="M4 3h6l3 3v7H4V3z" stroke="#a77d2e" strokeWidth="1.4" fill="none"/></svg>
          </div>
          contract.pdf · {entry.user}
        </div>
      } />
      <Field label="tags" value="client · retainer · 2023" />
    </div>
  );
}

function Field({ label, value, copy, link }) {
  return (
    <div style={{
      padding: '9px 0',
      borderBottom: '0.5px solid var(--hairline)',
      display: 'flex', flexDirection: 'column', gap: 2,
    }}>
      <div style={{ fontSize: 11.5, color: 'var(--accent-ink)', fontWeight: 600 }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 13,
        color: link ? 'var(--accent)' : 'var(--ink)',
        textDecoration: link ? 'underline' : 'none',
      }}>
        {value}
      </div>
    </div>
  );
}

function FieldRow({ label, right }) {
  return (
    <div style={{
      padding: '9px 0',
      borderBottom: '0.5px solid var(--hairline)',
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      <div style={{ fontSize: 11.5, color: 'var(--accent-ink)', fontWeight: 600, minWidth: 80 }}>{label}</div>
      <div style={{ flex: 1 }} />
      {right}
    </div>
  );
}

function PasswordField({ revealed, onToggle }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 6,
      fontFamily: 'var(--font-mono)', fontSize: 13, letterSpacing: revealed ? 0 : 2,
      color: 'var(--ink)',
    }}>
      <span>{revealed ? 'Fern8-Cliff!ride' : '••••••••••••'}</span>
      <button onClick={onToggle} style={{
        border: 'none', background: 'transparent', cursor: 'pointer',
        width: 22, height: 22, borderRadius: 5,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {Icon.eye(13, 'var(--muted)')}
      </button>
    </div>
  );
}

// ── Whole window ───────────────────────────────────────────────
function DesktopWindow({ selectedId, setSelectedId, density }) {
  const [query, setQuery] = useState('');
  const [revealed, setRevealed] = useState(false);
  const entry = ENTRIES.find(e => e.id === selectedId) || ENTRIES[2];

  return (
    <div style={{
      width: 920, height: 580,
      borderRadius: 14, overflow: 'hidden',
      boxShadow: 'var(--shadow-window)',
      background: 'var(--card-solid)',
      display: 'flex',
      fontFamily: 'var(--font-sans)',
      position: 'relative',
    }}>
      <VaultSidebar />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <Toolbar query={query} setQuery={setQuery} />
        <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
          <ItemList items={ENTRIES} selectedId={entry.id} onSelect={setSelectedId} query={query} />
          <DetailPane entry={entry} revealed={revealed} setRevealed={setRevealed} density={density} />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DesktopWindow });
