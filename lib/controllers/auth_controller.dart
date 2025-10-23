import 'package:get/get.dart';
import 'package:fms/core/constants/variables.dart';
import 'package:fms/core/storage/secure_storage.dart';
import 'package:fms/page/auth/presentation/login_page.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString apiKey = ''.obs;
  final _storage = SecureStorage();

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      final token = await _storage.read(Variables.prefApiKey);
      if (token != null && token.isNotEmpty) {
        apiKey.value = token;
        isAuthenticated.value = true;
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String token) async {
    await _storage.write(Variables.prefApiKey, token);
    apiKey.value = token;
    isAuthenticated.value = true;
  }

  Future<void> logout() async {
    // Clear all data
    await _storage.deleteAll();
    apiKey.value = '';
    isAuthenticated.value = false;
    
    // Redirect to login page
    Get.offAll(() => const LoginPage());
  }
}
