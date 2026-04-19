enum UserRole { admin, manager, tailor, seller }

enum LocationType { manufacturing, warehouse, retail }

enum TransactionType { purchase, production, transfer, sale, adjustment }

enum OrderStatus { pending, inProgress, completed, cancelled }

enum PaymentStatus { pending, paid }

enum ExpenseCategory { rent, salary, transport, utilities, other }

extension EnumParsing on String {
  UserRole? toUserRole() {
    final normalized = trim().toLowerCase();
    return UserRole.values.cast<UserRole?>().firstWhere(
          (e) => e!.name.toLowerCase() == normalized,
          orElse: () => null,
        );
  }

  LocationType? toLocationType() {
    return LocationType.values.cast<LocationType?>().firstWhere(
          (e) => e!.name == this,
          orElse: () => null,
        );
  }

  OrderStatus? toOrderStatus() {
    return OrderStatus.values.cast<OrderStatus?>().firstWhere(
          (e) => e!.name == this,
          orElse: () => null,
        );
  }

  PaymentStatus? toPaymentStatus() {
    return PaymentStatus.values.cast<PaymentStatus?>().firstWhere(
          (e) => e!.name == this,
          orElse: () => null,
        );
  }

  ExpenseCategory? toExpenseCategory() {
    return ExpenseCategory.values.cast<ExpenseCategory?>().firstWhere(
          (e) => e!.name == this,
          orElse: () => null,
        );
  }
}

UserRole parseUserRole(String? role) {
  final normalized = (role ?? '').trim().toLowerCase();
  if (normalized.isEmpty) return UserRole.seller;

  switch (normalized) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'tailor':
      return UserRole.tailor;
    case 'seller':
      return UserRole.seller;
    default:
      // Backward/legacy roles
      if (normalized == 'waiter' || normalized == 'cashier') return UserRole.seller;
      return UserRole.seller;
  }
}

