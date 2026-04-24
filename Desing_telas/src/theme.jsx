// Theme tokens — Theme.of(context) equivalent.
// Exposes getTheme(mode, accent) returning design tokens used by all screens.

const ACCENT_PRESETS = {
  blue:    { primary: '#0B4F8A', primaryDark: '#083F70', primaryInk: '#062F53', tint: '#E8F0F7' },
  teal:    { primary: '#0F766E', primaryDark: '#0B5E58', primaryInk: '#083F3C', tint: '#E6F2F1' },
  indigo:  { primary: '#3730A3', primaryDark: '#2C2683', primaryInk: '#1E1A5E', tint: '#EAE9F5' },
  slate:   { primary: '#334155', primaryDark: '#263040', primaryInk: '#1a2230', tint: '#EEF2F6' },
};

function getTheme(mode = 'light', accentKey = 'teal') {
  const accent = ACCENT_PRESETS[accentKey] || ACCENT_PRESETS.teal;
  if (mode === 'dark') {
    return {
      mode: 'dark',
      accentKey,
      bg:           '#0B1220',
      surface:      '#121A2B',
      surfaceAlt:   '#1A2338',
      border:       '#253250',
      borderSoft:   '#1C2740',
      text:         '#E6EDF7',
      textMuted:    '#8B98B4',
      textFaint:    '#5A6785',
      primary:      accent.primary,
      primaryDark:  accent.primaryDark,
      primaryInk:   accent.primaryInk,
      tint:         '#102826',
      onPrimary:    '#FFFFFF',
      // Semantic
      successBg:  '#052E2B', successFg: '#34D399', successLine: '#0F5E55',
      warningBg:  '#2C2008', warningFg: '#F5B544', warningLine: '#5B4312',
      dangerBg:   '#2A0E12', dangerFg:  '#F87171', dangerLine:  '#5A1E25',
      neutralBg:  '#1C2740', neutralFg: '#9CA7C2', neutralLine: '#2A3555',
      shadow: '0 8px 22px rgba(0,0,0,.45)',
      statusBarIcons: '#E6EDF7',
      statusBarBg: '#0B1220',
    };
  }
  return {
    mode: 'light',
    accentKey,
    bg:          '#F4F6FA',
    surface:     '#FFFFFF',
    surfaceAlt:  '#F8FAFC',
    border:      '#E3E8EF',
    borderSoft:  '#EEF2F6',
    text:        '#0F172A',
    textMuted:   '#64748B',
    textFaint:   '#94A3B8',
    primary:     accent.primary,
    primaryDark: accent.primaryDark,
    primaryInk:  accent.primaryInk,
    tint:        accent.tint,
    onPrimary:   '#FFFFFF',
    // Semantic
    successBg:  '#ECFDF5', successFg: '#047857', successLine: '#A7F3D0',
    warningBg:  '#FEF6E4', warningFg: '#B25C0B', warningLine: '#FCD9A3',
    dangerBg:   '#FEF2F2', dangerFg:  '#B91C1C', dangerLine:  '#FECACA',
    neutralBg:  '#F1F5F9', neutralFg: '#475569', neutralLine: '#E2E8F0',
    shadow: '0 8px 22px rgba(15,23,42,.06)',
    statusBarIcons: '#0F172A',
    statusBarBg: '#FFFFFF',
  };
}

// Status tokens for OS
const OS_STATUS = {
  aberto:    { label: 'Em aberto',     semantic: 'neutral' },
  execucao:  { label: 'Em execução',   semantic: 'warning' },
  executada: { label: 'Executada',     semantic: 'success' },
};

Object.assign(window, { getTheme, ACCENT_PRESETS, OS_STATUS });
