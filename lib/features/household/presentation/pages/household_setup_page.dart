import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Onboarding step shown right after Google sign-in when the user has no
/// household yet. Replaces the previous auto-create behavior with an
/// explicit choice between starting fresh or joining a partner's family.
class HouseholdSetupPage extends StatelessWidget {
  const HouseholdSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return ScreenScaffold(
      title: t.household.setup.title,
      titleSize: ScreenTitleSize.large,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final busy = state is AuthCreatingHousehold;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: [
              Text(
                t.household.setup.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ChoiceCard(
                icon: PhosphorIconsBold.house,
                iconColor: theme.colorScheme.primary,
                title: t.household.setup.createOwn.title,
                subtitle: t.household.setup.createOwn.subtitle,
                loading: busy,
                onTap: busy
                    ? null
                    : () => context
                        .read<AuthBloc>()
                        .add(const CreateOwnHouseholdRequested()),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceCard(
                icon: PhosphorIconsBold.linkSimple,
                iconColor: theme.colorScheme.primary,
                title: t.household.setup.joinExisting.title,
                subtitle: t.household.setup.joinExisting.subtitle,
                onTap: busy ? null : () => context.push('/join'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brMd,
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            PhosphorIconsRegular.caretRight,
            color: palette.onSurfaceMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}
