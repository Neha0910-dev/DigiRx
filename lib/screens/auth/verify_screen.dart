import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/screens/auth/login_screen.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/widgets/custom_button.dart';
import 'package:surebook/widgets/custom_text_field.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String mobile;
  final bool isSignup;

  const VerifyOtpScreen({
    super.key,
    required this.mobile,
    this.isSignup = false,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.verifySignupOtp(
        mobile: widget.mobile,
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Invalid OTP'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Verify OTP 🔐',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Enter the OTP sent to +91-${widget.mobile}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXLarge),
                CustomTextField(
                  label: 'OTP',
                  hintText: 'Enter OTP',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter OTP';
                    }
                    if (value.length < 4) {
                      return 'Enter valid OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingXLarge),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Verify',
                      onPressed: _verifyOtp,
                      isLoading: authProvider.isLoading,
                      icon: Icons.check_circle_outline,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
