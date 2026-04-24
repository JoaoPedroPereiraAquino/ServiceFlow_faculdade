// Tweaks panel — exposed when the host toolbar enables edit mode

function TweaksPanel({ theme, state, setState }) {
  const [open, setOpen] = React.useState(true);

  const Row = ({ label, children }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
      <div style={{ fontSize: 11, fontWeight: 600, color: '#64748B', textTransform: 'uppercase', letterSpacing: 0.4 }}>
        {label}
      </div>
      {children}
    </div>
  );

  const Chip = ({ active, onClick, children, tint }) => (
    <button className="tap" onClick={onClick} style={{
      padding: '6px 10px', borderRadius: 999,
      background: active ? (tint || '#0B4F8A') : '#F1F5F9',
      color: active ? '#fff' : '#0F172A',
      border: `1px solid ${active ? 'transparent' : '#E2E8F0'}`,
      fontSize: 12, fontWeight: 600, cursor: 'pointer',
      fontFamily: 'inherit',
    }}>{children}</button>
  );

  return (
    <div style={{
      position: 'fixed', right: 20, top: 20, width: 260,
      background: '#fff', borderRadius: 14,
      border: '1px solid #E3E8EF',
      boxShadow: '0 16px 40px rgba(15,23,42,.14)',
      padding: open ? 14 : 10,
      zIndex: 1000,
      fontFamily: 'Inter, system-ui, sans-serif',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: open ? 12 : 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Icon name="sliders" size={16} color="#0F172A" />
          <div style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>Tweaks</div>
        </div>
        <button onClick={() => setOpen(!open)} className="tap" style={{
          background: 'transparent', border: 'none', padding: 4, cursor: 'pointer', color: '#64748B',
        }}>
          <Icon name={open ? 'close' : 'chevron-down'} size={16} />
        </button>
      </div>

      {open && (
        <>
          <Row label="Modo">
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active={state.mode==='light'} onClick={() => setState({ mode: 'light' })}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Icon name="sun" size={12} /> Claro
                </span>
              </Chip>
              <Chip active={state.mode==='dark'} onClick={() => setState({ mode: 'dark' })}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Icon name="moon" size={12} /> Escuro
                </span>
              </Chip>
            </div>
          </Row>

          <Row label="Cor de acento">
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {Object.entries(ACCENT_PRESETS).map(([key, p]) => (
                <button key={key} className="tap"
                  onClick={() => setState({ accent: key })}
                  style={{
                    width: 30, height: 30, borderRadius: 10,
                    background: p.primary, cursor: 'pointer',
                    border: state.accent === key ? `2.5px solid ${p.primary}` : '2.5px solid transparent',
                    boxShadow: state.accent === key ? `0 0 0 2px #fff, 0 0 0 3.5px ${p.primary}` : 'none',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                  {state.accent === key && <Icon name="check" size={14} color="#fff" />}
                </button>
              ))}
            </div>
          </Row>

          <Row label="Densidade">
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active={state.density==='cozy'} onClick={() => setState({ density: 'cozy' })}>Confortável</Chip>
              <Chip active={state.density==='compact'} onClick={() => setState({ density: 'compact' })}>Compacta</Chip>
            </div>
          </Row>

          <Row label="Cantos">
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active={state.radius==='soft'} onClick={() => setState({ radius: 'soft' })}>Suaves</Chip>
              <Chip active={state.radius==='sharp'} onClick={() => setState({ radius: 'sharp' })}>Retos</Chip>
              <Chip active={state.radius==='round'} onClick={() => setState({ radius: 'round' })}>Redondos</Chip>
            </div>
          </Row>

          <Row label="Logo">
            <div style={{ display: 'flex', gap: 6 }}>
              <Chip active={state.logoVariant==='badge'} onClick={() => setState({ logoVariant: 'badge' })}>Badge</Chip>
              <Chip active={state.logoVariant==='flow'} onClick={() => setState({ logoVariant: 'flow' })}>Flow</Chip>
              <Chip active={state.logoVariant==='tag'} onClick={() => setState({ logoVariant: 'tag' })}>Tag</Chip>
            </div>
          </Row>

          <Row label="Ir para tela">
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {['login','signup','dashboard','oslist','os','client','notifications','profile'].map(s => (
                <Chip key={s} active={state.screen===s} onClick={() => setState({ screen: s })} tint="#0F172A">
                  {s}
                </Chip>
              ))}
            </div>
          </Row>
        </>
      )}
    </div>
  );
}

window.TweaksPanel = TweaksPanel;
