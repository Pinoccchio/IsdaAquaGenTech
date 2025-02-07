import 'package:flutter/material.dart';

String _appTheme = "primary";

/// Helper class for managing themes and colors.
class ThemeHelper {
  // A map of custom color themes supported by the app
  final Map<String, PrimaryColors> _supportedCustomColor = {
    'primary': PrimaryColors()
  };

// A map of color schemes supported by the app
  final Map<String, ColorScheme> _supportedColorScheme = {
    'primary': ColorSchemes.primaryColorScheme
  };

  /// Changes the app theme to [newTheme].
  void changeTheme(String newTheme) {
    _appTheme = newTheme;
  }

  /// Returns the primary colors for the current theme.
  PrimaryColors _getThemeColors() {
    //throw exception to notify given theme is not found or not generated by the generator
    if (!_supportedCustomColor.containsKey(_appTheme)) {
      throw Exception(
          "$_appTheme is not found.Make sure you have added this theme class in JSON Try running flutter pub run build_runner");
    }
    //return theme from map

    return _supportedCustomColor[_appTheme] ?? PrimaryColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    //throw exception to notify given theme is not found or not generated by the generator
    if (!_supportedColorScheme.containsKey(_appTheme)) {
      throw Exception(
          "$_appTheme is not found.Make sure you have added this theme class in JSON Try running flutter pub run build_runner");
    }
    //return theme from map

    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.primaryColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.onPrimary,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface;
        }),
        visualDensity: const VisualDensity(
          vertical: -4,
          horizontal: -4,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface;
        }),
        side: const BorderSide(
          width: 1,
        ),
        visualDensity: const VisualDensity(
          vertical: -4,
          horizontal: -4,
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: appTheme.gray700,
      ),
    );
  }

  /// Returns the primary colors for the current theme.
  PrimaryColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

/// Class containing the supported text theme styles.
class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
        bodyLarge: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 16,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: appTheme.gray400,
          fontSize: 14,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: appTheme.gray400,
          fontSize: 12,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w400,
        ),
        displayLarge: TextStyle(
          color: colorScheme.primary,
          fontSize: 64,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w900,
        ),
        displayMedium: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 48,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 32,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 24,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
        ),
        labelLarge: TextStyle(
          color: appTheme.gray50,
          fontSize: 12,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: appTheme.gray400,
          fontSize: 10,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 22,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: appTheme.whiteA700,
          fontSize: 18,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: colorScheme.primary,
          fontSize: 14,
          fontFamily: 'Urbanist',
          fontWeight: FontWeight.w600,
        ),
      );
}

/// Class containing the supported color schemes.
class ColorSchemes {
  static const primaryColorScheme = ColorScheme.light(
    // Primary colors
    primary: Color(0XFF1AADB6),
    primaryContainer: Color(0X8F282828),

    // Error colors
    errorContainer: Color(0XFFEB4335),
    onError: Color(0XFF919999),
    onErrorContainer: Color(0XFF0E1010),

    // On colors(text colors)
    onPrimary: Color(0XFF181A20),
    onPrimaryContainer: Color(0XFFE7E9E9),
  );
}

/// Class containing custom colors for a primary theme.
class PrimaryColors {
  // Blackc
  Color get black9000c => const Color(0X0C04060F);
  Color get realBlack => const Color(0xFF000000);

  Color get blueGray9007c => const Color(0X59353535);

  // Blue
  Color get blueA400 => const Color(0XFF1877F2);

  // BlueGray
  Color get blueGray100 => const Color(0XFFC8CCCC);
  Color get blueGray900 => const Color(0XFF31343B);
  Color get blueGray90059 => const Color(0X59353535);
  Color get blueGray90076 => const Color(0X762E2E2E);
  Color get blueGray400 => const Color(0XFF53565B);
  Color get gray500 => const Color(0XFFA3A2A7);
  Color get gray300 => const Color(0XFFE3E3E5);

  // Cyan
  Color get cyan200 => const Color(0XFF7BE6EC);
  Color get cyan300 => const Color(0XFF46DBE5);
  Color get cyan500 => const Color(0XFF00BCD3);
  Color get cyan600 => const Color(0XFF00BCD3);
  Color get cyan900 => const Color(0XFF0F656A);

  // Gray
  Color get gray400 => const Color(0XFFB8BDBD);
  Color get gray40001 => const Color(0XFFB0B6B6);
  Color get gray50 => const Color(0XFFFBFBFB);
  Color get gray5001 => const Color(0XFFF7FCFF);
  Color get gray700 => const Color(0XFF646D6D);
  Color get gray80000 => const Color(0X004B4B4B);
  Color get gray80046 => const Color(0X463A3A3A);
  Color get gray900 => const Color(0XFF1F1F1F);
  Color get gray800 => const Color(0XFF35383F);

  // Grayd
  Color get gray8001d => const Color(0X1D444444);
  Color get gray8002d => const Color(0X2D404040);

  // Green
  Color get green60019 => const Color(0X19359766);
  Color get green600 => const Color(0XFF359766);

  // GreenAf
  Color get greenA7003f => const Color(0X3F1AB65C);

  // Indigo
  Color get indigoA20014 => const Color(0X145A6CEA);

  // LightBlue
  Color get lightBlue600 => const Color(0XFF009CDE);

  // Red
  Color get red400 => const Color(0XFFEA5B52);
  Color get red40019 => const Color(0X19C65454);

  // Teal
  Color get teal900 => const Color(0XFF093A3D);

  // White
  Color get whiteA700 => const Color(0XFFFFFFFF);

  // Yellow
  Color get yellowA700 => const Color(0XFFFFD300);
}

PrimaryColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();
