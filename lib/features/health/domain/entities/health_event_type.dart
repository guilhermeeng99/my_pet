/// Categorization of a health event. Drives:
///
/// - the icon + accent color in the timeline,
/// - which optional fields the form surfaces (e.g. medication sub-form),
/// - the default reminder behavior (rule 2 of `docs/specs/health.md`).
enum HealthEventType {
  vetVisit,
  medication,
  deworming,
  fleaTickControl,
  grooming,
  exam,
  symptom,
  other,
}
