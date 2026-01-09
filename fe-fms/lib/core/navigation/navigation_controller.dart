import 'package:get/get.dart';

/// Controller for managing the bottom navigation bar state.
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxList<String> _titles = <String>['Dashboard', 'Vehicles', 'Jobs'].obs;

  /// Expose titles so UI can build tabs/destinations dynamically.
  RxList<String> get titles => _titles;

  /// Configures the available tabs based on the user's subscription status and role.
  ///
  /// [isPro] - Whether the user has a Pro subscription.
  /// [role] - Optional user role: 'monitor' or 'field'.
  void configureTabs({required bool isPro, String? role}) {
    final List<String> newTitles;
    if (isPro) {
      if (role == 'field') {
        newTitles = const ['Dashboard', 'Jobs'];
      } else if (role == 'monitor') {
        newTitles = const ['Dashboard', 'Vehicles'];
      } else {
        newTitles = const ['Dashboard', 'Vehicles', 'Jobs'];
      }
    } else {
      newTitles = const ['Dashboard', 'Vehicles'];
    }

    if (!_titlesMatch(newTitles)) {
      _titles.assignAll(newTitles);
      selectedIndex.value = 0;
    } else if (selectedIndex.value >= _titles.length) {
      selectedIndex.value = 0;
    }
  }

  /// Changes the currently selected tab index.
  void changeTab(int index) {
    if (index < 0 || index >= _titles.length) return;
    selectedIndex.value = index;
  }

  String get currentTitle =>
      (_titles.isNotEmpty && selectedIndex.value < _titles.length)
          ? _titles[selectedIndex.value]
          : '';

  bool _titlesMatch(List<String> other) {
    if (_titles.length != other.length) return false;
    for (var i = 0; i < _titles.length; i++) {
      if (_titles[i] != other[i]) {
        return false;
      }
    }
    return true;
  }
}