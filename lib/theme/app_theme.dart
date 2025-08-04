import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // カラーパレット
  static const Color primaryColor = Color(0xFF8B6F47); // ブラウン
  static const Color secondaryColor = Color(0xFF4A90E2); // ブルー
  static const Color accentColor = Color(0xFFFF6B6B); // レッド
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color infoColor = Color(0xFF3498DB);
  
  // Additional colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color error = errorColor;
  static const Color success = successColor;
  static const Color warning = warningColor;
  static const Color info = infoColor;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color backgroundTertiary = Color(0xFFF9F9F9);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color backgroundPrimary = Color(0xFFFAF9F7);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFAFAFA);

  // テキストスタイル
  static TextStyle get display1 => GoogleFonts.notoSans(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle get display2 => GoogleFonts.notoSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle get display3 => GoogleFonts.notoSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get heading1 => GoogleFonts.notoSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get heading2 => GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static TextStyle get body1 => GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get body2 => GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  // Legacy style names for compatibility
  static TextStyle get headline1 => heading1;
  static TextStyle get headline3 => display3;
  static TextStyle get headline2 => display2;
  
  // Helper methods
  static List<BoxShadow> buttonShadow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static TextStyle get button => GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ライトテーマカラー
  static const AppColors lightColors = AppColors(
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    surface: surfaceColor,
    onSurface: Color(0xFF1A1A1A),
    background: backgroundColor,
    onBackground: Color(0xFF1A1A1A),
    error: errorColor,
    onError: Colors.white,
    success: successColor,
    warning: warningColor,
    info: infoColor,
    surfaceVariant: Color(0xFFF0F0F0),
    outline: Color(0xFFE0E0E0),
  );

  // ダークテーマカラー
  static const AppColors darkColors = AppColors(
    primary: Color(0xFFB8956B),
    onPrimary: Color(0xFF1A1A1A),
    secondary: Color(0xFF5BA3F5),
    onSecondary: Color(0xFF1A1A1A),
    surface: Color(0xFF2C2C2C),
    onSurface: Color(0xFFF5F5F5),
    background: Color(0xFF1A1A1A),
    onBackground: Color(0xFFF5F5F5),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF1A1A1A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    surfaceVariant: Color(0xFF3C3C3C),
    outline: Color(0xFF404040),
  );

  // ライトテーマ
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightColors.primary,
      scaffoldBackgroundColor: lightColors.background,
      colorScheme: ColorScheme.light(
        primary: lightColors.primary,
        onPrimary: lightColors.onPrimary,
        secondary: lightColors.secondary,
        onSecondary: lightColors.onSecondary,
        surface: lightColors.surface,
        onSurface: lightColors.onSurface,
        background: lightColors.background,
        onBackground: lightColors.onBackground,
        error: lightColors.error,
        onError: lightColors.onError,
      ),
      textTheme: TextTheme(
        displayLarge: display1.copyWith(color: lightColors.onBackground),
        displayMedium: display2.copyWith(color: lightColors.onBackground),
        displaySmall: display3.copyWith(color: lightColors.onBackground),
        headlineLarge: heading1.copyWith(color: lightColors.onBackground),
        headlineMedium: heading2.copyWith(color: lightColors.onBackground),
        bodyLarge: body1.copyWith(color: lightColors.onBackground),
        bodyMedium: body2.copyWith(color: lightColors.onBackground.withOpacity(0.8)),
        bodySmall: caption.copyWith(color: lightColors.onBackground.withOpacity(0.6)),
        labelLarge: button.copyWith(color: lightColors.onPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors.surface,
        foregroundColor: lightColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading1.copyWith(color: lightColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors.primary,
          foregroundColor: lightColors.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColors.primary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: lightColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: lightColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColors.surface,
        selectedItemColor: lightColors.primary,
        unselectedItemColor: lightColors.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: lightColors.outline,
        thickness: 1,
      ),
    );
  }

  // ダークテーマ
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkColors.primary,
      scaffoldBackgroundColor: darkColors.background,
      colorScheme: ColorScheme.dark(
        primary: darkColors.primary,
        onPrimary: darkColors.onPrimary,
        secondary: darkColors.secondary,
        onSecondary: darkColors.onSecondary,
        surface: darkColors.surface,
        onSurface: darkColors.onSurface,
        background: darkColors.background,
        onBackground: darkColors.onBackground,
        error: darkColors.error,
        onError: darkColors.onError,
      ),
      textTheme: TextTheme(
        displayLarge: display1.copyWith(color: darkColors.onBackground),
        displayMedium: display2.copyWith(color: darkColors.onBackground),
        displaySmall: display3.copyWith(color: darkColors.onBackground),
        headlineLarge: heading1.copyWith(color: darkColors.onBackground),
        headlineMedium: heading2.copyWith(color: darkColors.onBackground),
        bodyLarge: body1.copyWith(color: darkColors.onBackground),
        bodyMedium: body2.copyWith(color: darkColors.onBackground.withOpacity(0.8)),
        bodySmall: caption.copyWith(color: darkColors.onBackground.withOpacity(0.6)),
        labelLarge: button.copyWith(color: darkColors.onPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors.surface,
        foregroundColor: darkColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading1.copyWith(color: darkColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors.primary,
          foregroundColor: darkColors.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColors.primary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: darkColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: darkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkColors.outline),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColors.surface,
        selectedItemColor: darkColors.primary,
        unselectedItemColor: darkColors.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: darkColors.outline,
        thickness: 1,
      ),
    );
  }
}

// カラー定義用クラス
class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;
  final Color info;
  final Color surfaceVariant;
  final Color outline;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.info,
    required this.surfaceVariant,
    required this.outline,
  });
}

// カスタムウィジェット用のスタイル
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: backgroundColor ?? theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      elevation: theme.brightness == Brightness.light ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: theme.brightness == Brightness.dark
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.grey,
                    width: 1,
                  ),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

class AppButtonStyles {
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
    );
  }
  
  static ButtonStyle secondaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      elevation: 0,
    );
  }
  
  static ButtonStyle textButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
  
  static ButtonStyle smallButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: const Size(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  static ButtonStyle modalPrimaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  static ButtonStyle modalSecondaryButton(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
  
  static Widget withShadow(Widget button) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: button,
    );
  }
}