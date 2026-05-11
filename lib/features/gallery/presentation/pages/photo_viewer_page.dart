import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/theme/app_colors.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// Immersive viewer keeps a fixed black scrim + white foreground regardless
// of theme — the photo itself is the content and the chrome must recede.
const Color _scrimColor = Colors.black;
const double _scrimOnIcon = 0.45;
const double _scrimOnPanel = 0.55;
const Color _foregroundColor = Colors.white;
const double _captionFadedAlpha = 0.7;

/// Full-screen photo viewer with swipe navigation, pinch-zoom via
/// [InteractiveViewer], and per-photo actions (caption, set profile,
/// delete). Reuses the parent [GalleryCubit] for mutations.
class PhotoViewerPage extends StatefulWidget {
  const PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    super.key,
  });

  final List<PetPhoto> photos;
  final int initialIndex;

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller;
  late int _index;
  late List<PetPhoto> _localPhotos;

  @override
  void initState() {
    super.initState();
    _localPhotos = [...widget.photos];
    _index = widget.initialIndex.clamp(0, _localPhotos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_localPhotos.isEmpty) {
      // All photos deleted — bail out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: _scrimColor);
    }
    final current = _localPhotos[_index];
    return Scaffold(
      backgroundColor: _scrimColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _localPhotos.length,
            itemBuilder: (context, i) {
              return InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: _localPhotos[i].url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            },
          ),
          // Top bar — back + counter.
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.xs,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              children: [
                _IconButton(
                  icon: PhosphorIconsBold.arrowLeft,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _Pill(text: '${_index + 1} / ${_localPhotos.length}'),
              ],
            ),
          ),
          // Bottom bar — caption + actions.
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            child: _BottomBar(
              photo: current,
              onEditCaption: () => _editCaption(current),
              onSetProfile: () => _setAsProfile(current),
              onDelete: () => _confirmDelete(current),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCaption(PetPhoto photo) async {
    final controller = TextEditingController(text: photo.caption ?? '');
    final next = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.gallery.actions.editCaption),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                InputDecoration(hintText: t.gallery.captionPlaceholder),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(t.common.save),
            ),
          ],
        );
      },
    );
    if (next == null || !mounted) return;
    await context.read<GalleryCubit>().updateCaption(photo.id, next);
  }

  Future<void> _setAsProfile(PetPhoto photo) async {
    final failure = await context.read<GalleryCubit>().setAsProfile(photo);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? t.gallery.actions.setAsProfileSuccess
                : t.gallery.errors.setAsProfileFailed,
          ),
        ),
      );
  }

  Future<void> _confirmDelete(PetPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.gallery.deleteConfirmTitle),
        content: Text(t.gallery.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<GalleryCubit>().delete(photo.id);
    if (!mounted) return;
    setState(() {
      _localPhotos.removeAt(_index);
      if (_index >= _localPhotos.length && _index > 0) _index--;
    });
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _scrimColor.withValues(alpha: _scrimOnIcon),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, color: _foregroundColor, size: 20),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(color: _foregroundColor);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _scrimColor.withValues(alpha: _scrimOnIcon),
        borderRadius: AppRadii.brPill,
      ),
      child: Text(text, style: labelStyle),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.photo,
    required this.onEditCaption,
    required this.onSetProfile,
    required this.onDelete,
  });

  final PetPhoto photo;
  final VoidCallback onEditCaption;
  final VoidCallback onSetProfile;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final date = (photo.takenAt ?? photo.createdAt).toLocal();
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _scrimColor.withValues(alpha: _scrimOnPanel),
        borderRadius: AppRadii.brXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo.caption != null && photo.caption!.isNotEmpty)
            Text(
              photo.caption!,
              style: textTheme.bodyMedium?.copyWith(color: _foregroundColor),
            ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            fmt.format(date),
            style: textTheme.bodySmall?.copyWith(
              color: _foregroundColor.withValues(alpha: _captionFadedAlpha),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Action(
                icon: PhosphorIconsBold.notePencil,
                label: t.gallery.actions.editCaption,
                onTap: onEditCaption,
              ),
              _Action(
                icon: PhosphorIconsBold.user,
                label: t.gallery.actions.setAsProfile,
                onTap: onSetProfile,
              ),
              _Action(
                icon: PhosphorIconsBold.trash,
                label: t.common.delete,
                onTap: onDelete,
                destructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : _foregroundColor;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: color);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
