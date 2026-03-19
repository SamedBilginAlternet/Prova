import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/garment_repository.dart';
import '../models/garment.dart';

part 'garments_provider.g.dart';

/// Currently selected category filter.
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  GarmentCategory build() => GarmentCategory.all;

  void select(GarmentCategory category) => state = category;
}

/// Fetches garments, filtered by [SelectedCategory].
@riverpod
Future<List<Garment>> garments(Ref ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final repo = ref.watch(garmentRepositoryProvider);
  return repo.getGarments(
    category: category == GarmentCategory.all ? null : category.value,
  );
}

/// The garment currently selected for try-on.
@riverpod
class SelectedGarment extends _$SelectedGarment {
  @override
  Garment? build() => null;

  void select(Garment garment) => state = garment;
  void clear() => state = null;
}
