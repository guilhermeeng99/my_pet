import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_colors.dart';

/// Theme extension carrying tokens not covered by Material's [ColorScheme].
///
/// Consume via `Theme.of(context).extension<AppPalette>()!` or the
/// [AppPaletteX] BuildContext extension below.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surfaceMuted,
    required this.outline,
    required this.onSurfaceMuted,
    required this.onSurfaceFaint,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.accentCat,
    required this.accentDog,
    required this.accentBird,
    required this.accentRabbit,
    required this.accentOther,
  });

  final Color surfaceMuted;
  final Color outline;
  final Color onSurfaceMuted;
  final Color onSurfaceFaint;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final Color accentCat;
  final Color accentDog;
  final Color accentBird;
  final Color accentRabbit;
  final Color accentOther;

  static const AppPalette light = AppPalette(
    surfaceMuted: AppColors.surfaceMuted,
    outline: AppColors.outline,
    onSurfaceMuted: AppColors.onSurfaceMuted,
    onSurfaceFaint: AppColors.onSurfaceFaint,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    accentCat: AppColors.accentCat,
    accentDog: AppColors.accentDog,
    accentBird: AppColors.accentBird,
    accentRabbit: AppColors.accentRabbit,
    accentOther: AppColors.accentOther,
  );

  @override
  AppPalette copyWith({
    Color? surfaceMuted,
    Color? outline,
    Color? onSurfaceMuted,
    Color? onSurfaceFaint,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? accentCat,
    Color? accentDog,
    Color? accentBird,
    Color? accentRabbit,
    Color? accentOther,
  }) =>
      AppPalette(
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        outline: outline ?? this.outline,
        onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
        onSurfaceFaint: onSurfaceFaint ?? this.onSurfaceFaint,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        accentCat: accentCat ?? this.accentCat,
        accentDog: accentDog ?? this.accentDog,
        accentBird: accentBird ?? this.accentBird,
        accentRabbit: accentRabbit ?? this.accentRabbit,
        accentOther: accentOther ?? this.accentOther,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceFaint: Color.lerp(onSurfaceFaint, other.onSurfaceFaint, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      accentCat: Color.lerp(accentCat, other.accentCat, t)!,
      accentDog: Color.lerp(accentDog, other.accentDog, t)!,
      accentBird: Color.lerp(accentBird, other.accentBird, t)!,
      accentRabbit: Color.lerp(accentRabbit, other.accentRabbit, t)!,
      accentOther: Color.lerp(accentOther, other.accentOther, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
