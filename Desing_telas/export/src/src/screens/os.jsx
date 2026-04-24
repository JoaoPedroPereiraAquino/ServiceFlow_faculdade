// New OS (Order of Service) screen — client dropdown, description, value, before/after photos, signature

function OSScreen({ theme, nav, showMessage, clients, onSave }) {
  const [clienteId, setClienteId] = React.useState('');
  const [desc, setDesc] = React.useState('');
  const [valor, setValor] = React.useState('');
  const [fotoAntes, setFotoAntes] = React.useState(null);
  const [fotoDepois, setFotoDepois] = React.useState(null);
  const [assinou, setAssinou] = React.useState(false);
  const [sigPath, setSigPath] = React.useState('');
  const [errors, setErrors] = React.useState({});
  const [loading, setLoading] = React.useState(false);
  const [dropdownOpen, setDropdownOpen] = React.useState(false);

  const selectedClient = clients.find(c => c.id === clienteId);

  // Signature pad
  const canvasRef = React.useRef(null);
  const drawing = React.useRef(false);
  const getPos = (e) => {
    const r = canvasRef.current.getBoundingClientRect();
    const t = e.touches ? e.touches[0] : e;
    return { x: t.clientX - r.left, y: t.clientY - r.top };
  };
  const start = (e) => { e.preventDefault(); drawing.current = true;
    const ctx = canvasRef.current.getContext('2d');
    const { x, y } = getPos(e);
    ctx.beginPath(); ctx.moveTo(x, y);
  };
  const move = (e) => {
    if (!drawing.current) return; e.preventDefault();
    const ctx = canvasRef.current.getContext('2d');
    const { x, y } = getPos(e);
    ctx.lineTo(x, y); ctx.stroke();
    setAssinou(true);
  };
  const end = () => { drawing.current = false; };
  const clearSig = () => {
    const c = canvasRef.current;
    c.getContext('2d').clearRect(0, 0, c.width, c.height);
    setAssinou(false);
  };
  React.useEffect(() => {
    const c = canvasRef.current;
    if (!c) return;
    c.width = c.offsetWidth * 2; c.height = c.offsetHeight * 2;
    const ctx = c.getContext('2d');
    ctx.scale(2, 2);
    ctx.strokeStyle = theme.text;
    ctx.lineWidth = 2; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  }, [theme.text]);

  // Simulate taking photo
  const takePhoto = (setter, label) => {
    showMessage({ kind: 'info', text: `Câmera aberta para: ${label}` });
    setTimeout(() => setter({ label, ts: Date.now() }), 400);
  };

  const submit = () => {
    const e = {};
    if (!clienteId) e.cliente = 'Selecione um cliente';
    if (desc.length < 10) e.desc = 'Descrição muito curta';
    const valorNum = parseFloat(valor.replace(/[^\d,]/g,'').replace(',','.')) || 0;
    if (valorNum <= 0) e.valor = 'Informe um valor válido';
    if (!assinou) e.sig = 'Assinatura obrigatória do cliente';
    setErrors(e);
    if (Object.keys(e).length) return;

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onSave({ clienteId, descricao: desc, valor: valorNum });
      showMessage({ kind: 'success', text: 'OS registrada com sucesso' });
      nav.pop();
    }, 2000);
  };

  return (
    <div className="fadein">
      <AppBar theme={theme} title="Nova ordem de serviço" onBack={() => nav.pop()} />

      <div style={{ padding: '16px 20px 40px' }}>
        <FormStack gap={16}>

          {/* Client dropdown */}
          <div>
            <div style={{
              fontSize: 12, fontWeight: 500, color: theme.textMuted,
              marginBottom: 6,
            }}>Cliente</div>
            <button
              className="tap"
              onClick={() => setDropdownOpen(!dropdownOpen)}
              style={{
                width: '100%', minHeight: 48,
                background: theme.surface,
                border: `1.5px solid ${errors.cliente ? theme.dangerFg : (dropdownOpen ? theme.primary : theme.border)}`,
                borderRadius: 12, padding: '0 12px',
                display: 'flex', alignItems: 'center', gap: 10,
                cursor: 'pointer', textAlign: 'left',
                color: theme.text, fontSize: 15, fontFamily: 'inherit',
              }}
            >
              <Icon name="users" size={18} color={theme.textMuted} />
              <div style={{ flex: 1, color: selectedClient ? theme.text : theme.textFaint }}>
                {selectedClient ? selectedClient.nome : 'Selecione um cliente'}
              </div>
              <Icon name="chevron-down" size={18} color={theme.textMuted}
                style={{ transform: dropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform .15s' }} />
            </button>
            {dropdownOpen && (
              <div style={{
                marginTop: 6, background: theme.surface,
                border: `1px solid ${theme.border}`, borderRadius: 12,
                overflow: 'hidden', boxShadow: theme.shadow,
                maxHeight: 240, overflowY: 'auto',
              }}>
                {clients.map(c => (
                  <div key={c.id} className="tap"
                    onClick={() => { setClienteId(c.id); setDropdownOpen(false); }}
                    style={{
                      padding: '12px 14px', cursor: 'pointer',
                      borderBottom: `1px solid ${theme.borderSoft}`,
                      background: c.id === clienteId ? theme.tint : 'transparent',
                      display: 'flex', flexDirection: 'column', gap: 2,
                    }}>
                    <div style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{c.nome}</div>
                    <div style={{ fontSize: 12, color: theme.textMuted }}>{c.doc}</div>
                  </div>
                ))}
              </div>
            )}
            {errors.cliente && (
              <div style={{ fontSize: 12, color: theme.dangerFg, marginTop: 6 }}>{errors.cliente}</div>
            )}
          </div>

          <CustomTextField
            theme={theme} label="Descrição do serviço"
            placeholder="Detalhe o que será executado..."
            value={desc} onChange={setDesc}
            multiline rows={4}
            error={errors.desc}
          />

          <CustomTextField
            theme={theme} label="Valor estipulado" icon="money" mask="money"
            placeholder="R$ 0,00"
            value={valor} onChange={setValor}
            error={errors.valor}
            keyboardType="decimal"
          />

          {/* Before/After photos */}
          <div>
            <div style={{
              fontSize: 12, fontWeight: 500, color: theme.textMuted,
              marginBottom: 6,
            }}>Evidências fotográficas</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {[
                { slot: fotoAntes, set: setFotoAntes, label: 'Foto antes' },
                { slot: fotoDepois, set: setFotoDepois, label: 'Foto depois' },
              ].map((p) => (
                <button key={p.label} className="tap"
                  onClick={() => takePhoto(p.set, p.label)}
                  style={{
                    aspectRatio: '1',
                    background: p.slot
                      ? `repeating-linear-gradient(135deg, ${theme.borderSoft}, ${theme.borderSoft} 6px, ${theme.surfaceAlt} 6px, ${theme.surfaceAlt} 12px)`
                      : theme.surface,
                    border: `1.5px dashed ${p.slot ? theme.primary : theme.border}`,
                    borderRadius: 12, cursor: 'pointer',
                    display: 'flex', flexDirection: 'column',
                    alignItems: 'center', justifyContent: 'center',
                    gap: 8, color: p.slot ? theme.primary : theme.textMuted,
                    position: 'relative', overflow: 'hidden',
                    fontFamily: 'inherit',
                  }}>
                  {p.slot ? (
                    <>
                      <div style={{
                        position: 'absolute', inset: 0,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontFamily: 'JetBrains Mono, monospace',
                        fontSize: 10, letterSpacing: 0.3,
                        color: theme.textMuted, opacity: .7,
                      }}>{p.label.replace(' ', '_')}.jpg</div>
                      <div style={{
                        position: 'absolute', bottom: 8, right: 8,
                        background: theme.primary, color: '#fff',
                        width: 24, height: 24, borderRadius: 999,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        <Icon name="check" size={14} />
                      </div>
                    </>
                  ) : (
                    <>
                      <Icon name="camera" size={22} />
                      <div style={{ fontSize: 12, fontWeight: 500 }}>{p.label}</div>
                    </>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Signature */}
          <div>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              marginBottom: 6,
            }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: errors.sig ? theme.dangerFg : theme.textMuted }}>
                Assinatura do cliente
              </div>
              <button onClick={clearSig} className="tap" style={{
                background: 'transparent', border: 'none', cursor: 'pointer',
                padding: 4, fontSize: 12, color: theme.primary, fontWeight: 500,
                fontFamily: 'inherit',
              }}>Limpar</button>
            </div>
            <div style={{
              background: theme.surface,
              border: `1.5px solid ${errors.sig ? theme.dangerFg : theme.border}`,
              borderRadius: 12,
              height: 140, position: 'relative', overflow: 'hidden',
            }}>
              <canvas
                ref={canvasRef}
                style={{ width: '100%', height: '100%', touchAction: 'none' }}
                onMouseDown={start} onMouseMove={move} onMouseUp={end} onMouseLeave={end}
                onTouchStart={start} onTouchMove={move} onTouchEnd={end}
              />
              {!assinou && (
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  pointerEvents: 'none', gap: 8,
                  color: theme.textFaint, fontSize: 13,
                }}>
                  <Icon name="signature" size={18} />
                  Assine aqui
                </div>
              )}
            </div>
            {errors.sig && (
              <div style={{ fontSize: 12, color: theme.dangerFg, marginTop: 6 }}>{errors.sig}</div>
            )}
          </div>

          <div style={{ marginTop: 8 }}>
            <CustomButton theme={theme} loading={loading} onClick={submit} icon={loading ? null : 'check'}>
              {loading ? 'Processando...' : 'Salvar OS'}
            </CustomButton>
          </div>
        </FormStack>
      </div>
    </div>
  );
}

window.OSScreen = OSScreen;
