import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:my_pet/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:my_pet/features/gallery/presentation/pages/photo_viewer_page.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PetGalleryArgs {
  const PetGalleryArgs({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;
}

class PetGalleryPage extends StatelessWidget {
  const PetGalleryPage({
    required this.householdId,
    required this.petId,
    required this.petName,
    super.key,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryCubit>(
      create: (_) =>
          GalleryCubit(repository: sl())..start(householdId, petId),
      child: _GalleryView(petName: petName),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView({required this.petName});

  final String petName;

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
                      t.gallery.tabTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<GalleryCubit, GalleryState>(
                  builder: (context, state) {
                    return switch (state) {
                      GalleryInitial() || GalleryLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      GalleryEmpty() => _Empty(
                          onAdd: () => _pickAndUpload(context),
                        ),
                      GalleryLoaded() => _Grid(state: state),
                      GalleryError() => Center(
                          child: Text(t.gallery.errors.loadFailed),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUpload(context),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(t.gallery.addPhoto),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4000,
      imageQuality: 95,
    );
    if (picked == null || !context.mounted) return;

    final auth = context.read<AuthBloc>().state;
    final uid = switch (auth) {
      AuthAuthenticated(:final user) => user.uid,
      _ => '',
    };
    final cubit = context.read<GalleryCubit>();
    final failure = await cubit.upload(
      source: File(picked.path),
      createdBy: uid,
    );
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t.gallery.errors.uploadFailed)),
      );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      children: [
        Icon(
          PhosphorIconsBold.imagesSquare,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.gallery.empty.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.gallery.empty.subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: palette.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: t.gallery.addPhoto,
          icon: PhosphorIconsBold.plus,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.state});
  final GalleryLoaded state;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemCount: state.photos.length,
      itemBuilder: (context, index) {
        final photo = state.photos[index];
        return _GridTile(
          photo: photo,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PhotoViewerPage(
                photos: state.photos,
                initialIndex: index,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.photo, required this.onTap});
  final PetPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.brMd,
      child: GestureDetector(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: photo.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => ColoredBox(
            color: context.palette.surfaceMuted,
          ),
          errorWidget: (_, _, _) => ColoredBox(
            color: context.palette.surfaceMuted,
            child: Icon(
              PhosphorIconsRegular.imageBroken,
              color: context.palette.onSurfaceFaint,
            ),
          ),
        ),
      ),
    );
  }
}
