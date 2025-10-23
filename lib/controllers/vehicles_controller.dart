import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/traxroot_icon_model.dart';
import 'package:fms/data/models/traxroot_object_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';

class VehiclesController extends GetxController {
  final _objectsDatasource = TraxrootObjectsDatasource(TraxrootAuthDatasource());

  final RxBool isLoading = false.obs;
  final RxList<TraxrootObjectModel> objects = <TraxrootObjectModel>[].obs;
  final RxMap<int, TraxrootIconModel> iconsById = <int, TraxrootIconModel>{}.obs;
  final RxnInt loadingObjectId = RxnInt();
  final RxString query = ''.obs;
  final RxnString selectedGroup = RxnString();
  final RxList<String> availableGroups = <String>[].obs;

  List<TraxrootObjectModel> get filteredObjects {
    final q = query.value.trim().toLowerCase();
    return objects.where((v) {
      final matchGroup = selectedGroup.value == null || 
                        selectedGroup.value!.isEmpty || 
                        v.service?.serverGroup == selectedGroup.value;
      final name = (v.name ?? '').toLowerCase();
      final comment = (v.main?.comment ?? '').toLowerCase();
      final matchText = q.isEmpty || name.contains(q) || comment.contains(q);
      return matchGroup && matchText;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;

    try {
      final objectsData = await _objectsDatasource.getObjects();
      final icons = await _objectsDatasource.getObjectIcons();
      
      final iconMap = <int, TraxrootIconModel>{};
      for (final icon in icons) {
        final id = icon.id;
        if (id != null) {
          iconMap[id] = icon;
        }
      }

      objects.value = objectsData;
      iconsById.value = iconMap;
      
      final groups = objectsData
          .map((o) => o.service?.serverGroup)
          .where((g) => g != null && g.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();
      
      availableGroups.value = groups;
      
      if (selectedGroup.value != null && !availableGroups.contains(selectedGroup.value)) {
        selectedGroup.value = null;
      }

      _precacheIcons(iconMap);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load vehicles. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _precacheIcons(Map<int, TraxrootIconModel> iconMap) {
    if (iconMap.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = Get.context;
        if (context != null) {
          for (final icon in iconMap.values) {
            final url = icon.url;
            if (url != null && url.isNotEmpty) {
              precacheImage(NetworkImage(url), context);
            }
          }
        }
      });
    }
  }

  Future<TraxrootObjectStatusModel?> fetchObjectStatus(TraxrootObjectModel vehicle) async {
    final objectId = vehicle.id;

    if (objectId == null) {
      Get.snackbar(
        'Error',
        'ID kendaraan tidak tersedia.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    loadingObjectId.value = objectId;

    TraxrootObjectStatusModel? status;
    try {
      status = await _objectsDatasource.getLatestPoint(objectId: objectId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat detail kendaraan.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (loadingObjectId.value == objectId) {
        loadingObjectId.value = null;
      }
    }

    if (status != null) {
      return status;
    }

    return TraxrootObjectStatusModel(
      id: vehicle.id,
      name: vehicle.name,
      latitude: vehicle.latitude,
      longitude: vehicle.longitude,
      address: vehicle.address,
    );
  }

  void updateQuery(String value) {
    query.value = value;
  }

  void updateSelectedGroup(String? value) {
    selectedGroup.value = (value == null || value.isEmpty) ? null : value;
  }
}
