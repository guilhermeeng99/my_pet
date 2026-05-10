import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_secondary_button.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Profile tab — minimal Phase 1.5 surface: identity card, household row,
/// app version, sign-out CTA. Family-management UI lands in Phase 3.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.profile.title,
      titleSize: ScreenTitleSize.large,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = switch (state) {
            AuthAuthenticated(:final user) => user,
            AuthNeedsHousehold(:final user) => user,
            _ => null,
          };
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _IdentityCard(
                displayName: user.displayName,
                email: user.email,
                photoUrl: user.photoUrl,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: PhosphorIconsRegular.house,
                label: t.profile.household,
                value: user.householdId ?? '—',
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                icon: PhosphorIconsRegular.info,
                label: t.profile.version,
                value: '0.1.0',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSecondaryButton(
                icon: PhosphorIconsRegular.signOut,
                label: t.auth.signOut,
                onPressed: () =>
                    context.read<AuthBloc>().add(const SignOutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final String? displayName;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                photoUrl == null ? null : NetworkImage(photoUrl!),
            child: photoUrl == null
                ? Icon(
                    PhosphorIconsBold.user,
                    size: 24,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName?.isNotEmpty ?? false ? displayName! : email,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
