// data.jsx — fictional vault entries

const ENTRIES = [
  { id: 'basin',     name: 'Basin (Napat Workspace)', brand: 'basin',    user: 'admin@napat.dev',       group: '#', kind: 'Login' },
  { id: '15pm',      name: '15 Point Meeting',        brand: 'delta',    user: 'admin@napat.dev',       group: '#', kind: 'Login' },
  { id: 'aperio',    name: 'Aperio',                  brand: 'lumen',    user: 'luca_martinez@fastmail.com', group: 'A', kind: 'Login', featured: true },
  { id: 'cairn',     name: 'Cairn (Customer Voice)',  brand: 'orbit',    user: 'admin@napat.dev',       group: 'C', kind: 'Login' },
  { id: 'chatter',   name: 'Chatter AI',              brand: 'nimbus',   user: 'luca_martinez@fastmail.com', group: 'C', kind: 'Login' },
  { id: 'contract',  name: 'Consulting Contract',     brand: 'vellum',   user: '917 bytes',             group: 'C', kind: 'Document' },
  { id: 'forge',     name: 'Forge',                   brand: 'codex',    user: 'luca_martinez@fastmail.com', group: 'F', kind: 'Login' },
  { id: 'forge2',    name: 'Forge Personal',          brand: 'codex',    user: 'luca_martinez@fastmail.com', group: 'F', kind: 'Login' },
  { id: 'forgerec',  name: 'Forge Recovery Codes',    brand: 'slab',     user: '206 bytes',             group: 'F', kind: 'Document' },
  { id: 'glade',     name: 'Glade Workspace',         brand: 'fern',     user: 'admin@napat.dev',       group: 'G', kind: 'Login' },
  { id: 'harbor',    name: 'Harbor Mail',             brand: 'harbor',   user: 'luca_martinez@fastmail.com', group: 'H', kind: 'Login' },
  { id: 'meridian',  name: 'Meridian',                brand: 'meridian', user: 'luca@meridian.co',      group: 'M', kind: 'Login' },
  { id: 'pivot',     name: 'Pivot',                   brand: 'pivot',    user: 'admin@napat.dev',       group: 'P', kind: 'Login' },
  { id: 'quill',     name: 'Quill',                   brand: 'quill',    user: 'luca_martinez@fastmail.com', group: 'Q', kind: 'Login' },
];

// Mobile Home screen entries (favorites / recents)
const MOBILE_HOME = {
  favorites: [
    { id: 'aperio-id', name: 'Aperio ID',      brand: 'lumen',   user: 'luca_martinez@fastmail.com' },
    { id: 'harbor-m',  name: 'Harbor Mail',    brand: 'harbor',  user: 'luca_martinez@fastmail.com' },
    { id: 'home-wifi', name: 'Home Wi-Fi',     brand: 'basin',   user: 'GreatBlue_Heron_5G' },
    { id: 'nestflix',  name: 'Nestflix',       brand: 'ember',   user: 'luca_martinez@fastmail.com' },
  ],
};

Object.assign(window, { ENTRIES, MOBILE_HOME });
