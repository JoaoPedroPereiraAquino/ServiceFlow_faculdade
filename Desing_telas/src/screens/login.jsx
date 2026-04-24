// Login screen — email + password + "Criar nova conta" link
// Validation: email contains "@", password length > 6

function LoginScreen({ theme, nav, showMessage }) {
  const [email, setEmail] = React.useState('');
  const [pass, setPass]   = React.useState('');
  const [obscure, setObscure] = React.useState(true);
  const [errors, setErrors]   = React.useState({});
  const [loading, setLoading] = React.useState(false);
  const [shake, setShake]     = React.useState(false);

  const submit = () => {
    const e = {};
    if (!email) e.email = 'Informe seu e-mail';
    else if (!email.includes('@')) e.email = 'E-mail inválido';
    if (!pass) e.pass = 'Informe sua senha';
    else if (pass.length <= 6) e.pass = 'Senha deve ter mais de 6 caracteres';
    setErrors(e);
    if (Object.keys(e).length) {
      setShake(true); setTimeout(() => setShake(false), 400);
      return;
    }
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      showMessage({ kind: 'success', text: 'Bem-vindo de volta, Ana' });
      nav.replace('dashboard');
    }, 1200);
  };

  return (
    <div className="fadein" style={{
      minHeight: '100%', background: theme.bg,
      display: 'flex', flexDirection: 'column',
      padding: '30px 24px 24px',
    }}>
      <div style={{ marginTop: 28, marginBottom: 28, display: 'flex', justifyContent: 'center' }}>
        <AppLogo theme={theme} size={72} variant={theme._logoVariant || 'badge'} />
      </div>

      <div className={shake ? 'shake' : ''}>
        <div style={{
          fontSize: 22, fontWeight: 700, color: theme.text,
          letterSpacing: -0.4, marginBottom: 4,
        }}>Bem-vindo</div>
        <div style={{
          fontSize: 14, color: theme.textMuted, marginBottom: 22,
        }}>Entre na sua conta para continuar.</div>

        <FormStack gap={16}>
          <CustomTextField
            theme={theme} label="E-mail" icon="mail"
            placeholder="voce@empresa.com"
            value={email} onChange={setEmail}
            error={errors.email}
            keyboardType="email"
          />
          <CustomTextField
            theme={theme} label="Senha" icon="lock"
            placeholder="••••••••"
            value={pass} onChange={setPass}
            obscure={obscure}
            onToggleObscure={() => setObscure(!obscure)}
            error={errors.pass}
          />
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: -4 }}>
            <button className="tap" style={{
              background: 'transparent', border: 'none', cursor: 'pointer',
              fontSize: 13, fontWeight: 500, color: theme.primary,
              padding: 0,
            }} onClick={() => showMessage({ kind: 'info', text: 'Enviaremos o link de redefinição por e-mail.' })}>
              Esqueci minha senha
            </button>
          </div>
          <div style={{ marginTop: 8 }}>
            <CustomButton theme={theme} loading={loading} onClick={submit}>
              Entrar
            </CustomButton>
          </div>
        </FormStack>
      </div>

      <div style={{ height: 24 }} />

      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        margin: '0 0 14px', color: theme.textFaint, fontSize: 12,
      }}>
        <div style={{ flex: 1, height: 1, background: theme.borderSoft }} />
        ou
        <div style={{ flex: 1, height: 1, background: theme.borderSoft }} />
      </div>

      <CustomButton theme={theme} variant="secondary" onClick={() => nav.push('signup')} icon="plus">
        Criar nova conta
      </CustomButton>

      <div style={{ flex: 1 }} />

      <div style={{
        textAlign: 'center', fontSize: 11, color: theme.textFaint,
        marginTop: 16, letterSpacing: 0.2,
      }}>
        ServiceFlow · v1.0.0
      </div>
    </div>
  );
}

window.LoginScreen = LoginScreen;
