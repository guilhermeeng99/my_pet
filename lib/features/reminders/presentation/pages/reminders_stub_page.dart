import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Placeholder Reminders tab. Standalone reminders ship in Phase 2 (see
/// roadmap.md). The empty card sits in the new bottom-nav shell so the tab
/// surface exists today.
class RemindersStubPage extends StatelessWidget {
  const RemindersStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.nav.reminders,
      titleSize: ScreenTitleSize.large,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          FeatureListCard(
            icon: PhosphorIconsRegular.bell,
            title: t.reminders.stub.title,
            subtitle: t.reminders.stub.subtitle,
          ),
        ],
      ),
    );
  }
}
