import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/presentation/cubit/household_cubit.dart';
import 'package:my_pet/features/household/presentation/cubit/invite_cubit.dart';
import 'package:my_pet/features/household/presentation/cubit/member_management_cubit.dart';
import 'package:my_pet/features/household/presentation/pages/household_audit_page.dart';
import 'package:my_pet/features/household/presentation/widgets/invite_code_dialog.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Family management — owner sees remove + transfer per partner; partner
/// sees "Leave household". Both surface the audit log link.
class HouseholdMembersPage extends StatelessWidget {
  const HouseholdMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = _currentUser(authState);
        if (user == null || user.householdId == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  HouseholdCubit(repository: sl())..start(user.householdId!),
            ),
            BlocProvider(create: (_) => InviteCubit(repository: sl())),
            BlocProvider(
              create: (_) => MemberManagementCubit(repository: sl()),
            ),
          ],
          child: _MembersView(user: user),
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

class _MembersView extends StatelessWidget {
  const _MembersView({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<MemberManagementCubit, MemberManagementState>(
              listener: _onManagementState,
            ),
            BlocListener<InviteCubit, InviteState>(listener: _onInviteState),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    CircleIconButton(
                      icon: PhosphorIconsBold.arrowLeft,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        t.household.members.title,
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: BlocBuilder<HouseholdCubit, HouseholdState>(
                    builder: (context, state) => switch (state) {
                      HouseholdLoading() ||
                      HouseholdInitial() =>
                        const Center(child: CircularProgressIndicator()),
                      HouseholdLoaded() => _Body(state: state, user: user),
                      HouseholdNotFound() || HouseholdError() => Center(
                          child: Text(t.household.errors.generic),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onManagementState(
    BuildContext context,
    MemberManagementState state,
  ) {
    if (state is MemberManagementError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_failureMessage(state))),
      );
      context.read<MemberManagementCubit>().reset();
      return;
    }
    if (state is MemberManagementSuccess) {
      context.read<MemberManagementCubit>().reset();
      // Leave drops us out of the household; AuthBloc redirects on next
      // stream tick. Until then, pop back so the user isn't stuck.
      if (state.action == MemberManagementAction.leave) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  void _onInviteState(BuildContext context, InviteState state) {
    if (state is InviteGenerated) {
      unawaited(showInviteCodeDialog(context, state.invite));
      context.read<InviteCubit>().reset();
    }
  }

  String _failureMessage(MemberManagementError error) =>
      error.failure.message ?? t.household.errors.generic;
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.user});

  final HouseholdLoaded state;
  final AuthUser user;

  bool get _isOwner => state.household.ownerId == user.uid;
  HouseholdMember? get _partner {
    for (final m in state.members) {
      if (m.uid != user.uid) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemberManagementCubit, MemberManagementState>(
      builder: (context, manageState) {
        final busy = manageState is MemberManagementBusy;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            SectionHeader(title: t.household.members.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            for (final m in state.members)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MemberCard(
                  member: m,
                  isMe: m.uid == user.uid,
                  isCurrentUserOwner: _isOwner,
                  busy: busy,
                  onRemove: () => _confirmRemove(context, m),
                  onTransfer: () => _confirmTransfer(context, m),
                ),
              ),
            if (_partner == null && _isOwner) ...[
              const SizedBox(height: AppSpacing.sm),
              FeatureListCard(
                icon: PhosphorIconsBold.userPlus,
                title: t.household.actions.generateInvite,
                onTap: () => context.read<InviteCubit>().generate(
                      householdId: state.household.id,
                      createdBy: user.uid,
                    ),
              ),
            ],
            if (!_isOwner) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: t.household.members.danger),
              const SizedBox(height: AppSpacing.xs),
              _LeaveCard(
                busy: busy,
                onTap: () =>
                    _confirmLeave(context, state.household, user),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: t.household.members.history),
            const SizedBox(height: AppSpacing.xs),
            FeatureListCard(
              icon: PhosphorIconsRegular.clockClockwise,
              title: t.household.members.audit,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      HouseholdAuditPage(householdId: state.household.id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    HouseholdMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.household.members.removeConfirmTitle),
        content: Text(
          t.household.members.removeConfirmBody(
            name: member.displayName ?? member.email,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.household.members.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<MemberManagementCubit>().remove(
          householdId: state.household.id,
          actor: user,
          target: member,
        );
  }

  Future<void> _confirmTransfer(
    BuildContext context,
    HouseholdMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.household.members.transferConfirmTitle),
        content: Text(
          t.household.members.transferConfirmBody(
            name: member.displayName ?? member.email,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.household.members.transfer),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<MemberManagementCubit>().transfer(
          householdId: state.household.id,
          actor: user,
          newOwner: member,
        );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    Household household,
    AuthUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.household.members.leaveConfirmTitle),
        content: Text(t.household.members.leaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.household.members.leave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<MemberManagementCubit>().leave(
          householdId: household.id,
          actor: user,
        );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isMe,
    required this.isCurrentUserOwner,
    required this.busy,
    required this.onRemove,
    required this.onTransfer,
  });

  final HouseholdMember member;
  final bool isMe;
  final bool isCurrentUserOwner;
  final bool busy;
  final VoidCallback onRemove;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final showAdminActions =
        isCurrentUserOwner && !isMe && !member.isOwner;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: member.photoUrl == null
                    ? null
                    : NetworkImage(member.photoUrl!),
                child: member.photoUrl == null
                    ? Icon(
                        PhosphorIconsBold.user,
                        size: 20,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (member.displayName?.isNotEmpty ?? false)
                                ? member.displayName!
                                : member.email,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '· ${t.household.you}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadii.brPill,
                ),
                child: Text(
                  member.isOwner
                      ? t.household.memberRoleOwner
                      : t.household.memberRolePartner,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (showAdminActions) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onTransfer,
                    icon: const Icon(PhosphorIconsBold.crown),
                    label: Text(t.household.members.transfer),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(PhosphorIconsBold.userMinus),
                    label: Text(t.household.members.remove),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = context.palette.danger;
    return AppCard(
      onTap: busy ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              PhosphorIconsBold.signOut,
              color: danger,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.household.members.leave,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: danger, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  t.household.members.leaveSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
