import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/page/home/presentation/home_page.dart';
import 'package:fms/page/vehicles/presentation/vehicles_page.dart';
import 'package:fms/page/jobs/presentation/jobs_gate_tab.dart';
import 'package:fms/controllers/navigation_controller.dart';
import 'package:fms/core/services/subscription.dart';
import 'core/widgets/app_bar_widget.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavigationController());
    final isPro = subscriptionService.currentPlan == Plan.pro;

    // Ensure controller titles/tabs stay in sync with subscription level
    navController.configureTabs(isPro: isPro);

    // Basic users only see Home and Jobs
    // Pro users see Home, Vehicles, and Jobs
    final tabs = isPro
        ? const [
            HomeTab(),
            VehiclesPage(),
            JobsGateTab(),
          ]
        : const [
            HomeTab(),
            JobsGateTab(),
          ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // If not on home tab, navigate to home first
        if (navController.selectedIndex.value != 0) {
          navController.changeTab(0);
        } else {
          // Already on home, exit app
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to exit the application?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          
          if (shouldExit == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Obx(() => Scaffold(
        appBar: AppBarWidget(title: navController.currentTitle),
        body: IndexedStack(
          index: navController.selectedIndex.value,
          children: tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navController.selectedIndex.value,
          onDestinationSelected: navController.changeTab,
          destinations: isPro
              ? const [
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
                ]
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.list_alt_outlined),
                    selectedIcon: Icon(Icons.list_alt),
                    label: 'Jobs',
                  ),
                ],
        ),
      )),
    );
  }
}
