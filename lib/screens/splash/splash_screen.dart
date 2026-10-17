
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFF4C5C2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_rounded,
                size: 55,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'FIELD SURVEY',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F4437),
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Survey lapangan jadi lebih mudah.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF73776D),
              ),
            ),

            const SizedBox(height: 35),

            const CircularProgressIndicator(
              color: Color(0xFF4C5C2D),
            ),

            const SizedBox(height: 15),

            const Text(
              'Menyiapkan aplikasi...',
              style: TextStyle(
                color: Color(0xFF73776D),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
