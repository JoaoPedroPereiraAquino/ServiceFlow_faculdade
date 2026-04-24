// App root — wires navigation, theme, tweaks, device frame

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "mode": "light",
  "accent": "blue",
  "density": "cozy",
  "radius": "soft",
  "screen": "login"
}/*EDITMODE-END*/;

function App() {
  // Tweaks state
  const [tweaks, setTweaks] = React.useState(TWEAK_DEFAULTS);
  const [editMode, setEditMode] = React.useState(false);

  // Data
  const [clients, setClients] = React.useState(INITIAL_CLIENTS);
  const [osList, setOsList] = React.useState(INITIAL_OS);

  // Nav stack — each entry { screen, params }
  const [stack, setStack] = React.useState([{ screen: TWEAK_DEFAULTS.screen, params: {} }]);
  const top = stack[stack.length - 1];

  const nav = {
    push: (screen, params = {}) => setStack(s => [...s, { screen, params }]),
    pop:  () => setStack(s => s.length > 1 ? s.slice(0, -1) : s),
    replace: (screen, params = {}) => setStack([{ screen, params }]),
  };

  // Snackbar
  const [msg, setMsg] = React.useState(null);
  const showMessage = (m) => {
    setMsg(m);
    clearTimeout(showMessage._t);
    showMessage._t = setTimeout(() => setMsg(null), 2600);
  };

  // React to Tweaks "screen" changes — act as replace
  React.useEffect(() => {
    if (!tweaks.screen) return;
    if (top.screen !== tweaks.screen) {
      setStack([{ screen: tweaks.screen, params: {} }]);
    }
  }, [tweaks.screen]);

  // Host protocol
  React.useEffect(() => {
    const handler = (e) => {
      const t = e.data?.type;
      if (t === '__activate_edit_mode') setEditMode(true);
      if (t === '__deactivate_edit_mode') setEditMode(false);
    };
    window.addEventListener('message', handler);
    window.parent.postMessage({ type: '__edit_mode_available' }, '*');
    return () => window.removeEventListener('message', handler);
  }, []);

  const updateTweaks = (patch) => {
    setTweaks(t => ({ ...t, ...patch }));
    window.parent.postMessage({ type: '__edit_mode_set_keys', edits: patch }, '*');
  };

  const theme = React.useMemo(() => {
    const base = getTheme(tweaks.mode, tweaks.accent);
    return base;
  }, [tweaks.mode, tweaks.accent]);

  // Density / radius tweaks as CSS variables on frame
  const radiusScale = tweaks.radius === 'sharp' ? 0.35 : tweaks.radius === 'round' ? 1.4 : 1;

  // Map screen name -> component
  const renderScreen = () => {
    const { screen, params } = top;
    const shared = { theme, nav, showMessage };
    switch (screen) {
      case 'login':     return <LoginScreen {...shared} />;
      case 'signup':    return <SignupScreen {...shared} />;
      case 'client':    return <ClientScreen {...shared} clients={clients} setClients={setClients} />;
      case 'os':        return <OSScreen {...shared} clients={clients}
                          onSave={(os) => setOsList([{
                            id: 'OS-' + String(500 + osList.length).padStart(5, '0'),
                            ...os, status: 'aberto', criadoEm: 'agora', tecnico: 'Ana S.',
                          }, ...osList])} />;
      case 'dashboard': return <DashboardScreen {...shared} osList={osList} clients={clients} />;
      case 'oslist':    return <OSListScreen {...shared} osList={osList} clients={clients} params={params} />;
      default:          return <LoginScreen {...shared} />;
    }
  };

  // Responsive scale: fit phone inside viewport
  const [scale, setScale] = React.useState(1);
  React.useEffect(() => {
    const fit = () => {
      const availH = window.innerHeight - 40;
      const availW = Math.min(window.innerWidth - 40, 520);
      const s = Math.min(availH / (PHONE_HEIGHT + 60), availW / PHONE_WIDTH, 1);
      setScale(s);
    };
    fit(); window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);

  // Apply radius scale via inline style pass-through
  const themed = React.useMemo(() => ({
    ...theme,
    _radiusScale: radiusScale,
    _density: tweaks.density,
  }), [theme, radiusScale, tweaks.density]);

  const screenLabel = {
    login: '01 Login', signup: '02 Cadastro', dashboard: '03 Dashboard',
    os: '04 Nova OS', client: '05 Novo Cliente', oslist: '06 Lista de OS',
  }[top.screen] || 'Screen';

  return (
    <div style={{
      minHeight: '100vh', width: '100%',
      background: tweaks.mode === 'dark' ? '#0F172A' : '#EEF2F6',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      padding: '28px 0',
      fontFamily: 'Inter, system-ui, sans-serif',
    }}>
      {/* Screen label header */}
      <div data-screen-label={screenLabel} style={{
        marginBottom: 20, textAlign: 'center',
      }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace',
          fontSize: 11, fontWeight: 500, letterSpacing: 0.6,
          color: tweaks.mode==='dark' ? '#8B98B4' : '#64748B',
          textTransform: 'uppercase',
        }}>ServiceFlow · Android Prototype</div>
        <div style={{
          fontSize: 18, fontWeight: 700, marginTop: 4,
          color: tweaks.mode==='dark' ? '#E6EDF7' : '#0F172A',
          letterSpacing: -0.3,
        }}>{screenLabel}</div>
      </div>

      <div style={{
        transform: `scale(${scale})`, transformOrigin: 'top center',
        width: PHONE_WIDTH, height: PHONE_HEIGHT,
        marginBottom: (1 - scale) * -PHONE_HEIGHT,
      }}>
        <div style={{ position: 'relative', width: PHONE_WIDTH, height: PHONE_HEIGHT }}>
          <DeviceFrame theme={themed}>
            {renderScreen()}
          </DeviceFrame>
          <Snackbar theme={themed} msg={msg} />
        </div>
      </div>

      {/* Nav controls (below phone) */}
      <div style={{
        marginTop: 16, display: 'flex', gap: 8, alignItems: 'center',
        background: tweaks.mode==='dark' ? '#121A2B' : '#fff',
        border: `1px solid ${tweaks.mode==='dark' ? '#253250' : '#E3E8EF'}`,
        borderRadius: 999, padding: '6px 10px 6px 6px',
        boxShadow: '0 6px 16px rgba(15,23,42,.08)',
      }}>
        <button onClick={() => nav.pop()} disabled={stack.length <= 1}
          className="tap" style={{
            width: 32, height: 32, borderRadius: 999, border: 'none',
            background: stack.length>1 ? (tweaks.mode==='dark' ? '#253250' : '#F1F5F9') : 'transparent',
            color: tweaks.mode==='dark' ? '#E6EDF7' : '#0F172A',
            cursor: stack.length>1 ? 'pointer' : 'not-allowed',
            opacity: stack.length>1 ? 1 : .4,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
          <Icon name="back" size={16} />
        </button>
        <div style={{
          fontSize: 12, color: tweaks.mode==='dark' ? '#8B98B4' : '#64748B',
          fontFamily: 'JetBrains Mono, monospace', padding: '0 6px',
        }}>
          {stack.map(s => s.screen).join(' › ')}
        </div>
      </div>

      {editMode && (
        <TweaksPanel theme={theme} state={tweaks} setState={updateTweaks} />
      )}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
