import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class OrderDetailController extends GetxController {
  final _repo = ErpRepository();

  final String orderId;
  final int quantity;
  OrderDetailController({required this.orderId, required this.quantity});

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> measurements = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> order = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refreshMeasurements();
  }

  Future<void> refreshMeasurements() async {
    try {
      isLoading.value = true;
      error.value = '';
      final o = await _repo.getCustomerOrder(orderId);
      if (o != null) {
        order.assignAll(o);
      }
      await _repo.ensureMeasurementsForOrder(orderId: orderId, quantity: quantity);
      measurements.value = await _repo.listMeasurements(orderId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrderStatus(String status) async {
    await _repo.updateCustomerOrderStatus(orderId: orderId, status: status);
    await refreshMeasurements();
  }

  Future<void> setFinalPaymentPaymentType(String paymentType) async {
    await _repo.updateCustomerOrderFinalPaymentType(
      orderId: orderId,
      finalPaymentPaymentType: paymentType,
    );
    await refreshMeasurements();
  }

  Future<void> saveMeasurement({
    required String measurementId,
    String? customerLabel,
    num? height,
    num? chest,
    num? waist,
    num? hip,
    num? shoulder,
    num? sleeveLength,
    num? neck,
    num? inseam,
    num? thigh,
    num? calf,
    String? notes,
  }) async {
    await _repo.updateMeasurement(
      measurementId: measurementId,
      customerLabel: customerLabel,
      height: height,
      chest: chest,
      waist: waist,
      hip: hip,
      shoulder: shoulder,
      sleeveLength: sleeveLength,
      neck: neck,
      inseam: inseam,
      thigh: thigh,
      calf: calf,
      notes: notes,
    );
    await refreshMeasurements();
  }

  Future<void> saveMeasurementForItem({
    required int itemIndex,
    String? customerLabel,
    num? height,
    num? chest,
    num? waist,
    num? hip,
    num? shoulder,
    num? sleeveLength,
    num? neck,
    num? inseam,
    num? thigh,
    num? calf,
    String? notes,
  }) async {
    final id = await _repo.ensureMeasurementRow(orderId: orderId, itemIndex: itemIndex);
    await saveMeasurement(
      measurementId: id,
      customerLabel: customerLabel,
      height: height,
      chest: chest,
      waist: waist,
      hip: hip,
      shoulder: shoulder,
      sleeveLength: sleeveLength,
      neck: neck,
      inseam: inseam,
      thigh: thigh,
      calf: calf,
      notes: notes,
    );
  }
}

