import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  final List<String> titles = const [
    'Dashboard',
    'Vehicles',
    'Jobs',
  ];

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  String get currentTitle => titles[selectedIndex.value];
}
