import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/models/doctor_model.dart';
import 'package:surebook/shared/providers/appointment_provider.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/widgets/custom_button.dart';
import 'package:surebook/widgets/custom_text_field.dart';
import 'package:surebook/screens/main_navigation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime date;
  final String timeSlot;
  final String notes;

  const PaymentScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.timeSlot,
    required this.notes,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    _animationController.forward();

    // Pre-fill cardholder name with user name
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.currentUser?.name ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    if (value.replaceAll(' ', '').length < 16) {
      return 'Please enter a valid card number';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (value.length < 5) {
      return 'Please enter a valid expiry date';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length < 3) {
      return 'Please enter a valid CVV';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter cardholder name';
    }
    return null;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Book the appointment
      final success = await appointmentProvider.bookAppointment(
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        patientId: authProvider.currentUser!.id,
        date: widget.date,
        timeSlot: widget.timeSlot,
        fee: widget.doctor.consultationFee,
        notes: widget.notes.isEmpty ? null : widget.notes,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception(appointmentProvider.errorMessage ?? 'Failed to book appointment');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            const Text('Appointment Booked! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your appointment with Dr. ${widget.doctor.name} has been confirmed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Column(
                children: [
                  Text(
                    '📅 ${widget.date.day}/${widget.date.month}/${widget.date.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '🕐 ${widget.timeSlot}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Done',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(initialIndex: 1),
                ),
                (route) => false,
              );
            },
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        
                        _buildSummaryRow('Doctor', widget.doctor.name),
                        _buildSummaryRow('Specialty', widget.doctor.specialty),
                        _buildSummaryRow('Date', '${widget.date.day}/${widget.date.month}/${widget.date.year}'),
                        _buildSummaryRow('Time', widget.timeSlot),
                        
                        const Divider(),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Consultation Fee',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '\$${widget.doctor.consultationFee.toInt()}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXLarge),

                  // Payment Method
                  Text(
                    'Payment Method 💳',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // Payment Card
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'BANK CARD',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 2,
                                ),
                              ),
                              Icon(
                                Icons.credit_card,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          Text(
                            _cardNumberController.text.isEmpty
                                ? '**** **** **** ****'
                                : _cardNumberController.text
                                    .replaceAll(RegExp(r'\d(?=\d{4})'), '*'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                          
                          const SizedBox(height: AppConstants.paddingMedium),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CARDHOLDER NAME',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    _nameController.text.isEmpty
                                        ? 'YOUR NAME'
                                        : _nameController.text.toUpperCase(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EXPIRES',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    _expiryController.text.isEmpty
                                        ? 'MM/YY'
                                        : _expiryController.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXLarge),

                  // Card Details Form
                  CustomTextField(
                    label: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.credit_card,
                    validator: _validateCardNumber,
                    onChanged: (value) {
                      setState(() {}); // Update card preview
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Expiry Date',
                          hintText: 'MM/YY',
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.date_range,
                          validator: _validateExpiry,
                          onChanged: (value) {
                            setState(() {}); // Update card preview
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: CustomTextField(
                          label: 'CVV',
                          hintText: '123',
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.lock,
                          validator: _validateCVV,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  CustomTextField(
                    label: 'Cardholder Name',
                    hintText: 'John Doe',
                    controller: _nameController,
                    prefixIcon: Icons.person,
                    validator: _validateName,
                    onChanged: (value) {
                      setState(() {}); // Update card preview
                    },
                  ),

                  const SizedBox(height: AppConstants.paddingXLarge * 2),
                ],
              ),
            ),
          ),
        ),
      ),

      // Bottom Payment Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Pay \$${widget.doctor.consultationFee.toInt()}',
            onPressed: _processPayment,
            isLoading: _isProcessing,
            icon: Icons.payment,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}