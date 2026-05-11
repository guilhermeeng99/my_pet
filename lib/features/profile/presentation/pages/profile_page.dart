import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/i18n/locale_preference_service.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_bottom_nav.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_field.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/presentation/cubit/account_deletion_cubit.dart';
import 'package:my_pet/features/household/presentation/cubit/household_cubit.dart';
import 'package:my_pet/features/household/presentation/cubit/invite_cubit.dart';
import 'package:my_pet/features/household/presentation/cubit/member_management_cubit.dart';
import 'package:my_pet/features/household/presentation/widgets/invite_code_dialog.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Settings tab — identity, household / partner card with invite-code flow,
/// app version, sign out. Mirrors the reference settings layout from
/// `docs/specs/household.md`.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = _currentUser(authState);
        if (user == null || user.householdId == null) {
          return ScreenScaffold(
            title: t.profile.title,
            titleSize: ScreenTitleSize.large,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  HouseholdCubit(repository: sl())..start(user.householdId!),
            ),
            BlocProvider(
              create: (_) => InviteCubit(repository: sl()),
            ),
            BlocProvider(
              create: (_) => MemberManagementCubit(repository: sl()),
            ),
            BlocProvider(
              create: (_) =>
                  AccountDeletionCubit(households: sl(), auth: sl()),
            ),
          ],
          child: _ProfileView(user: user),
        );
      },
    );
  }

  AuthUser? _currentUser(AuthState state) => switch (state) {
        AuthAuthenticated(:final user) => user,
        AuthNeedsHousehold(:final user) => user,
        _ => null,
      };
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.profile.title,
      titleSize: ScreenTitleSize.large,
      body: MultiBlocListener(
        listeners: [
          BlocListener<InviteCubit, InviteState>(listener: _onInviteState),
          BlocListener<MemberManagementCubit, MemberManagementState>(
            listener: _onMemberManagementState,
          ),
          BlocListener<AccountDeletionCubit, AccountDeletionState>(
            listener: _onDeletionState,
          ),
        ],
        child: ListView(
          // The floating bottom-nav pill overlaps this scrollable (see
          // `AppShell.extendBody`). `AppBottomNav.reservedSpace` returns
          // pill height + system safe-area, keeping the Danger Zone fully
          // reachable above the pill while content above continues to
          // scroll naturally behind it.
          padding: EdgeInsets.fromLTRB(
            0,
            AppSpacing.md,
            0,
            AppBottomNav.reservedSpace(context) + AppSpacing.md,
          ),
          children: [
            _HouseholdSection(user: user),
            const SizedBox(height: AppSpacing.lg),
            const _PreferencesSection(),
            const SizedBox(height: AppSpacing.lg),
            const _AboutSection(),
            const SizedBox(height: AppSpacing.lg),
            _SignOutCard(
              onTap: () =>
                  context.read<AuthBloc>().add(const SignOutRequested()),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _DangerZoneSection(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _onDeletionState(BuildContext context, AccountDeletionState state) {
    if (state is AccountDeletionFailed) {
      final message = switch (state.failure) {
        HouseholdNotEmptyFailure() =>
          t.profile.dangerZone.deleteAll.partnerBlockBody,
        RequiresRecentLoginFailure() =>
          t.profile.dangerZone.deleteAll.requiresRecentLogin,
        _ => t.profile.dangerZone.deleteAll.error,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.read<AccountDeletionCubit>().reset();
    }
    // AccountDeletionDone leaves the rest to AuthBloc — the FirebaseAuth
    // user is gone, the auth stream emits null, and the router redirects to
    // /welcome on its own.
  }

  void _onInviteState(BuildContext context, InviteState state) {
    if (state is InviteGenerated) {
      unawaited(showInviteCodeDialog(context, state.invite));
      context.read<InviteCubit>().reset();
      return;
    }
    if (state is InviteError) {
      final message = switch (state.failure) {
        HouseholdFullFailure() => t.household.errors.householdFull,
        _ => t.household.errors.generic,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.read<InviteCubit>().reset();
    }
  }

  /// Surfaces leave/remove failures inline as a snackbar. Success is
  /// handled implicitly: the affected user doc's `householdId` clears →
  /// the profile stream fires → `AuthBloc` (the leaver) or the household
  /// stream (the owner who just removed someone) updates and the UI
  /// re-renders. No manual nav from here.
  void _onMemberManagementState(
    BuildContext context,
    MemberManagementState state,
  ) {
    if (state is MemberManagementError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.household.errors.generic)),
      );
      context.read<MemberManagementCubit>().reset();
    }
  }
}

/// Combined Profile-tab household section. Matches the my-cycle pattern
/// (`docs/specs/household.md` & sibling repo's Settings page): one rounded
/// card listing both members stacked with a divider, a tinted "status"
/// card below ("Sharing pets together" / "Just you for now"), and a single
/// inline action (Generate invite for solo owner; Leave household for the
/// partner). Owner-only flows (transfer admin, audit log) live behind a
/// secondary "Manage family · audit log" text link to keep the surface
/// uncluttered.
class _HouseholdSection extends StatelessWidget {
  const _HouseholdSection({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HouseholdCubit, HouseholdState>(
      builder: (context, state) {
        return switch (state) {
          HouseholdLoading() || HouseholdInitial() =>
            const _HouseholdSkeleton(),
          HouseholdLoaded() => _HouseholdLoadedBody(state: state, user: user),
          HouseholdNotFound() ||
          HouseholdError() =>
            const _HouseholdFallback(),
        };
      },
    );
  }
}

class _HouseholdSkeleton extends StatelessWidget {
  const _HouseholdSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: SizedBox(
        height: 84,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HouseholdFallback extends StatelessWidget {
  const _HouseholdFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Text(
        t.household.errors.generic,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _HouseholdLoadedBody extends StatelessWidget {
  const _HouseholdLoadedBody({required this.state, required this.user});

  final HouseholdLoaded state;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final paired = state.hasPartner;
    final iAmOwner =
        state.members.any((m) => m.uid == user.uid && m.isOwner);
    final partner = paired
        ? state.members.firstWhere((m) => m.uid != user.uid)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MembersCard(members: state.members, currentUid: user.uid),
        const SizedBox(height: AppSpacing.md),
        _StatusCard(paired: paired),
        if (!paired && iAmOwner) ...[
          const SizedBox(height: AppSpacing.sm),
          const _GenerateInviteButton(),
        ],
        // Asymmetric member action: owner sees "Remove <partner>" (kicks
        // the partner out, owner stays), partner sees "Leave household"
        // (drops self, household lives on with the owner).
        if (paired) ...[
          const SizedBox(height: AppSpacing.sm),
          if (iAmOwner && partner != null)
            _RemovePartnerButton(user: user, partner: partner)
          else
            _LeaveHouseholdButton(user: user),
        ],
      ],
    );
  }
}

/// Single rounded card listing every household member as `avatar + name +
/// email`, with a hairline divider between rows. No role badges and no
/// "You" tag — the design intentionally treats the partnership as
/// symmetric on this screen (owner-only flows live behind Manage family).
class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.members, required this.currentUid});

  final List<HouseholdMember> members;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    // Sort so the signed-in user always appears first. Stable order between
    // rebuilds prevents avatars from jumping around when the partner
    // profile snapshot lands a tick after the household doc.
    final ordered = [...members]
      ..sort((a, b) {
        if (a.uid == currentUid) return -1;
        if (b.uid == currentUid) return 1;
        return 0;
      });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 0.5,
                color: context.palette.surfaceMuted,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _PersonRow(member: ordered[i]),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final name = (member.displayName?.isNotEmpty ?? false)
        ? member.displayName!
        : member.email;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage:
              member.photoUrl == null ? null : NetworkImage(member.photoUrl!),
          child: member.photoUrl == null
              ? Icon(
                  PhosphorIconsBold.user,
                  size: 22,
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
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tinted card with a heart icon + title + short subtitle. Two flavors:
/// paired (primary tint, "Sharing pets together") and solo (muted tint,
/// "Just you for now"). Always at least one row so the layout doesn't
/// jump when the partner profile loads.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.paired});

  final bool paired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final accent = paired ? theme.colorScheme.primary : palette.onSurfaceMuted;
    final bg = paired
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : palette.surfaceMuted;
    final title = paired
        ? t.household.status.pairedTitle
        : t.household.status.soloTitle;
    final subtitle = paired
        ? t.household.status.pairedSubtitle
        : t.household.status.soloSubtitle;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              paired ? PhosphorIconsBold.heart : PhosphorIconsRegular.userPlus,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _GenerateInviteButton extends StatelessWidget {
  const _GenerateInviteButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteCubit, InviteState>(
      builder: (context, state) {
        final busy = state is InviteGenerating;
        return Center(
          child: TextButton.icon(
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsBold.linkSimple, size: 18),
            label: Text(t.household.actions.generateInvite),
            onPressed: busy
                ? null
                : () {
                    final auth = context.read<AuthBloc>().state;
                    final user = switch (auth) {
                      AuthAuthenticated(:final user) => user,
                      _ => null,
                    };
                    if (user?.householdId == null) return;
                    unawaited(
                      context.read<InviteCubit>().generate(
                            householdId: user!.householdId!,
                            createdBy: user.uid,
                          ),
                    );
                  },
          ),
        );
      },
    );
  }
}

/// Text button below the status card, shown to both members of a paired
/// household. Triggers a confirm dialog, then calls
/// `MemberManagementCubit.leave`. Success isn't navigated locally — the
/// user doc's `householdId` clears, the `AuthBloc` profile stream fires,
/// and the router redirects to setup. For owners, the datasource
/// auto-transfers ownership to the partner before removing the user, so
/// the household data lives on with the remaining member.
class _LeaveHouseholdButton extends StatelessWidget {
  const _LeaveHouseholdButton({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return BlocBuilder<MemberManagementCubit, MemberManagementState>(
      builder: (context, state) {
        final busy = state is MemberManagementBusy;
        return Center(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: danger),
            onPressed: busy ? null : () => _confirmAndLeave(context),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(danger),
                    ),
                  )
                : Text(t.household.members.leave),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndLeave(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.brXL),
        title: Text(t.household.members.leaveConfirmTitle),
        content: Text(
          t.household.members.leaveConfirmBody,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.danger,
            ),
            child: Text(t.household.members.leave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (user.householdId == null) return;
    await context.read<MemberManagementCubit>().leave(
          householdId: user.householdId!,
          actor: user,
        );
  }
}

/// Owner-only counterpart to `_LeaveHouseholdButton`. Confirms, then
/// detaches the partner from the household (their `users/{uid}.householdId`
/// is cleared, household membership shrinks back to the owner alone).
/// The owner stays put — no router redirect needed.
class _RemovePartnerButton extends StatelessWidget {
  const _RemovePartnerButton({required this.user, required this.partner});

  final AuthUser user;
  final HouseholdMember partner;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return BlocBuilder<MemberManagementCubit, MemberManagementState>(
      builder: (context, state) {
        final busy = state is MemberManagementBusy;
        return Center(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: danger),
            onPressed: busy ? null : () => _confirmAndRemove(context),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(danger),
                    ),
                  )
                : Text(_label),
          ),
        );
      },
    );
  }

  String get _partnerName =>
      (partner.displayName?.isNotEmpty ?? false) ? partner.displayName! : partner.email;

  String get _label => '${t.household.members.remove} $_partnerName';

  Future<void> _confirmAndRemove(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.brXL),
        title: Text(t.household.members.removeConfirmTitle),
        content: Text(
          t.household.members.removeConfirmBody(name: _partnerName),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.danger,
            ),
            child: Text(t.household.members.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (user.householdId == null) return;
    await context.read<MemberManagementCubit>().remove(
          householdId: user.householdId!,
          actor: user,
          target: partner,
        );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            t.profile.preferences.title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: palette.onSurfaceMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadii.brMd,
                ),
                child: Icon(
                  PhosphorIconsRegular.globe,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  t.profile.preferences.language,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const _LanguageToggle(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatefulWidget {
  const _LanguageToggle();

  @override
  State<_LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<_LanguageToggle> {
  Future<void> _select(AppLocale locale) async {
    if (LocaleSettings.currentLocale == locale) return;
    await sl<LocalePreferenceService>().write(locale);
    await LocaleSettings.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final current = TranslationProvider.of(context).locale;
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: AppRadii.brPill,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(
            label: t.profile.preferences.languageEnglish,
            selected: current == AppLocale.en,
            onTap: () => _select(AppLocale.en),
          ),
          _LanguageChip(
            label: t.profile.preferences.languagePortuguese,
            selected: current == AppLocale.ptBr,
            onTap: () => _select(AppLocale.ptBr),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: AppRadii.brPill,
      child: InkWell(
        borderRadius: AppRadii.brPill,
        onTap: selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : context.palette.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: context.palette.onSurfaceMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(t.profile.about.title),
        _InfoRow(
          icon: PhosphorIconsRegular.info,
          label: t.profile.version,
          value: sl<PackageInfo>().version,
        ),
      ],
    );
  }
}

/// Tappable card-shaped sign-out — matches the danger-tinted, full-width
/// look from the reference settings layout. Replaces the previous outlined
/// pill button so the action carries the visual weight it deserves.
class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = context.palette.danger;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsBold.signOut, color: danger, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            t.auth.signOut,
            style: theme.textTheme.titleMedium?.copyWith(
              color: danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final danger = palette.danger;
    return BlocBuilder<AccountDeletionCubit, AccountDeletionState>(
      builder: (context, deletion) {
        final deleting = deletion is AccountDeletionDeleting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel(t.profile.dangerZone.title),
            AppCard(
              onTap: deleting ? null : () => _onTap(context),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: 0.12),
                      borderRadius: AppRadii.brMd,
                    ),
                    alignment: Alignment.center,
                    child: deleting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(danger),
                            ),
                          )
                        : Icon(
                            PhosphorIconsBold.warningOctagon,
                            size: 18,
                            color: danger,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.profile.dangerZone.deleteAll.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deleting
                              ? t.profile.dangerZone.deleteAll.deleting
                              : t.profile.dangerZone.deleteAll.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 18,
                    color: palette.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final household = context.read<HouseholdCubit>().state;
    final auth = context.read<AuthBloc>().state;
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    if (user == null || user.householdId == null) return;

    if (household is HouseholdLoaded && household.hasPartner) {
      await _showPartnerBlockDialog(context);
      return;
    }

    final confirmed = await _showConfirmDialog(context, email: user.email);
    if (!confirmed || !context.mounted) return;
    await context.read<AccountDeletionCubit>().run(
          householdId: user.householdId!,
          userId: user.uid,
        );
  }

  Future<void> _showPartnerBlockDialog(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.brXL),
        title: Text(t.profile.dangerZone.deleteAll.partnerBlockTitle),
        content: Text(
          t.profile.dangerZone.deleteAll.partnerBlockBody,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.common.done),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String email,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAllConfirmDialog(email: email),
    );
    return result ?? false;
  }
}

/// Two-step destructive confirmation. The "Delete forever" button stays
/// disabled until the user types their full account email — the only way
/// to wipe the household, every pet record and the auth user in one shot.
/// The email is the strongest typing-target available (already shown in
/// the profile card, unambiguous, and never blank for an authenticated
/// session).
class _DeleteAllConfirmDialog extends StatefulWidget {
  const _DeleteAllConfirmDialog({required this.email});

  final String email;

  @override
  State<_DeleteAllConfirmDialog> createState() =>
      _DeleteAllConfirmDialogState();
}

class _DeleteAllConfirmDialogState extends State<_DeleteAllConfirmDialog> {
  final TextEditingController _ctrl = TextEditingController();
  bool _showMismatch = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _matches =>
      _ctrl.text.trim().toLowerCase() == widget.email.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final danger = palette.danger;
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.brXL),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.12),
                  borderRadius: AppRadii.brLg,
                ),
                child: Icon(
                  PhosphorIconsBold.warningOctagon,
                  color: danger,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.profile.dangerZone.deleteAll.confirmTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.profile.dangerZone.deleteAll.confirmBody(
                appName: AppConstants.appName,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.onSurfaceMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              icon: PhosphorIconsBold.envelope,
              label: t.profile.dangerZone.deleteAll.confirmTypeEmailLabel,
              child: TextField(
                controller: _ctrl,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: t.profile.dangerZone.deleteAll
                      .confirmTypeEmailHint(email: widget.email),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
                onSubmitted: (_) {
                  if (_matches) Navigator.of(context).pop(true);
                },
              ),
            ),
            if (_showMismatch && !_matches) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.profile.dangerZone.deleteAll.confirmTypeEmailMismatch,
                style: theme.textTheme.bodySmall?.copyWith(color: danger),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: danger,
                disabledBackgroundColor: danger.withValues(alpha: 0.4),
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(56),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.brPill,
                ),
              ),
              onPressed: _matches
                  ? () => Navigator.of(context).pop(true)
                  : () => setState(() => _showMismatch = true),
              child: Text(
                t.profile.dangerZone.deleteAll.confirmCta,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.profile.dangerZone.deleteAll.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
