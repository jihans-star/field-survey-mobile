import 'dart:convert';
import 'dart:typed_data';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:field_survey/screens/survey/form_survey_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  Map<String, dynamic>? survey;

  bool isLoading = true;
  String? errorMessage;

  Uint8List? imageBytes;
  bool isLoadingImage = false;

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
    fetchDetail();
  }

  // ============================================================
  // FETCH DETAIL
  // ============================================================

  Future<void> fetchDetail() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    imageBytes = null;

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys/${widget.surveyId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == true && result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);

          if (!mounted) return;

          setState(() {
            survey = data;
            isLoading = false;
          });

          final photoName = data['photo']?.toString();

          if (photoName != null &&
              photoName.isNotEmpty &&
              photoName != 'placeholder.jpg') {
            fetchImage(photoName, token);
          }

          return;
        }
      }

      throw Exception('Survey tidak ditemukan');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat detail survey.';
      });
    }
  }

  // ============================================================
  // FETCH IMAGE
  // ============================================================

  Future<void> fetchImage(String photoName, String token) async {
    if (mounted) {
      setState(() {
        isLoadingImage = true;
      });
    }

    try {
      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/image/$fileName'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          imageBytes = response.bodyBytes;
          isLoadingImage = false;
        });

        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Hapus Survey?',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Data survey yang dihapus tidak dapat dikembalikan.',
            style: TextStyle(color: greyText, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: greyText, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(
          'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}/delete',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar('Survey berhasil dihapus');

        Navigator.pop(context, true);
      } else {
        _showSnackBar('Gagal menghapus survey');
      }
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Terjadi kesalahan');
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> editSurvey() async {
    if (survey == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyFormPage(survey: survey)),
    );

    if (result == true && mounted) {
      fetchDetail();
    }
  }

  // ============================================================
  // MAPS
  // ============================================================

  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Tidak dapat membuka Google Maps');
    }
  }

  // ============================================================
  // COPY
  // ============================================================

  void copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));

    _showSnackBar('Koordinat berhasil disalin');
  }

  // ============================================================
  // IMAGE
  // ============================================================

  void showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: darkText.withOpacity(.8),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (errorMessage != null || survey == null) {
      return _errorState();
    }

    final title = survey!['title']?.toString() ?? 'Tanpa Judul';

    final description = survey!['description']?.toString() ?? '';

    final category =
        survey!['category_name']?.toString() ??
        survey!['category']?['name']?.toString() ??
        'Tanpa Kategori';

    final date = survey!['created_at']?.toString() ?? '-';

    final lat = double.tryParse(survey!['latitude']?.toString() ?? '');

    final lng = double.tryParse(survey!['longitude']?.toString() ?? '');

    final hasCoords = lat != null && lng != null;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchDetail,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(title, category, date),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  _buildPhotoCard(),

                  const SizedBox(height: 16),

                  _buildDescriptionCard(description),

                  const SizedBox(height: 16),

                  _buildLocationCard(lat, lng, hasCoords),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(String title, String category, String date) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (survey != null) ...[
          IconButton(
            onPressed: editSurvey,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: deleteSurvey,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned(
              right: -55,
              top: -60,
              child: _circle(180, Colors.white.withOpacity(.07)),
            ),
            Positioned(
              left: -70,
              bottom: -60,
              child: _circle(170, beige.withOpacity(.09)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 45, 22, 24),
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
                          color: Colors.white.withOpacity(.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
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

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Widget _buildPhotoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.image_outlined, 'Foto Survey'),
          const SizedBox(height: 15),
          if (isLoadingImage)
            const SizedBox(
              height: 210,
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else if (imageBytes != null)
            GestureDetector(
              onTap: () => showFullImageDialog(imageBytes!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: greyText,
                    size: 35,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada foto survey',
                    style: TextStyle(color: greyText, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionCard(String description) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.notes_outlined, 'Deskripsi'),
          const SizedBox(height: 14),
          Text(
            description.isNotEmpty ? description : 'Tidak ada deskripsi.',
            style: const TextStyle(color: darkText, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationCard(double? lat, double? lng, bool hasCoords) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.location_on_outlined, 'Lokasi Survey'),
          const SizedBox(height: 14),
          if (hasCoords) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pin_drop_outlined,
                    size: 19,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$lat, $lng',
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => copyCoordinates(lat!, lng!),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    color: primaryColor,
                    tooltip: 'Salin',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat!, lng!),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.field_survey',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 45,
                          height: 45,
                          child: const Icon(
                            Icons.location_on,
                            color: primaryColor,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () => openGoogleMaps(lat, lng),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Buka Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ] else
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  'Koordinat lokasi tidak tersedia',
                  style: TextStyle(color: greyText, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: beige,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(
            color: darkText.withOpacity(.045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: beige,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              errorMessage ?? 'Survey tidak ditemukan',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: fetchDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
