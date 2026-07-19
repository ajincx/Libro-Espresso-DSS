class RecipeException implements Exception {
  final String message;
  RecipeException(this.message);

  @override
  String toString() => message;

  factory RecipeException.duplicateRecipe() => RecipeException('An active recipe already exists for this product in this branch.');
  factory RecipeException.inactiveProduct() => RecipeException('Cannot create a recipe for an inactive product.');
  factory RecipeException.inactiveIngredient(String name) => RecipeException('Cannot add inactive ingredient "\$name" to a recipe.');
  factory RecipeException.emptyRecipe() => RecipeException('A recipe must have at least one ingredient.');
  factory RecipeException.invalidQuantity() => RecipeException('Ingredient quantities must be greater than zero.');
  factory RecipeException.invalidUnit() => RecipeException('Invalid unit of measurement for recipe item.');
  factory RecipeException.duplicateIngredient() => RecipeException('Duplicate ingredient entry in the recipe.');
  factory RecipeException.unauthorized() => RecipeException('You do not have permission to perform this action.');
  factory RecipeException.notFound() => RecipeException('Recipe not found.');
  factory RecipeException.firestoreFailure(String e) => RecipeException('Database error: \$e');
}
