import 'package:flutter/widgets.dart';

/// Service for global navigation access without context.
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
