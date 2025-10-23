import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/theme/app_theme.dart';
import 'package:fms/page/auth/presentation/login_page.dart';
import 'package:fms/nav_bar.dart';
import 'package:fms/controllers/auth_controller.dart';

void main() {
  // Initialize controllers
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'E-FMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Obx(() {
      if (authController.isLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return authController.isAuthenticated.value 
          ? const NavBar() 
          : const LoginPage();
    });
  }
}
