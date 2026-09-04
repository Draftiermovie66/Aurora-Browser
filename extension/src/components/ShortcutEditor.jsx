import React, { useState } from 'react';

export default function ShortcutEditor({ shortcuts, onSave, onClose }) {
  const [items, setItems] = useState(shortcuts.map(s => ({ ...s })));
  const [name, setName] = useState('');
  const [url, setUrl] = useState('');

  const update = (i, field, value) => {
    setItems(items.map((s, idx) => idx === i ? { ...s, [field]: value } : s));
  };

  const remove = (i) => {
    setItems(items.filter((_, idx) => idx !== i));
  };

  const move = (i, dir) => {
    const j = i + dir;
    if (j < 0 || j >= items.length) return;
    const next = [...items];
    [next[i], next[j]] = [next[j], next[i]];
    setItems(next);
  };

  const add = () => {
    if (!name.trim() || !url.trim()) return;
    const next = [...items, { name: name.trim(), url: url.trim() }];
    setItems(next);
    setName('');
    setUrl('');
  };

  const validUrl = (u) => /^https?:\/\//.test(u);

  return (
    <div className="picker-overlay" onClick={onClose}>
      <div className="picker shortcut-picker" onClick={e => e.stopPropagation()}>
        <div className="picker-head">
          <h3>Edit Shortcuts</h3>
          <button className="icon-btn" onClick={onClose} title="Close">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <div className="add-row">
          <input type="text" placeholder="Name" value={name} onChange={e => setName(e.target.value)} />
          <input type="text" placeholder="https://..." value={url} onChange={e => setUrl(e.target.value)} />
          <button className="ok" onClick={add}>Add</button>
        </div>

        <div className="shortcut-list">
          {items.map((s, i) => (
            <div className="shortcut-row" key={i}>
              <div className="move-btns">
                <button onClick={() => move(i, -1)} disabled={i === 0} title="Move up">\u2191</button>
                <button onClick={() => move(i, 1)} disabled={i === items.length - 1} title="Move down">\u2193</button>
              </div>
              <input
                className="row-name"
                type="text"
                value={s.name}
                onChange={e => update(i, 'name', e.target.value)}
              />
              <input
                className="row-url"
                type="text"
                value={s.url}
                onChange={e => update(i, 'url', e.target.value)}
              />
              <button className="remove-btn" onClick={() => remove(i)} title="Remove">\u00d7</button>
            </div>
          ))}
        </div>

        <div className="picker-btns">
          <button className="ok" onClick={() => {
            const valid = items.filter(s => s.name.trim() && validUrl(s.url));
            onSave(valid);
          }}>Save</button>
          <button className="cancel" onClick={onClose}>Cancel</button>
        </div>
      </div>
    </div>
  );
}