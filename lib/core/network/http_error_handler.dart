import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/controllers/auth_controller.dart';

class HttpErrorHandler {
  static void handleResponse(int statusCode, String responseBody) {
    if (statusCode == 401) {
      _handleUnauthorized();
    }
  }

  static void _handleUnauthorized() {
    // Get AuthController
    try {
      final authController = Get.find<AuthController>();
      
      // Clear all data and redirect to login
      authController.logout();
      
      // Show snackbar using Flutter's SnackBar (not Get.snackbar)
      final context = Get.context;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If AuthController not found, just log the error
      debugPrint('Error handling unauthorized: $e');
    }
  }

  static Exception createException(int statusCode, String responseBody) {
    handleResponse(statusCode, responseBody);
    return Exception('HTTP $statusCode: $responseBody');
  }
}
