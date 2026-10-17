import 'dart:convert';

import 'package:field_survey/screens/survey/form_survey_page.dart';
import 'package:field_survey/screens/survey/survey_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  List<dynamic> surveys = [];
  bool isLoading = true;

  static const Color primary = Color(0xFF8B9A6E);
  static const Color cream = Color(0xFFF7F2EB);
  static const Color beige = Color(0xFFEAE2D6);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkText = Color(0xFF3F4437);
  static const Color primaryColor = Color(0xFF4C5C2D);
  static const Color greyText = Color(0xFF73776D);

  @override
  void initState() {
    super.initState();
    getSurvey();
  }

  Future<void> openMaps(String? latitude, String? longitude) async {
    if (latitude == null || longitude == null) {
      return;
    }

    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);

    if (lat == null || lng == null) {
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      _showSnackBar('Tidak dapat membuka Google Maps');
    }
  }

  Future<void> getSurvey() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          surveys = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        _showSnackBar('Gagal mengambil data survey (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showSnackBar('Terjadi kesalahan saat mengambil data survey');
    }
  }

  Future<void> _navigateToAddNewSurvey() async {
    final isSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SurveyFormPage()),
    );

    if (isSuccess == true && mounted) {
      setState(() {
        isLoading = true;
      });

      getSurvey();
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '-';
    }

    try {
      final parsedDate = DateTime.parse(date);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${parsedDate.day} '
          '${months[parsedDate.month - 1]} '
          '${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              backgroundColor: Colors.white,
              onRefresh: getSurvey,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: surveys.isEmpty ? _emptyState() : _buildContent(),
                  ),
                ],
              ),
            ),
      floatingActionButton: surveys.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddNewSurvey,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 5,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 245,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              isLoading = true;
            });

            getSurvey();
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned(
              top: -75,
              right: -45,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              top: 105,
              left: -75,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: beige.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              right: 55,
              bottom: 25,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 48, 22, 22),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'SURVEY LAPANGAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Survey Lapangan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Pantau dan kelola data survey '
                        'lapangan kamu.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Survey Kamu',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Data survey yang telah dilakukan',
                    style: TextStyle(color: greyText, fontSize: 12),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      size: 15,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${surveys.length}',
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ...surveys.map(
            (survey) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _surveyCard(survey as Map<String, dynamic>),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surveyCard(Map<String, dynamic> survey) {
    final category = survey['category_name']?.toString() ?? 'Umum';

    final title = survey['title']?.toString() ?? 'Tanpa Judul';

    final description =
        survey['description']?.toString() ?? 'Tidak ada deskripsi';

    final latitude = survey['latitude']?.toString();

    final longitude = survey['longitude']?.toString();

    final date = formatDate(survey['created_at']?.toString());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurveyDetailPage(surveyId: survey['id']),
            ),
          );

          if (result == true && mounted) {
            setState(() {
              isLoading = true;
            });

            getSurvey();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: lightGrey),
            boxShadow: [
              BoxShadow(
                color: darkText.withOpacity(0.045),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CATEGORY + DATE
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: beige,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 13,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: greyText,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    date,
                    style: const TextStyle(color: greyText, fontSize: 10.5),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // TITLE
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 7),

              // DESCRIPTION
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 15),

              // LOCATION
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: beige,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: primaryColor,
                        size: 19,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi',
                            style: TextStyle(color: greyText, fontSize: 9.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${latitude ?? '-'}, '
                            '${longitude ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        openMaps(latitude, longitude);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Peta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              // DETAIL
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Lihat detail',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 100),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: lightGrey),
              boxShadow: [
                BoxShadow(
                  color: darkText.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: beige,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: primaryColor,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Belum Ada Survey',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Belum ada data survey yang tersimpan. '
                  'Mulai tambahkan survey lapangan kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: greyText, fontSize: 12, height: 1.5),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddNewSurvey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text(
                      'Tambah Survey',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
