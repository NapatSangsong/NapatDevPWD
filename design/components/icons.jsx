// icons.jsx — small UI icons + original "brand" marks for fictional entries

// ───────── UI icons ─────────
const Icon = {
  chevL: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M10 3l-5 5 5 5" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>
  ),
  chevR: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M6 3l5 5-5 5" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>
  ),
  chevDown: (s=12,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M3 6l5 5 5-5" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>
  ),
  search: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><circle cx="7" cy="7" r="4.5" stroke={c} strokeWidth="1.5"/><path d="M10.5 10.5L14 14" stroke={c} strokeWidth="1.5" strokeLinecap="round"/></svg>
  ),
  plus: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M8 3v10M3 8h10" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>
  ),
  bell: (s=15,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M8 2c-2.2 0-4 1.8-4 4v2.5L3 10.5h10L12 8.5V6c0-2.2-1.8-4-4-4z" stroke={c} strokeWidth="1.4" strokeLinejoin="round"/><path d="M6.5 12.5a1.5 1.5 0 003 0" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>
  ),
  sort: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M4 3v10M4 13l-2-2M4 13l2-2M11 3v10M11 3l-2 2M11 3l2 2" stroke={c} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/></svg>
  ),
  filter: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M2 4h12M4 8h8M6 12h4" stroke={c} strokeWidth="1.5" strokeLinecap="round"/></svg>
  ),
  grid: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><rect x="2" y="2" width="5" height="5" rx="1" stroke={c} strokeWidth="1.4"/><rect x="9" y="2" width="5" height="5" rx="1" stroke={c} strokeWidth="1.4"/><rect x="2" y="9" width="5" height="5" rx="1" stroke={c} strokeWidth="1.4"/><rect x="9" y="9" width="5" height="5" rx="1" stroke={c} strokeWidth="1.4"/></svg>
  ),
  user: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><circle cx="8" cy="5.5" r="2.5" stroke={c} strokeWidth="1.4"/><path d="M3 13c1-2.5 3-3.5 5-3.5S12 10.5 13 13" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>
  ),
  share: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M8 10V2m0 0L5 5m3-3l3 3" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M3 9v4a1 1 0 001 1h8a1 1 0 001-1V9" stroke={c} strokeWidth="1.5" strokeLinecap="round"/></svg>
  ),
  edit: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M11.5 2.5l2 2L5 13H3v-2l8.5-8.5z" stroke={c} strokeWidth="1.5" strokeLinejoin="round"/></svg>
  ),
  dots: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16"><circle cx="4" cy="8" r="1.2" fill={c}/><circle cx="8" cy="8" r="1.2" fill={c}/><circle cx="12" cy="8" r="1.2" fill={c}/></svg>
  ),
  check: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M3 8l3 3 7-7" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
  ),
  eye: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M1.5 8s2.5-4.5 6.5-4.5S14.5 8 14.5 8 12 12.5 8 12.5 1.5 8 1.5 8z" stroke={c} strokeWidth="1.4"/><circle cx="8" cy="8" r="2" stroke={c} strokeWidth="1.4"/></svg>
  ),
  copy: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><rect x="5" y="5" width="9" height="9" rx="1.5" stroke={c} strokeWidth="1.4"/><path d="M11 5V3.5A1.5 1.5 0 009.5 2h-6A1.5 1.5 0 002 3.5v6A1.5 1.5 0 003.5 11H5" stroke={c} strokeWidth="1.4"/></svg>
  ),
  link: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M9 7l-2 2m-1-3L4.5 7.5a2.5 2.5 0 003.5 3.5L9.5 9.5M7 10l2-2m1 3l1.5-1.5a2.5 2.5 0 00-3.5-3.5L6.5 7.5" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>
  ),
  people: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><circle cx="6" cy="6" r="2.2" stroke={c} strokeWidth="1.3"/><circle cx="11" cy="7" r="1.7" stroke={c} strokeWidth="1.3"/><path d="M2.5 12.5c.5-2 2-3 3.5-3s3 1 3.5 3M9.5 12.5c.4-1.6 1.6-2.4 2.7-2.4 1.1 0 2.2.8 2.6 2.4" stroke={c} strokeWidth="1.3" strokeLinecap="round"/></svg>
  ),
  tag: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><path d="M8.5 2h4.5v4.5L7 13 2.5 8.5 8.5 2z" stroke={c} strokeWidth="1.4" strokeLinejoin="round"/><circle cx="10.5" cy="4.5" r=".8" fill={c}/></svg>
  ),
  key: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><circle cx="5" cy="8" r="3" stroke={c} strokeWidth="1.4"/><path d="M8 8h6m-2 0v2m-2-2v3" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>
  ),
  vault: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><rect x="2" y="3" width="12" height="10" rx="1.5" stroke={c} strokeWidth="1.4"/><circle cx="8" cy="8" r="2" stroke={c} strokeWidth="1.4"/><path d="M8 5.5v-1M8 11.5v1" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>
  ),
  globe: (s=14,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="6" stroke={c} strokeWidth="1.4"/><path d="M2 8h12M8 2c2 2 2 10 0 12M8 2c-2 2-2 10 0 12" stroke={c} strokeWidth="1.3"/></svg>
  ),
  home: (s=20,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none"><path d="M3 11l9-7 9 7v9a2 2 0 01-2 2h-4v-6h-6v6H5a2 2 0 01-2-2v-9z" stroke={c} strokeWidth="1.7" strokeLinejoin="round"/></svg>
  ),
  list: (s=20,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none"><rect x="4" y="5" width="16" height="14" rx="2" stroke={c} strokeWidth="1.7"/><path d="M8 9h8M8 13h8M8 17h5" stroke={c} strokeWidth="1.7" strokeLinecap="round"/></svg>
  ),
  scan: (s=20,c='currentColor') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none"><path d="M4 8V6a2 2 0 012-2h2M20 8V6a2 2 0 00-2-2h-2M4 16v2a2 2 0 002 2h2M20 16v2a2 2 0 01-2 2h-2" stroke={c} strokeWidth="1.8" strokeLinecap="round"/><path d="M7 12h10" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>
  ),
};

// ───────── Abstract brand marks (ORIGINAL, fictional) ─────────
// Each is a colored tile with a simple geometric mark.
function BrandMark({ seed, size = 32, radius = 8 }) {
  const p = BRANDS[seed] || BRANDS.default;
  return (
    <div style={{
      width: size, height: size, borderRadius: radius,
      background: p.bg, display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0, boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.1)',
    }}>
      {p.mark(size)}
    </div>
  );
}

const BRANDS = {
  lumen: {
    bg: '#f5a524',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <circle cx="10" cy="10" r="3.2" fill="#fff"/>
        {[0,60,120,180,240,300].map(a => (
          <rect key={a} x="9" y="2" width="2" height="4.5" rx="1" fill="#fff"
            transform={`rotate(${a} 10 10)`} />
        ))}
      </svg>
    ),
  },
  pivot: {
    bg: '#111827',
    mark: (s) => (
      <svg width={s*0.5} height={s*0.5} viewBox="0 0 20 20">
        <rect x="3" y="3" width="6" height="14" rx="1.5" fill="#fff"/>
        <rect x="11" y="3" width="6" height="6" rx="1.5" fill="#fff"/>
      </svg>
    ),
  },
  nimbus: {
    bg: '#3b82f6',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <path d="M4 13a3 3 0 013-3 4 4 0 017.8-1A3 3 0 0116 15H5a3 3 0 01-1-2z" fill="#fff"/>
      </svg>
    ),
  },
  ember: {
    bg: '#e11d48',
    mark: (s) => (
      <svg width={s*0.5} height={s*0.5} viewBox="0 0 20 20">
        <path d="M10 3c2 3 5 4 5 8a5 5 0 11-10 0c0-2 1-3 2.5-4C10 9 9 5 10 3z" fill="#fff"/>
      </svg>
    ),
  },
  orbit: {
    bg: '#8b5cf6',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <ellipse cx="10" cy="10" rx="7" ry="3" stroke="#fff" strokeWidth="1.6" fill="none"/>
        <circle cx="10" cy="10" r="2.6" fill="#fff"/>
      </svg>
    ),
  },
  harbor: {
    bg: '#0ea5e9',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <path d="M3 13c2 0 2 1.5 4 1.5s2-1.5 3-1.5 1 1.5 3 1.5 2-1.5 4-1.5M10 3v10M4 9l6-6 6 6" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
  },
  fern: {
    bg: '#16a34a',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <path d="M10 17V5M10 5c-3 2-5 4-5 7M10 5c3 2 5 4 5 7M10 9c-2 1-3 2-3 4M10 9c2 1 3 2 3 4" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round"/>
      </svg>
    ),
  },
  slab: {
    bg: '#111827',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <rect x="3" y="6" width="14" height="3" fill="#fff"/>
        <rect x="3" y="11" width="9" height="3" fill="#fff"/>
      </svg>
    ),
  },
  meridian: {
    bg: '#4f46e5',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <circle cx="10" cy="10" r="7" stroke="#fff" strokeWidth="1.6" fill="none"/>
        <path d="M3 10h14M10 3v14" stroke="#fff" strokeWidth="1.6"/>
      </svg>
    ),
  },
  vellum: {
    bg: '#d97706',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <path d="M4 4h9l3 3v9H4V4z" stroke="#fff" strokeWidth="1.6" fill="none"/>
        <path d="M13 4v3h3" stroke="#fff" strokeWidth="1.6" fill="none"/>
      </svg>
    ),
  },
  codex: {
    bg: '#0f172a',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <path d="M7 5L3 10l4 5M13 5l4 5-4 5" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
  },
  delta: {
    bg: '#14b8a6',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <path d="M10 3l7 12H3l7-12z" fill="#fff"/>
      </svg>
    ),
  },
  quill: {
    bg: '#be185d',
    mark: (s) => (
      <svg width={s*0.6} height={s*0.6} viewBox="0 0 20 20">
        <path d="M4 16l5-5M15 4c-4 0-8 3-8 8l1 1c5 0 7-4 7-9z" stroke="#fff" strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    ),
  },
  basin: {
    bg: '#2563eb',
    mark: (s) => (
      <svg width={s*0.55} height={s*0.55} viewBox="0 0 20 20">
        <path d="M3 6h14l-2 10H5L3 6z" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinejoin="round"/>
        <path d="M7 10h6" stroke="#fff" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    ),
  },
  default: {
    bg: '#64748b',
    mark: (s) => (<svg width={s*0.4} height={s*0.4} viewBox="0 0 20 20"><circle cx="10" cy="10" r="6" fill="#fff"/></svg>),
  },
};

Object.assign(window, { Icon, BrandMark, BRANDS });
