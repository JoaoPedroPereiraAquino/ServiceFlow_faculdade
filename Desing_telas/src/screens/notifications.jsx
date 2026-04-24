// Notifications screen

function NotificationsScreen({ theme, nav, showMessage }) {
  const [items, setItems] = React.useState([
    { id: 1, kind: 'success', icon: 'check',   title: 'OS-00411 foi concluída',      body: 'Paula M. finalizou o serviço para Café da Praça.', time: '2 min',   unread: true },
    { id: 2, kind: 'warning', icon: 'clock',   title: 'Prazo da OS-00409 hoje',      body: 'Troca de correia — Oficina Motor Sul. Entrega até 18h.', time: '1 h',   unread: true },
    { id: 3, kind: 'info',    icon: 'users',   title: 'Novo cliente cadastrado',     body: 'Mariana Ribeiro foi adicionada por Ricardo S.',           time: '3 h',   unread: true },
    { id: 4, kind: 'info',    icon: 'money',   title: 'Pagamento recebido',          body: 'R$ 2.480,00 referente à OS-00412.',                       time: 'ontem', unread: false },
    { id: 5, kind: 'danger',  icon: 'bell',    title: 'OS-00407 sem resposta',       body: 'Aguardando orçamento há 3 dias.',                         time: '2 dias', unread: false },
    { id: 6, kind: 'info',    icon: 'pencil',  title: 'OS-00405 em execução',        valor: null, body: 'Paula M. iniciou atendimento.',                time: '3 dias', unread: false },
  ]);

  const markAll = () => setItems(items.map(i => ({ ...i, unread: false })));
  const unreadCount = items.filter(i => i.unread).length;

  const sem = {
    success: { bg: theme.successBg, fg: theme.successFg, line: theme.successLine },
    warning: { bg: theme.warningBg, fg: theme.warningFg, line: theme.warningLine },
    danger:  { bg: theme.dangerBg,  fg: theme.dangerFg,  line: theme.dangerLine },
    info:    { bg: theme.tint,      fg: theme.primary,   line: theme.borderSoft },
  };

  return (
    <div className="fadein">
      <AppBar theme={theme} title="Notificações"
        subtitle={unreadCount ? `${unreadCount} não lidas` : 'Tudo em dia'}
        right={
          <button onClick={markAll} className="tap" style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            color: theme.primary, fontSize: 12, fontWeight: 600,
            padding: '8px 12px', fontFamily: 'inherit',
          }}>Marcar tudo</button>
        }
      />

      <div style={{ padding: '8px 16px 24px' }}>
        {items.map((n, i) => {
          const c = sem[n.kind];
          return (
            <div key={n.id} className="tap"
              onClick={() => { setItems(items.map(x => x.id===n.id ? {...x, unread:false} : x));
                showMessage({ kind: 'info', text: `Abrindo: ${n.title}` }); }}
              style={{
                display: 'flex', gap: 12, padding: '12px 10px',
                borderBottom: i < items.length-1 ? `1px solid ${theme.borderSoft}` : 'none',
                cursor: 'pointer', position: 'relative',
              }}>
              {n.unread && (
                <div style={{
                  position: 'absolute', left: 2, top: '50%',
                  width: 6, height: 6, borderRadius: 999,
                  background: theme.primary, transform: 'translateY(-50%)',
                }} />
              )}
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: c.bg, color: c.fg,
                border: `1px solid ${c.line}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
              }}>
                <Icon name={n.icon} size={18} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                  <div style={{
                    fontSize: 14, fontWeight: n.unread ? 600 : 500, color: theme.text,
                    flex: 1, minWidth: 0,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  }}>{n.title}</div>
                  <div style={{ fontSize: 11, color: theme.textFaint, flexShrink: 0 }}>{n.time}</div>
                </div>
                <div style={{
                  fontSize: 13, color: theme.textMuted, marginTop: 2, lineHeight: 1.45,
                  display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
                }}>{n.body}</div>
              </div>
            </div>
          );
        })}

        {items.length === 0 && (
          <div style={{ textAlign: 'center', padding: 40, color: theme.textMuted }}>
            <Icon name="bell" size={32} color={theme.textFaint} />
            <div style={{ marginTop: 8 }}>Nenhuma notificação</div>
          </div>
        )}
      </div>
    </div>
  );
}

window.NotificationsScreen = NotificationsScreen;
