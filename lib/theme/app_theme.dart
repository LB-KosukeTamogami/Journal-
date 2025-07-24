import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// セマンティックカラーを管理するクラス
class AppColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color surface;
  final Color background;
  final Color surfaceVariant;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color successContainer;
  final Color warningContainer;
  final Color errorContainer;
  final Color infoContainer;
  final Color onSuccess;
  final Color onWarning;
  final Color onError;
  final Color onInfo;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.background,
    required this.surfaceVariant,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.successContainer,
    required this.warningContainer,
    required this.errorContainer,
    required this.infoContainer,
    required this.onSuccess,
    required this.onWarning,
    required this.onError,
    required this.onInfo,
  });
}

class AppTheme {
  // Light Theme Colors
  static const AppColors lightColors = AppColors(
    // Brand Colors - Squirrel Theme
    primary: Color(0xFF8B6D47),        // リスの毛色（ウォームブラウン）
    secondary: Color(0xFF6B8E7F),      // 森の緑（ソフトグリーン）
    accent: Color(0xFF4A3728),         // ダークブラウン（木の幹）
    
    // Surface Colors
    surface: Color(0xFFFFFFFF),        // カード背景
    background: Color(0xFFF5F5F5),     // メイン背景（薄いグレー）
    surfaceVariant: Color(0xFFF8F6F3), // セクション区切り（薄いベージュ）
    
    // On Colors
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2C2C2C),
    onBackground: Color(0xFF2C2C2C),
    
    // Text Colors
    textPrimary: Color(0xFF2C2C2C),
    textSecondary: Color(0xFF6B6B6B),
    textTertiary: Color(0xFF9B9B9B),
    
    // Border & Divider
    border: Color(0xFFD4C4B0),  // 薄茶色のボーダー
    divider: Color(0xFFD4C4B0),  // 薄茶色のボーダー
    
    // Semantic Colors
    success: Color(0xFF7CB342),        // フレッシュグリーン
    warning: Color(0xFFFFB74D),        // どんぐりオレンジ
    error: Color(0xFFE57373),          // ソフトレッド
    info: Color(0xFF64B5F6),           // スカイブルー
    
    // Semantic Container Colors
    successContainer: Color(0xFFE8F5E9),
    warningContainer: Color(0xFFFFF8E1),
    errorContainer: Color(0xFFFFEBEE),
    infoContainer: Color(0xFFE3F2FD),
    
    // On Semantic Colors
    onSuccess: Color(0xFFFFFFFF),
    onWarning: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    onInfo: Color(0xFFFFFFFF),
  );

  // Dark Theme Colors (Duolingo-inspired soft dark theme)
  static const AppColors darkColors = AppColors(
    // Brand Colors - Adjusted for dark theme
    primary: Color(0xFFB8A080),        // 明るめのウォームブラウン
    secondary: Color(0xFF8FA89E),      // 明るめの森の緑
    accent: Color(0xFF6B5443),         // 明るめのブラウン
    
    // Surface Colors - Not pure black
    surface: Color(0xFF2B2B2B),        // カード背景（ソフトダーク）
    background: Color(0xFF1F1F1F),     // メイン背景（ソフトブラック）
    surfaceVariant: Color(0xFF363636), // セクション区切り
    
    // On Colors
    onPrimary: Color(0xFF2C2C2C),
    onSecondary: Color(0xFF2C2C2C),
    onSurface: Color(0xFFF5F5F5),
    onBackground: Color(0xFFF5F5F5),
    
    // Text Colors
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFBDBDBD),
    textTertiary: Color(0xFF8C8C8C),
    
    // Border & Divider
    border: Color(0xFF5C4A3A),  // ダークモード用の茶色ボーダー
    divider: Color(0xFF5C4A3A),  // ダークモード用の茶色ボーダー
    
    // Semantic Colors - Adjusted for dark theme
    success: Color(0xFF9CCC65),        // 明るめのグリーン
    warning: Color(0xFFFFCA28),        // 明るめのオレンジ
    error: Color(0xFFEF5350),          // 明るめのレッド
    info: Color(0xFF90CAF9),           // 明るめのブルー
    
    // Semantic Container Colors
    successContainer: Color(0xFF2E7D32),
    warningContainer: Color(0xFFF57C00),
    errorContainer: Color(0xFFC62828),
    infoContainer: Color(0xFF1565C0),
    
    // On Semantic Colors
    onSuccess: Color(0xFF000000),
    onWarning: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    onInfo: Color(0xFF000000),
  );

  // Current theme colors (will be set based on brightness)
  static AppColors colors = lightColors;
  
  // Legacy color references (for backward compatibility)
  static Color get primaryColor => colors.primary;
  static Color get secondaryColor => colors.secondary;
  static Color get accentColor => colors.accent;
  static Color get primaryBlue => colors.secondary;
  static Color get primaryBlueLight => const Color(0xFF5A8EB0);
  static Color get primaryBlueDark => const Color(0xFF34627F);
  static Color get textPrimary => colors.textPrimary;
  static Color get textSecondary => colors.textSecondary;
  static Color get textTertiary => colors.textTertiary;
  static Color get backgroundPrimary => colors.surface;
  static Color get backgroundSecondary => colors.background;
  static Color get backgroundTertiary => colors.surfaceVariant;
  static Color get success => colors.success;
  static Color get warning => colors.warning;
  static Color get error => colors.error;
  static Color get info => colors.info;
  static Color get borderColor => lightColors.border;  // Deprecated - use Theme.of(context).dividerColor
  static Color get dividerColor => lightColors.divider;  // Deprecated - use Theme.of(context).dividerColor
  
  // Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),  // より濃いシャドウ
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),  // より濃いシャドウ
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> buttonShadow(Color primaryColor) => [
    BoxShadow(
      color: primaryColor.withOpacity(0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Text Styles - These will use the current theme colors
  static TextStyle get headline1 => GoogleFonts.notoSansJp(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  static TextStyle get headline2 => GoogleFonts.notoSansJp(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle get headline3 => GoogleFonts.notoSansJp(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle get body1 => GoogleFonts.notoSansJp(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get body2 => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get caption => GoogleFonts.notoSansJp(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static TextStyle get button => GoogleFonts.notoSansJp(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1,
  );
  
  // Helper function to get colors based on brightness
  static AppColors getColors(Brightness brightness) {
    return brightness == Brightness.light ? lightColors : darkColors;
  }

  // Theme Data
  static ThemeData getTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final themeColors = isLight ? lightColors : darkColors;
    colors = themeColors; // Update static variable for legacy support
    
    return ThemeData(
      brightness: brightness,
      primaryColor: themeColors.primary,
      scaffoldBackgroundColor: themeColors.background,
      
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: themeColors.primary,
        onPrimary: themeColors.onPrimary,
        secondary: themeColors.secondary,
        onSecondary: themeColors.onSecondary,
        error: themeColors.error,
        onError: themeColors.onError,
        background: themeColors.background,
        onBackground: themeColors.onBackground,
        surface: themeColors.surface,
        onSurface: themeColors.onSurface,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.notoSansJp(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: themeColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.notoSansJp(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
          height: 1.3,
        ),
        displaySmall: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
          height: 1.3,
        ),
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: themeColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.notoSansJp(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: themeColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: themeColors.textTertiary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.notoSansJp(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
          height: 1,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.surface,
        surfaceTintColor: Colors.transparent, // Material 3のtintを無効化
        elevation: 0.5, // 軽微な影を追加
        shadowColor: themeColors.border.withOpacity(0.3),
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: themeColors.textPrimary,
          height: 1.3,
        ),
        iconTheme: IconThemeData(color: themeColors.textPrimary),
        actionsIconTheme: IconThemeData(color: themeColors.textSecondary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColors.primary,
          foregroundColor: themeColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: button,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: themeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: body2.copyWith(color: themeColors.textTertiary),
      ),
      
      dividerTheme: DividerThemeData(
        color: themeColors.divider,
        thickness: 1,
        space: 0,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: themeColors.surface,
        selectedItemColor: themeColors.primary,
        unselectedItemColor: themeColors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
  
  static ThemeData get lightTheme => getTheme(Brightness.light);
  static ThemeData get darkTheme => getTheme(Brightness.dark);
}

// カスタムウィジェット
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        boxShadow: AppTheme.buttonShadow(Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: AppTheme.button),
                ],
              ),
      ),
    );
  }
}

// セカンダリボタンコンポーネント
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        boxShadow: AppTheme.buttonShadow(Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTheme.button.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
      ),
    );
  }
}

// 統一されたElevatedButtonスタイル関数
class AppButtonStyles {
  // プライマリボタンスタイル
  static ButtonStyle primaryButton(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: AppTheme.button,
  );

  // セカンダリボタンスタイル  
  static ButtonStyle secondaryButton(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: Theme.of(context).primaryColor,
    side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: AppTheme.button.copyWith(color: Theme.of(context).primaryColor),
  );

  // 小さいボタンスタイル（modal内等で使用）
  static ButtonStyle smallButton(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    minimumSize: const Size(0, 44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: AppTheme.button.copyWith(fontSize: 14),
  );

  // モーダル専用プライマリボタンスタイル（不透明な背景）
  static ButtonStyle modalPrimaryButton(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: AppTheme.button,
  );

  // モーダル専用セカンダリボタンスタイル（不透明な白い背景）
  static ButtonStyle modalSecondaryButton(BuildContext context) => OutlinedButton.styleFrom(
    backgroundColor: Theme.of(context).cardColor,
    foregroundColor: Theme.of(context).primaryColor,
    side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: AppTheme.button.copyWith(color: Theme.of(context).primaryColor),
  );

  // モーダル専用エラーボタンスタイル（不透明な白い背景）
  static ButtonStyle modalErrorButton(BuildContext context) => OutlinedButton.styleFrom(
    backgroundColor: Theme.of(context).cardColor,
    foregroundColor: Theme.of(context).colorScheme.error,
    side: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: AppTheme.button.copyWith(color: Theme.of(context).colorScheme.error),
  );

  // モーダル専用成功ボタンスタイル（不透明な背景）
  static ButtonStyle modalSuccessButton(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF7CB342),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    textStyle: AppTheme.button,
  );

  // 影付きコンテナでボタンをラップするヘルパー
  static Widget withShadow(Widget button, Color primaryColor, {bool removeShadowFor56px = true}) {
    if (removeShadowFor56px && button is ElevatedButton) {
      return button;
    }
    if (removeShadowFor56px && button is OutlinedButton) {
      return button;
    }
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.buttonShadow(primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: button,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}