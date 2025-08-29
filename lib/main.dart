import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surebook/theme.dart';
import 'package:surebook/shared/providers/auth_provider.dart';
import 'package:surebook/shared/providers/doctor_provider.dart';
import 'package:surebook/shared/providers/appointment_provider.dart';
import 'package:surebook/screens/splash_screen.dart';
import 'package:surebook/shared/constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
