import 'package:flutter/material.dart';
import 'package:surebook/screens/doctors/doctor_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.menu, color: Colors.black87),
        //     onPressed: () {},
        //   )
        // ],
      ),
      body: SingleChildScrollView(
        // padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 55),
            // Heading
            Padding(
              padding: const EdgeInsets.all(16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF262A33)),
                  children: [
                    const TextSpan(text: "Book Your "),
                    const TextSpan(
                        text: "Doctor ", style: TextStyle(color: Colors.red)),
                    const TextSpan(text: "Appointment "),
                    TextSpan(
                        text: "Easily",
                        style: TextStyle(color: Colors.pink.shade400)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "Connect with trusted healthcare professionals and schedule appointments in minutes. Your health, our priority.",
                style: TextStyle(color: Colors.black54, fontSize: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search doctors",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final query = _searchController.text.trim();

                      if (query.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DoctorListScreen(initialQuery: query),
                          ),
                        );
                      } else {
                        // optional: show a message if search is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please enter a search term")),
                        );
                      }
                    },
                    child: const Text("Search",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Categories
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8, // horizontal space between chips
                runSpacing: 8, // vertical space between lines
                children: [
                  _categoryChip("Cardiology"),
                  _categoryChip("Pediatrics"),
                  _categoryChip("Dermatology"),
                  // _categoryChip("Neurology"),
                  // _categoryChip("Orthopedics"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Doctor Image
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(16),
            //   child: Image.network(
            //     "https://appointee-ease.lovable.app/assets/hero-medical-DJsZWjm5.jpg",
            //     fit: BoxFit.cover,
            //   ),
            // ),
            // const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Red tilted background card
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: -0.05, // tilt effect
                      child: Container(
                        height: 370,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.red.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  // Foreground doctor image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      "assets/doctor.jpg",
                      fit: BoxFit.cover,
                      height: 380,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("500+", "Verified Doctors"),
                  _statItem("50,000+", "Happy Patients"),
                ],
              ),
            ),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("4.9/5", "Average Rating"),
                  _statItem("24/7", "Support Available"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Why Choose Us
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  textAlign: TextAlign.center,
                  "Why Choose AppointEase?",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
                ),
              ),
            ),
            // const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                textAlign: TextAlign.center,
                "We make healthcare accessible with our innovative platform designed for modern patients",
                style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Features
            _featureCard(
              icon: Icons.search,
              title: "Find Specialists",
              description:
                  "Search and filter from hundreds of verified doctors",
            ),
            const SizedBox(height: 16),
            _featureCard(
              icon: Icons.calendar_today,
              title: "Book Appointments",
              description: "Schedule visits with doctors in just a few taps",
            ),
            const SizedBox(height: 16),
            _featureCard(
              icon: Icons.support_agent,
              title: "24/7 Support",
              description: "Get assistance whenever you need it",
            ),
            const SizedBox(height: 50),

            ctaCard()
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.red),
      ),
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Colors.red.shade300)),
    );
  }

  static Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.red, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gradient icon background
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade300, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16), // rounded square
              ),
              child: Icon(
                icon,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget ctaCard() {
    return Container(
      // height: 280,
      // margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade300, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
          ),
          Text(
            "Ready to Take Control of Your Health?",
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            "Join thousands of patients who trust AppointEase for their healthcare needs",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text(
              "Get Started Free",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
