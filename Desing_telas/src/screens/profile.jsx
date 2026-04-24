// Profile screen

function ProfileScreen({ theme, nav, showMessage }) {
  const stats = [
    { label: 'OS no mês',     value: '24'   },
    { label: 'Faturamento',   value: 'R$ 11k' },
    { label: 'Avaliação',     value: '4,8'  },
  ];

  const sections = [
    {
      title: 'Conta',
      items: [
        { icon: 'user',     label: 'Dados pessoais',    hint: 'Nome, e-mail, telefone' },
        { icon: 'lock',     label: 'Segurança',         hint: 'Senha, 2FA' },
        { icon: 'building', label: 'Dados da empresa',  hint: 'Razão social, CNPJ' },
      ],
    },
    {
      title: 'Preferências',
      items: [
        { icon: 'bell',     label: 'Notificações',      hint: 'Push, e-mail, SMS', onClick: () => nav.push('notifications') },
        { icon: 'moon',     label: 'Aparência',         hint: 'Tema e idioma' },
        { icon: 'sliders',  label: 'Unidades e moeda',  hint: 'R$ · pt-BR' },
      ],
    },
    {
      title: 'Suporte',
      items: [
        { icon: 'mail',     label: 'Fale conosco',      hint: 'suporte@serviceflow.app' },
        { icon: 'settings', label: 'Sobre o app',       hint: 'v1.0.0 (build 124)' },
      ],
    },
  ];

  return (
    <div className="fadein">
      <AppBar theme={theme} title="Perfil" />

      <div style={{ padding: '20px 20px 28px', display: 'flex', flexDirection: 'column', gap: 20 }}>

        {/* Header card */}
        <div style={{
          background: `linear-gradient(135deg, ${theme.primary}, ${theme.primaryDark})`,
          color: '#fff', borderRadius: 18, padding: 18,
          display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: `0 12px 28px ${theme.primary}33`,
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: 999,
            background: 'rgba(255,255,255,.2)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 22, fontWeight: 700, border: '2px solid rgba(255,255,255,.3)',
          }}>AS</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.2 }}>Ana Souza</div>
            <div style={{ fontSize: 12, opacity: .85, marginTop: 2 }}>Gestora · ServiceFlow Pro</div>
            <div style={{
              marginTop: 8, display: 'inline-flex', alignItems: 'center', gap: 5,
              background: 'rgba(255,255,255,.2)', padding: '3px 8px',
              borderRadius: 999, fontSize: 11, fontWeight: 600,
            }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: '#34D399' }} />
              Online
            </div>
          </div>
          <button className="tap" onClick={() => showMessage({ kind: 'info', text: 'Abrindo editor de perfil' })}
            style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'rgba(255,255,255,.15)', color: '#fff',
              border: '1px solid rgba(255,255,255,.25)', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
            <Icon name="pencil" size={16} />
          </button>
        </div>

        {/* Stats */}
        <div style={{
          background: theme.surface,
          border: `1px solid ${theme.borderSoft}`,
          borderRadius: 14, padding: '14px 10px',
          display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
        }}>
          {stats.map((s, i) => (
            <div key={s.label} style={{
              textAlign: 'center',
              borderRight: i < stats.length-1 ? `1px solid ${theme.borderSoft}` : 'none',
            }}>
              <div style={{ fontSize: 18, fontWeight: 700, color: theme.text, letterSpacing: -0.3, fontFeatureSettings: '"tnum"' }}>
                {s.value}
              </div>
              <div style={{ fontSize: 11, color: theme.textMuted, marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Sections */}
        {sections.map(sec => (
          <div key={sec.title}>
            <div style={{
              fontSize: 11, fontWeight: 600, letterSpacing: 0.4,
              color: theme.textMuted, textTransform: 'uppercase',
              padding: '0 4px 8px',
            }}>{sec.title}</div>
            <div style={{
              background: theme.surface,
              border: `1px solid ${theme.borderSoft}`,
              borderRadius: 14, overflow: 'hidden',
            }}>
              {sec.items.map((it, i) => (
                <button key={it.label} className="tap"
                  onClick={it.onClick || (() => showMessage({ kind: 'info', text: it.label }))}
                  style={{
                    width: '100%', display: 'flex', alignItems: 'center', gap: 12,
                    padding: '12px 14px', background: 'transparent',
                    border: 'none', borderBottom: i < sec.items.length-1 ? `1px solid ${theme.borderSoft}` : 'none',
                    cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
                  }}>
                  <div style={{
                    width: 34, height: 34, borderRadius: 10,
                    background: theme.tint, color: theme.primary,
                    border: `1px solid ${theme.borderSoft}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon name={it.icon} size={16} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{it.label}</div>
                    <div style={{ fontSize: 12, color: theme.textMuted, marginTop: 1 }}>{it.hint}</div>
                  </div>
                  <Icon name="chevron-right" size={16} color={theme.textFaint} />
                </button>
              ))}
            </div>
          </div>
        ))}

        {/* Logout */}
        <button className="tap" onClick={() => nav.replace('login')}
          style={{
            width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center',
            gap: 8, padding: '14px', background: theme.surface,
            border: `1.5px solid ${theme.dangerLine}`, color: theme.dangerFg,
            borderRadius: 12, cursor: 'pointer', fontSize: 14, fontWeight: 600,
            fontFamily: 'inherit',
          }}>
          <Icon name="logout" size={16} />
          Sair da conta
        </button>
      </div>
    </div>
  );
}

window.ProfileScreen = ProfileScreen;
