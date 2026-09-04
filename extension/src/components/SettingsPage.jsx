import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import ThemePicker from './ThemePicker';
import ShortcutEditor from './ShortcutEditor';
import { THEMES } from '../theme';
import { SEARCH_ENGINES } from '../search';

const EASE = [0.16, 1, 0.3, 1];

const TABS = [
  { id: 'appearance', label: 'Appearance' },
  { id: 'search',     label: 'Search' },
  { id: 'shortcuts',  label: 'Shortcuts' },
  { id: 'about',      label: 'About' },
];

export default function SettingsPage({
  theme,
  onApplyTheme,
  searchEngine,
  onSearchEngine,
  shortcuts,
  onSaveShortcuts,
  onClose,
}) {
  const [tab, setTab] = useState('appearance');
  const [themeModal, setThemeModal] = useState(false);
  const [shortcutModal, setShortcutModal] = useState(false);
  const [saved, setSaved] = useState(false);

  const flashSaved = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 1400);
  };

  const pickEngine = (e) => {
    onSearchEngine(e.id);
    flashSaved();
  };

  return (
    <motion.div
      className="settings-page"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: EASE }}
    >
      <header className="settings-head">
        <div className="settings-title">
          <img src="aurora.png" alt="" className="settings-logo" draggable="false" />
          <div>
            <h1>Settings</h1>
            <p>Aurora Browser</p>
          </div>
        </div>
        <button className="icon-btn" onClick={onClose} title="Close">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        </button>
      </header>

      <div className="settings-body">
        <nav className="settings-nav">
          {TABS.map(t => (
            <button
              key={t.id}
              className={`settings-tab${tab === t.id ? ' active' : ''}`}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </nav>

        <section className="settings-content" key={tab}>
          {tab === 'appearance' && (
            <div className="settings-section">
              <h2>Appearance</h2>
              <p className="settings-desc">Pick a theme or build your own. Changes apply to the new tab instantly.</p>

              <div className="theme-grid">
                {THEMES.map(t => (
                  <button
                    key={t.id}
                    className={`theme-card${theme.id === t.id ? ' active' : ''}`}
                    onClick={() => { onApplyTheme(t); flashSaved(); }}
                    style={{ '--card-bg': t.bg, '--card-accent': t.accent }}
                  >
                    <span className="theme-swatch-lg" />
                    <span className="theme-name">{t.id}</span>
                  </button>
                ))}
                <button
                  className={`theme-card custom${theme.id === 'custom' ? ' active' : ''}`}
                  onClick={() => setThemeModal(true)}
                >
                  <span className="theme-swatch-lg custom-swatch">+</span>
                  <span className="theme-name">Custom</span>
                </button>
              </div>
            </div>
          )}

          {tab === 'search' && (
            <div className="settings-section">
              <h2>Search engine</h2>
              <p className="settings-desc">Choose which engine handles searches from the new tab.</p>

              <div className="engine-list">
                {SEARCH_ENGINES.map(e => (
                  <button
                    key={e.id}
                    className={`engine-row${searchEngine.id === e.id ? ' active' : ''}`}
                    onClick={() => pickEngine(e)}
                  >
                    <span className="engine-radio">{searchEngine.id === e.id && <span className="engine-dot" />}</span>
                    <span className="engine-name">{e.name}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {tab === 'shortcuts' && (
            <div className="settings-section">
              <h2>Shortcuts</h2>
              <p className="settings-desc">Edit the quick links shown on the new tab.</p>
              <p className="settings-count">{shortcuts.length} shortcut{shortcuts.length === 1 ? '' : 's'}</p>
              <button className="settings-btn" onClick={() => setShortcutModal(true)}>
                Edit shortcuts
              </button>
            </div>
          )}

          {tab === 'about' && (
            <div className="settings-section">
              <h2>About</h2>
              <img src="aurora.png" alt="Aurora Browser" className="about-logo" draggable="false" />
              <p className="about-name">Aurora Browser</p>
              <p className="about-desc">
                A fast, private, auto-updating browser built on Chromium.
              </p>
              <div className="about-links">
                <a href="https://github.com/Draftiermovie66/Aurora-Browser/releases" target="_blank">Releases</a>
                <a href="https://github.com/Draftiermovie66/Aurora-Browser/issues" target="_blank">Report an issue</a>
                <a href="https://github.com/Draftiermovie66/Aurora-Browser" target="_blank">Source code</a>
              </div>
            </div>
          )}
        </section>
      </div>

      <footer className="settings-foot">
        <AnimatePresence>
          {saved && (
            <motion.span
              className="saved-toast"
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
            >
              Saved
            </motion.span>
          )}
        </AnimatePresence>
        <button className="cancel" onClick={onClose}>Close</button>
      </footer>

      {themeModal && (
        <ThemePicker
          current={theme}
          onApply={(t) => { onApplyTheme(t); setThemeModal(false); flashSaved(); }}
          onClose={() => setThemeModal(false)}
        />
      )}

      {shortcutModal && (
        <ShortcutEditor
          shortcuts={shortcuts}
          onSave={(next) => { onSaveShortcuts(next); setShortcutModal(false); flashSaved(); }}
          onClose={() => setShortcutModal(false)}
        />
      )}
    </motion.div>
  );
}