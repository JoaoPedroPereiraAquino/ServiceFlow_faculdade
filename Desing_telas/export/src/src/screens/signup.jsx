// Signup screen — cadastro de novo usuário

function SignupScreen({ theme, nav, showMessage }) {
  const [form, setForm] = React.useState({
    nome: '', email: '', telefone: '', senha: '', confirma: '',
  });
  const [errors, setErrors] = React.useState({});
  const [loading, setLoading] = React.useState(false);
  const [obscure, setObscure] = React.useState(true);

  const upd = (k) => (v) => setForm({ ...form, [k]: v });

  const submit = () => {
    const e = {};
    if (!form.nome || form.nome.length < 3) e.nome = 'Nome muito curto';
    if (!form.email.includes('@')) e.email = 'E-mail inválido';
    if (form.telefone.replace(/\D/g, '').length < 10) e.telefone = 'Telefone incompleto';
    if (form.senha.length <= 6) e.senha = 'Senha deve ter mais de 6 caracteres';
    if (form.senha !== form.confirma) e.confirma = 'Senhas não conferem';
    setErrors(e);
    if (Object.keys(e).length) return;

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      showMessage({ kind: 'success', text: 'Conta criada com sucesso' });
      nav.pop();
    }, 1500);
  };

  return (
    <div className="fadein">
      <AppBar theme={theme} title="Criar conta" onBack={() => nav.pop()} />

      <div style={{ padding: '20px 24px 40px' }}>
        <div style={{
          fontSize: 15, color: theme.textMuted, marginBottom: 22, lineHeight: 1.5,
        }}>
          Preencha seus dados para começar a gerenciar ordens de serviço.
        </div>

        <FormStack gap={16}>
          <CustomTextField
            theme={theme} label="Nome completo" icon="user"
            placeholder="Ana Souza"
            value={form.nome} onChange={upd('nome')} error={errors.nome}
          />
          <CustomTextField
            theme={theme} label="E-mail" icon="mail"
            placeholder="ana@empresa.com"
            value={form.email} onChange={upd('email')} error={errors.email}
            keyboardType="email"
          />
          <CustomTextField
            theme={theme} label="Telefone" icon="phone" mask="phone"
            placeholder="(11) 98888-7777"
            value={form.telefone} onChange={upd('telefone')} error={errors.telefone}
            keyboardType="tel"
          />
          <CustomTextField
            theme={theme} label="Senha" icon="lock"
            placeholder="no mínimo 7 caracteres"
            value={form.senha} onChange={upd('senha')} error={errors.senha}
            obscure={obscure}
            onToggleObscure={() => setObscure(!obscure)}
          />
          <CustomTextField
            theme={theme} label="Confirme a senha" icon="lock"
            placeholder="repita a senha"
            value={form.confirma} onChange={upd('confirma')} error={errors.confirma}
            obscure={obscure}
          />

          <div style={{
            display: 'flex', gap: 10, alignItems: 'flex-start',
            background: theme.tint, border: `1px solid ${theme.borderSoft}`,
            borderRadius: 10, padding: 12, marginTop: 4,
          }}>
            <Icon name="check" size={16} color={theme.primary} style={{ marginTop: 2 }} />
            <div style={{ fontSize: 12, color: theme.text, lineHeight: 1.5 }}>
              Ao criar conta você concorda com os <b>Termos de uso</b> e a <b>Política de privacidade</b> do ServiceFlow.
            </div>
          </div>

          <CustomButton theme={theme} loading={loading} onClick={submit}>
            Criar conta
          </CustomButton>
        </FormStack>
      </div>
    </div>
  );
}

window.SignupScreen = SignupScreen;
