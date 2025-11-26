import 'package:flutter/material.dart';
import 'package:fms/core/services/subscription.dart';
import 'package:fms/page/jobs/presentation/jobs_page.dart';
import 'package:fms/page/upgrade_required/presentation/upgrade_required_page.dart';

/// A gatekeeper widget that shows the Jobs page for Pro users
/// or an upgrade prompt for basic users.
class JobsGateTab extends StatelessWidget {
  const JobsGateTab({super.key});

  @override
  Widget build(BuildContext context) {
    //if pro, return Jobs page
    //if basic, return Upgrade required page
    if (subscriptionService.currentPlan == Plan.pro) {
      return const JobsPage();
    }
    return const UpgradeRequiredPage();
    // return const JobsPage();
  }
}
