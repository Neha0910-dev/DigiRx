import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/providers/appointment_provider.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/shared/models/appointment_model.dart';
import 'package:surebook/widgets/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await appointmentProvider.loadAppointments(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
            const SizedBox(width: 8),
            const Text(
              "DigiRx",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 25,
            ),
            const Text(
              "My Appointments",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 25),
            ),
            const Text(
              "Manage your medical appointments",
              style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  fontSize: 16),
            ),
            SizedBox(
              height: 25,
            ),
            // TabBar kept outside AppBar
            Consumer<AppointmentProvider>(
              builder: (context, appointmentProvider, child) {
                final upcomingCount = appointmentProvider
                    .getAppointmentsByStatus(AppointmentStatus.upcoming)
                    .length;
                final completedCount = appointmentProvider
                    .getAppointmentsByStatus(AppointmentStatus.completed)
                    .length;
                final cancelledCount = appointmentProvider
                    .getAppointmentsByStatus(AppointmentStatus.cancelled)
                    .length;

                return Material(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  child: PreferredSize(
                    preferredSize: const Size.fromHeight(36),
                    child: SizedBox(
                      height: 36,
                      child: TabBar(
                        controller: _tabController,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        tabs: [
                          Tab(text: "Upcoming ($upcomingCount)"),
                          Tab(text: "Completed ($completedCount)"),
                          Tab(text: "Cancelled ($cancelledCount)"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(
                      AppointmentStatus.upcoming), // Upcoming tab
                  _buildAppointmentsList(
                      AppointmentStatus.completed), // Completed tab
                  _buildAppointmentsList(AppointmentStatus.cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(AppointmentStatus status) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        if (appointmentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final appointments =
            appointmentProvider.getAppointmentsByStatus(status);

        if (appointments.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: _loadAppointments,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
              itemCount: appointments.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppConstants.paddingSmall),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                print(appointment);
                print(appointment.doctorName);
                return AppointmentCard(
                  appointment: appointment,
                  onTap: () => _showAppointmentDetails(appointment),
                  onCancel: status == AppointmentStatus.upcoming
                      ? () => _cancelAppointment(appointment)
                      : null,
                  onReschedule: status == AppointmentStatus.upcoming
                      ? () => _rescheduleAppointment(appointment)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppointmentStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title, subtitle;
    IconData icon;

    switch (status) {
      case AppointmentStatus.upcoming:
        title = 'No Upcoming Appointments';
        subtitle = 'Book an appointment with a doctor to get started';
        icon = Icons.calendar_today_outlined;
        break;
      case AppointmentStatus.completed:
        title = 'No Completed Appointments';
        subtitle = 'Your completed appointments will appear here';
        icon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.cancelled:
        title = 'No Cancelled Appointments';
        subtitle = 'Your cancelled appointments will appear here';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAppointmentDetailsSheet(appointment),
    );
  }

  Widget _buildAppointmentDetailsSheet(Appointment appointment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Appointment Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Appointment Details
              _buildDetailRow('Doctor', appointment.doctorName, Icons.person),
              _buildDetailRow(
                  'Date', _formatDate(appointment.date), Icons.calendar_today),
              _buildDetailRow('Time', appointment.timeSlot, Icons.access_time),
              _buildDetailRow('Status', _getStatusText(appointment.status),
                  Icons.info_outline),
              if (appointment.notes!.isNotEmpty)
                _buildDetailRow('Notes', appointment.notes ?? '', Icons.note),

              const SizedBox(height: AppConstants.paddingLarge),

              // Actions
              if (appointment.status == AppointmentStatus.upcoming) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _cancelAppointment(appointment);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _rescheduleAppointment(appointment);
                        },
                        child: const Text('Reschedule'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    // if (confirmed == true) {
    //   final appointmentProvider =
    //       Provider.of<AppointmentProvider>(context, listen: false);
    //   await appointmentProvider.cancelAppointment(appointment.id);

    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('Appointment cancelled successfully'),
    //       ),
    //     );
    //   }
    // }
  }

  void _rescheduleAppointment(Appointment appointment) {
    // TODO: Navigate to reschedule screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule feature coming soon'),
      ),
    );
  }
}
