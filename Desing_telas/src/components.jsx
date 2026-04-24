// Reusable components: CustomTextField, CustomButton, AppLogo, Snackbar, Loader, Badge, Card

// ─── AppLogo ───────────────────────────────────────────────
// Variants:
//  'badge'  — rounded-square badge with custom SF mark + wordmark beneath
//  'flow'   — stylised flowing "S" glyph in a rounded square (suggests movement/flow)
//  'tag'    — work-order tag shape with checkmark (suggests service/tickets)
function AppLogo({ theme, size = 64, withText = true, align = 'center', variant = 'badge' }) {
  const Mark = (() => {
    const s = size;
    if (variant === 'flow') {
      // Flowing S + two speed-marks inside a rounded square
      return (
        <div style={{
          width: s, height: s, borderRadius: s * 0.28,
          background: `linear-gradient(145deg, ${theme.primary}, ${theme.primaryDark})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 12px 28px ${theme.primary}40, inset 0 1px 0 rgba(255,255,255,.18)`,
          position: 'relative', overflow: 'hidden',
        }}>
          {/* subtle diagonal highlight */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(160deg, rgba(255,255,255,.18) 0%, transparent 55%)',
          }} />
          <svg viewBox="0 0 48 48" width={s*0.7} height={s*0.7} style={{ position: 'relative' }}>
            {/* flowing S built from two arcs */}
            <path d="M34 14 Q 26 10, 20 14 Q 14 18, 20 24 Q 26 30, 20 34 Q 14 38, 10 34"
              fill="none" stroke="#fff" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>
            {/* flow arrow */}
            <path d="M30 30 L 38 30 M 35 27 L 38 30 L 35 33"
              fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" opacity=".85"/>
          </svg>
        </div>
      );
    }
    if (variant === 'tag') {
      // Work-order tag (ticket) with a check
      return (
        <div style={{
          width: s, height: s,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative',
        }}>
          <svg viewBox="0 0 64 64" width={s} height={s}>
            <defs>
              <linearGradient id="sfTagG" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor={theme.primary}/>
                <stop offset="1" stopColor={theme.primaryDark}/>
              </linearGradient>
              <filter id="sfTagShadow" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="6" stdDeviation="5" floodColor={theme.primary} floodOpacity="0.25"/>
              </filter>
            </defs>
            {/* tag body */}
            <g filter="url(#sfTagShadow)">
              <path d="M8 18 L 34 8 Q 38 6.5 41 9.5 L 57 25.5 Q 60 28.5 58.5 32.5 L 48 58 Q 46.5 62 42.5 60.5 L 13 49 Q 8 47 8 42 Z"
                fill="url(#sfTagG)"/>
            </g>
            {/* punch hole */}
            <circle cx="23" cy="23" r="4.2" fill={theme.bg}/>
            <circle cx="23" cy="23" r="2" fill={theme.primaryDark}/>
            {/* check mark */}
            <path d="M27 38 L 33 44 L 46 30"
              fill="none" stroke="#fff" strokeWidth="4.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      );
    }
    // default 'badge' — cleaner SF monogram
    return (
      <div style={{
        width: s, height: s, borderRadius: s * 0.28,
        background: `linear-gradient(145deg, ${theme.primary}, ${theme.primaryDark})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 12px 28px ${theme.primary}40, inset 0 1px 0 rgba(255,255,255,.18)`,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: 'linear-gradient(160deg, rgba(255,255,255,.2) 0%, transparent 50%)',
        }} />
        <svg viewBox="0 0 48 48" width={s*0.62} height={s*0.62} style={{ position: 'relative' }}>
          {/* S — two-stroke curve */}
          <path d="M29 13 Q 16 13, 16 20 Q 16 25, 24 25 Q 32 25, 32 30 Q 32 36, 19 36"
            fill="none" stroke="#fff" strokeWidth="4" strokeLinecap="round"/>
          {/* small dot accent */}
          <circle cx="35" cy="15" r="2.2" fill="#fff" opacity=".9"/>
        </svg>
      </div>
    );
  })();

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      flexDirection: align === 'center' ? 'column' : 'row',
      justifyContent: align === 'center' ? 'center' : 'flex-start',
    }}>
      {Mark}
      {withText && (
        <div style={{ textAlign: align === 'center' ? 'center' : 'left' }}>
          <div style={{
            fontSize: align === 'center' ? 24 : 18,
            fontWeight: 700, color: theme.text,
            letterSpacing: -0.6, lineHeight: 1.1,
          }}>
            Service<span style={{ color: theme.primary, fontWeight: 800 }}>Flow</span>
          </div>
          {align === 'center' && (
            <div style={{
              fontSize: 12, color: theme.textMuted, marginTop: 6,
              letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 500,
            }}>
              Gestão de ordens de serviço
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── CustomTextField ──────────────────────────────────────
function CustomTextField({
  theme, label, value, onChange, placeholder, type = 'text',
  icon, trailing, error, obscure, onToggleObscure, multiline, rows = 4,
  mask, autoFocus, keyboardType, onFocus,
}) {
  const [focus, setFocus] = React.useState(false);
  const applyMask = (raw) => {
    if (!mask) return raw;
    const digits = raw.replace(/\D/g, '');
    if (mask === 'cpfcnpj') {
      if (digits.length <= 11) {
        return digits
          .replace(/^(\d{3})(\d)/, '$1.$2')
          .replace(/^(\d{3})\.(\d{3})(\d)/, '$1.$2.$3')
          .replace(/\.(\d{3})(\d)/, '.$1-$2').slice(0, 14);
      }
      return digits
        .replace(/^(\d{2})(\d)/, '$1.$2')
        .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
        .replace(/\.(\d{3})(\d)/, '.$1/$2')
        .replace(/(\d{4})(\d)/, '$1-$2').slice(0, 18);
    }
    if (mask === 'phone') {
      return digits
        .replace(/^(\d{2})(\d)/, '($1) $2')
        .replace(/(\d{5})(\d)/, '$1-$2').slice(0, 15);
    }
    if (mask === 'money') {
      const cents = digits.padStart(3, '0');
      const reais = cents.slice(0, -2).replace(/^0+/, '') || '0';
      const withSep = reais.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
      return `R$ ${withSep},${cents.slice(-2)}`;
    }
    return raw;
  };
  const borderColor = error ? theme.dangerFg : (focus ? theme.primary : theme.border);
  const labelColor = error ? theme.dangerFg : (focus ? theme.primary : theme.textMuted);

  return (
    <label style={{ display: 'block', position: 'relative' }}>
      <div style={{
        fontSize: 12, fontWeight: 500, color: labelColor,
        marginBottom: 6, letterSpacing: 0.1,
      }}>{label}</div>
      <div style={{
        display: 'flex', alignItems: multiline ? 'flex-start' : 'center',
        background: theme.surface,
        border: `1.5px solid ${borderColor}`,
        borderRadius: 12,
        padding: multiline ? '10px 12px' : '0 12px',
        minHeight: multiline ? undefined : 48,
        transition: 'border-color .15s, background .15s',
      }}>
        {icon && (
          <div style={{ color: labelColor, marginRight: 10, display: 'flex', alignItems: 'center' }}>
            <Icon name={icon} size={18} />
          </div>
        )}
        {multiline ? (
          <textarea
            rows={rows}
            value={value ?? ''}
            onFocus={(e) => { setFocus(true); onFocus && onFocus(e); }}
            onBlur={() => setFocus(false)}
            onChange={(e) => onChange && onChange(applyMask(e.target.value))}
            placeholder={placeholder}
            style={{
              flex: 1, border: 'none', background: 'transparent',
              fontFamily: 'inherit', color: theme.text, fontSize: 15,
              resize: 'none', padding: 0,
            }}
          />
        ) : (
          <input
            type={obscure ? 'password' : type}
            value={value ?? ''}
            autoFocus={autoFocus}
            inputMode={keyboardType}
            onFocus={(e) => { setFocus(true); onFocus && onFocus(e); }}
            onBlur={() => setFocus(false)}
            onChange={(e) => onChange && onChange(applyMask(e.target.value))}
            placeholder={placeholder}
            style={{
              flex: 1, border: 'none', background: 'transparent',
              fontFamily: 'inherit', color: theme.text, fontSize: 15,
              height: 46,
            }}
          />
        )}
        {onToggleObscure && (
          <button type="button" onClick={onToggleObscure} className="tap" style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            padding: 6, color: theme.textMuted, display: 'flex',
          }}>
            <Icon name={obscure ? 'eye' : 'eye-off'} size={18} />
          </button>
        )}
        {trailing}
      </div>
      {error && (
        <div style={{ fontSize: 12, color: theme.dangerFg, marginTop: 6 }}>{error}</div>
      )}
    </label>
  );
}

// ─── CustomButton ────────────────────────────────────────
function CustomButton({
  theme, children, onClick, variant = 'primary', icon, loading,
  disabled, fullWidth = true, size = 'md',
}) {
  const heights = { sm: 40, md: 48, lg: 52 };
  const styles = {
    primary: {
      background: theme.primary, color: theme.onPrimary,
      border: `1.5px solid ${theme.primary}`,
      boxShadow: `0 1px 0 ${theme.primaryDark}`,
    },
    secondary: {
      background: theme.surface, color: theme.text,
      border: `1.5px solid ${theme.border}`,
    },
    ghost: {
      background: 'transparent', color: theme.primary,
      border: '1.5px solid transparent',
    },
    danger: {
      background: theme.dangerFg, color: '#fff',
      border: `1.5px solid ${theme.dangerFg}`,
    },
  };
  const s = styles[variant];
  return (
    <button
      className="tap"
      onClick={disabled || loading ? null : onClick}
      disabled={disabled || loading}
      style={{
        width: fullWidth ? '100%' : undefined,
        height: heights[size],
        borderRadius: 12,
        fontFamily: 'inherit', fontSize: 15, fontWeight: 600,
        letterSpacing: 0.1,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.5 : 1,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        gap: 8, ...s,
      }}
    >
      {loading ? (
        <div style={{
          width: 18, height: 18, borderRadius: 999,
          border: '2px solid rgba(255,255,255,.35)',
          borderTopColor: '#fff',
          animation: 'spin .8s linear infinite',
        }} />
      ) : (
        <>
          {icon && <Icon name={icon} size={18} />}
          {children}
        </>
      )}
    </button>
  );
}

// ─── Snackbar (MessagesMixin output) ──────────────────
function Snackbar({ theme, msg }) {
  if (!msg) return null;
  const palettes = {
    success: { bg: theme.successFg, fg: '#fff', icon: 'check' },
    error:   { bg: theme.dangerFg, fg: '#fff', icon: 'close' },
    info:    { bg: theme.text, fg: theme.surface, icon: 'bell' },
  };
  const p = palettes[msg.kind] || palettes.info;
  return (
    <div className="snack" style={{
      position: 'absolute', left: '50%', bottom: 36,
      transform: 'translateX(-50%)',
      background: p.bg, color: p.fg,
      borderRadius: 10, padding: '10px 14px',
      display: 'flex', alignItems: 'center', gap: 10,
      fontSize: 14, fontWeight: 500,
      boxShadow: '0 10px 24px rgba(0,0,0,.18)',
      maxWidth: 330, zIndex: 50,
    }}>
      <Icon name={p.icon} size={18} />
      {msg.text}
    </div>
  );
}

// ─── Loader overlay (LoaderMixin output) ────────────
function LoaderOverlay({ theme, show, text = 'Processando...' }) {
  if (!show) return null;
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: 'rgba(15,23,42,.55)',
      backdropFilter: 'blur(2px)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      flexDirection: 'column', gap: 14,
      zIndex: 100,
    }}>
      <div className="spinner" />
      <div style={{ color: '#fff', fontSize: 14, fontWeight: 500 }}>{text}</div>
    </div>
  );
}

// ─── Badge (OS status chip) ──────────────────────────
function Badge({ theme, status, small }) {
  const cfg = OS_STATUS[status] || { label: status, semantic: 'neutral' };
  const semMap = {
    success:  { bg: theme.successBg, fg: theme.successFg, line: theme.successLine, dot: theme.successFg },
    warning:  { bg: theme.warningBg, fg: theme.warningFg, line: theme.warningLine, dot: theme.warningFg },
    neutral:  { bg: theme.neutralBg, fg: theme.neutralFg, line: theme.neutralLine, dot: theme.neutralFg },
    danger:   { bg: theme.dangerBg,  fg: theme.dangerFg,  line: theme.dangerLine,  dot: theme.dangerFg },
  };
  const c = semMap[cfg.semantic] || semMap.neutral;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: c.bg, color: c.fg,
      border: `1px solid ${c.line}`,
      borderRadius: 999,
      padding: small ? '2px 8px' : '3px 10px',
      fontSize: small ? 11 : 12, fontWeight: 600, letterSpacing: 0.1,
      whiteSpace: 'nowrap',
    }}>
      <span style={{ width: 6, height: 6, borderRadius: 999, background: c.dot }} />
      {cfg.label}
    </span>
  );
}

// ─── Money helper ───────────────────────────────────
function fmtBRL(n) {
  return n.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

// ─── Section header ─────────────────────────────────
function SectionHeader({ theme, children, action }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '18px 20px 8px',
    }}>
      <div style={{
        fontSize: 12, fontWeight: 600, letterSpacing: 0.4,
        color: theme.textMuted, textTransform: 'uppercase',
      }}>{children}</div>
      {action}
    </div>
  );
}

// ─── FormRow wrapper ────────────────────────────────
function FormStack({ children, gap = 14 }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap }}>
      {children}
    </div>
  );
}

Object.assign(window, {
  AppLogo, CustomTextField, CustomButton, Snackbar, LoaderOverlay,
  Badge, fmtBRL, SectionHeader, FormStack,
});
