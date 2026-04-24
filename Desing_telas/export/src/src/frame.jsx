// Android device frame + app bar + status bar.
// Uses theme for colors; built around a 390x844 "phone" canvas.

const PHONE_WIDTH = 390;
const PHONE_HEIGHT = 844;

function StatusBar({ theme }) {
  return (
    <div style={{
      height: 36, display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', padding: '0 18px 0 22px',
      background: theme.statusBarBg,
      color: theme.statusBarIcons,
      fontSize: 14, fontWeight: 600,
      fontFamily: 'Inter, system-ui, sans-serif',
      position: 'relative', zIndex: 2,
    }}>
      <div>9:41</div>
      <div style={{
        position: 'absolute', left: '50%', top: 8,
        transform: 'translateX(-50%)',
        width: 22, height: 22, borderRadius: 999,
        background: '#0a0a0a',
      }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
        <Icon name="signal" size={14} color={theme.statusBarIcons} />
        <Icon name="wifi" size={14} color={theme.statusBarIcons} />
        <Icon name="battery" size={18} color={theme.statusBarIcons} />
      </div>
    </div>
  );
}

function GestureBar({ theme }) {
  return (
    <div style={{
      height: 22, display: 'flex',
      alignItems: 'center', justifyContent: 'center',
      background: theme.surface,
      borderTop: `1px solid ${theme.borderSoft}`,
    }}>
      <div style={{
        width: 120, height: 4, borderRadius: 999,
        background: theme.text, opacity: .55,
      }} />
    </div>
  );
}

// Top AppBar — flat, bordered bottom, Material 3-ish small
function AppBar({ theme, title, onBack, right, subtitle, transparent }) {
  return (
    <div style={{
      minHeight: 56, padding: '8px 8px 8px 6px',
      display: 'flex', alignItems: 'center',
      background: transparent ? 'transparent' : theme.surface,
      borderBottom: transparent ? 'none' : `1px solid ${theme.borderSoft}`,
      fontFamily: 'Inter, system-ui, sans-serif',
      position: 'sticky', top: 0, zIndex: 3,
    }}>
      {onBack ? (
        <button className="tap" onClick={onBack} style={{
          width: 44, height: 44, borderRadius: 999,
          background: 'transparent', border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: theme.text, flexShrink: 0,
        }}>
          <Icon name="back" size={22} />
        </button>
      ) : <div style={{ width: 14 }} />}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 18, fontWeight: 600, color: theme.text,
          letterSpacing: -0.1, lineHeight: 1.2,
        }}>{title}</div>
        {subtitle && (
          <div style={{ fontSize: 12, color: theme.textMuted, marginTop: 2 }}>{subtitle}</div>
        )}
      </div>
      {right}
    </div>
  );
}

// Device frame wraps everything
function DeviceFrame({ theme, children, scale = 1 }) {
  return (
    <div style={{
      width: PHONE_WIDTH, height: PHONE_HEIGHT,
      borderRadius: 44, overflow: 'hidden',
      background: theme.surface,
      boxShadow: theme.shadow + ', 0 0 0 10px #111827, 0 0 0 11px #1f2937',
      display: 'flex', flexDirection: 'column',
      transform: `scale(${scale})`, transformOrigin: 'top center',
      position: 'relative',
      fontFamily: 'Inter, system-ui, sans-serif',
    }}>
      <StatusBar theme={theme} />
      <div className="phone-scroll" style={{
        flex: 1, overflow: 'auto', background: theme.bg, position: 'relative',
      }}>
        {children}
      </div>
      <GestureBar theme={theme} />
    </div>
  );
}

Object.assign(window, { StatusBar, GestureBar, AppBar, DeviceFrame, PHONE_WIDTH, PHONE_HEIGHT });
