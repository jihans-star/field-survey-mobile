import 'dart:convert';
import 'dart:typed_data';

import 'package:field_survey/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfilePage({
    super.key,
    this.profile,
    Map<String, dynamic>? profileData,
  });

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController birthPlaceController;
  late TextEditingController birthDateController;

  String? gender;
  String? apiBirthDate;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Future<Uint8List?>? oldProfileImageFuture;

  bool isLoading = false;

  static const String baseUrl = 'https://sijala.biz.id/api/v1';
  static const String profileUpdateEndpoint = '$baseUrl/profile/update';
  static const String imageEndpoint = 'https://sijala.biz.id/api/image';

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

    final profile = widget.profile ?? {};

    nameController = TextEditingController(
      text: profile['name']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: profile['email']?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: profile['phone']?.toString() ?? '',
    );

    birthPlaceController = TextEditingController(
      text: profile['birth_place']?.toString() ?? '',
    );

    final rawGender = profile['gender']?.toString().toLowerCase();

    if (rawGender != null) {
      if (rawGender.startsWith('l')) {
        gender = 'L';
      } else if (rawGender.startsWith('p')) {
        gender = 'P';
      }
    }

    String displayBirthDate = '';
    final rawDate = profile['birth_date']?.toString();

    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        DateTime? parsedDate;

        if (rawDate.contains('-')) {
          final parts = rawDate.split('-');

          if (parts.length == 3) {
            if (parts[0].length == 4) {
              parsedDate = DateTime.parse(rawDate);
            } else if (parts[2].length == 4) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);

              parsedDate = DateTime(year, month, day);
            }
          }
        }

        if (parsedDate != null) {
          final day = parsedDate.day.toString().padLeft(2, '0');
          final month = parsedDate.month.toString().padLeft(2, '0');
          final year = parsedDate.year.toString();

          displayBirthDate = '$day-$month-$year';
          apiBirthDate = '$year-$month-$day';
        } else {
          displayBirthDate = rawDate;
          apiBirthDate = rawDate;
        }
      } catch (_) {
        displayBirthDate = rawDate;
        apiBirthDate = rawDate;
      }
    }

    birthDateController = TextEditingController(text: displayBirthDate);

    final oldPhoto = profile['photo']?.toString();

    if (oldPhoto != null && oldPhoto.isNotEmpty) {
      oldProfileImageFuture = fetchProfileImage(oldPhoto);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  dynamic safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        selectedImage = pickedFile;
        selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil gambar dari galeri.'),
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

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> selectBirthDate() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );

    if (apiBirthDate != null && apiBirthDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(apiBirthDate!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1966),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final year = picked.year.toString();

    setState(() {
      birthDateController.text = '$day-$month-$year';
      apiBirthDate = '$year-$month-$day';
    });
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih jenis kelamin.'),
          backgroundColor: Colors.brown,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(profileUpdateEndpoint),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = nameController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['phone'] = phoneController.text.trim();
      request.fields['gender'] = gender!;
      request.fields['birth_place'] = birthPlaceController.text.trim();

      if (apiBirthDate != null && apiBirthDate!.isNotEmpty) {
        request.fields['birth_date'] = apiBirthDate!;
      }

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data != null && data['status'] == true) {
          if (data['data'] != null) {
            await prefs.setString('user', jsonEncode(data['data']));
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui.'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true);
        } else {
          throw Exception(data?['message'] ?? 'Gagal memperbarui profil.');
        }
      } else if (response.statusCode == 422) {
        String validationErrors = '';

        if (data != null && data['errors'] != null && data['errors'] is Map) {
          final errorsMap = data['errors'] as Map;

          for (final key in errorsMap.keys) {
            final messages = errorsMap[key];

            if (messages is List) {
              for (final msg in messages) {
                validationErrors += '$msg\n';
              }
            }
          }
        }

        if (validationErrors.isEmpty) {
          validationErrors = data?['message'] ?? 'Validasi gagal.';
        }

        throw Exception(validationErrors.trim());
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        context.go(AppRoutes.login);
        return;
      } else {
        throw Exception(
          'Gagal memperbarui profil. Error Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      String msg = e.toString().replaceAll('Exception: ', '');

      if (msg.toLowerCase().contains('socket') ||
          msg.toLowerCase().contains('failed to connect') ||
          msg.toLowerCase().contains('clientexception')) {
        msg = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.brown,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: greyText, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: lightGrey.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
      ),
    );
  }

  Widget sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.035)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget photoSection() {
    final oldPhoto = widget.profile?['photo']?.toString();

    return Center(
      child: Column(
        children: [
          Container(
            width: 125,
            height: 125,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: beige,
              border: Border.all(color: primary.withOpacity(0.4), width: 2),
            ),
            child: ClipOval(
              child: selectedImageBytes != null
                  ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                  : oldPhoto != null && oldPhoto.isNotEmpty
                  ? FutureBuilder<Uint8List?>(
                      future: oldProfileImageFuture,
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
                          size: 58,
                          color: primaryColor,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 58,
                      color: primaryColor,
                    ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            selectedImage != null ? 'Foto baru dipilih' : 'Foto Profil',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan foto yang jelas dan mudah dikenali.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: greyText),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : pickImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Pilih Foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withOpacity(0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            expandedHeight: 175,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: const Text(
              'Edit Profil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  const Positioned(
                    left: 18,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perbarui Profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pastikan informasi kamu tetap terbaru.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 35),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    sectionCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'Foto Profil',
                      subtitle: 'Perbarui foto akun kamu',
                      child: photoSection(),
                    ),

                    const SizedBox(height: 16),

                    sectionCard(
                      icon: Icons.person_outline,
                      title: 'Data Pribadi',
                      subtitle: 'Informasi dasar akun kamu',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel('Nama Lengkap'),
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: inputDecoration(
                              icon: Icons.person_outline,
                              hint: 'Nama lengkap',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama wajib diisi';
                              }

                              if (value.trim().length > 255) {
                                return 'Nama maksimal 255 karakter';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          fieldLabel('Email'),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: inputDecoration(
                              icon: Icons.email_outlined,
                              hint: 'nama@email.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }

                              if (!value.contains('@')) {
                                return 'Format email tidak valid';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          fieldLabel('Nomor HP'),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: inputDecoration(
                              icon: Icons.phone_outlined,
                              hint: '08xxxxxxxxxx',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor HP wajib diisi';
                              }

                              if (value.trim().length < 10) {
                                return 'Nomor HP minimal 10 digit';
                              }

                              if (value.trim().length > 15) {
                                return 'Nomor HP maksimal 15 digit';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    sectionCard(
                      icon: Icons.badge_outlined,
                      title: 'Informasi Tambahan',
                      subtitle: 'Lengkapi informasi pribadi kamu',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel('Jenis Kelamin'),
                          DropdownButtonFormField<String>(
                            value: gender,
                            decoration: inputDecoration(
                              icon: Icons.wc_outlined,
                              hint: 'Pilih jenis kelamin',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'L',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'P',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      gender = value;
                                    });
                                  },
                            validator: (value) {
                              if (value == null) {
                                return 'Jenis kelamin wajib dipilih';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          fieldLabel('Tempat Lahir'),
                          TextFormField(
                            controller: birthPlaceController,
                            textInputAction: TextInputAction.next,
                            decoration: inputDecoration(
                              icon: Icons.location_on_outlined,
                              hint: 'Kota tempat lahir',
                            ),
                            validator: (value) {
                              if (value != null && value.trim().length > 100) {
                                return 'Tempat lahir maksimal 100 karakter';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          fieldLabel('Tanggal Lahir'),
                          TextFormField(
                            controller: birthDateController,
                            readOnly: true,
                            onTap: isLoading ? null : selectBirthDate,
                            decoration: inputDecoration(
                              icon: Icons.calendar_today_outlined,
                              hint: 'Pilih tanggal lahir',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tanggal lahir wajib dipilih';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
