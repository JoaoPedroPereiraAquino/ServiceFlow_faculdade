/// Configuração estática do Supabase do projeto **ServiceFlow**.
///
/// Os valores aqui são **públicos** (anon/publishable). Toda a segurança
/// real é garantida pelas políticas RLS do banco — cada usuário só
/// enxerga as próprias linhas (auth.uid() = user_id).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://rccmmsdxueijgoalqnwr.supabase.co';

  static const String publishableKey =
      'sb_publishable_YIQh099eo0qxmkg5BGZWBQ_L2Ublj3W';
}
