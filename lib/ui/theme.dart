import 'package:flutter/material.dart';

/// Medica UI Kit 디자인 시스템의 토큰. 이름은 피그마 변수명을 그대로 따른다.
///
/// 원본의 Primary(#246BFD 파랑)는 쓰지 않고, 주 색을 무채색으로 바꿨다.
/// 라이트에서는 Greyscale 900, 다크에서는 흰색이 주 색 역할을 한다.
abstract final class Palette {
  static const grey900 = Color(0xFF212121);
  static const grey800 = Color(0xFF424242);
  static const grey700 = Color(0xFF616161);
  static const grey600 = Color(0xFF757575);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey50 = Color(0xFFFAFAFA);

  static const dark1 = Color(0xFF181A20);
  static const dark2 = Color(0xFF1F222A);
  static const dark3 = Color(0xFF35383F);

  static const white = Color(0xFFFFFFFF);
  static const error = Color(0xFFF75555);
  static const errorBackground = Color(0xFFFFF5F5);
  static const success = Color(0xFF07BD74);
}

/// 앱 전체 테마. 라이트/다크 모두 같은 토큰에서 만들어 톤을 맞춘다.
class AppTheme {
  AppTheme._();

  /// 영문·숫자는 Urbanist, 한글은 이 서체에 글리프가 없어 시스템 서체로 폴백된다.
  static const String fontFamily = 'Urbanist';

  /// [fontFallback] 은 글리프 단위 시스템 폴백이 없는 테스트 환경에서 한글 폰트를 걸 때 쓴다.
  static ThemeData light({List<String>? fontFallback}) =>
      _build(_lightScheme, fontFallback);
  static ThemeData dark({List<String>? fontFallback}) =>
      _build(_darkScheme, fontFallback);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.grey900,
    onPrimary: Palette.white,
    primaryContainer: Palette.grey100,
    onPrimaryContainer: Palette.grey900,
    secondary: Palette.grey700,
    onSecondary: Palette.white,
    secondaryContainer: Palette.grey100,
    onSecondaryContainer: Palette.grey900,
    tertiary: Palette.grey800,
    onTertiary: Palette.white,
    error: Palette.error,
    onError: Palette.white,
    errorContainer: Palette.errorBackground,
    onErrorContainer: Palette.error,
    surface: Palette.white,
    onSurface: Palette.grey900,
    onSurfaceVariant: Palette.grey600,
    surfaceContainerLowest: Palette.white,
    surfaceContainerLow: Palette.grey50,
    surfaceContainer: Palette.grey50,
    surfaceContainerHigh: Palette.grey100,
    surfaceContainerHighest: Palette.grey100,
    outline: Palette.grey400,
    outlineVariant: Palette.grey200,
    inverseSurface: Palette.grey900,
    onInverseSurface: Palette.white,
    inversePrimary: Palette.white,
    shadow: Color(0xFF04060F),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Palette.white,
    onPrimary: Palette.grey900,
    primaryContainer: Palette.dark3,
    onPrimaryContainer: Palette.white,
    secondary: Palette.grey400,
    onSecondary: Palette.grey900,
    secondaryContainer: Palette.dark3,
    onSecondaryContainer: Palette.white,
    tertiary: Palette.grey300,
    onTertiary: Palette.grey900,
    error: Palette.error,
    onError: Palette.white,
    errorContainer: Color(0x14F75555),
    onErrorContainer: Palette.error,
    surface: Palette.dark1,
    onSurface: Palette.white,
    onSurfaceVariant: Palette.grey500,
    surfaceContainerLowest: Palette.dark1,
    surfaceContainerLow: Palette.dark2,
    surfaceContainer: Palette.dark2,
    surfaceContainerHigh: Palette.dark2,
    surfaceContainerHighest: Palette.dark3,
    outline: Palette.grey700,
    outlineVariant: Palette.dark3,
    inverseSurface: Palette.white,
    onInverseSurface: Palette.grey900,
    inversePrimary: Palette.grey900,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  /// 피그마 타이포그래피 스타일(H3~H6, body xlarge~xsmall)을 Material 슬롯에 대응시킨다.
  /// 제목은 행간 1.2·자간 0, 본문은 행간 1.4·자간 0.2 가 디자인 시스템 규칙이다.
  static TextTheme _textTheme(Color onSurface, List<String>? fontFallback) {
    TextStyle heading(double size) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0,
      color: onSurface,
    );
    TextStyle body(double size, FontWeight weight) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      fontWeight: weight,
      height: 1.4,
      letterSpacing: 0.2,
      color: onSurface,
    );

    return TextTheme(
      displayLarge: heading(48), // H1
      displayMedium: heading(40), // H2
      displaySmall: heading(32), // H3
      headlineLarge: heading(32), // H3
      headlineMedium: heading(20), // H5 (앱바 제목)
      headlineSmall: heading(18), // H6
      titleLarge: heading(18), // H6
      titleMedium: body(15, FontWeight.w600),
      titleSmall: body(14, FontWeight.w600), // body medium semibold
      bodyLarge: body(15, FontWeight.w400),
      bodyMedium: body(14, FontWeight.w400), // body medium regular
      bodySmall: body(12, FontWeight.w400), // body small regular
      labelLarge: body(14, FontWeight.w700), // 버튼
      labelMedium: body(12, FontWeight.w500), // body small medium
      labelSmall: body(10, FontWeight.w500), // body xsmall medium
    );
  }

  static ThemeData _build(ColorScheme scheme, List<String>? fontFallback) {
    final isDark = scheme.brightness == Brightness.dark;
    // 컴포넌트 테마의 글자 스타일도 모두 여기서 파생되므로 서체가 한 곳에서 정해진다.
    final textTheme = _textTheme(scheme.onSurface, fontFallback);

    // 버튼·칩·탭 모두 피그마에서 rounded-[100px] 인 알약 모양이다.
    const pill = StadiumBorder();
    final disabledFill = isDark ? Palette.dark3 : Palette.grey300;
    final disabledText = isDark ? Palette.grey600 : Palette.grey500;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      // 키트는 428pt 화면 기준이라 그대로 쓰면 크다. 전체를 한 단계 촘촘하게 쓴다.
      visualDensity: VisualDensity.compact,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        titleTextStyle: textTheme.headlineMedium,
      ),
      // 라이트는 흰 바탕 위에 Greyscale 200 테두리로 구분하고,
      // 다크는 Dark 2 면이 Dark 1 바탕과 대비되므로 테두리를 두지 않는다.
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? Palette.dark2 : Palette.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide.none
              : const BorderSide(color: Palette.grey200),
        ),
      ),
      // Input Field: 채움만 있고 테두리 없음, 활성 상태에서만 주 색 테두리.
      // 키트의 높이 60 은 크게 느껴져 48 로 줄였다.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: isDark ? Palette.dark2 : Palette.grey100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: Palette.grey500),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? scheme.primary
              : Palette.grey500,
        ),
        suffixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? scheme.primary
              : Palette.grey500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Palette.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: pill,
          textStyle: textTheme.labelLarge,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: pill,
          side: BorderSide(color: scheme.primary, width: 1.5),
          textStyle: textTheme.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: pill,
          textStyle: textTheme.titleSmall,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: pill,
          side: BorderSide(color: scheme.primary, width: 1.5),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          foregroundColor: scheme.primary,
          textStyle: textTheme.titleSmall,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide(color: scheme.primary, width: 1.5),
        labelStyle: textTheme.titleSmall,
        selectedColor: scheme.primary,
        secondaryLabelStyle: textTheme.titleSmall?.copyWith(
          color: scheme.onPrimary,
        ),
        checkmarkColor: scheme.onPrimary,
      ),
      // Toggle: 켜짐은 주 색 트랙, 꺼짐은 Greyscale 200 트랙. 손잡이는 항상 흰색.
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Palette.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? Palette.grey600 : scheme.primary)
              : (isDark ? Palette.dark3 : Palette.grey200),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Palette.grey500,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Palette.dark3 : Palette.grey200,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isDark ? Palette.dark3 : Palette.grey200,
        circularTrackColor: Colors.transparent,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: Palette.error,
        textColor: Palette.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: isDark ? Palette.dark3 : Palette.grey300,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.headlineMedium,
      ),
      // Bottom Bars: 인디케이터 없이 아이콘·라벨 색으로만 선택을 표시한다.
      // 선택은 주 색 + bold, 비선택은 Greyscale 500 + medium, 라벨 10px.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 56,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                )
              : textTheme.labelSmall?.copyWith(color: Palette.grey500),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : Palette.grey500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 24),
        unselectedIconTheme: const IconThemeData(
          color: Palette.grey500,
          size: 24,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: Palette.grey500,
        ),
      ),
    );
  }
}
