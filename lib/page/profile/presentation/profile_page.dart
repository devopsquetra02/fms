import 'package:flutter/material.dart';
import 'package:fms/core/services/subscription.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../../../data/datasource/auth_remote_datasource.dart';
import '../../../data/models/response/profile_response_model.dart';
import '../../../data/datasource/profile_remote_datasource.dart';
import '../../../nav_bar.dart';
import '../../auth/presentation/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileResponseModel? _profile;
  bool _loading = true;
  final _profileDs = ProfileRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _profileDs.getProfile();
      if (mounted) {
        setState(() {
          _profile = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = subscriptionService.currentPlan == Plan.pro;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        //back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NavBar()),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.person),
                  ),
                  //from api
                  title: Text(
                    _loading
                        ? 'Loading...'
                        : (_profile?.data?.fullname ?? 'Unknown'),
                  ),
                  subtitle: Text(
                    _loading
                        ? 'Loading...'
                        : (_profile?.data?.email ?? 'Unknown'),
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPro
                          ? Colors.blue.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPro ? 'PRO' : 'BASIC',
                      style: TextStyle(
                        color: isPro
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<Plan>(
                        segments: const [
                          ButtonSegment(
                            value: Plan.basic,
                            label: Text('Basic'),
                          ),
                          ButtonSegment(value: Plan.pro, label: Text('Pro')),
                        ],
                        selected: {subscriptionService.currentPlan},
                        // Disabled - cannot change subscription from app
                        onSelectionChanged: null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPro
                            ? 'Pro plan includes map view and vehicle tracking'
                            : 'Basic plan - upgrade to Pro for map view and vehicle tracking',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  subtitle: const Text('help@efms.app'),
                  onTap: () {},
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    //show dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await AuthRemoteDataSource().logout();
                              if (mounted) {
                                SnackbarUtils(
                                  text: 'Logout successful',
                                  backgroundColor: Colors.green,
                                  icon: Icons.logout,
                                ).showSuccessSnackBar(context);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                              else {
                                SnackbarUtils(
                                  text: 'Logout failed',
                                  backgroundColor: Colors.red,
                                  icon: Icons.logout,
                                ).showErrorSnackBar(context);
                              }
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
