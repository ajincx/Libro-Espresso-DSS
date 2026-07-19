class IngredientException implements Exception {
  final String message;
  IngredientException(this.message);

  @override
  String toString() => message;

  factory IngredientException.duplicateName() => IngredientException('An ingredient with this name already exists in this branch.');
  factory IngredientException.emptyName() => IngredientException('Ingredient name cannot be empty.');
  factory IngredientException.invalidCost() => IngredientException('Cost per unit cannot be negative.');
  factory IngredientException.invalidStock() => IngredientException('Current stock and reorder level cannot be negative.');
  factory IngredientException.invalidUnit() => IngredientException('Invalid unit of measurement.');
  factory IngredientException.inactiveBranch() => IngredientException('Cannot create or update ingredients in an inactive branch.');
  factory IngredientException.unauthorized() => IngredientException('You do not have permission to perform this action.');
  factory IngredientException.notFound() => IngredientException('Ingredient not found.');
  factory IngredientException.firestoreFailure(String e) => IngredientException('Database error: \$e');
}
