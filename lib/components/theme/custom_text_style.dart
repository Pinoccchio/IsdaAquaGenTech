import 'package:flutter/material.dart';
import 'package:isda_aqua_gentech/components/theme/theme_helper.dart';

/// A collection of pre-defined text styles for customizing text appearance,
/// categorized by different font families and weights.
/// Additionally, this class includes extensions on [TextStyle] to easily apply specific font families to text.

class CustomTextStyles {
  // Body text style
  static get titleMediumWhiteA700 => theme.textTheme.titleMedium!.copyWith(
    color: appTheme.whiteA700,
    fontWeight: FontWeight.w700,
  );
  static get titleSmallPrimary => theme.textTheme.titleSmall!.copyWith(
    color: theme.colorScheme.primary,
  );
  static get titleMediumWhiteA700_1 => theme.textTheme.titleMedium!.copyWith(
    color: appTheme.whiteA700,
  );
  static get bodyLarge18 => theme.textTheme.bodyLarge!.copyWith(
        fontSize: 18,
      );
  static get bodyLargeGray40001 => theme.textTheme.bodyLarge!.copyWith(
        color: appTheme.gray40001,
      );
  static get bodyLargePrimary => theme.textTheme.bodyLarge!.copyWith(
        color: theme.colorScheme.primary,
      );
  static get bodyMediumBluegray100 => theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.blueGray100,
      );
  static get bodyMediumGray40001 => theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray40001,
      );
  static get bodyMediumGray50 => theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray50,
      );
  static get bodyMediumGray50_1 => theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.gray50,
      );
  static get bodyMediumOnError => theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onError,
      );
  static get bodyMediumWhiteA700 => theme.textTheme.bodyMedium!.copyWith(
        color: appTheme.whiteA700,
      );
  static get bodySmall10 => theme.textTheme.bodySmall!.copyWith(
        fontSize: 10,
      );
  static get bodySmall_1 => theme.textTheme.bodySmall!;
  // Headline text style
  static get headlineLargePrimary => theme.textTheme.headlineLarge!.copyWith(
        color: theme.colorScheme.primary,
      );
  static get headlineSmallPrimary => theme.textTheme.headlineSmall!.copyWith(
        color: theme.colorScheme.primary,
      );
  // Label text style
  static get labelLargeGray400 => theme.textTheme.labelLarge!.copyWith(
    color: appTheme.gray400,
  );
  static get labelLargeGray40001 => theme.textTheme.labelLarge!.copyWith(
        color: appTheme.gray40001,
      );
  static get titleSmallBluegray400 => theme.textTheme.titleSmall!.copyWith(
    color: appTheme.blueGray400,
  );
  static get labelMediumGray500 => theme.textTheme.labelMedium!.copyWith(
    color: appTheme.gray500,
    fontWeight: FontWeight.w500,
  );
  static get titleSmallOnPrimaryContainer =>
      theme.textTheme.titleSmall!.copyWith(
        color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
      );
  static get labelLargeBluegray9007c => theme.textTheme.labelLarge!.copyWith(
    color: appTheme.blueGray9007c,
  );
  static get titleMediumBluegray400 => theme.textTheme.titleMedium!.copyWith(
    color: appTheme.blueGray400,
    fontWeight: FontWeight.w500,
  );
  static get labelMediumBluegray100 => theme.textTheme.labelMedium!.copyWith(
        color: appTheme.blueGray100,
      );
  static get labelMediumCyan200 => theme.textTheme.labelMedium!.copyWith(
        color: appTheme.cyan200,
      );
  static get labelMediumCyan300 => theme.textTheme.labelMedium!.copyWith(
        color: appTheme.cyan300,
        fontWeight: FontWeight.w600,
      );
  static get labelMediumPrimary => theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      );
  static get labelMediumPrimaryBold => theme.textTheme.labelMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      );
  static get labelMediumRed400 => theme.textTheme.labelMedium!.copyWith(
        color: appTheme.red400,
        fontWeight: FontWeight.w600,
      );
  static get labelMediumRed400_1 => theme.textTheme.labelMedium!.copyWith(
        color: appTheme.red400,
      );
  // Title text style
  static get titleLarge20 => theme.textTheme.titleLarge!.copyWith(
        fontSize: 20,
      );
  static get titleMedium18 => theme.textTheme.titleMedium!.copyWith(
    fontSize: 18,
  );
  static get titleLargePrimary => theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 20,
      );
  static get titleLargeSemiBold => theme.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static TextStyle titleMedium16 = theme.textTheme.titleMedium!.copyWith(
    fontSize: 16,
    color: Colors.white,
  );
  static get titleMediumGray40001 => theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray40001,
        fontWeight: FontWeight.w500,
      );
  static get titleMediumGray50 => theme.textTheme.titleMedium!.copyWith(
        color: appTheme.gray50,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumOnPrimaryContainer =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onPrimaryContainer,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumPrimary => theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumPrimary16 => theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 16,
      );
  static get titleMediumPrimarySemiBold =>
      theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumRed400 => theme.textTheme.titleMedium!.copyWith(
        color: appTheme.red400,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumSemiBold => theme.textTheme.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );
  static get titleMediumSemiBold_1 => theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );
  static get titleMediumSourceSansPro =>
      theme.textTheme.titleMedium!.sourceSansPro.copyWith(
        fontWeight: FontWeight.w600,
      );
  static get titleSmallGray400 => theme.textTheme.titleSmall!.copyWith(
        color: appTheme.gray400,
        fontWeight: FontWeight.w500,
      );
  static get titleSmallGray40001 => theme.textTheme.titleSmall!.copyWith(
        color: appTheme.gray40001,
        fontWeight: FontWeight.w500,
      );
  static get titleSmallWhiteA700 => theme.textTheme.titleSmall!.copyWith(
        color: appTheme.whiteA700,
      );
  static get titleSmallWhiteA700_1 => theme.textTheme.titleSmall!.copyWith(
        color: appTheme.whiteA700,
      );
}

extension on TextStyle {
  TextStyle get sourceSansPro {
    return copyWith(
      fontFamily: 'Source Sans Pro',
    );
  }

  TextStyle get urbanist {
    return copyWith(
      fontFamily: 'Urbanist',
    );
  }
}
