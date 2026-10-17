import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primary = Color(0xFF8B9A6E);
  static const Color cream = Color(0xFFF7F2EB);
  static const Color beige = Color(0xFFEAE2D6);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkText = Color(0xFF3F4437);
  static const Color primaryColor = Color(0xFF4C5C2D);
  static const Color greyText = Color(0xFF73776D);

  int totalSurveys = 0;
  int totalCategories = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getDashboard();
  }

  Future<void> getDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == true) {
        final data = result['data'];

        setState(() {
          totalSurveys = data['total_surveys'] ?? 0;
          totalCategories = data['total_categories'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        _showMessage(result['message'] ?? 'Gagal mengambil data dashboard.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      _showMessage('Terjadi kesalahan saat mengambil data.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryColor),
    );
  }

  Future<void> _refresh() async {
    await getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),

                          _buildStatistics(),

                          const SizedBox(height: 26),

                          _buildSectionTitle(
                            title: 'Aktivitas Survey',
                            subtitle: 'Ringkasan data yang tersedia',
                          ),

                          const SizedBox(height: 12),

                          // _buildSurveyOverview(),
                          const SizedBox(height: 12),

                          _buildBottomInfo(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 235,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: primaryColor),
          child: Stack(
            children: [
              Positioned(
                right: -45,
                top: 45,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                ),
              ),

              Positioned(
                right: 45,
                top: 105,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: beige,
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: primaryColor,
                          size: 27,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Pantau dan kelola data survey lapangan kamu.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: totalSurveys,
            label: 'Total Survey',
            icon: Icons.assignment_rounded,
            isMain: true,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _buildStatCard(
            value: totalCategories,
            label: 'Kategori',
            icon: Icons.category_rounded,
            isMain: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int value,
    required String label,
    required IconData icon,
    required bool isMain,
  }) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isMain ? primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMain ? primary : lightGrey),
        boxShadow: [
          BoxShadow(
            color: darkText.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -18,
            child: Icon(
              icon,
              size: 80,
              color: isMain
                  ? Colors.white.withOpacity(0.08)
                  : primary.withOpacity(0.08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isMain ? Colors.white.withOpacity(0.18) : beige,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isMain ? Colors.white : primaryColor,
                  size: 23,
                ),
              ),

              const Spacer(),

              Text(
                value.toString(),
                style: TextStyle(
                  color: isMain ? Colors.white : darkText,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                label,
                style: TextStyle(
                  color: isMain ? Colors.white70 : greyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 3),

        Text(subtitle, style: const TextStyle(color: greyText, fontSize: 12)),
      ],
    );
  }

  // Widget _buildSurveyOverview() {
  //   final bool hasSurvey = totalSurveys > 0;

  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(22),
  //       border: Border.all(color: lightGrey),
  //       boxShadow: [
  //         BoxShadow(
  //           color: darkText.withOpacity(0.05),
  //           blurRadius: 14,
  //           offset: const Offset(0, 6),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 58,
  //           height: 58,
  //           decoration: BoxDecoration(
  //             color: beige,
  //             borderRadius: BorderRadius.circular(18),
  //           ),
  //           child: Icon(
  //             hasSurvey ? Icons.trending_up_rounded : Icons.assignment_outlined,
  //             color: primaryColor,
  //             size: 29,
  //           ),
  //         ),

  //         const SizedBox(width: 16),

  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 hasSurvey ? 'Survey tersedia' : 'Belum ada survey',
  //                 style: const TextStyle(
  //                   color: darkText,
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),

  //               const SizedBox(height: 5),

  //               Text(
  //                 hasSurvey
  //                     ? '$totalSurveys data survey telah tersimpan.'
  //                     : 'Mulai tambahkan survey lapangan pertama kamu.',
  //                 style: const TextStyle(
  //                   color: greyText,
  //                   fontSize: 12,
  //                   height: 1.4,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         const SizedBox(width: 8),

  //         Container(
  //           width: 34,
  //           height: 34,
  //           decoration: BoxDecoration(
  //             color: cream,
  //             borderRadius: BorderRadius.circular(11),
  //           ),
  //           child: const Icon(
  //             Icons.arrow_forward_ios_rounded,
  //             color: primaryColor,
  //             size: 14,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBottomInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Pastikan data survey dan lokasi yang kamu masukkan sudah sesuai.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
