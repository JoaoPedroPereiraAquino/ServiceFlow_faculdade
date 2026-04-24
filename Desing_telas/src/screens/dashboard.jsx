// Dashboard — KPI cards + recent OS + shortcuts

function DashboardScreen({ theme, nav, osList, clients, showMessage }) {
  const sum = summarizeOS(osList);

  const cards = [
    { key: 'total',     label: 'Total',        icon: 'briefcase', semantic: 'neutral', data: sum.total     },
    { key: 'aberto',    label: 'Em aberto',    icon: 'clock',     semantic: 'neutral', data: sum.aberto    },
    { key: 'execucao',  label: 'Em execução',  icon: 'pencil',    semantic: 'warning', data: sum.execucao  },
    { key: 'executada', label: 'Executada',    icon: 'check',     semantic: 'success', data: sum.executada },
  ];

  const semMap = {
    success: { bg: theme.successBg, fg: theme.successFg, line: theme.successLine },
    warning: { bg: theme.warningBg, fg: theme.warningFg, line: theme.warningLine },
    neutral: { bg: theme.tint,      fg: theme.primary,   line: theme.borderSoft  },
  };

  const recent = osList.slice(0, 3);

  return (
    <div className="fadein" style={{ paddingBottom: 24 }}>
      {/* Custom app bar w/ greeting */}
      <div style={{
        padding: '18px 20px 14px',
        background: theme.surface,
        borderBottom: `1px solid ${theme.borderSoft}`,
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 999,
          background: theme.tint, color: theme.primary,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontWeight: 600, fontSize: 15,
        }}>AS</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: theme.textMuted }}>Olá, bom dia</div>
          <div style={{ fontSize: 16, fontWeight: 600, color: theme.text, letterSpacing: -0.2 }}>Ana Souza</div>
        </div>
        <button className="tap" onClick={() => showMessage({ kind: 'info', text: 'Sem notificações pendentes' })}
          style={{
            width: 40, height: 40, borderRadius: 999,
            background: theme.surfaceAlt,
            border: `1px solid ${theme.borderSoft}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: theme.text, cursor: 'pointer', position: 'relative',
          }}>
          <Icon name="bell" size={18} />
          <span style={{
            position: 'absolute', top: 8, right: 9, width: 8, height: 8,
            borderRadius: 999, background: theme.dangerFg,
            border: `2px solid ${theme.surfaceAlt}`,
          }} />
        </button>
        <button className="tap" onClick={() => nav.replace('login')} style={{
          width: 40, height: 40, borderRadius: 999,
          background: theme.surfaceAlt,
          border: `1px solid ${theme.borderSoft}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: theme.text, cursor: 'pointer',
        }}>
          <Icon name="logout" size={18} />
        </button>
      </div>

      {/* Faturamento summary strip */}
      <div style={{ padding: '18px 20px 0' }}>
        <div style={{
          background: `linear-gradient(135deg, ${theme.primary}, ${theme.primaryDark})`,
          color: '#fff', borderRadius: 16, padding: 18,
          display: 'flex', alignItems: 'center', gap: 16,
          boxShadow: `0 12px 28px ${theme.primary}33`,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, opacity: .8, fontWeight: 500, letterSpacing: 0.4, textTransform: 'uppercase' }}>
              Faturamento · abril
            </div>
            <div style={{ fontSize: 26, fontWeight: 700, marginTop: 4, letterSpacing: -0.5 }}>
              {fmtBRL(sum.total.value)}
            </div>
            <div style={{ fontSize: 12, opacity: .85, marginTop: 6 }}>
              {sum.executada.count} OS faturadas · {sum.execucao.count + sum.aberto.count} em andamento
            </div>
          </div>
          <div style={{
            width: 56, height: 56, borderRadius: 14,
            background: 'rgba(255,255,255,.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="chart" size={26} />
          </div>
        </div>
      </div>

      {/* KPI grid */}
      <SectionHeader theme={theme}>Indicadores</SectionHeader>
      <div style={{
        padding: '0 20px',
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12,
      }}>
        {cards.map(c => {
          const sem = semMap[c.semantic];
          return (
            <div key={c.key} className="kpi-card tap" onClick={() => nav.push('oslist', { filter: c.key })}
              style={{
                background: theme.surface,
                border: `1px solid ${theme.borderSoft}`,
                borderRadius: 14, padding: 14,
                display: 'flex', flexDirection: 'column', gap: 10,
                transition: 'all .15s',
              }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 10,
                  background: sem.bg, color: sem.fg,
                  border: `1px solid ${sem.line}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name={c.icon} size={16} />
                </div>
                <Icon name="chevron-right" size={16} color={theme.textFaint} />
              </div>
              <div>
                <div style={{ fontSize: 12, color: theme.textMuted, fontWeight: 500 }}>{c.label}</div>
                <div style={{
                  fontSize: 24, fontWeight: 700, color: theme.text,
                  letterSpacing: -0.6, marginTop: 2,
                }}>{c.data.count}</div>
              </div>
              <div style={{
                paddingTop: 8, borderTop: `1px dashed ${theme.borderSoft}`,
                fontSize: 13, fontWeight: 600, color: sem.fg,
                fontFeatureSettings: '"tnum"',
              }}>
                {fmtBRL(c.data.value)}
              </div>
            </div>
          );
        })}
      </div>

      {/* Quick actions */}
      <SectionHeader theme={theme}>Atalhos</SectionHeader>
      <div style={{
        padding: '0 20px',
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12,
      }}>
        <button className="tap" onClick={() => nav.push('os')} style={{
          background: theme.primary, color: '#fff',
          border: 'none', borderRadius: 14, padding: '16px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
          cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
          boxShadow: `0 6px 14px ${theme.primary}33`,
        }}>
          <Icon name="plus" size={20} />
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Nova OS</div>
            <div style={{ fontSize: 11, opacity: .8 }}>Registrar serviço</div>
          </div>
        </button>
        <button className="tap" onClick={() => nav.push('client')} style={{
          background: theme.surface, color: theme.text,
          border: `1px solid ${theme.borderSoft}`, borderRadius: 14, padding: '16px 14px',
          display: 'flex', alignItems: 'center', gap: 12,
          cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left',
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: 10,
            background: theme.tint, color: theme.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="users" size={16} />
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Novo cliente</div>
            <div style={{ fontSize: 11, color: theme.textMuted }}>Cadastrar contato</div>
          </div>
        </button>
      </div>

      {/* Recent OS */}
      <SectionHeader theme={theme} action={
        <button onClick={() => nav.push('oslist', { filter: 'total' })} className="tap"
          style={{ background: 'transparent', border: 'none', padding: 0,
            color: theme.primary, fontSize: 12, fontWeight: 600, cursor: 'pointer',
            fontFamily: 'inherit',
          }}>Ver todas</button>
      }>Ordens recentes</SectionHeader>
      <div style={{
        margin: '0 20px',
        background: theme.surface,
        border: `1px solid ${theme.borderSoft}`,
        borderRadius: 14, overflow: 'hidden',
      }}>
        {recent.map((o, i) => {
          const client = clients.find(c => c.id === o.clienteId);
          return (
            <div key={o.id} className="tap" onClick={() => showMessage({ kind: 'info', text: `Abrindo ${o.id}` })}
              style={{
                padding: '12px 14px',
                borderBottom: i < recent.length - 1 ? `1px solid ${theme.borderSoft}` : 'none',
                display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
              }}>
              <div style={{
                fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
                fontWeight: 600, color: theme.textMuted, letterSpacing: 0.4,
                writingMode: 'vertical-rl', transform: 'rotate(180deg)',
                paddingRight: 4, borderRight: `1px solid ${theme.borderSoft}`,
              }}>{o.id}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: 13, fontWeight: 600, color: theme.text,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{client ? client.nome : '—'}</div>
                <div style={{ fontSize: 12, color: theme.textMuted, marginTop: 2,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{o.descricao}</div>
              </div>
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: theme.text, fontFeatureSettings: '"tnum"' }}>
                  {fmtBRL(o.valor)}
                </div>
                <div style={{ marginTop: 4 }}>
                  <Badge theme={theme} status={o.status} small />
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

window.DashboardScreen = DashboardScreen;
