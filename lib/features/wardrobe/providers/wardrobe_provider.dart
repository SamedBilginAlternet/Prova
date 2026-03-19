import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/wardrobe_repository.dart';
import '../models/wardrobe_item.dart';

part 'wardrobe_provider.g.dart';

/// Active category filter for the wardrobe grid.
@riverpod
class WardrobeFilter extends _$WardrobeFilter {
  @override
  ({String? category, String? season, String? occasion}) build() =>
      (category: null, season: null, occasion: null);

  void setCategory(String? category) =>
      state = (category: category, season: state.season, occasion: state.occasion);

  void setSeason(String? season) =>
      state = (category: state.category, season: season, occasion: state.occasion);

  void setOccasion(String? occasion) =>
      state = (category: state.category, season: state.season, occasion: occasion);

  void clear() => state = (category: null, season: null, occasion: null);
}

/// Full wardrobe list, reactive to filter changes.
@riverpod
Future<List<WardrobeItem>> wardrobeItems(WardrobeItemsRef ref) async {
  ref.watch(currentUserProvider); // invalidate on auth change
  final filter = ref.watch(wardrobeFilterProvider);
  final repo = ref.watch(wardrobeRepositoryProvider);
  return repo.getItems(
    category: filter.category,
    season: filter.season,
    occasion: filter.occasion,
  );
}

/// Single item detail.
@riverpod
Future<WardrobeItem> wardrobeItem(WardrobeItemRef ref, String id) async {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return repo.getItem(id);
}

/// Signed URL for a wardrobe item image.
@riverpod
Future<String?> wardrobeItemUrl(WardrobeItemUrlRef ref, String storagePath) async {
  if (storagePath.isEmpty) return null;
  final repo = ref.read(wardrobeRepositoryProvider);
  return repo.getSignedUrl(storagePath);
}

/// Upload state machine
sealed class WardrobeUploadState {}
class WardrobeUploadIdle extends WardrobeUploadState {}
class WardrobeUploadLoading extends WardrobeUploadState {
  final double progress;
  WardrobeUploadLoading(this.progress);
}
class WardrobeUploadSuccess extends WardrobeUploadState {
  final WardrobeItem item;
  WardrobeUploadSuccess(this.item);
}
class WardrobeUploadError extends WardrobeUploadState {
  final String message;
  WardrobeUploadError(this.message);
}

@riverpod
class WardrobeUploadNotifier extends _$WardrobeUploadNotifier {
  @override
  WardrobeUploadState build() => WardrobeUploadIdle();

  Future<void> upload({
    required File imageFile,
    required String category,
    String? name,
    String? color,
    String? colorHex,
    String? pattern,
    String? season,
    String? occasion,
    String? brand,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = WardrobeUploadError('Oturum açmanız gerekiyor');
      return;
    }

    state = WardrobeUploadLoading(0.3);

    try {
      final repo = ref.read(wardrobeRepositoryProvider);
      state = WardrobeUploadLoading(0.6);

      final item = await repo.addItem(
        userId: user.id,
        imageFile: imageFile,
        category: category,
        name: name,
        color: color,
        colorHex: colorHex,
        pattern: pattern,
        season: season,
        occasion: occasion,
        brand: brand,
        notes: notes,
      );

      state = WardrobeUploadSuccess(item);
      ref.invalidate(wardrobeItemsProvider);
    } catch (e) {
      state = WardrobeUploadError('Yüklenemedi: ${e.toString()}');
    }
  }

  void reset() => state = WardrobeUploadIdle();
}

/// Delete a wardrobe item.
@riverpod
class WardrobeDeleteNotifier extends _$WardrobeDeleteNotifier {
  @override
  bool build() => false; // isDeleting

  Future<bool> delete(WardrobeItem item) async {
    state = true;
    try {
      await ref.read(wardrobeRepositoryProvider).deleteItem(item);
      ref.invalidate(wardrobeItemsProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = false;
    }
  }
}
