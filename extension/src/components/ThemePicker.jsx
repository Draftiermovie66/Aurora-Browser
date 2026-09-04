import React, { useState } from 'react';

export default function ThemePicker({ current, onApply, onClose }) {
  const [bg, setBg] = useState(current.bg && current.bg.charAt(0) === '#' ? current.bg : '#2b2a33');
  const [txt, setTxt] = useState(current.txt || '#fbfbfe');
  const [accent, setAccent] = useState(current.accent || '#7a56e9');
  const [img, setImg] = useState(current.img || '');

  return (
    <div className="picker-overlay" onClick={onClose}>
      <div className="picker" onClick={e => e.stopPropagation()}>
        <h3>New Tab Settings</h3>

        <label>Background color</label>
        <input type="color" value={bg} onChange={e => setBg(e.target.value)} />

        <label>Text color</label>
        <input type="color" value={txt} onChange={e => setTxt(e.target.value)} />

        <label>Accent color</label>
        <input type="color" value={accent} onChange={e => setAccent(e.target.value)} />

        <label>Background image URL</label>
        <input type="text" value={img} onChange={e => setImg(e.target.value)} placeholder="optional" />

        <div className="picker-btns">
          <button className="ok" onClick={() => onApply({ id: 'custom', bg, txt, accent, img })}>
            Done
          </button>
          <button className="cancel" onClick={onClose}>Cancel</button>
        </div>
      </div>
    </div>
  );
}