import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/app_secondary_button.dart';
import 'package:my_pet/features/household/domain/entities/invite.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Modal that displays a freshly generated invite code so the user can copy
/// it into a chat with their partner. Closes itself on the close button.
Future<void> showInviteCodeDialog(BuildContext context, Invite invite) {
  return showDialog<void>(
    context: context,
    builder: (_) => _InviteCodeDialog(invite: invite),
  );
}

class _InviteCodeDialog extends StatelessWidget {
  const _InviteCodeDialog({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final formatter = DateFormat.yMMMd().add_Hm();
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.brXL),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                PhosphorIconsBold.linkSimple,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.household.invite.title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              t.household.invite.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _CodeChips(code: invite.code),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.household.invite.validity(
                datetime: formatter.format(invite.expiresAt.toLocal()),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              icon: PhosphorIconsBold.copy,
              label: t.household.invite.copy,
              onPressed: () => _onCopy(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: t.household.invite.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCopy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.household.invite.copied)),
    );
  }
}

class _CodeChips extends StatelessWidget {
  const _CodeChips({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in code.split(''))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadii.brMd,
              ),
              alignment: Alignment.center,
              child: Text(
                c,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
