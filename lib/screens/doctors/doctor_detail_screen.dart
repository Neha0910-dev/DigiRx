import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surebook/screens/main_navigation_screen.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/models/doctor_model.dart';
import 'package:surebook/shared/models/family_model.dart';
import 'package:surebook/shared/models/user_model.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/shared/providers/doctor_provider.dart';
import 'package:surebook/widgets/custom_button.dart';
import 'package:surebook/screens/booking/booking_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _selectedBranchId;
  DateTime? _selectedDate;
  String? _selectedTime;
  Future<List<FamilyMember>>? _familyMembersFuture;
  String? _selectedMemberId;
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
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _familyMembersFuture = fetchFamilyMembers(user.id);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> addMember({
    required String name,
    required String gender,
    required String age,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user_data");
    final user = User.fromJson(jsonDecode(userData!));

    // Now you can use both
    final customerId = user.id;

    if (customerId == null) {
      throw Exception('Customer ID not found');
    }

    final url = Uri.parse('https://api1.thecuredesk.com/patient/add-member');

    final body = jsonEncode({
      "name": name,
      "gender": gender,
      "age": age,
      "customerId": customerId,
      "mobile": mobile
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('Member added successfully');
      } else {
        throw Exception('Failed to add member: ${data}');
      }
    } else {
      throw Exception('Failed to add member: ${response.body}');
    }
  }

  Widget _buildMemberDropdownSection(
    BuildContext context,
    String title,
    IconData icon,
    List<FamilyMember> members,
    String? selectedMemberId,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: AppConstants.paddingSmall),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
                icon: Icon(Icons.add, color: colorScheme.onSurface),
                onPressed: () {
                  _showAddMemberDialog(context);
                }),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedMemberId,
              hint: Text(
                "Select family member",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              items: members.map((member) {
                return DropdownMenuItem<String>(
                  value: member.id,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    String? selectedGender;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add Family Member",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter name" : null,
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: ["Male", "Female", "Other"]
                        .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedGender = value;
                    },
                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: const Icon(Icons.wc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null ? "Select gender" : null,
                  ),
                  const SizedBox(height: 16),

                  // Age
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Age",
                      prefixIcon: const Icon(Icons.cake),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter age" : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter mobile number" : null,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await addMember(
                      name: nameController.text,
                      gender: selectedGender!,
                      age: ageController.text,
                      mobile: mobileController.text,
                    );

                    Navigator.pop(ctx);

                    // ✅ Refresh family members
                    final prefs = await SharedPreferences.getInstance();
                    final userData = prefs.getString("user_data");
                    final user = User.fromJson(jsonDecode(userData!));
                    setState(() {
                      _familyMembersFuture = fetchFamilyMembers(user.id);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Member added successfully"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed: $e")),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  DateTime? selectedDateTime;

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          selectedDateTime = fullDateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Doctor Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: IconButton(
                  icon:
                      Icon(Icons.favorite_border, color: colorScheme.onSurface),
                  onPressed: () {
                    // TODO: Implement favorite functionality
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    margin: const EdgeInsets.only(top: 60),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXLarge),
                      image: DecorationImage(
                        image: AssetImage(
                          "assets/man.png",
                        ),
                        // fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Doctor Info
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Name and Specialty
                      Center(
                        child: Column(
                          children: [
                            Text(
                              widget.doctor.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingMedium,
                                vertical: AppConstants.paddingSmall,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLarge),
                              ),
                              child: Text(
                                widget.doctor.specialty,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            context,
                            Icons.star,
                            widget.doctor.rating.toString(),
                            'Rating',
                            Colors.amber,
                          ),
                          _buildStatCard(
                            context,
                            Icons.work_outline,
                            '${widget.doctor.experienceYears}+',
                            'Experience',
                            colorScheme.primary,
                          ),
                          _buildStatCard(
                            context,
                            Icons.attach_money,
                            '\$${widget.doctor.consultationFee.toInt()}',
                            'Consultation',
                            colorScheme.secondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingXLarge),

                      // About Section
                      _buildSection(
                        context,
                        'About Doctor',
                        Icons.person,
                        widget.doctor.specialty,
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // // Education Section
                      // _buildSection(
                      //   context,
                      //   'Education',
                      //   Icons.school,
                      //   widget.doctor.education,
                      // ),

                      // const SizedBox(height: AppConstants.paddingLarge),

                      // Hospital Section
                      _buildSection(
                        context,
                        'Hospital',
                        Icons.local_hospital,
                        widget.doctor.hospital,
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildBranchDropdownSection(
                        context,
                        "Select Branch",
                        Icons.location_city,
                        widget.doctor.branches, // ✅ directly use List<Branch>
                        _selectedBranchId,
                        (newValue) {
                          setState(() {
                            _selectedBranchId = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppConstants.paddingSmall),
                              Text(
                                'Select Appointment Date & Time',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          ElevatedButton(
                            onPressed: () => _pickDateTime(context),
                            child: const Text("Choose Date & Time"),
                          ),
                          if (selectedDateTime != null) ...[
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              "Selected: ${selectedDateTime.toString()}",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]
                        ],
                      ),

                      // Available Days

                      const SizedBox(height: AppConstants.paddingXLarge * 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Book Appointment Button
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
            text: 'Book Appointment',
            icon: Icons.calendar_today,
            onPressed: () async {
              if (_selectedBranchId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a branch")),
                );
                return;
              }
              if (selectedDateTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select date & time")),
                );
                return;
              }

              final doctorProvider =
                  Provider.of<DoctorProvider>(context, listen: false);
              final prefs = await SharedPreferences.getInstance();
              // 🔹 Get user
              final userData = prefs.getString("user_data");
              final user = User.fromJson(jsonDecode(userData!));

              // Now you can use both
              final memberId = user.memberId;
              final userId = user.id;

              final success = await doctorProvider.bookAppointment(
                memberId: _selectedMemberId ??
                    user.memberId, // 🔹 replace with logged-in memberId
                customerId: userId, // 🔹 replace with logged-in customerId
                appointmentTime: selectedDateTime!,
                branchId: _selectedBranchId!,
                clientId:
                    widget.doctor.client!.id, // ✅ doctor model should have this
                doctorId: widget.doctor.id,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Appointment booked successfully!")),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MainNavigationScreen(
                        initialIndex: 2), // 👈 2 = appointments tab
                  ),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to book appointment.")),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchDropdownSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Branch> branches, // ✅ now uses Branch model
    String? selectedBranchId,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBranchId,
              hint: Text(
                "Select branch",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              items: branches.map((branch) {
                return DropdownMenuItem<String>(
                  value: branch.id, // ✅ use Branch.id
                  child: Text(branch.name), // ✅ use Branch.name
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingLarge),
        FutureBuilder<List<FamilyMember>>(
          future: _familyMembersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text("Failed to load family members");
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("No family members found"),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text("Add Family Member"),
                    onPressed: () {
                      _showAddMemberDialog(context); // 👈 open add member form
                    },
                  ),
                ],
              );
            } else {
              final members = snapshot.data!;
              return _buildMemberDropdownSection(
                context,
                "Select Family Member",
                Icons.group,
                members,
                _selectedMemberId,
                (newValue) {
                  setState(() {
                    _selectedMemberId = newValue;
                  });
                },
              );
            }
          },
        ),
      ],
    );
  }
}
