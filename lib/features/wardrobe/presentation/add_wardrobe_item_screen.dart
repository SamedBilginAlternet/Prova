import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/prova_button.dart';
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';

class AddWardrobeItemScreen extends ConsumerStatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  ConsumerState<AddWardrobeItemScreen> createState() =>
      _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends ConsumerState<AddWardrobeItemScreen> {
  final _picker = ImagePicker();
  File? _imageFile;

  // Form state
  WardrobeCategory _category = WardrobeCategory.top;
  WardrobeSeason _season = WardrobeSeason.all;
  WardrobeOccasion _occasion = WardrobeOccasion.all;
  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _brandCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 90,
    );
    if (xfile == null) return;
    setState(() => _imageFile = File(xfile.path));
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir fotoğraf seçin')),
      );
      return;
    }

    await ref.read(wardrobeUploadProvider.notifier).upload(
          imageFile: _imageFile!,
          category: _category.value,
          name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
          season: _season.value,
          occasion: _occasion.value,
          brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(wardrobeUploadProvider);

    ref.listen(wardrobeUploadProvider, (_, next) {
      if (next is WardrobeUploadSuccess) {
        ref.read(wardrobeUploadProvider.notifier).reset();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kıyafet gardırobuna eklendi!')),
        );
      }
    });

    final isLoading = uploadState is WardrobeUploadLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kıyafet Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker
            _PhotoPickerSection(
              imageFile: _imageFile,
              onPickGallery: () => _pickImage(ImageSource.gallery),
              onPickCamera: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Category selector
            _SectionLabel('Kategori *'),
            const SizedBox(height: AppSpacing.sm),
            _CategorySelector(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Name (optional)
            _SectionLabel('İsim (opsiyonel)'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'ör. Beyaz oversize tişört'),
            ),
            const SizedBox(height: AppSpacing.base),

            // Color
            _SectionLabel('Renk'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _colorCtrl,
              decoration: const InputDecoration(hintText: 'ör. Beyaz, Kırmızı, Lacivert'),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Season
            _SectionLabel('Mevsim'),
            const SizedBox(height: AppSpacing.sm),
            _ChipSelector<WardrobeSeason>(
              items: WardrobeSeason.values,
              selected: _season,
              labelOf: (s) => s.labelTr,
              onSelected: (s) => setState(() => _season = s),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Occasion
            _SectionLabel('Ortam'),
            const SizedBox(height: AppSpacing.sm),
            _ChipSelector<WardrobeOccasion>(
              items: WardrobeOccasion.values,
              selected: _occasion,
              labelOf: (o) => o.labelTr,
              onSelected: (o) => setState(() => _occasion = o),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Brand
            _SectionLabel('Marka'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(hintText: 'ör. Zara, H&M'),
            ),
            const SizedBox(height: AppSpacing.base),

            // Notes
            _SectionLabel('Notlar'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Bu kıyafet hakkında notlar...',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Error
            if (uploadState is WardrobeUploadError)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.base),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Text(
                  uploadState.message,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),

            // Progress
            if (isLoading) ...[
              LinearProgressIndicator(
                value: (uploadState as WardrobeUploadLoading).progress,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            ProvaButton(
              label: 'Gardıroba Ekle',
              onPressed: isLoading ? null : _save,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerSection extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const _PhotoPickerSection({
    required this.imageFile,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusLg,
            child: Image.file(
              imageFile!,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onPickGallery,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: const Text('Değiştir',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PickerButton(
            icon: Icons.photo_library_outlined,
            label: 'Galeri',
            onTap: onPickGallery,
          ),
          const SizedBox(width: AppSpacing.xxl),
          _PickerButton(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            onTap: onPickCamera,
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.onSurfaceMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.titleMedium);
}

class _CategorySelector extends StatelessWidget {
  final WardrobeCategory selected;
  final ValueChanged<WardrobeCategory> onSelected;

  const _CategorySelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: WardrobeCategory.values.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              '${cat.emoji} ${cat.labelTr}',
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _ChipSelector({
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentSurface : AppColors.surface,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              labelOf(item),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.accent : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
