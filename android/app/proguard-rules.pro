# =============================================================================
# ServiceFlow — regras ProGuard/R8 para o build de release.
#
# Estratégia: manter mínimo necessário pro Flutter + plugins funcionarem
# após shrink/obfuscação. Tudo que não estiver explicitamente preservado
# pode ser renomeado/eliminado pelo R8.
# =============================================================================

# ---- Flutter / Dart core ---------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Plugins usados (sqflite, image_picker, signature, secure_storage, ...)
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keepattributes *Annotation*, EnclosingMethod, Signature, InnerClasses

# Reflection do supabase_flutter / gotrue (chamadas Kotlin coroutines)
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Dio + http
-dontwarn okhttp3.**
-dontwarn okio.**

# OkHttp / OkIO usado por dependências transitivas (image_picker, etc)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ---- Logs: remove TODOS os Log.* / println / debugPrint em release -----------
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ---- Não logar mensagens internas de exceções ------------------------------
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
