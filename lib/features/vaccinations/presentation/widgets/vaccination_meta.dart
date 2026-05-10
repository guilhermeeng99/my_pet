import 'package:flutter/material.dart';
import 'package:my_pet/app/widgets/status_badge.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  static StatusTone toneFor(VaccinationStatus s) {
    return switch (s) {
      VaccinationStatus.overdue => StatusTone.danger,
      VaccinationStatus.dueSoon => StatusTone.warning,
      VaccinationStatus.upToDate => StatusTone.success,
      VaccinationStatus.noNextDose => StatusTone.neutral,
    };
  }

  static IconData iconFor(VaccinationStatus s) {
    return switch (s) {
      VaccinationStatus.overdue => PhosphorIconsBold.warning,
      VaccinationStatus.dueSoon => PhosphorIconsBold.clock,
      VaccinationStatus.upToDate => PhosphorIconsBold.checkCircle,
      VaccinationStatus.noNextDose => PhosphorIconsBold.question,
    };
  }
}
