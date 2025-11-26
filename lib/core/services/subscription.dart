/// Enum representing the user's subscription plan.
enum Plan { basic, pro }

/// Service for managing subscription-related logic.
class SubscriptionService {
  Plan currentPlan;
  SubscriptionService({this.currentPlan = Plan.basic});

  bool get hasJobsAccess => currentPlan == Plan.pro;
}

final subscriptionService = SubscriptionService();
