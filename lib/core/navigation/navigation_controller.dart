import 'package:get/get.dart';

/// Controller for managing the bottom navigation bar state.
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxList<String> _titles = <String>['Dashboard', 'Vehicles', 'Jobs'].obs;

  /// Configures the available tabs based on the user's subscription status.
  ///
  /// [isPro] - Whether the user has a Pro subscription.
  void configureTabs({required bool isPro}) {
    final newTitles = isPro
        ? const ['Dashboard', 'Vehicles', 'Jobs']
        : const ['Dashboard', 'Jobs'];

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

  String get currentTitle => _titles[selectedIndex.value];

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
