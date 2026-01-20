import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController konfirmasiPasswordController =
      TextEditingController();

  bool showPassword = false;
  bool loading = false;

  bool get isFormValid {
    return namaController.text.isNotEmpty &&
        teleponController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        konfirmasiPasswordController.text.isNotEmpty &&
        passwordController.text == konfirmasiPasswordController.text;
  }

  Future<void> registerUser() async {
    setState(() => loading = true);

    final url = Uri.parse('https://fifafel.my.id/api/penumpang/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama_penumpang': namaController.text,
          'no_telepon': teleponController.text,
          'email': emailController.text,
          'username': usernameController.text,
          'password': passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pendaftaran berhasil!')));
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        });
      } else {
        String pesan = 'Gagal daftar.';
        if (data is Map && data.containsKey('errors')) {
          pesan = data['errors'].values.first[0];
        } else if (data is Map && data.containsKey('message')) {
          pesan = data['message'];
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pesan)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  // INPUT STYLE BARU — placeholder di dalam, label di luar
  InputDecoration buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[100],
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
      ),
    );
  }

  // Widget helper untuk label di atas input
  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Akun',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yuk, lengkapi data dirimu untuk daftar.',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            // NAMA
            buildLabel("Nama Lengkap"),
            const SizedBox(height: 6),
            TextField(
              controller: namaController,
              decoration: buildInputDecoration('Masukkan nama lengkap'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // TELEPON
            buildLabel("No Telepon"),
            const SizedBox(height: 6),
            TextField(
              controller: teleponController,
              keyboardType: TextInputType.phone,
              decoration: buildInputDecoration('Masukkan nomor telepon'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // EMAIL
            buildLabel("Email"),
            const SizedBox(height: 6),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: buildInputDecoration('Masukkan email'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // USERNAME
            buildLabel("Username"),
            const SizedBox(height: 6),
            TextField(
              controller: usernameController,
              decoration: buildInputDecoration('Masukkan username'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // PASSWORD
            buildLabel("Password"),
            const SizedBox(height: 6),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: buildInputDecoration(
                'Masukkan password',
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[700],
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // KONFIRMASI PASSWORD
            buildLabel("Konfirmasi Password"),
            const SizedBox(height: 6),
            TextField(
              controller: konfirmasiPasswordController,
              obscureText: true,
              decoration: buildInputDecoration('Ulangi password'),
              onChanged: (_) => setState(() {}),
            ),

            if (passwordController.text.isNotEmpty &&
                konfirmasiPasswordController.text.isNotEmpty &&
                passwordController.text != konfirmasiPasswordController.text)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Password dan konfirmasi password tidak sama',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 30),

            // BUTTON DAFTAR
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: (!loading && isFormValid) ? registerUser : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: (!loading && isFormValid)
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
                          )
                        : LinearGradient(colors: [Colors.grey, Colors.grey]),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          "DAFTAR",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BUTTON LOGIN
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "SUDAH PUNYA AKUN",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
