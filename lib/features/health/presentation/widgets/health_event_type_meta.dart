import 'package:flutter/widgets.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HealthEventTypeMeta {
  static IconData icon(HealthEventType type) => switch (type) {
        HealthEventType.vetVisit => PhosphorIconsBold.stethoscope,
        HealthEventType.medication => PhosphorIconsBold.pill,
        HealthEventType.deworming => PhosphorIconsBold.bug,
        HealthEventType.fleaTickControl => PhosphorIconsBold.bugDroid,
        HealthEventType.grooming => PhosphorIconsBold.sparkle,
        HealthEventType.exam => PhosphorIconsBold.flask,
        HealthEventType.symptom => PhosphorIconsBold.thermometer,
        HealthEventType.other => PhosphorIconsBold.heart,
      };

  static String label(HealthEventType type) => switch (type) {
        HealthEventType.vetVisit => t.health.types.vetVisit,
        HealthEventType.medication => t.health.types.medication,
        HealthEventType.deworming => t.health.types.deworming,
        HealthEventType.fleaTickControl => t.health.types.fleaTickControl,
        HealthEventType.grooming => t.health.types.grooming,
        HealthEventType.exam => t.health.types.exam,
        HealthEventType.symptom => t.health.types.symptom,
        HealthEventType.other => t.health.types.other,
      };
}
