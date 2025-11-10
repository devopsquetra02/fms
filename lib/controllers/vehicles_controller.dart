import 'dart:developer';

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
  final RxMap<String, int> groupCounts = <String, int>{}.obs;
  
  // Dynamic mapping of group IDs to group names from API
  final RxMap<int, String> groupIdToName = <int, String>{}.obs;

  List<TraxrootObjectModel> get filteredObjects {
    final q = query.value.trim().toLowerCase();
    return objects.where((v) {
      // Check if vehicle belongs to selected group
      bool matchGroup = selectedGroup.value == null || selectedGroup.value!.isEmpty;
      
      if (!matchGroup && selectedGroup.value != null) {
        // Check if any of the vehicle's groups matches the selected group
        for (final group in v.groups) {
          // Group is an integer ID, convert to name
          int? groupId;
          if (group is int) {
            groupId = group;
          } else if (group is String) {
            groupId = int.tryParse(group);
          }
          
          if (groupId != null) {
            final groupName = groupIdToName[groupId];
            if (groupName == selectedGroup.value) {
              matchGroup = true;
              break;
            }
          }
        }
      }
      
      final name = (v.name ?? '').toLowerCase();
      final comment = (v.main?.comment ?? '').toLowerCase();
      final matchText = q.isEmpty || name.contains(q) || comment.contains(q);
      return matchGroup && matchText;
    }).toList();
  }

  int get totalVehicleCount => objects.length;

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
      final objectGroups = await _objectsDatasource.getObjectGroups();
      
      final iconMap = <int, TraxrootIconModel>{};
      for (final icon in icons) {
        final id = icon.id;
        if (id != null) {
          iconMap[id] = icon;
        }
      }

      objects.value = objectsData;
      iconsById.value = iconMap;
      
      // Build group ID to name mapping from API
      final groupMapping = <int, String>{};
      for (final group in objectGroups) {
        if (group.groupId > 0 && group.name != null && group.name!.isNotEmpty) {
          groupMapping[group.groupId] = group.name!;
        }
      }
      groupIdToName.value = groupMapping;
      
      log('Object groups count: ${objectGroups.length}', name: 'VehiclesController.loadData');
      log('Group mapping: $groupMapping', name: 'VehiclesController.loadData');
      
      // Build group list with counts from groups field
      final groupCountMap = <String, int>{};
      
      // Log sample vehicle groups for debugging
      if (objectsData.isNotEmpty) {
        final sampleVehicles = objectsData.take(3).toList();
        for (var v in sampleVehicles) {
          log('Vehicle ${v.name}: groups = ${v.groups}', name: 'VehiclesController.loadData');
        }
      }
      
      for (final obj in objectsData) {
        // Extract group IDs from groups array and convert to names
        if (obj.groups.isNotEmpty) {
          for (final group in obj.groups) {
            // Groups are integer IDs
            int? groupId;
            if (group is int) {
              groupId = group;
            } else if (group is String) {
              groupId = int.tryParse(group);
            }
            
            if (groupId != null) {
              final groupName = groupIdToName[groupId];
              if (groupName != null && groupName.isNotEmpty) {
                groupCountMap[groupName] = (groupCountMap[groupName] ?? 0) + 1;
              }
            }
          }
        }
      }
      
      final groups = groupCountMap.keys.toList()..sort();
      
      log('Group count map: $groupCountMap', name: 'VehiclesController.loadData');
      log('Available groups: $groups', name: 'VehiclesController.loadData');
      
      availableGroups.value = groups;
      groupCounts.value = groupCountMap;
      
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
