export const THEMES = [
  { id: 'default',  bg: '#2b2a33', txt: '#fbfbfe', accent: '#7a56e9', img: '' },
  { id: 'blue',     bg: '#1a2435', txt: '#e0eaf5', accent: '#3b82f6', img: '' },
  { id: 'green',    bg: '#1a2e20', txt: '#e0f0e0', accent: '#22c55e', img: '' },
  { id: 'red',      bg: '#2e1a1a', txt: '#f0e0e0', accent: '#ef4444', img: '' },
  { id: 'orange',   bg: '#2e261a', txt: '#f0eae0', accent: '#f59e0b', img: '' },
  { id: 'light',    bg: '#f0f0f0', txt: '#1a1a1a', accent: '#7a56e9', img: '' },
  { id: 'midnight', bg: '#121212', txt: '#a0a0a0', accent: '#a855f7', img: '' },
];

function shade(hex, pct) {
  hex = hex.replace('#', '');
  if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
  let r = parseInt(hex.substring(0, 2), 16);
  let g = parseInt(hex.substring(2, 4), 16);
  let b = parseInt(hex.substring(4, 6), 16);
  r = Math.min(255, Math.max(0, Math.round(r + r * pct)));
  g = Math.min(255, Math.max(0, Math.round(g + g * pct)));
  b = Math.min(255, Math.max(0, Math.round(b + b * pct)));
  return '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

export function applyTheme(t) {
  const body = document.body;
  if (t.img) {
    body.style.background = '';
    body.style.backgroundImage = `url(${t.img})`;
    body.style.backgroundSize = 'cover';
    body.style.backgroundPosition = 'center';
    body.style.backgroundRepeat = 'no-repeat';
  } else {
    body.style.backgroundImage = 'none';
    body.style.background = `linear-gradient(180deg, ${shade(t.bg, -0.2)} 0%, ${t.bg} 40%)`;
  }
  body.style.color = t.txt;
}

export function getSavedTheme() {
  try {
    const saved = JSON.parse(localStorage.getItem('aurora-theme'));
    if (saved && THEMES.find(t => t.id === saved.id)) return saved;
    if (saved && saved.id === 'custom') return saved;
  } catch {}
  return THEMES[0];
}

export function saveTheme(t) {
  localStorage.setItem('aurora-theme', JSON.stringify(t));
}