import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/page/home/presentation/home_page.dart';
import 'package:fms/page/vehicles/presentation/vehicles_page.dart';
import 'package:fms/page/jobs/presentation/jobs_gate_tab.dart';
import 'package:fms/controllers/navigation_controller.dart';
import 'core/widgets/app_bar_widget.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavigationController());

    final tabs = const [
      HomeTab(),
      VehiclesPage(),
      JobsGateTab(),
    ];

    return Obx(() => Scaffold(
      appBar: AppBarWidget(title: navController.currentTitle),
      body: IndexedStack(
        index: navController.selectedIndex.value,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navController.selectedIndex.value,
        onDestinationSelected: navController.changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Jobs',
          ),
        ],
      ),
    ));
  }
}
