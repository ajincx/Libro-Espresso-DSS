class BranchException implements Exception {
  final String message;
  BranchException(this.message);

  @override
  String toString() => message;

  factory BranchException.duplicateName() => BranchException('A branch with this name already exists.');
  factory BranchException.invalidEmail() => BranchException('The provided email is invalid.');
  factory BranchException.invalidContact() => BranchException('The provided contact number is invalid.');
  factory BranchException.emptyName() => BranchException('Branch name cannot be empty.');
  factory BranchException.unauthorized() => BranchException('You do not have permission to perform this action.');
  factory BranchException.notFound() => BranchException('Branch not found.');
  factory BranchException.inactiveAssignment() => BranchException('Cannot assign a manager to an inactive branch.');
  factory BranchException.ownerAssignment() => BranchException('Owners automatically have access to all branches and cannot be assigned as Managers.');
  factory BranchException.duplicateAssignment() => BranchException('This manager is already assigned to a branch. Managers can only manage one branch at a time.');
  factory BranchException.managerNotFound() => BranchException('Manager user not found.');
  factory BranchException.firestoreFailure(String e) => BranchException('Database error: \$e');
}
