import 'package:flutter/material.dart';

/// Tema global de Turco (claro y oscuro). Los widgets leen siempre
/// Theme.of(context): nunca usan colores fijos.
class AppTheme {
  AppTheme._();

  static const Color semilla = Color(0xFF00695C);
  static const String fuente = 'Poppins';

  static const double radioTarjeta = 16;
  static const double radioControl = 12;

  static final ColorScheme _esquemaClaro = ColorScheme.fromSeed(
    seedColor: semilla,
  ).copyWith(
    primary: const Color(0xFF006A60),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFF9EF2E4),
    onPrimaryContainer: const Color(0xFF00201C),
    secondaryContainer: const Color(0xFFCCE8E2),
    onSecondaryContainer: const Color(0xFF05201C),
    tertiary: const Color(0xFF456179),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFCFE5FF),
    onTertiaryContainer: const Color(0xFF001D32),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    surface: const Color(0xFFF4FBF9),
    onSurface: const Color(0xFF161D1B),
    onSurfaceVariant: const Color(0xFF3F4946),
    surfaceContainer: const Color(0xFFE9EFED),
    surfaceContainerLow: const Color(0xFFEEF5F3),
    surfaceContainerHigh: const Color(0xFFE9EFED),
    outline: const Color(0xFF6F7977),
    outlineVariant: const Color(0xFFBEC9C5),
  );

  static final ColorScheme _esquemaOscuro = ColorScheme.fromSeed(
    seedColor: semilla,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF53DBC9),
    onPrimary: const Color(0xFF003731),
    primaryContainer: const Color(0xFF005047),
    onPrimaryContainer: const Color(0xFF9EF2E4),
    secondaryContainer: const Color(0xFF314B47),
    onSecondaryContainer: const Color(0xFFCCE8E2),
    tertiary: const Color(0xFFADCAE6),
    onTertiary: const Color(0xFF14334B),
    tertiaryContainer: const Color(0xFF2D4A63),
    onTertiaryContainer: const Color(0xFFCFE5FF),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: const Color(0xFF0E1514),
    onSurface: const Color(0xFFDDE4E1),
    onSurfaceVariant: const Color(0xFFBEC9C5),
    surfaceContainer: const Color(0xFF1A2120),
    surfaceContainerLow: const Color(0xFF161D1C),
    surfaceContainerHigh: const Color(0xFF1A2120),
    outline: const Color(0xFF899390),
    outlineVariant: const Color(0xFF3F4946),
  );

  static ThemeData get claro => _construir(_esquemaClaro);
  static ThemeData get oscuro => _construir(_esquemaOscuro);

  static ThemeData _construir(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: fuente,
      brightness: cs.brightness,
    );

    final texto = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ).apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);

    final formaControl = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radioControl),
    );

    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioControl),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return base.copyWith(
      textTheme: texto,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: texto.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: formaControl,
          minimumSize: const Size(0, 48),
          textStyle: texto.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: formaControl,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: cs.outline),
          textStyle: texto.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: formaControl,
          textStyle: texto.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: borde(cs.outline),
        enabledBorder: borde(cs.outline),
        focusedBorder: borde(cs.primary, 2),
        errorBorder: borde(cs.error),
        focusedErrorBorder: borde(cs.error, 2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: texto.bodyMedium?.copyWith(color: cs.error, fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioControl),
        ),
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: Colors.transparent,
        selectedColor: cs.secondaryContainer,
        labelStyle: texto.bodyMedium,
        checkmarkColor: cs.onSecondaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: cs.secondaryContainer,
          selectedForegroundColor: cs.onSecondaryContainer,
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          textStyle: texto.bodyMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final seleccionado = estados.contains(WidgetState.selected);
          return texto.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
            color: seleccionado ? cs.onSurface : cs.onSurfaceVariant,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: texto.titleLarge,
        contentTextStyle:
            texto.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle:
            texto.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        shape: formaControl,
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant),
    );
  }
}
