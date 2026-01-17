
abstract class CategoriesEvent {}

class LoadCategories extends CategoriesEvent {}

class AddCategory extends CategoriesEvent {
  final String name;
  final String? icon;
  final String color;
  AddCategory({required this.name, this.icon, required this.color});
}

class UpdateCategory extends CategoriesEvent {
  final String id;
  final String name;
  final String? icon;
  final String color;
  UpdateCategory({
    required this.id,
    required this.name,
    this.icon,
    required this.color,
  });
}

class DeleteCategory extends CategoriesEvent {
  final String id;
  DeleteCategory(this.id);
}
