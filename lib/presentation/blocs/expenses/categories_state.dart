import 'package:expense/data/local/database.dart';

class CategoriesState {
  final List<LocalCategory> categories;
  final bool isLoading;
  final String? error;

  CategoriesState({
    required this.categories,
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<LocalCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
