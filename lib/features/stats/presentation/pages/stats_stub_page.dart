import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Placeholder Stats tab. Health and spending dashboards land in Phase 4 (see
/// roadmap.md). The card describes what the user can expect later.
class StatsStubPage extends StatelessWidget {
  const StatsStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.nav.stats,
      titleSize: ScreenTitleSize.large,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          FeatureListCard(
            icon: PhosphorIconsRegular.chartLineUp,
            title: t.stats.stub.title,
            subtitle: t.stats.stub.subtitle,
          ),
        ],
      ),
    );
  }
}
