export const DEFAULT_SHORTCUTS = [
  { name: 'YouTube',      url: 'https://youtube.com' },
  { name: 'GitHub',       url: 'https://github.com' },
  { name: 'Reddit',       url: 'https://reddit.com' },
  { name: 'Wikipedia',    url: 'https://wikipedia.org' },
  { name: 'Gmail',        url: 'https://mail.google.com' },
  { name: 'X',            url: 'https://x.com' },
  { name: 'Amazon',       url: 'https://amazon.com' },
  { name: 'Netflix',      url: 'https://netflix.com' },
  { name: 'Stack Overflow', url: 'https://stackoverflow.com' },
  { name: 'Discord',      url: 'https://discord.com' },
  { name: 'Twitch',       url: 'https://twitch.tv' },
  { name: 'Spotify',      url: 'https://spotify.com' },
];

const COOKIE_NAME = 'aurora_shortcuts';

export function loadShortcuts() {
  try {
    const val = getCookie(COOKIE_NAME);
    if (val) {
      const parsed = JSON.parse(decodeURIComponent(val));
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
  } catch (e) {}
  return DEFAULT_SHORTCUTS;
}

export function saveShortcuts(shortcuts) {
  setCookie(COOKIE_NAME, encodeURIComponent(JSON.stringify(shortcuts)), 365);
}

export function resetShortcuts() {
  document.cookie = COOKIE_NAME + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
}

function getCookie(name) {
  const match = document.cookie.match('(^|;)\\s*' + name + '\\s*=\\s*([^;]+)');
  return match ? match[2] : null;
}

function setCookie(name, value, days) {
  const d = new Date();
  d.setTime(d.getTime() + days * 24 * 60 * 60 * 1000);
  document.cookie = name + '=' + value + '; expires=' + d.toUTCString() + '; path=/';
}