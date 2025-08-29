import 'package:flutter/material.dart';
import 'package:surebook/screens/home/home_screen.dart';
import 'package:surebook/screens/doctors/doctor_list_screen.dart';
import 'package:surebook/screens/appointments/appointments_screen.dart';
import 'package:surebook/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    DoctorListScreen(initialQuery: null),
    const AppointmentsScreen(),
    const ProfileScreen(),
  ];
  void openDoctorSearch(String query) {
    setState(() {
      _screens[1] = DoctorListScreen(initialQuery: query);
      _selectedIndex = 1;
    });
    _pageController.jumpToPage(1);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Widget _buildIcon(IconData icon, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15), // background circle
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.red),
      );
    } else {
      return Icon(icon, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // disable swipe
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          selectedFontSize: 12, // bigger font for active label
          unselectedFontSize: 12,
          currentIndex: _selectedIndex,
          enableFeedback: false,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.home_outlined, _selectedIndex == 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.search, _selectedIndex == 1),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                  Icons.calendar_today_outlined, _selectedIndex == 2),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.person_outline, _selectedIndex == 3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
