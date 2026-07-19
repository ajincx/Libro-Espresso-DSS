class ProductException implements Exception {
  final String message;
  ProductException(this.message);

  @override
  String toString() => message;

  factory ProductException.duplicateName() => ProductException('A product with this name already exists in this branch.');
  factory ProductException.emptyName() => ProductException('Product name cannot be empty.');
  factory ProductException.invalidPrice() => ProductException('Selling price cannot be negative.');
  factory ProductException.invalidCategory() => ProductException('Invalid product category.');
  factory ProductException.inactiveBranch() => ProductException('Cannot create or update products in an inactive branch.');
  factory ProductException.unauthorized() => ProductException('You do not have permission to perform this action.');
  factory ProductException.notFound() => ProductException('Product not found.');
  factory ProductException.firestoreFailure(String e) => ProductException('Database error: \$e');
}
