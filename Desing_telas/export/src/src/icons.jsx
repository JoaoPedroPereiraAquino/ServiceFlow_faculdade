// Icons — stroked line icons, 24x24 viewBox, inherit currentColor.
// Avoid emoji; use these for all UI icon needs.

const Icon = ({ name, size = 20, color = 'currentColor', strokeWidth = 1.7, style }) => {
  const common = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth,
    strokeLinecap: 'round', strokeLinejoin: 'round', style,
  };
  switch (name) {
    case 'mail': return (
      <svg {...common}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>
    );
    case 'lock': return (
      <svg {...common}><rect x="4.5" y="10.5" width="15" height="10" rx="2"/><path d="M8 10.5V7a4 4 0 018 0v3.5"/></svg>
    );
    case 'user': return (
      <svg {...common}><circle cx="12" cy="8" r="4"/><path d="M4 20c1.5-4 5-6 8-6s6.5 2 8 6"/></svg>
    );
    case 'users': return (
      <svg {...common}><circle cx="9" cy="8" r="3.5"/><path d="M2.5 19c1-3.5 4-5.5 6.5-5.5s5.5 2 6.5 5.5"/><circle cx="17" cy="7" r="2.8"/><path d="M16 14c2 .1 4 1.3 5.2 4"/></svg>
    );
    case 'building': return (
      <svg {...common}><rect x="4" y="3" width="16" height="18" rx="1.5"/><path d="M8 7h2M14 7h2M8 11h2M14 11h2M8 15h2M14 15h2M10 21v-3h4v3"/></svg>
    );
    case 'phone': return (
      <svg {...common}><path d="M5 5c0-1 1-2 2-2h2l2 5-2.5 1.5a10 10 0 005 5L15 12l5 2v2c0 1-1 2-2 2A14 14 0 015 5z"/></svg>
    );
    case 'id': return (
      <svg {...common}><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="12" r="2.2"/><path d="M5 17c.5-1.8 2-2.5 4-2.5s3.5.7 4 2.5M14.5 10h4M14.5 13h3"/></svg>
    );
    case 'eye': return (
      <svg {...common}><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/></svg>
    );
    case 'eye-off': return (
      <svg {...common}><path d="M3 3l18 18M10.6 10.6a3 3 0 104.2 4.2M9.9 5.2A10.3 10.3 0 0112 5c6 0 9.5 7 9.5 7a13.7 13.7 0 01-3.2 3.9M6.7 7A13.6 13.6 0 002.5 12s3.5 7 9.5 7c1.2 0 2.3-.2 3.3-.6"/></svg>
    );
    case 'back': return (
      <svg {...common}><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
    );
    case 'close': return (
      <svg {...common}><path d="M6 6l12 12M18 6L6 18"/></svg>
    );
    case 'check': return (
      <svg {...common}><path d="M4 12l5 5L20 6"/></svg>
    );
    case 'plus': return (
      <svg {...common}><path d="M12 5v14M5 12h14"/></svg>
    );
    case 'chevron-right': return (
      <svg {...common}><path d="M9 6l6 6-6 6"/></svg>
    );
    case 'chevron-down': return (
      <svg {...common}><path d="M6 9l6 6 6-6"/></svg>
    );
    case 'search': return (
      <svg {...common}><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-3.7-3.7"/></svg>
    );
    case 'bell': return (
      <svg {...common}><path d="M6 16V11a6 6 0 1112 0v5l1.5 2H4.5L6 16z"/><path d="M10 20a2 2 0 004 0"/></svg>
    );
    case 'camera': return (
      <svg {...common}><path d="M4 8h3l2-2.5h6L17 8h3a1.5 1.5 0 011.5 1.5v9A1.5 1.5 0 0120 20H4a1.5 1.5 0 01-1.5-1.5v-9A1.5 1.5 0 014 8z"/><circle cx="12" cy="13.5" r="3.5"/></svg>
    );
    case 'image': return (
      <svg {...common}><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="1.8"/><path d="M4 18l5-5 4 4 3-3 4 4"/></svg>
    );
    case 'money': return (
      <svg {...common}><rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 9v.01M18 15v.01"/></svg>
    );
    case 'chart': return (
      <svg {...common}><path d="M4 20V4M4 20h16"/><path d="M8 16v-4M12 16V8M16 16v-7"/></svg>
    );
    case 'clock': return (
      <svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.5 2"/></svg>
    );
    case 'briefcase': return (
      <svg {...common}><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 012-2h4a2 2 0 012 2v2M3 12h18"/></svg>
    );
    case 'settings': return (
      <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.9l.1.1a2 2 0 01-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.9-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 01-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.9.3l-.1.1a2 2 0 01-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.9 1.7 1.7 0 00-1.5-1H3a2 2 0 010-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.9l-.1-.1a2 2 0 012.8-2.8l.1.1a1.7 1.7 0 001.9.3H9a1.7 1.7 0 001-1.5V3a2 2 0 014 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.9-.3l.1-.1a2 2 0 012.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.9V9a1.7 1.7 0 001.5 1H21a2 2 0 010 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>
    );
    case 'logout': return (
      <svg {...common}><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/></svg>
    );
    case 'pencil': return (
      <svg {...common}><path d="M4 20h4l10-10-4-4L4 16v4z"/><path d="M14 6l4 4"/></svg>
    );
    case 'trash': return (
      <svg {...common}><path d="M4 7h16M9 7V5a1.5 1.5 0 011.5-1.5h3A1.5 1.5 0 0115 5v2M6 7l1 13a2 2 0 002 2h6a2 2 0 002-2l1-13"/></svg>
    );
    case 'filter': return (
      <svg {...common}><path d="M4 5h16l-6 8v6l-4-2v-4L4 5z"/></svg>
    );
    case 'signature': return (
      <svg {...common}><path d="M3 17c2 0 3-6 5-6s2 4 4 4 3-8 5-8 2 6 4 6"/><path d="M3 21h18"/></svg>
    );
    case 'sun': return (
      <svg {...common}><circle cx="12" cy="12" r="4"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.5 1.5M16.9 16.9l1.5 1.5M5.6 18.4l1.5-1.5M16.9 7.1l1.5-1.5"/></svg>
    );
    case 'moon': return (
      <svg {...common}><path d="M20 14a8 8 0 01-10-10 8 8 0 1010 10z"/></svg>
    );
    case 'sliders': return (
      <svg {...common}><path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h14M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="19" cy="18" r="2"/></svg>
    );
    case 'home': return (
      <svg {...common}><path d="M3 11l9-7 9 7v9a1.5 1.5 0 01-1.5 1.5H14v-6h-4v6H4.5A1.5 1.5 0 013 20v-9z"/></svg>
    );
    case 'wifi': return (
      <svg {...common} strokeWidth="2"><path d="M5 12a10 10 0 0114 0"/><path d="M8.5 15a6 6 0 017 0"/><circle cx="12" cy="18" r="1" fill="currentColor"/></svg>
    );
    case 'battery': return (
      <svg {...common}><rect x="2.5" y="8" width="17" height="8" rx="1.5"/><rect x="20.5" y="10.5" width="1.5" height="3" rx=".5" fill="currentColor" stroke="none"/><rect x="4" y="9.5" width="12" height="5" rx=".5" fill="currentColor" stroke="none"/></svg>
    );
    case 'signal': return (
      <svg {...common} strokeWidth="2"><path d="M3 18h2v2H3zM8 14h2v6H8zM13 10h2v10h-2zM18 5h2v15h-2z" fill="currentColor" stroke="none"/></svg>
    );
    default: return null;
  }
};

Object.assign(window, { Icon });
