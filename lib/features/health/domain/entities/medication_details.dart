import 'package:equatable/equatable.dart';

/// Sub-object stored inline on a `HealthEvent` when `type == medication`.
/// Keeps the rich medication metadata together with the event without
/// promoting it to its own collection (most pets have a handful of
/// medications per year — joining is not worth the complexity).
class MedicationDetails extends Equatable {
  const MedicationDetails({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.prescribedBy,
  });

  /// "Apoquel", "Amoxicillin", etc.
  final String name;

  /// Free-form dosage, e.g. "10mg" or "1/2 pill".
  final String dosage;

  /// Free-form frequency, e.g. "every 12h".
  final String frequency;

  /// Total length of the treatment in days; the form uses this to schedule
  /// daily reminders for the event window.
  final int durationDays;

  final String? prescribedBy;

  MedicationDetails copyWith({
    String? name,
    String? dosage,
    String? frequency,
    int? durationDays,
    String? prescribedBy,
    bool clearPrescribedBy = false,
  }) {
    return MedicationDetails(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      durationDays: durationDays ?? this.durationDays,
      prescribedBy:
          clearPrescribedBy ? null : (prescribedBy ?? this.prescribedBy),
    );
  }

  @override
  List<Object?> get props =>
      [name, dosage, frequency, durationDays, prescribedBy];
}
