import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../page/profile/presentation/profile_page.dart';

/// A custom app bar widget with a logo and profile action.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/images/logo.jpg', width: 25, height: 25),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Get.to(() => const ProfilePage());
          },
        ),
      ],
    );
  }
}
