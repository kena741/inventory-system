import 'package:get/get.dart';

import '../../../../core/services/erp_repository.dart';

class TimeLogsController extends GetxController {
  final _repo = ErpRepository();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> logs = <Map<String, dynamic>>[].obs;
  final RxBool isClockedIn = false.obs;
  final Rx<DateTime?> activeClockIn = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = '';
      logs.value = await _repo.listMyTimeLogs();
      final active = await _repo.getMyActiveClockIn();
      activeClockIn.value = active;
      isClockedIn.value = active != null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleClock() async {
    if (isClockedIn.value) {
      await _repo.clockOut();
    } else {
      await _repo.clockIn();
    }
    await load();
  }
}

