import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/prova_button.dart';
import '../providers/photo_provider.dart';

class UploadPhotoScreen extends ConsumerStatefulWidget {
  const UploadPhotoScreen({super.key});

  @override
  ConsumerState<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends ConsumerState<UploadPhotoScreen> {
  File? _previewFile;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (xfile == null) return;
    setState(() => _previewFile = File(xfile.path));
    ref.read(selectedPhotoFileProvider.notifier).set(File(xfile.path));
  }

  Future<void> _upload() async {
    if (_previewFile == null) return;
    await ref.read(photoUploadProvider.notifier).upload(_previewFile!);
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(photoUploadProvider);

    // Navigate after successful upload
    ref.listen(photoUploadProvider, (_, next) {
      if (next is UploadSuccess) {
        ref.read(photoUploadProvider.notifier).reset();
        context.go(AppRoutes.garmentBrowser);
      }
    });

    final isUploading = uploadState is UploadInProgress;
    final progress = uploadState is UploadInProgress ? uploadState.progress : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fotoğraf Seç'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageInsets,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Instruction text
              if (_previewFile == null) ...[
                Text(
                  'Fotoğrafını Yükle',
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'En iyi sonuç için düz renkli arka plan önünde, tam vücut veya üst vücut fotoğrafı kullanın.',
                  style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],

              // Preview or placeholder
              Expanded(
                child: _previewFile != null
                    ? _PhotoPreview(file: _previewFile!)
                    : const _PhotoPlaceholder(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Error message
              if (uploadState is UploadError) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Text(
                    uploadState.message,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
              ],

              // Upload progress
              if (isUploading) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Yükleniyor...',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.base),
              ],

              // Action buttons
              if (_previewFile == null) ...[
                ProvaButton(
                  label: 'Galeriden Seç',
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icons.photo_library_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                ProvaButton.outlined(
                  label: 'Kamera ile Çek',
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icons.camera_alt_outlined,
                ),
              ] else ...[
                ProvaButton(
                  label: 'Bu Fotoğrafı Kullan',
                  onPressed: isUploading ? null : _upload,
                  isLoading: isUploading,
                ),
                const SizedBox(height: AppSpacing.md),
                ProvaButton.ghost(
                  label: 'Başka Bir Fotoğraf Seç',
                  onPressed: isUploading ? null : () => setState(() {
                    _previewFile = null;
                    ref.read(selectedPhotoFileProvider.notifier).clear();
                  }),
                ),
              ],

              const SizedBox(height: AppSpacing.base),

              // Tips
              _PhotoTips(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final File file;

  const _PhotoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLg,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            size: 72,
            color: AppColors.onSurfaceMuted.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Fotoğrafın burada görünecek',
            style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _PhotoTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'İyi sonuç için: Düz arka plan, iyi aydınlatma, yüz görünür, tam veya yarım boy poz.',
              style: AppTextStyles.caption.copyWith(color: AppColors.accentDark),
            ),
          ),
        ],
      ),
    );
  }
}
