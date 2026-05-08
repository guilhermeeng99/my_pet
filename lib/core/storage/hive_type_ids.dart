/// Centralized registry of Hive type IDs.
///
/// Adding a new `@HiveType` adapter? Add the constant here first, then
/// reference it in the annotation. Never reuse an ID, even after deleting
/// the type — old data on user devices may still reference it.
abstract final class HiveTypeIds {
  // Core (0-9)
  static const int outboxOperation = 0;

  // Pets domain (10-19)
  static const int pet = 10;
  static const int species = 11;
  static const int sex = 12;

  // Vaccinations (20-29)
  static const int vaccination = 20;
  static const int vaccineCategory = 21;

  // Health (30-39)
  static const int healthEvent = 30;
  static const int healthEventType = 31;
  static const int medicationDetails = 32;

  // Weight (40-49)
  static const int weightEntry = 40;

  // Reminders (50-59)
  static const int reminder = 50;
  static const int reminderType = 51;
  static const int recurrence = 52;

  // Gallery / docs (60-79)
  static const int petPhoto = 60;
  static const int petDocument = 70;
  static const int documentCategory = 71;

  // Household / auth (80-89)
  static const int household = 80;
  static const int authUser = 81;
}
