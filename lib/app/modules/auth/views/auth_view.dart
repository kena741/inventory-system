import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthController get controller => Get.find<AuthController>();

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final password = _passwordController.text.trim();
      if (controller.isSignUpMode.value) {
        controller.signUp(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: password,
        );
      } else {
        controller.login(_emailOrPhoneController.text.trim(), password);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              Colors.white,
              scheme.primary.withValues(alpha: 0.16),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Zulu Inventory',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock • Sales • Control',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final isSignUp = controller.isSignUpMode.value;
                          return Text(
                            isSignUp
                                ? 'Create your account'
                                : 'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                        Obx(
                          () => controller.errorMessage.value.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          controller.errorMessage.value,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Form(
                          key: _formKey,
                          child: Obx(() {
                            final isSignUp = controller.isSignUpMode.value;
                            return Column(
                              children: [
                                if (isSignUp) ...[
                                  TextFormField(
                                    controller: _emailController,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'name@example.com',
                                      prefixIcon:
                                          const Icon(Icons.email_outlined),
                                      filled: true,
                                      fillColor: scheme.primary
                                          .withValues(alpha: 0.06),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) return 'Email is required';
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'First Name',
                                            prefixIcon: const Icon(
                                              Icons.badge_outlined,
                                            ),
                                            filled: true,
                                            fillColor: scheme.primary
                                                .withValues(alpha: 0.06),
                                          ),
                                          validator: (value) {
                                            final v = value?.trim() ?? '';
                                            if (v.isEmpty) {
                                              return 'First name required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            prefixIcon: const Icon(
                                              Icons.badge_outlined,
                                            ),
                                            filled: true,
                                            fillColor: scheme.primary
                                                .withValues(alpha: 0.06),
                                          ),
                                          validator: (value) {
                                            final v = value?.trim() ?? '';
                                            if (v.isEmpty) {
                                              return 'Last name required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Phone',
                                      hintText: '09xxxxxxxx',
                                      prefixIcon:
                                          const Icon(Icons.phone_outlined),
                                      filled: true,
                                      fillColor: scheme.primary
                                          .withValues(alpha: 0.06),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) return 'Phone is required';
                                      if (v.length < 9) {
                                        return 'Enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  TextFormField(
                                    controller: _emailOrPhoneController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Email or Phone',
                                      hintText: 'Enter your email or phone',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: scheme.primary
                                          .withValues(alpha: 0.06),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) {
                                        return 'Email or phone is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  textInputAction: isSignUp
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: isSignUp ? null : (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: scheme.primary
                                        .withValues(alpha: 0.06),
                                  ),
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty) return 'Password is required';
                                    if (isSignUp && v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (isSignUp) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      hintText: 'Re-enter your password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      filled: true,
                                      fillColor: scheme.primary
                                          .withValues(alpha: 0.06),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) {
                                        return 'Confirm your password';
                                      }
                                      if (v != _passwordController.text.trim()) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 32),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  controller.isLoading.value ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      controller.isSignUpMode.value
                                          ? 'Create Account'
                                          : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Obx(() {
                            final isSignUp = controller.isSignUpMode.value;
                            return TextButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.toggleMode,
                              child: Text(
                                isSignUp
                                    ? 'Already have an account? Sign in'
                                    : 'New here? Create an account',
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
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

