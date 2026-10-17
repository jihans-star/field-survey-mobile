import 'dart:convert';
import 'dart:typed_data';

import 'package:field_survey/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String baseUrl = 'https://sijala.biz.id/api/v1';
  static const String profileEndpoint = '$baseUrl/profile';
  static const String imageEndpoint = 'https://sijala.biz.id/api/image';

  static const Color primary = Color(0xFF8B9A6E);
  static const Color cream = Color(0xFFF7F2EB);
  static const Color beige = Color(0xFFEAE2D6);
  static const Color darkText = Color(0xFF3F4437);
  static const Color primaryColor = Color(0xFF4C5C2D);
  static const Color greyText = Color(0xFF73776D);

  Map<String, dynamic>? profile;
  Future<Uint8List?>? profileImageFuture;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final profileData = Map<String, dynamic>.from(data['data']);

        final photo = profileData['photo']?.toString();

        if (!mounted) return;

        setState(() {
          profile = profileData;

          if (photo != null && photo.isNotEmpty) {
            profileImageFuture = fetchProfileImage(photo);
          } else {
            profileImageFuture = null;
          }

          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        context.go(AppRoutes.login);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data profile.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.brown,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Uint8List?> fetchProfileImage(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final cleanFileName = fileName.split('/').last;

      final response = await http.get(
        Uri.parse('$imageEndpoint/$cleanFileName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun?',
            style: TextStyle(color: greyText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        context.go(AppRoutes.login);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go(AppRoutes.login);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout gagal. Silakan coba lagi.'),
            backgroundColor: Colors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server.'),
          backgroundColor: Colors.brown,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> handleRefresh() async {
    await getProfile();
  }

  BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.035)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.045),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: beige,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: greyText),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget profileHeader() {
    final name = profile!['name']?.toString() ?? '-';
    final username = profile!['username']?.toString() ?? '-';
    final photo = profile!['photo']?.toString();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 108,
                height: 108,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: beige,
                  border: Border.all(color: primary.withOpacity(0.4), width: 2),
                ),
                child: ClipOval(
                  child: photo != null && photo.isNotEmpty
                      ? FutureBuilder<Uint8List?>(
                          future: profileImageFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              );
                            }

                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }

                            return const Icon(
                              Icons.person_rounded,
                              size: 55,
                              color: primaryColor,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 55,
                          color: primaryColor,
                        ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '@$username',
            style: const TextStyle(fontSize: 13, color: greyText),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 16, color: primaryColor),
                SizedBox(width: 6),
                Text(
                  'Pengguna Field Survey',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: beige,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primaryColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: greyText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final iconColor = danger ? Colors.brown : primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: danger ? Colors.brown.withOpacity(0.09) : beige,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: danger ? Colors.brown : darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: greyText),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: danger ? Colors.brown : greyText,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (profile == null) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 250),
            Center(
              child: Text(
                'Data profile tidak ditemukan.',
                style: TextStyle(color: greyText),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          profileHeader(),

          const SizedBox(height: 22),

          sectionTitle(
            icon: Icons.badge_outlined,
            title: 'Informasi Pribadi',
            subtitle: 'Data yang tersimpan pada akun kamu',
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: infoItem(
                        icon: Icons.person_outline,
                        label: 'Username',
                        value: profile!['username']?.toString() ?? '-',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: infoItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile!['email']?.toString() ?? '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: infoItem(
                        icon: Icons.phone_outlined,
                        label: 'Nomor HP',
                        value: profile!['phone']?.toString() ?? '-',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: infoItem(
                        icon: Icons.wc_outlined,
                        label: 'Jenis Kelamin',
                        value: profile!['gender']?.toString() ?? '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: infoItem(
                        icon: Icons.location_on_outlined,
                        label: 'Tempat Lahir',
                        value: profile!['birth_place']?.toString() ?? '-',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: infoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal Lahir',
                        value: profile!['birth_date']?.toString() ?? '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          sectionTitle(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Akun',
            subtitle: 'Kelola akun dan sesi kamu',
          ),

          const SizedBox(height: 13),

          actionCard(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            subtitle: 'Perbarui informasi dan foto profil',
            onTap: () async {
              if (profile == null) return;

              final result = await context.push(
                AppRoutes.editProfile,
                extra: profile,
              );

              if (result == true && mounted) {
                await getProfile();
              }
            },
          ),

          const SizedBox(height: 10),

          actionCard(
            icon: Icons.logout_rounded,
            title: 'Keluar',
            subtitle: 'Keluar dari akun Field Survey',
            danger: true,
            onTap: logout,
          ),

          const SizedBox(height: 22),

          Center(
            child: Column(
              children: [
                Icon(
                  Icons.eco_outlined,
                  color: primary.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Field Survey',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: greyText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kelola data survey dengan lebih mudah',
                  style: TextStyle(fontSize: 10, color: greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 185,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: getProfile,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
              const SizedBox(width: 5),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned(
                    top: -55,
                    right: -35,
                    child: Container(
                      width: 155,
                      height: 155,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: beige.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -70,
                    left: -45,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.25),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 105,
                    right: 80,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akun Saya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola informasi profil kamu.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverFillRemaining(hasScrollBody: true, child: buildBody()),
        ],
      ),
    );
  }
}
