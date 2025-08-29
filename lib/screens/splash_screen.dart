import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/shared/constants/app_constants.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/shared/providers/doctor_provider.dart';
import 'package:surebook/shared/providers/appointment_provider.dart';
import 'package:surebook/screens/auth/login_screen.dart';
import 'package:surebook/screens/main_navigation_screen.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late VideoPlayerController _videoController;
  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/splash.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(false);
        _videoController.setVolume(0);
        _videoController.setPlaybackSpeed(0.5);

        setState(() {});
        _videoController.play();

        // Navigate after video finishes
        _videoController.addListener(() {
          if (_videoController.value.position >=
                  _videoController.value.duration &&
              mounted) {
            _initializeApp();
          }
        });
      });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _initializeApp();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    await Future.wait([
      authProvider.init(),
      doctorProvider.loadDoctors(),
    ]);

    // Initialize appointment provider if user is logged in
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      await appointmentProvider.loadAppointments(authProvider.currentUser!.id);
    }

    // Wait for animation to complete
    await _animationController.forward();

    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Navigate based on authentication state
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video
          _videoController.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : Container(color: Colors.transparent),

          // Optional overlay (your logo, text, etc.)
          // Center(
          //   child: FadeTransition(
          //     opacity: _fadeAnimation,
          //     child: ScaleTransition(
          //       scale: _scaleAnimation,
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Icon(
          //             Icons.medical_services_rounded,
          //             size: 80,
          //             color: Colors.white,
          //           ),
          //           const SizedBox(height: 20),
          //           // Text(
          //           //   AppConstants.appName,
          //           //   style:
          //           //       Theme.of(context).textTheme.headlineLarge?.copyWith(
          //           //             color: Colors.white,
          //           //             fontWeight: FontWeight.bold,
          //           //           ),
          //           // ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
