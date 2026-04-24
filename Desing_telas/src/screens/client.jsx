// Client registration screen

function ClientScreen({ theme, nav, showMessage, clients, setClients }) {
  const [form, setForm] = React.useState({ nome: '', doc: '', email: '', telefone: '' });
  const [errors, setErrors] = React.useState({});
  const [loading, setLoading] = React.useState(false);
  const upd = (k) => (v) => setForm({ ...form, [k]: v });

  const submit = () => {
    const e = {};
    if (!form.nome) e.nome = 'Informe o nome ou razão social';
    const digs = form.doc.replace(/\D/g, '');
    if (digs.length !== 11 && digs.length !== 14) e.doc = 'CPF ou CNPJ inválido';
    if (!form.email.includes('@')) e.email = 'E-mail inválido';
    if (form.telefone.replace(/\D/g, '').length < 10) e.telefone = 'Telefone incompleto';
    setErrors(e);
    if (Object.keys(e).length) return;

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setClients([...clients, { id: 'c' + Date.now(), ...form }]);
      showMessage({ kind: 'success', text: 'Cliente cadastrado com sucesso' });
      nav.pop();
    }, 1400);
  };

  return (
    <div className="fadein">
      <AppBar theme={theme} title="Novo cliente" onBack={() => nav.pop()} />

      <div style={{ padding: '20px 24px 40px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: theme.tint, color: theme.primary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="building" size={22} />
          </div>
          <div>
            <div style={{ fontSize: 15, fontWeight: 600, color: theme.text }}>Dados do cliente</div>
            <div style={{ fontSize: 12, color: theme.textMuted }}>Vincule OS a este cadastro depois.</div>
          </div>
        </div>

        <FormStack gap={16}>
          <CustomTextField
            theme={theme} label="Nome / Razão social" icon="building"
            placeholder="Ex: Indústrias Bravo Ltda."
            value={form.nome} onChange={upd('nome')} error={errors.nome}
          />
          <CustomTextField
            theme={theme} label="CPF / CNPJ" icon="id" mask="cpfcnpj"
            placeholder="000.000.000-00"
            value={form.doc} onChange={upd('doc')} error={errors.doc}
            keyboardType="numeric"
          />
          <CustomTextField
            theme={theme} label="E-mail" icon="mail"
            placeholder="contato@empresa.com"
            value={form.email} onChange={upd('email')} error={errors.email}
            keyboardType="email"
          />
          <CustomTextField
            theme={theme} label="Telefone" icon="phone" mask="phone"
            placeholder="(11) 98888-7777"
            value={form.telefone} onChange={upd('telefone')} error={errors.telefone}
            keyboardType="tel"
          />

          <div style={{ marginTop: 12, display: 'flex', gap: 10 }}>
            <CustomButton theme={theme} variant="secondary" onClick={() => nav.pop()}>
              Cancelar
            </CustomButton>
            <CustomButton theme={theme} loading={loading} onClick={submit} icon="check">
              Salvar
            </CustomButton>
          </div>
        </FormStack>
      </div>
    </div>
  );
}

window.ClientScreen = ClientScreen;
