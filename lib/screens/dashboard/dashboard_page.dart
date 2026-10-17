import 'package:field_survey/screens/dashboard/home_page.dart';
import 'package:field_survey/screens/profile/profile.dart';
import 'package:field_survey/screens/survey/survey_page.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static const Color primary = Color(0xFF8B9A6E);
  static const Color cream = Color(0xFFF7F2EB);
  static const Color beige = Color(0xFFEAE2D6);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkText = Color(0xFF3F4437);
  static const Color primaryColor = Color(0xFF4C5C2D);
  static const Color greyText = Color(0xFF73776D);

  final List<Widget> _pages = const [HomePage(), SurveyPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: lightGrey, width: 1)),
          boxShadow: [
            BoxShadow(
              color: darkText.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: greyText,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home_outlined, isActive: false),
                  activeIcon: _buildNavIcon(Icons.home_rounded, isActive: true),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.assignment_outlined,
                    isActive: false,
                  ),
                  activeIcon: _buildNavIcon(
                    Icons.assignment_rounded,
                    isActive: true,
                  ),
                  label: 'Survey',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.person_outline_rounded,
                    isActive: false,
                  ),
                  activeIcon: _buildNavIcon(
                    Icons.person_rounded,
                    isActive: true,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, {required bool isActive}) {
    if (!isActive) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Icon(Icons.circle, size: 0),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: beige,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, size: 23, color: primaryColor),
    );
  }
}
