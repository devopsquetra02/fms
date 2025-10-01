import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermission {
  static Future<bool> ensurePhotosPermission(BuildContext context) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        final goToSettings = await _showSettingsDialog(
          context,
          'Aplikasi memerlukan akses Foto untuk mengunggah bukti pekerjaan. Buka Pengaturan untuk memberikan izin.',
        );
        if (goToSettings) {
          await openAppSettings();
        }
      }
      return false;
    } else {
      // Android: use storage permission (the plugin maps correctly depending on SDK), and we also declare READ_MEDIA_IMAGES in manifest for Android 13+
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        final goToSettings = await _showSettingsDialog(
          context,
          'Aplikasi memerlukan akses Penyimpanan/Foto untuk mengunggah bukti pekerjaan. Buka Pengaturan untuk memberikan izin.',
        );
        if (goToSettings) {
          await openAppSettings();
        }
      }
      return false;
    }
  }

  static Future<bool> _showSettingsDialog(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin Diperlukan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
