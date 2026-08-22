import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String nama = "";
  String email = "";
  String username = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');

    if (userString != null) {
      final user = jsonDecode(userString);

      setState(() {
        nama = user['name'] ?? '';
        email = user['email'] ?? '';
        username = user['username'] ?? '';
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');

    if (!mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.lightBlueAccent,
                      child: Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),

                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '@$username',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 40),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pengaturan Akun",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Colors.blue,
                        ),
                        title: const Text("Edit Profil"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(
                          Icons.lock_outline,
                          color: Colors.blue,
                        ),
                        title: const Text("Keamanan & Sandi"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),

                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        title: const Text("Tentang Aplikasi"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}