import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/providers/doctor_provider.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/widgets/doctor_card.dart';
import 'package:surebook/screens/doctors/doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final String? initialQuery;
  const DoctorListScreen({super.key, this.initialQuery});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  bool _isFilterExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: AppConstants.animationMedium),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DoctorProvider>(context, listen: false);
      provider.resetSearch();

      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _searchController.text = widget.initialQuery!; // ✅ show query in field
        provider.searchDoctors(widget.initialQuery!); // ✅ load doctors
      } else {
        provider.loadDoctors(refresh: true); // load all doctors
      }
    });
    // Pagination listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = Provider.of<DoctorProvider>(context, listen: false);
        if (!provider.isLoading && provider.hasMore) {
          provider.loadDoctors(refresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text(
              'Hello, ${authProvider.currentUser?.name.split(' ').first ?? 'User'}! 👋',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
      body: Consumer<DoctorProvider>(
        builder: (context, doctorProvider, child) {
          // Show loading spinner on first load
          if (doctorProvider.doctors.isEmpty && doctorProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 🔍 Search + Filters (always visible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusLarge),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search doctors, specialties...',
                            prefixIcon: Icon(Icons.search,
                                color: colorScheme.onSurface.withOpacity(0.6)),
                            suffixIcon: IconButton(
                              onPressed: _toggleFilters,
                              icon: AnimatedRotation(
                                turns: _isFilterExpanded ? 0.5 : 0,
                                duration: const Duration(
                                    milliseconds: AppConstants.animationMedium),
                                child: Icon(Icons.filter_list,
                                    color: colorScheme.primary),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMedium,
                              vertical: AppConstants.paddingMedium,
                            ),
                          ),
                          onChanged: (value) {
                            Provider.of<DoctorProvider>(context, listen: false)
                                .searchDoctors(value);
                          },
                        ),
                      ),
                      // Filters expand section
                      SizeTransition(
                        sizeFactor: _filterAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(
                              top: AppConstants.paddingMedium),
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.surfaceContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusMedium),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🏅 Experience Filter
                              Text("Experience",
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text("0-5 yrs"),
                                    selected: false,
                                    onSelected: (val) {
                                      // handle selection
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text("5-10 yrs"),
                                    selected: false,
                                    onSelected: (val) {},
                                  ),
                                  FilterChip(
                                    label: const Text("10+ yrs"),
                                    selected: false,
                                    onSelected: (val) {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 🩺 Specialization Filter
                              Text("Specialization",
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                hint: const Text("Select specialization"),
                                items: [
                                  "Cardiologist",
                                  "Dermatologist",
                                  "Neurologist",
                                  "Pediatrician",
                                ]
                                    .map((spec) => DropdownMenuItem(
                                          value: spec,
                                          child: Text(spec),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  // handle specialization change
                                },
                              ),
                              const SizedBox(height: 16),

                              // ⭐ Rating Filter with Chips
                              Text("Rating", style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                children: [
                                  FilterChip(
                                    label: const Text("4⭐ & above"),
                                    selected: false,
                                    onSelected: (val) {
                                      // handle 4+ filter
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text("3⭐ & above"),
                                    selected: false,
                                    onSelected: (val) {
                                      // handle 3+ filter
                                    },
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                    child: FilterChip(
                                      label: const Text("2⭐ & above"),
                                      selected: false,
                                      onSelected: (val) {
                                        // handle 2+ filter
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ❌ No doctors found message
              if (doctorProvider.doctors.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(height: AppConstants.paddingMedium),
                          Text(
                            'No doctors found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          Text(
                            'Try adjusting your filters or search terms',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 👩‍⚕️ Doctors Grid
              if (doctorProvider.doctors.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: _getAspectRatio(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < doctorProvider.doctors.length) {
                          final doctor = doctorProvider.doctors[index];
                          return DoctorCard(
                            doctor: doctor,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DoctorDetailScreen(doctor: doctor),
                                ),
                              );
                            },
                          );
                        } else {
                          // Bottom loader
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                      childCount: doctorProvider.doctors.length +
                          (doctorProvider.isLoading ? 1 : 0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 1.7; // Mobile
    if (width < 1200) return 4.5; // Tablet
    return 6.5; // Desktop
  }
}
