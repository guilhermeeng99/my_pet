import 'package:flutter/material.dart';

import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';
import 'package:my_pet/gen/strings.g.dart';

abstract final class VaccineCategoryMeta {
  static String label(VaccineCategory c) {
    return switch (c) {
      VaccineCategory.core => t.vaccinations.category.core,
      VaccineCategory.noncore => t.vaccinations.category.noncore,
      VaccineCategory.rabies => t.vaccinations.category.rabies,
      VaccineCategory.other => t.vaccinations.category.other,
    };
  }
}

abstract final class VaccinationStatusMeta {
  static String label(VaccinationStatus s) {
    return switch (s) {
      VaccinationStatus.overdue => t.vaccinations.status.overdue,
      VaccinationStatus.dueSoon => t.vaccinations.status.dueSoon,
      VaccinationStatus.upToDate => t.vaccinations.status.upToDate,
      VaccinationStatus.noNextDose => t.vaccinations.status.noNextDose,
    };
  }

  static Color colorFor(VaccinationStatus s, ColorScheme scheme) {
    return switch (s) {
      VaccinationStatus.overdue => scheme.error,
      VaccinationStatus.dueSoon => scheme.tertiary,
      VaccinationStatus.upToDate => scheme.primary,
      VaccinationStatus.noNextDose => scheme.outline,
    };
  }

  static IconData iconFor(VaccinationStatus s) {
    return switch (s) {
      VaccinationStatus.overdue => Icons.error_outline_rounded,
      VaccinationStatus.dueSoon => Icons.schedule_rounded,
      VaccinationStatus.upToDate => Icons.check_circle_outline_rounded,
      VaccinationStatus.noNextDose => Icons.help_outline_rounded,
    };
  }
}
