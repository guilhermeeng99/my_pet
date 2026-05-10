import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/features/household/domain/entities/audit_event.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Read-only event log. Streams the last 100 audit entries; the server
/// rule blocks updates/deletes so the history can't be tampered with.
class HouseholdAuditPage extends StatelessWidget {
  const HouseholdAuditPage({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
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
                      t.household.audit.title,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: StreamBuilder<List<AuditEvent>>(
                  stream: sl<HouseholdRepository>().watchAudit(householdId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final events = snap.data ?? const <AuditEvent>[];
                    if (events.isEmpty) {
                      return Center(
                        child: Text(
                          t.household.audit.empty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurfaceMuted,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _AuditTile(event: events[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.event});
  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final fmt = DateFormat.yMMMd().add_jm();
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              _iconFor(event.action),
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sentenceFor(event),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(event.at.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
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

  IconData _iconFor(AuditAction action) => switch (action) {
        AuditAction.householdCreated => PhosphorIconsBold.house,
        AuditAction.inviteGenerated => PhosphorIconsBold.linkSimple,
        AuditAction.inviteAccepted => PhosphorIconsBold.userPlus,
        AuditAction.memberRemoved => PhosphorIconsBold.userMinus,
        AuditAction.memberLeft => PhosphorIconsBold.signOut,
        AuditAction.ownerTransferred => PhosphorIconsBold.crown,
        AuditAction.householdRenamed => PhosphorIconsBold.pencilSimple,
      };

  String _sentenceFor(AuditEvent e) {
    final actor = e.actorName;
    final target = e.targetName ?? '';
    return switch (e.action) {
      AuditAction.householdCreated =>
        t.household.audit.lines.householdCreated(actor: actor),
      AuditAction.inviteGenerated =>
        t.household.audit.lines.inviteGenerated(actor: actor),
      AuditAction.inviteAccepted =>
        t.household.audit.lines.inviteAccepted(actor: actor),
      AuditAction.memberRemoved =>
        t.household.audit.lines.memberRemoved(actor: actor, target: target),
      AuditAction.memberLeft =>
        t.household.audit.lines.memberLeft(actor: actor),
      AuditAction.ownerTransferred =>
        t.household.audit.lines.ownerTransferred(actor: actor, target: target),
      AuditAction.householdRenamed =>
        t.household.audit.lines.householdRenamed(actor: actor),
    };
  }
}
