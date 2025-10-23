// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart' hide Response;
// import 'package:fms/controllers/auth_controller.dart';

// class ApiInterceptor extends Interceptor {
//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) {
//     // Check for 401 Unauthorized
//     if (err.response?.statusCode == 401) {
//       _handleUnauthorized();
//       return handler.reject(err);
//     }

//     super.onError(err, handler);
//   }

//   void _handleUnauthorized() {
//     // Get AuthController
//     final authController = Get.find<AuthController>();
    
//     // Clear all data
//     authController.logout();
    
//     // Show snackbar using Flutter's SnackBar (not Get.snackbar)
//     final context = Get.context;
//     if (context != null && context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Session expired. Please login again.'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }
// }
