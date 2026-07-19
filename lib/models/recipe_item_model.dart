class RecipeItemModel {
  final String recipeItemId;
  final String recipeId;
  final String ingredientId;
  final double quantity;
  final String unit;

  RecipeItemModel({
    required this.recipeItemId,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
  });

  factory RecipeItemModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RecipeItemModel(
      recipeItemId: documentId,
      recipeId: data['recipeId'] ?? '',
      ingredientId: data['ingredientId'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'ingredientId': ingredientId,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
