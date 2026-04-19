import 'package:get/get.dart';

import '../../../models/erp/enums.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../../core/services/erp_repository.dart';
import '../../../../core/utils/supabase_utils.dart';

/// Purchase-request lifecycle: manager → admin approval → manager orders →
/// seller confirms purchase → manager records receipt (meters, price, good/damaged).
abstract final class RawMaterialRequestStatuses {
  static const pending = 'pending';
  static const approved = 'approved';
  static const ordered = 'ordered';
  static const sellerConfirmed = 'seller_confirmed';
  static const completed = 'completed';
  static const rejected = 'rejected';
}

/// Values stored in `raw_material_requests.workflow_audit[].kind`.
abstract final class WorkflowAuditKind {
  static const requestCreated = 'request_created';
  static const adminApproved = 'admin_approved';
  static const adminRejected = 'admin_rejected';
  static const managerOrdered = 'manager_ordered';
  static const sellerConfirmed = 'seller_confirmed';
  static const requestCompleted = 'request_completed';
}

class RawMaterialRequestsController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;

  final RxBool isMaterialsLoading = false.obs;
  final RxString materialsError = ''.obs;
  final RxList<Map<String, dynamic>> materials = <Map<String, dynamic>>[].obs;

  /// For receipt dialog: vendors (admin-managed).
  final RxList<Map<String, dynamic>> vendors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshRequests();
    refreshMaterials();
    refreshVendors();
  }

  UserRole _role() =>
      parseUserRole(Get.find<AuthController>().currentUser.value?.role);

  String _actorDisplayName() {
    final u = Get.find<AuthController>().currentUser.value;
    if (u == null) return '';
    final n = u.fullName.trim();
    if (n.isNotEmpty) return n;
    final e = (u.email ?? '').trim();
    if (e.isNotEmpty) return e;
    final p = u.phone.trim();
    if (p.isNotEmpty) return p;
    return '';
  }

  Map<String, dynamic>? _requestById(String id) {
    for (final r in requests) {
      if ((r['id']?.toString() ?? '') == id) return r;
    }
    return null;
  }

  String _normStatus(Map<String, dynamic>? r) =>
      (r?['status']?.toString() ?? RawMaterialRequestStatuses.pending)
          .trim()
          .toLowerCase();

  Future<void> refreshRequests() async {
    try {
      isLoading.value = true;
      error.value = '';
      requests.value = await _repo.listRawMaterialRequests();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshMaterials() async {
    try {
      isMaterialsLoading.value = true;
      materialsError.value = '';
      materials.value = await _repo.listRawMaterials();
    } catch (e) {
      materialsError.value = e.toString();
    } finally {
      isMaterialsLoading.value = false;
    }
  }

  Future<void> refreshVendors() async {
    try {
      vendors.value = await _repo.listVendors();
    } catch (_) {
      vendors.value = <Map<String, dynamic>>[];
    }
  }

  Future<void> createRequest({
    required String materialName,
    required String unit,
    required num quantity,
    String? notes,
  }) async {
    if (_role() != UserRole.manager) {
      Get.snackbar('Not allowed', 'Only managers can create purchase requests.');
      return;
    }
    await _repo.createRawMaterialRequest(
      materialName: materialName,
      unit: unit,
      quantity: quantity,
      notes: notes,
      actorName: _actorDisplayName(),
    );
    await refreshRequests();
  }

  Future<void> createRequestsBatch({
    required List<Map<String, dynamic>> items,
    required String notes,
  }) async {
    if (_role() != UserRole.manager) {
      Get.snackbar('Not allowed', 'Only managers can create purchase requests.');
      return;
    }
    await _repo.createRawMaterialRequestJsonb(
      items: items,
      notes: notes,
      actorName: _actorDisplayName(),
    );
    await refreshRequests();
  }

  Future<void> adminApprove(String id) async {
    if (_role() != UserRole.admin) {
      Get.snackbar('Not allowed', 'Only an admin can approve requests.');
      return;
    }
    if (_normStatus(_requestById(id)) != RawMaterialRequestStatuses.pending) {
      Get.snackbar('Invalid state', 'Only pending requests can be approved.');
      return;
    }
    final uid = SupabaseUtils.getCurrentUid() ?? '';
    await _repo.appendRawMaterialRequestWorkflowEvent(
      id: id,
      rowPatch: {'status': RawMaterialRequestStatuses.approved},
      kind: WorkflowAuditKind.adminApproved,
      actorUserId: uid,
      actorName: _actorDisplayName(),
      actorRole: UserRole.admin.name,
    );
    await refreshRequests();
  }

  Future<void> adminReject(String id) async {
    if (_role() != UserRole.admin) {
      Get.snackbar('Not allowed', 'Only an admin can reject requests.');
      return;
    }
    if (_normStatus(_requestById(id)) != RawMaterialRequestStatuses.pending) {
      Get.snackbar('Invalid state', 'Only pending requests can be rejected.');
      return;
    }
    final uid = SupabaseUtils.getCurrentUid() ?? '';
    await _repo.appendRawMaterialRequestWorkflowEvent(
      id: id,
      rowPatch: {'status': RawMaterialRequestStatuses.rejected},
      kind: WorkflowAuditKind.adminRejected,
      actorUserId: uid,
      actorName: _actorDisplayName(),
      actorRole: UserRole.admin.name,
    );
    await refreshRequests();
  }

  Future<void> managerMarkOrdered(String id) async {
    if (_role() != UserRole.manager) {
      Get.snackbar('Not allowed', 'Only a manager can mark a request as ordered.');
      return;
    }
    if (_normStatus(_requestById(id)) != RawMaterialRequestStatuses.approved) {
      Get.snackbar(
        'Invalid state',
        'The purchase order must be approved before ordering.',
      );
      return;
    }
    final uid = SupabaseUtils.getCurrentUid() ?? '';
    await _repo.appendRawMaterialRequestWorkflowEvent(
      id: id,
      rowPatch: {'status': RawMaterialRequestStatuses.ordered},
      kind: WorkflowAuditKind.managerOrdered,
      actorUserId: uid,
      actorName: _actorDisplayName(),
      actorRole: UserRole.manager.name,
    );
    await refreshRequests();
  }

  Future<void> sellerConfirmPurchased(String id) async {
    if (_role() != UserRole.seller) {
      Get.snackbar('Not allowed', 'Only a seller can confirm the purchase.');
      return;
    }
    if (_normStatus(_requestById(id)) != RawMaterialRequestStatuses.ordered) {
      Get.snackbar(
        'Invalid state',
        'The manager must mark this request as ordered first.',
      );
      return;
    }
    final uid = SupabaseUtils.getCurrentUid() ?? '';
    await _repo.appendRawMaterialRequestWorkflowEvent(
      id: id,
      rowPatch: {'status': RawMaterialRequestStatuses.sellerConfirmed},
      kind: WorkflowAuditKind.sellerConfirmed,
      actorUserId: uid,
      actorName: _actorDisplayName(),
      actorRole: UserRole.seller.name,
    );
    await refreshRequests();
  }

  Future<void> managerCompleteWithReceipt({
    required String id,
    required List<Map<String, dynamic>> lines,
    DateTime? purchaseDate,
  }) async {
    if (_role() != UserRole.manager) {
      Get.snackbar('Not allowed', 'Only a manager can record the receipt.');
      return;
    }
    if (_normStatus(_requestById(id)) !=
        RawMaterialRequestStatuses.sellerConfirmed) {
      Get.snackbar(
        'Invalid state',
        'The seller must confirm the purchase before you record receipt.',
      );
      return;
    }
    if (lines.isEmpty) {
      Get.snackbar('Receipt', 'Add at least one line with quantities.');
      return;
    }
    final uid = SupabaseUtils.getCurrentUid() ?? '';
    final receipt = <String, dynamic>{
      'lines': lines,
      'purchase_date': (purchaseDate ?? DateTime.now()).toIso8601String(),
      'recorded_at': DateTime.now().toIso8601String(),
      'recorded_by': uid,
    };
    await _repo.completeRawMaterialRequestWithReceipt(
      id: id,
      managerReceipt: receipt,
      auditActorUserId: uid,
      auditActorName: _actorDisplayName(),
      auditActorRole: UserRole.manager.name,
    );
    await refreshRequests();
    await refreshMaterials();
  }

  /// Legacy: admin could set any status. Kept for older data tooling if needed.
  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    if (_role() != UserRole.admin) {
      Get.snackbar('Not allowed', 'Only admin can change request status.');
      return;
    }
    await _repo.updateRawMaterialRequestStatus(id: id, status: status);
    await refreshRequests();
  }
}
