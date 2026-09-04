export const SEARCH_ENGINES = [
  { id: 'google',     name: 'Google',     action: 'https://www.google.com/search',   param: 'q' },
  { id: 'duckduckgo', name: 'DuckDuckGo', action: 'https://duckduckgo.com/',          param: 'q' },
  { id: 'bing',       name: 'Bing',       action: 'https://www.bing.com/search',      param: 'q' },
  { id: 'startpage',  name: 'Startpage',  action: 'https://www.startpage.com/sp/search', param: 'query' },
  { id: 'ecosia',     name: 'Ecosia',     action: 'https://www.ecosia.org/search',    param: 'q' },
];

const KEY = 'aurora_search_engine';

export function loadSearchEngine() {
  try {
    const id = localStorage.getItem(KEY);
    const eng = SEARCH_ENGINES.find(e => e.id === id);
    return eng || SEARCH_ENGINES[0];
  } catch (e) {
    return SEARCH_ENGINES[0];
  }
}

export function saveSearchEngine(id) {
  try {
    localStorage.setItem(KEY, id);
  } catch (e) {}
}