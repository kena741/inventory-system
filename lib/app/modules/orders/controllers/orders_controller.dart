import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class OrdersController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshOrders();
  }

  Future<void> refreshOrders() async {
    try {
      isLoading.value = true;
      error.value = '';
      orders.value = await _repo.listCustomerOrders();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createOrder({
    required String customerName,
    String? clothCode,
    required int quantity,
    required num initialPayment,
    required num remainingPayment,
    num? totalAmount,
    DateTime? deliveryDate,
    String? description,
    String status = 'pending',
    String? customerInterest,
    String? customerAddress,
    String? customerNumber,
    String initialPaymentPaymentType = 'cash',
  }) async {
    final orderId = await _repo.createCustomerOrder(
      customerName: customerName,
      clothCode: clothCode,
      quantity: quantity,
      initialPayment: initialPayment,
      remainingPayment: remainingPayment,
      totalAmount: totalAmount,
      deliveryDate: deliveryDate,
      description: description,
      status: status,
      customerInterest: customerInterest,
      customerAddress: customerAddress,
      customerNumber: customerNumber,
      initialPaymentPaymentType: initialPaymentPaymentType,
    );
    await _repo.ensureMeasurementsForOrder(orderId: orderId, quantity: quantity);
    await refreshOrders();
  }
}

