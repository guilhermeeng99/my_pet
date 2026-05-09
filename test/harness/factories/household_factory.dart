import 'package:my_pet/features/household/data/models/household_model.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';

class HouseholdFactory {
  static Household build({
    String id = 'household_42',
    String name = "Jane's family",
    String ownerId = 'uid_123',
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return Household(
      id: id,
      name: name,
      ownerId: ownerId,
      memberIds: memberIds ?? <String>[ownerId],
      createdAt: createdAt ?? DateTime.utc(2026),
    );
  }

  static HouseholdModel buildModel({
    String id = 'household_42',
    String name = "Jane's family",
    String ownerId = 'uid_123',
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return HouseholdModel(
      id: id,
      name: name,
      ownerId: ownerId,
      memberIds: memberIds ?? <String>[ownerId],
      createdAt: createdAt ?? DateTime.utc(2026),
    );
  }
}
