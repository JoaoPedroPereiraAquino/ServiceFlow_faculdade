// OS List — opened from dashboard cards with a filter

function OSListScreen({ theme, nav, osList, clients, params = {} }) {
  const [filter, setFilter] = React.useState(params.filter || 'total');
  const [q, setQ] = React.useState('');

  const filters = [
    { key: 'total',     label: 'Todas',       count: osList.length },
    { key: 'aberto',    label: 'Em aberto',   count: osList.filter(o => o.status==='aberto').length   },
    { key: 'execucao',  label: 'Em execução', count: osList.filter(o => o.status==='execucao').length },
    { key: 'executada', label: 'Executada',   count: osList.filter(o => o.status==='executada').length },
  ];

  const filtered = osList
    .filter(o => filter === 'total' ? true : o.status === filter)
    .filter(o => {
      const cli = clients.find(c => c.id === o.clienteId);
      const text = `${o.id} ${o.descricao} ${cli?.nome ?? ''}`.toLowerCase();
      return text.includes(q.toLowerCase());
    });

  const totalValue = filtered.reduce((a, o) => a + o.valor, 0);

  return (
    <div className="fadein" style={{ position: 'relative', minHeight: '100%' }}>
      <AppBar theme={theme} title="Ordens de serviço"
        subtitle={`${filtered.length} resultados · ${fmtBRL(totalValue)}`}
      />

      {/* Filter chips (scrollable — supports mouse-drag, touch, wheel) */}
      <div className="no-scrollbar" ref={(el) => {
        if (!el || el.__dragBound) return;
        el.__dragBound = true;
        let down = false, startX = 0, startScroll = 0, moved = false;
        el.addEventListener('pointerdown', (e) => {
          down = true; moved = false;
          startX = e.clientX; startScroll = el.scrollLeft;
          el.setPointerCapture?.(e.pointerId);
        });
        el.addEventListener('pointermove', (e) => {
          if (!down) return;
          const dx = e.clientX - startX;
          if (Math.abs(dx) > 4) moved = true;
          el.scrollLeft = startScroll - dx;
        });
        const end = (e) => {
          down = false;
          if (moved) {
            // swallow the click that follows a drag
            const kill = (ev) => { ev.stopPropagation(); ev.preventDefault(); el.removeEventListener('click', kill, true); };
            el.addEventListener('click', kill, true);
          }
        };
        el.addEventListener('pointerup', end);
        el.addEventListener('pointercancel', end);
      }}
      style={{
        display: 'flex', gap: 8, padding: '12px 20px 8px',
        overflowX: 'auto', background: theme.surface,
        borderBottom: `1px solid ${theme.borderSoft}`,
        scrollbarWidth: 'none',
        touchAction: 'pan-x',
        WebkitOverflowScrolling: 'touch',
        overscrollBehaviorX: 'contain',
        cursor: 'grab', userSelect: 'none',
      }}
      onWheel={(e) => {
        if (Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
          e.currentTarget.scrollLeft += e.deltaY;
        }
      }}>
        {filters.map(f => {
          const active = filter === f.key;
          return (
            <button key={f.key} className="tap"
              onClick={() => setFilter(f.key)}
              style={{
                background: active ? theme.primary : theme.surfaceAlt,
                color: active ? '#fff' : theme.text,
                border: `1px solid ${active ? theme.primary : theme.borderSoft}`,
                borderRadius: 999, padding: '7px 14px',
                fontSize: 13, fontWeight: 600,
                fontFamily: 'inherit', cursor: 'pointer',
                whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', gap: 6,
              }}>
              {f.label}
              <span style={{
                background: active ? 'rgba(255,255,255,.25)' : theme.borderSoft,
                color: active ? '#fff' : theme.textMuted,
                borderRadius: 999, padding: '1px 7px', fontSize: 11,
                fontFeatureSettings: '"tnum"',
              }}>{f.count}</span>
            </button>
          );
        })}
      </div>

      {/* Search */}
      <div style={{ padding: '12px 20px 4px', background: theme.surface, borderBottom: `1px solid ${theme.borderSoft}` }}>
        <CustomTextField
          theme={theme} label="" icon="search"
          placeholder="Buscar por cliente, ID ou descrição"
          value={q} onChange={setQ}
        />
      </div>

      {/* List */}
      {filtered.length === 0 ? (
        <div style={{
          padding: '60px 24px', textAlign: 'center',
          color: theme.textMuted, fontSize: 14,
        }}>
          <Icon name="briefcase" size={32} color={theme.textFaint} />
          <div style={{ marginTop: 10 }}>Nenhuma OS encontrada</div>
        </div>
      ) : (
        <div style={{ padding: '12px 20px 24px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {filtered.map(o => {
            const client = clients.find(c => c.id === o.clienteId);
            return (
              <div key={o.id} className="tap"
                style={{
                  background: theme.surface,
                  border: `1px solid ${theme.borderSoft}`,
                  borderRadius: 14, padding: 14,
                  cursor: 'pointer',
                }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                  <div style={{
                    fontFamily: 'JetBrains Mono, monospace',
                    fontSize: 11, fontWeight: 600,
                    color: theme.textMuted, letterSpacing: 0.3,
                  }}>{o.id}</div>
                  <div style={{ flex: 1 }} />
                  <Badge theme={theme} status={o.status} small />
                </div>
                <div style={{ fontSize: 15, fontWeight: 600, color: theme.text, letterSpacing: -0.1 }}>
                  {client ? client.nome : '—'}
                </div>
                <div style={{
                  fontSize: 13, color: theme.textMuted, lineHeight: 1.45,
                  marginTop: 3,
                  display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical',
                  overflow: 'hidden',
                }}>{o.descricao}</div>
                <div style={{
                  marginTop: 10, paddingTop: 10,
                  borderTop: `1px dashed ${theme.borderSoft}`,
                  display: 'flex', alignItems: 'center', gap: 10, fontSize: 12,
                  color: theme.textMuted,
                }}>
                  <Icon name="clock" size={14} />
                  {o.criadoEm}
                  <div style={{ width: 1, height: 10, background: theme.borderSoft }} />
                  <Icon name="user" size={14} />
                  {o.tecnico}
                  <div style={{ flex: 1 }} />
                  <div style={{
                    fontSize: 14, fontWeight: 700, color: theme.text,
                    fontFeatureSettings: '"tnum"',
                  }}>{fmtBRL(o.valor)}</div>
                </div>
              </div>
            );
          })}
        </div>
      )}

    </div>
  );
}

window.OSListScreen = OSListScreen;
