import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fms/core/widgets/snackbar_utils.dart';
import 'package:fms/nav_bar.dart';
import 'package:fms/core/constants/variables.dart';
import 'package:fms/data/datasource/auth_remote_datasource.dart';
import 'package:fms/core/services/subscription.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:fms/core/services/traxroot_credentials_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/auth_button.dart';
import '../widget/auth_text_field.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _dataSource = AuthRemoteDataSource();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final res = await _dataSource.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      final apiKey = res.data?.apiKey;
      final userID = res.data?.userId;
      final company = res.data?.company;
      final companyId = res.data?.companyId;
      final companyType = res.data?.companyType;
      final companyLabel = res.data?.companyLabel;
      final usernameTraxroot = res.data?.usernameTraxroot;
      final passwordTraxroot = res.data?.passwordTraxroot;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Error fetch data');
      }

      // Save all data to SharedPreferences
      await prefs.setString(Variables.prefApiKey, apiKey);
      log(userID.toString(), name: 'Login', level: 800);

      if (userID != null && userID.toString().isNotEmpty) {
        await prefs.setString(Variables.prefUserID, userID.toString());
      }

      if (company != null) {
        await prefs.setString(Variables.prefCompany, company);
      }

      if (companyId != null) {
        await prefs.setInt(Variables.prefCompanyID, companyId);
      }

      if (companyType != null) {
        await prefs.setInt(Variables.prefCompanyType, companyType);
        // Initialize subscription service based on company type
        // 1 = basic, 2 = pro
        subscriptionService.currentPlan = companyType == 2
            ? Plan.pro
            : Plan.basic;
        log(
          'Company type: $companyType, Plan: ${subscriptionService.currentPlan}',
          name: 'Login',
          level: 800,
        );
      }

      if (companyLabel != null) {
        await prefs.setString(Variables.prefCompanyLabel, companyLabel);
      }

      await TraxrootCredentialsManager.cache(
        username: usernameTraxroot,
        password: passwordTraxroot,
        prefs: prefs,
      );

      // Reset ApiClient logout flag for new login session
      ApiClient.resetLogoutFlag();

      if (!mounted) return;
      SnackbarUtils(
        text: 'Login Success',
        backgroundColor: Colors.green,
      ).showSuccessSnackBar(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavBar()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Login Failed';
      // Extract error message from exception
      final exceptionMessage = e.toString();
      if (exceptionMessage.startsWith('Exception: ')) {
        errorMessage = exceptionMessage.substring('Exception: '.length);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo and Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 85,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to E-FMS',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Email Field
                  AuthTextField(
                    label: 'Email',
                    hint: 'Fill your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Invalid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Password Field
                  AuthTextField(
                    label: 'Password',
                    hint: 'Fill your password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 4) {
                        return 'Password must be at least 4 characters long';
                      }
                      // if (!RegExp(
                      //   r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
                      // ).hasMatch(value)) {
                      //   return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
                      // }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Register Button
                  AuthButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
