// Bottom navigation bar — appears on top-level screens only

function BottomNav({ theme, current, onChange, onNewOS }) {
  const items = [
    { key: 'dashboard',     icon: 'home',      label: 'Início'   },
    { key: 'oslist',        icon: 'briefcase', label: 'Ordens'   },
    { key: '__newos',       icon: 'plus',      label: 'Nova OS', primary: true },
    { key: 'notifications', icon: 'bell',      label: 'Alertas'  },
    { key: 'profile',       icon: 'user',      label: 'Perfil'   },
  ];

  return (
    <div style={{
      background: theme.surface,
      borderTop: `1px solid ${theme.borderSoft}`,
      padding: '6px 6px 8px',
      display: 'flex', alignItems: 'stretch', justifyContent: 'space-around',
      flexShrink: 0,
    }}>
      {items.map(it => {
        if (it.primary) {
          return (
            <button key={it.key} className="tap" onClick={onNewOS}
              style={{
                background: 'transparent', border: 'none', cursor: 'pointer',
                display: 'flex', flexDirection: 'column', alignItems: 'center',
                gap: 3, padding: '4px 6px', flex: 1,
                fontFamily: 'inherit',
              }}>
              <div style={{
                width: 40, height: 40, borderRadius: 14,
                background: theme.primary, color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: `0 6px 14px ${theme.primary}55`,
              }}>
                <Icon name={it.icon} size={20} />
              </div>
              <div style={{ fontSize: 10, fontWeight: 600, color: theme.primary }}>
                {it.label}
              </div>
            </button>
          );
        }
        const active = current === it.key;
        return (
          <button key={it.key} className="tap" onClick={() => onChange(it.key)}
            style={{
              background: 'transparent', border: 'none', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 3, padding: '6px 4px 4px', flex: 1,
              color: active ? theme.primary : theme.textMuted,
              position: 'relative', fontFamily: 'inherit',
            }}>
            {active && (
              <div style={{
                position: 'absolute', top: 0, left: '50%',
                width: 24, height: 3, borderRadius: 999,
                background: theme.primary, transform: 'translateX(-50%)',
              }} />
            )}
            <Icon name={it.icon} size={20} strokeWidth={active ? 2 : 1.7} />
            <div style={{
              fontSize: 10, fontWeight: active ? 600 : 500,
            }}>{it.label}</div>
          </button>
        );
      })}
    </div>
  );
}

window.BottomNav = BottomNav;
