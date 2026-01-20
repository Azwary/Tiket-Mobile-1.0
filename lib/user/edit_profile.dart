import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfilePage extends StatefulWidget {
  final int userId; // id user untuk API
  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  final Color primaryRed = const Color.fromARGB(255, 150, 0, 0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load data dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaController.text = prefs.getString('nama_penumpang') ?? '';
      usernameController.text = prefs.getString('username') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      teleponController.text = prefs.getString('no_telepon') ?? '';
      // jangan tampilkan password asli, biar aman
      passwordController.text = '';
    });
  }

  // Simpan data ke SharedPreferences
  Future<void> _saveUserDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama_penumpang', namaController.text);
    await prefs.setString('username', usernameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('no_telepon', teleponController.text);
  }

  // Update profile ke server Laravel
  Future<void> _updateProfileOnServer() async {
    final url = Uri.parse(
      'https://fifafel.my.id/api/penumpang/${widget.userId}',
    );
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_penumpang': namaController.text,
        'username': usernameController.text,
        'email': emailController.text,
        'no_telepon': teleponController.text,
        'password': passwordController.text.isNotEmpty
            ? passwordController.text
            : null,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status']) {
        await _saveUserDataLocally();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal update: ${data['message']}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error server: ${response.statusCode}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Edit Profil",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Nama Lengkap"),
                  _buildTextField(
                    controller: namaController,
                    hint: "Masukkan nama lengkap",
                  ),
                  const SizedBox(height: 18),
                  _buildLabel("Username"),
                  _buildTextField(
                    controller: usernameController,
                    hint: "Masukkan username",
                  ),
                  const SizedBox(height: 18),
                  _buildLabel("Email"),
                  _buildTextField(
                    controller: emailController,
                    hint: "Masukkan email",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel("Nomor Telepon"),
                  _buildTextField(
                    controller: teleponController,
                    hint: "08xxxxxxxxxx",
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _buildLabel("Password"),
                  _buildTextField(
                    controller: passwordController,
                    hint: "Masukkan password baru (opsional)",
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  await _updateProfileOnServer();
                },
                child: Text(
                  "Simpan Perubahan",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1.8),
        ),
      ),
    );
  }
}