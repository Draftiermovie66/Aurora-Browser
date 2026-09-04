import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import GearIcon from './components/GearIcon';
import SearchIcon from './components/SearchIcon';
import ThemePicker from './components/ThemePicker';
import ShortcutEditor from './components/ShortcutEditor';
import { THEMES, applyTheme, getSavedTheme, saveTheme } from './theme';
import { loadShortcuts, saveShortcuts, DEFAULT_SHORTCUTS } from './shortcuts';

// beUI-style motion tokens
const EASE_OUT = [0.16, 1, 0.3, 1];
const SPRING_REVEAL = { type: 'spring', stiffness: 200, damping: 20 };

const fadeUp = {
  hidden: { opacity: 0, y: 16, filter: 'blur(4px)' },
  show: (i) => ({
    opacity: 1,
    y: 0,
    filter: 'blur(0px)',
    transition: { ...SPRING_REVEAL, delay: 0.05 * i },
  }),
};

const stagger = {
  hidden: {},
  show: { transition: { staggerChildren: 0.05, delayChildren: 0.05 } },
};

function faviconUrl(url) {
  try {
    const host = new URL(url).hostname.replace('www.', '');
    return `https://www.google.com/s2/favicons?domain=${host}&sz=64`;
  } catch {
    return '';
  }
}

function getLogoSrc() {
  if (typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.getURL) {
    return chrome.runtime.getURL('aurora.png');
  }
  return 'aurora.png';
}

function getReleaseNotes() {
  return fetch('https://api.github.com/repos/Draftiermovie66/Aurora-Browser/releases/latest')
    .then(r => r.ok ? r.json() : Promise.reject())
    .then(data => {
      const lines = (data.body || '').split('\n').filter(l => l.trim() && !l.startsWith('#'));
      return {
        tag: data.tag_name,
        notes: lines.slice(0, 4).map(l => l.replace(/^[-*]\s*/, '').substring(0, 80)),
      };
    });
}

const SEARCH_STORAGE = 'aurora_last_search';
const FIRST_RUN_STORAGE = 'aurora_first_run';
const PROFILE_STORAGE = 'aurora_profile_key';

function loadLastSearch() {
  try { return localStorage.getItem(SEARCH_STORAGE) || ''; } catch (e) { return ''; }
}
function saveLastSearch(value) {
  try { localStorage.setItem(SEARCH_STORAGE, value); } catch (e) {}
}

// Persist a stable profile key across app version bumps so the user's
// session (theme, shortcuts, last search) is carried forward regardless of
// which Aurora version renders this page.
function ensureProfileKey() {
  try {
    if (!localStorage.getItem(PROFILE_STORAGE)) {
      localStorage.setItem(PROFILE_STORAGE, 'default-' + Date.now().toString(36));
    }
  } catch (e) {}
}

export default function App() {
  const [theme, setTheme] = useState(getSavedTheme());
  const [pickerOpen, setPickerOpen] = useState(false);
  const [editorOpen, setEditorOpen] = useState(false);
  const [release, setRelease] = useState(null);
  const [shortcuts, setShortcuts] = useState(() => loadShortcuts());
  const [query, setQuery] = useState(loadLastSearch);
  const searchRef = React.useRef(null);

  useEffect(() => {
    applyTheme(theme);
    ensureProfileKey();
  }, [theme]);

  useEffect(() => {
    getReleaseNotes().then(setRelease).catch(() => {});
  }, []);

  // Global keyboard shortcuts.
  useEffect(() => {
    const onKey = (e) => {
      const mod = e.ctrlKey || e.metaKey;
      // Ctrl/Cmd+E or "?" opens the shortcut editor
      if ((mod && e.key.toLowerCase() === 'e') || (!mod && e.key === '?')) {
        e.preventDefault();
        setEditorOpen(true);
      }
      // "Escape" closes open modals
      if (e.key === 'Escape') {
        setPickerOpen(false);
        setEditorOpen(false);
      }
      // "/" focuses the search box
      if (!mod && e.key === '/' && document.activeElement !== searchRef.current) {
        e.preventDefault();
        searchRef.current?.focus();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  // Persist the in-progress search so the session resumes after navigating away.
  useEffect(() => {
    const timer = setTimeout(() => saveLastSearch(query), 250);
    return () => clearTimeout(timer);
  }, [query]);

  // Mark first visit (used to show a small "Press ? for shortcuts" hint).
  const [isFirstRun] = useState(() => {
    let first = false;
    try {
      if (!localStorage.getItem(FIRST_RUN_STORAGE)) {
        first = true;
        localStorage.setItem(FIRST_RUN_STORAGE, '1');
      }
    } catch (e) {}
    return first;
  });

  const handleSearchSubmit = () => {
    saveLastSearch('');
    setQuery('');
    searchRef.current?.blur();
  };

  const handleThemeChange = (t) => {
    setTheme(t);
    saveTheme(t);
  };

  const handleShortcutsChange = (next) => {
    setShortcuts(next);
    saveShortcuts(next);
  };

  return (
    <motion.div className="app"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6 }}
    >
      <div className="top-bar">
        <motion.button
          className="gear-btn"
          onClick={() => setPickerOpen(true)}
          title="Settings"
          whileHover={{ scale: 1.1, rotate: 45 }}
          whileTap={{ scale: 0.9 }}
          transition={SPRING_REVEAL}
        >
          <GearIcon />
        </motion.button>
      </div>

      <main className="main">
        <motion.img
          src={getLogoSrc()}
          alt="Aurora"
          className="logo"
          draggable="false"
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ ...SPRING_REVEAL, delay: 0.05 }}
        />

        <motion.form
          className="search"
          action="https://www.google.com/search"
          method="GET"
          target="_top"
          onSubmit={handleSearchSubmit}
          variants={fadeUp}
          initial="hidden"
          animate="show"
          custom={1}
        >
          <input
            type="text"
            name="q"
            ref={searchRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search the web"
            autoFocus
          />
          <SearchIcon />
        </motion.form>

        <section className="shortcuts-section">
          <motion.div className="section-header" variants={fadeUp} initial="hidden" animate="show" custom={2}>
            <h2>Shortcuts</h2>
            <div className="header-actions">
              <motion.button
                className="edit-btn"
                onClick={() => setEditorOpen(true)}
                title="Edit shortcuts"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                transition={SPRING_REVEAL}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.828 2.828 0 114 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></svg>
                Edit
              </motion.button>
              <div className="theme-swatches">
                {THEMES.map(t => (
                  <motion.button
                    key={t.id}
                    className={`swatch${theme.id === t.id ? ' active' : ''}`}
                    style={{ background: t.bg }}
                    title={t.id}
                    onClick={() => handleThemeChange(t)}
                    whileHover={{ scale: 1.25 }}
                    whileTap={{ scale: 0.85 }}
                    transition={SPRING_REVEAL}
                  />
                ))}
              </div>
            </div>
          </motion.div>
          <motion.div
            className="shortcuts-grid"
            variants={stagger}
            initial="hidden"
            animate="show"
          >
            {shortcuts.map((s, i) => (
              <motion.a
                key={s.url}
                className="shortcut"
                href={s.url}
                target="_top"
                variants={fadeUp}
                custom={i}
                whileHover={{ y: -3 }}
                whileTap={{ scale: 0.95 }}
                transition={SPRING_REVEAL}
              >
                <div className="shortcut-icon">
                  <img src={faviconUrl(s.url)} width="32" height="32" alt={s.name} />
                </div>
                <span className="shortcut-name">{s.name}</span>
              </motion.a>
            ))}
          </motion.div>
        </section>

        <section className="stories-section">
          <motion.div className="section-header" variants={fadeUp} initial="hidden" animate="show" custom={3}>
            <h2>Recommended</h2>
          </motion.div>
          <motion.div
            className="stories-grid"
            variants={stagger}
            initial="hidden"
            animate="show"
          >
            {release ? (
              <>
                <motion.a className="story" href="https://github.com/Draftiermovie66/Aurora-Browser/releases" target="_blank" variants={fadeUp} whileHover={{ y: -2 }} transition={SPRING_REVEAL}>
                  <div className="story-body">
                    <div className="story-title">{release.tag} is out</div>
                    <div className="story-source">Aurora Browser</div>
                  </div>
                </motion.a>
                {release.notes.map((note, i) => (
                  <motion.a key={i} className="story" href="https://github.com/Draftiermovie66/Aurora-Browser/releases" target="_blank" variants={fadeUp} custom={i} whileHover={{ y: -2 }} transition={SPRING_REVEAL}>
                    <div className="story-body">
                      <div className="story-title">{note}</div>
                      <div className="story-source">{release.tag}</div>
                    </div>
                  </motion.a>
                ))}
              </>
            ) : (
              <motion.a className="story" href="https://github.com/Draftiermovie66/Aurora-Browser" target="_blank" variants={fadeUp} whileHover={{ y: -2 }} transition={SPRING_REVEAL}>
                <div className="story-body">
                  <div className="story-title">Aurora Browser</div>
                  <div className="story-source">Aurora-based &bull; Auto-updating &bull; Private</div>
                </div>
              </motion.a>
            )}
          </motion.div>
        </section>
      </main>

      <motion.footer
        className="footer"
        variants={fadeUp}
        initial="hidden"
        animate="show"
        custom={4}
      >
        {isFirstRun && (
          <span className="kbd-hint">Tip: press <kbd>?</kbd> to edit shortcuts, <kbd>/</kbd> to search</span>
        )}
        <a href="https://github.com/Draftiermovie66/Aurora-Browser/releases" target="_blank">Releases</a>
        <a href="https://github.com/Draftiermovie66/Aurora-Browser/issues" target="_blank">Report Issue</a>
        <a href="https://github.com/Draftiermovie66/Aurora-Browser" target="_blank">Source</a>
      </motion.footer>

      <AnimatePresence>
        {pickerOpen && (
          <ThemePicker
            current={theme}
            onApply={(t) => { handleThemeChange(t); setPickerOpen(false); }}
            onClose={() => setPickerOpen(false)}
          />
        )}

        {editorOpen && (
          <ShortcutEditor
            shortcuts={shortcuts}
            onSave={(next) => { handleShortcutsChange(next); setEditorOpen(false); }}
            onClose={() => setEditorOpen(false)}
          />
        )}
      </AnimatePresence>
    </motion.div>
  );
}