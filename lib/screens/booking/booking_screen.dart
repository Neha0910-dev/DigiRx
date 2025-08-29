import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/models/doctor_model.dart';
import 'package:surebook/shared/providers/appointment_provider.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/widgets/custom_button.dart';
import 'package:surebook/widgets/time_slot_selector.dart';
import 'package:surebook/screens/booking/payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;

  const BookingScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  final TextEditingController _notesController = TextEditingController();

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  List<String> _getAvailableTimeSlots() {
    // Check if selected date is available for this doctor
    final dayName = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][_selectedDate.weekday % 7];
    
    if (!widget.doctor.availableDays.contains(dayName)) {
      return [];
    }
    
    return widget.doctor.availableTimeSlots;
  }

  List<String> _getBookedSlots() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    return appointmentProvider.getBookedSlotsForDate(widget.doctor.id, _selectedDate);
  }

  void _proceedToPayment() {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          doctor: widget.doctor,
          date: _selectedDate,
          timeSlot: _selectedTimeSlot!,
          notes: _notesController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final availableSlots = _getAvailableTimeSlots();
    final bookedSlots = _getBookedSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Info Card
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          image: DecorationImage(
                            image: NetworkImage(widget.doctor.profileImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctor.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.doctor.specialty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fee: \$${widget.doctor.consultationFee.toInt()}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXLarge),

                // Date Selection
                Text(
                  'Select Date',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} - ${['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][_selectedDate.weekday % 7]}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingXLarge),

                // Time Slot Selection
                if (availableSlots.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        Text(
                          'Doctor not available on this date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          'Please select a different date',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Morning Slots
                  if (availableSlots.any((slot) => AppConstants.morningSlots.contains(slot))) ...[
                    TimeSlotSelector(
                      title: 'Morning Slots 🌅',
                      timeSlots: availableSlots.where((slot) => AppConstants.morningSlots.contains(slot)).toList(),
                      bookedSlots: bookedSlots,
                      selectedSlot: _selectedTimeSlot,
                      onSlotSelected: (slot) {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],

                  // Afternoon Slots
                  if (availableSlots.any((slot) => AppConstants.afternoonSlots.contains(slot))) ...[
                    TimeSlotSelector(
                      title: 'Afternoon Slots ☀️',
                      timeSlots: availableSlots.where((slot) => AppConstants.afternoonSlots.contains(slot)).toList(),
                      bookedSlots: bookedSlots,
                      selectedSlot: _selectedTimeSlot,
                      onSlotSelected: (slot) {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],

                  // Evening Slots
                  if (availableSlots.any((slot) => AppConstants.eveningSlots.contains(slot))) ...[
                    TimeSlotSelector(
                      title: 'Evening Slots 🌙',
                      timeSlots: availableSlots.where((slot) => AppConstants.eveningSlots.contains(slot)).toList(),
                      bookedSlots: bookedSlots,
                      selectedSlot: _selectedTimeSlot,
                      onSlotSelected: (slot) {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],

                  // Notes Section
                  Text(
                    'Additional Notes (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms or concerns...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXLarge * 2),
                ],
              ],
            ),
          ),
        ),
      ),

      // Bottom Button
      bottomNavigationBar: availableSlots.isNotEmpty
          ? Container(
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
                  text: 'Proceed to Payment',
                  onPressed: _proceedToPayment,
                  icon: Icons.payment,
                ),
              ),
            )
          : null,
    );
  }
}