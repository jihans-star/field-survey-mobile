import 'dart:convert';
import 'dart:typed_data';

import 'package:field_survey/screens/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const SurveyFormPage({super.key, this.survey});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  final latitudeController = TextEditingController();

  final longitudeController = TextEditingController();

  int? selectedCategoryId;

  List<Map<String, dynamic>> categories = [];

  bool isLoadingCategories = true;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? existingImageBytes;

  bool isSubmitting = false;

  bool get isEdit => widget.survey != null;

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

    if (isEdit) {
      final s = widget.survey!;

      titleController.text = s['title']?.toString() ?? '';

      descriptionController.text = s['description']?.toString() ?? '';

      latitudeController.text = s['latitude']?.toString() ?? '';

      longitudeController.text = s['longitude']?.toString() ?? '';

      selectedCategoryId = int.tryParse(s['category_id']?.toString() ?? '');

      final photoName = s['photo']?.toString();

      if (photoName != null &&
          photoName.isNotEmpty &&
          photoName != 'placeholder.jpg') {
        fetchExistingImage(photoName);
      }
    }

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<void> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['data'] is List) {
          final List rawList = decoded['data'];

          if (!mounted) return;

          setState(() {
            categories = rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            isLoadingCategories = false;
          });

          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // ============================================================
  // EXISTING IMAGE
  // ============================================================

  Future<void> fetchExistingImage(String photoName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

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
          existingImageBytes = response.bodyBytes;
        });
      }
    } catch (_) {}
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (!mounted) return;

        setState(() {
          selectedImage = pickedFile;
          selectedImageBytes = bytes;
        });
      }
    } catch (_) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      existingImageBytes = null;
    });
  }

  // ============================================================
  // IMAGE SOURCE
  // ============================================================

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: beige,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _sourceTile(
                  ctx,
                  Icons.photo_library_outlined,
                  'Galeri Foto',
                  'Pilih foto dari perangkat',
                  ImageSource.gallery,
                ),
                _sourceTile(
                  ctx,
                  Icons.camera_alt_outlined,
                  'Kamera',
                  'Ambil foto langsung',
                  ImageSource.camera,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceTile(
    BuildContext ctx,
    IconData icon,
    String title,
    String subtitle,
    ImageSource source,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(ctx);
          pickImage(source);
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: beige,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: greyText, fontSize: 10),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: greyText),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveSurvey() async {
    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi.');
      return;
    }

    if (selectedCategoryId == null || selectedCategoryId == 0) {
      showErrorSnackBar('Kategori survey wajib dipilih.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

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

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://sijala.biz.id/api/v1/surveys/save'),
      );

      request.headers['Accept'] = 'application/json';

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = titleController.text.trim();

      request.fields['category_id'] = selectedCategoryId.toString();

      if (descriptionController.text.trim().isNotEmpty) {
        request.fields['description'] = descriptionController.text.trim();
      }

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      if (isEdit) {
        if (widget.survey != null && widget.survey!['id'] != null) {
          request.fields['id'] = widget.survey!['id'].toString();
        }

        request.fields['_method'] = 'PUT';
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

      final streamed = await request.send();

      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil disimpan!',
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body);

        if (decoded['errors'] != null && decoded['errors'] is Map) {
          final Map<String, dynamic> errors = decoded['errors'];

          final List<String> errorMessages = [];

          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorMessages.add(value.first.toString());
            }
          });

          if (errorMessages.isNotEmpty) {
            throw Exception(errorMessages.join('\n'));
          }
        }

        throw Exception(decoded['message'] ?? 'Data tidak valid.');
      }

      throw Exception(
        'Gagal menyimpan '
        '(Kode: ${response.statusCode})',
      );
    } catch (e) {
      if (!mounted) return;

      showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _input({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: greyText, fontSize: 12),
      hintStyle: const TextStyle(color: greyText, fontSize: 12),
      prefixIcon: Icon(icon, color: primaryColor, size: 19),
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lightGrey),
        boxShadow: [
          BoxShadow(
            color: darkText.withOpacity(.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: beige,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: greyText, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: Text(
              isEdit ? 'Edit Survey' : 'Tambah Survey',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -60,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -70,
                    bottom: -80,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: beige.withOpacity(.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 60, 22, 20),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Perbarui Data' : 'Isi Data Survey',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isEdit
                                  ? 'Ubah informasi survey kamu.'
                                  : 'Lengkapi informasi survey lapangan.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
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
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // =========================
                    // INFORMASI
                    // =========================
                    _section(
                      icon: Icons.assignment_outlined,
                      title: 'Informasi Survey',
                      subtitle: 'Masukkan informasi utama survey',
                      children: [
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: darkText, fontSize: 13),
                          decoration: _input(
                            label: 'Judul Survey *',
                            hint: 'Contoh: Saluran Air Rusak',
                            icon: Icons.title_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Judul survey wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        isLoadingCategories
                            ? Container(
                                height: 54,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: cream,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: selectedCategoryId,
                                decoration: _input(
                                  label: 'Kategori *',
                                  hint: 'Pilih kategori survey',
                                  icon: Icons.category_outlined,
                                ),
                                dropdownColor: Colors.white,
                                items: categories.map((cat) {
                                  final id =
                                      int.tryParse(
                                        cat['id']?.toString() ?? '',
                                      ) ??
                                      0;

                                  final name = cat['name']?.toString() ?? '';

                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: darkText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategoryId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value == 0) {
                                    return 'Kategori wajib dipilih';
                                  }
                                  return null;
                                },
                              ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: descriptionController,
                          maxLines: 4,
                          style: const TextStyle(color: darkText, fontSize: 13),
                          decoration: _input(
                            label: 'Deskripsi',
                            hint: 'Ceritakan kondisi yang ditemukan...',
                            icon: Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),

                    // =========================
                    // FOTO
                    // =========================
                    _section(
                      icon: Icons.camera_alt_outlined,
                      title: 'Foto Survey',
                      subtitle: 'Tambahkan dokumentasi lokasi',
                      children: [
                        if (selectedImageBytes != null ||
                            existingImageBytes != null)
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: Image.memory(
                                  selectedImageBytes ?? existingImageBytes!,
                                  width: double.infinity,
                                  height: 210,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: showImageSourceDialog,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 17,
                                      ),
                                      label: const Text('Ganti Foto'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: const BorderSide(
                                          color: primaryColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: removeSelectedImage,
                                    style: IconButton.styleFrom(
                                      backgroundColor: beige,
                                      foregroundColor: primaryColor,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: showImageSourceDialog,
                            child: Container(
                              height: 155,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cream,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: primary.withOpacity(.5),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: primaryColor,
                                    size: 38,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Tambahkan Foto',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ketuk untuk memilih foto',
                                    style: TextStyle(
                                      color: greyText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // =========================
                    // LOKASI
                    // =========================
                    _section(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi Survey',
                      subtitle: 'Masukkan koordinat lokasi',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: latitudeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 12,
                                ),
                                decoration: _input(
                                  label: 'Latitude',
                                  hint: '-7.3390000',
                                  icon: Icons.my_location_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: longitudeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 12,
                                ),
                                decoration: _input(
                                  label: 'Longitude',
                                  hint: '108.2310000',
                                  icon: Icons.explore_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // =========================
                    // SAVE
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : saveSurvey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEdit
                                        ? Icons.check_rounded
                                        : Icons.save_outlined,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit
                                        ? 'SIMPAN PERUBAHAN'
                                        : 'SIMPAN SURVEY',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .4,
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

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
