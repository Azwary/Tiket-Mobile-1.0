import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'halaman_utama_user.dart';
import 'package:tiket/core/app_bar_costum.dart';

class HalamanKonfirmasiPembayaran extends StatefulWidget {
  final String dari, ke, tanggal, jamKeberangkatan;
  final int totalBayar;
  final int idPemesanan;
  final List<Map<String, dynamic>> detailPenumpang;

  const HalamanKonfirmasiPembayaran({
    super.key,
    required this.dari,
    required this.ke,
    required this.tanggal,
    required this.jamKeberangkatan,
    required this.totalBayar,
    required this.idPemesanan,
    required this.detailPenumpang,
  });

  @override
  State<HalamanKonfirmasiPembayaran> createState() =>
      _HalamanKonfirmasiPembayaranState();
}

class _HalamanKonfirmasiPembayaranState
    extends State<HalamanKonfirmasiPembayaran> {
  late Timer _timer;
  int _remainingSeconds = 15 * 60;
  PlatformFile? pickedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  String formatTanggalIndo(String tanggal) {
    final date = DateTime.parse(tanggal);
    return DateFormat('d MMMM yyyy', 'id').format(date);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        if (mounted) {
          _showWaktuHabisDialog();
        }
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image, // FOTO SAJA
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      if (!mounted) return;
      setState(() => pickedFile = result.files.first);
    }
  }

  Future<void> _uploadBukti() async {
    if (pickedFile == null) {
      _showErrorDialog("Silakan pilih foto bukti pembayaran terlebih dahulu!");
      return;
    }

    final allowed = ['jpg', 'jpeg', 'png'];
    final ext = pickedFile!.extension?.toLowerCase();
    if (!allowed.contains(ext)) {
      _showErrorDialog("Hanya foto JPG atau PNG yang diperbolehkan.");
      return;
    }
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final idPenumpang = prefs.getInt('id_penumpang');

      if (idPenumpang == null) {
        _showErrorDialog("ID penumpang tidak ditemukan. Silakan login ulang.");
        return;
      }

      final uri = Uri.parse('https://fifafel.my.id/api/pemesanan');
      final request = http.MultipartRequest('POST', uri);

      request.fields['id_penumpang'] = idPenumpang.toString();
      request.fields['id_jadwal'] = widget.detailPenumpang.first['id_jadwal']
          .toString();
      request.fields['tanggal'] = widget.tanggal;

      for (int i = 0; i < widget.detailPenumpang.length; i++) {
        request.fields['nama[$i]'] = widget.detailPenumpang[i]['nama'];
        request.fields['kursi[$i]'] = widget.detailPenumpang[i]['id_kursi']
            .toString();
      }

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            pickedFile!.bytes!,
            filename: pickedFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            pickedFile!.path!,
            filename: pickedFile!.name,
          ),
        );
      }

      request.headers.addAll({
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          if (!mounted) return;

          final prefs = await SharedPreferences.getInstance();
          final idPenumpang = prefs.getInt('id_penumpang');

          if (idPenumpang != null) {
            _showBuktiTerkirimDialog(idPenumpang);
          }
        }
      } else {
        final data = json.decode(response.body);
        _showErrorDialog(
          data['message'] ??
              'Terjadi kesalahan server (${response.statusCode})',
        );
      }
    } catch (e) {
      _showErrorDialog("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // 🔓 Fungsi unlock kursi manual/back
  Future<void> _unlockKursi() async {
    try {
      final idJadwal = widget.detailPenumpang.first['id_jadwal'];
      final kursiIds = widget.detailPenumpang
          .map((p) => p['id_kursi'].toString())
          .toList();

      final uri = Uri.parse('https://fifafel.my.id/api/unlock-kursi');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_jadwal': idJadwal, 'kursi': kursiIds}),
      );

      if (response.statusCode == 200) {
        print("✅ Kursi berhasil di-unlock saat kembali");
      } else {
        print("⚠️ Gagal unlock kursi: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Terjadi kesalahan unlock kursi: $e");
    }
  }

  void _showBuktiTerkirimDialog(int idPenumpang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 12),
            Text(
              "Bukti Pembayaran Terkirim!",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Silahkan tunggu konfirmasi admin di halaman tiket saya.",
              style: GoogleFonts.poppins(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // tutup dialog

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const HalamanUtamaUser(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF960000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Tiket Saya",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _showWaktuHabisDialog() async {
    await _unlockKursi();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off, color: Color(0xFF960000), size: 80),
            const SizedBox(height: 12),
            Text(
              "Waktu Habis!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Batas waktu pembayaran berakhir.\nPemesanan dibatalkan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const HalamanUtamaUser(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF960000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Kembali ke Beranda",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waktuHabis = _remainingSeconds == 0;

    return WillPopScope(
      onWillPop: () async {
        return await _showKonfirmasiKembaliDialog();
      },
      child: Scaffold(
        appBar: AppBarCustom(
          title: 'Pembayaran',
          onBack: () async {
            await _showKonfirmasiKembaliDialog();
          },
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildTimer(waktuHabis),
              const SizedBox(height: 20),
              _buildDetailCard(),
              const SizedBox(height: 14),
              _buildTransferCard(),
              const SizedBox(height: 14),
              _buildUploadCard(waktuHabis),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (waktuHabis || pickedFile == null || _isUploading)
                      ? null
                      : _uploadBukti,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF960000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Kirim Bukti Pembayaran",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showKonfirmasiKembaliDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Konfirmasi"),
            content: const Text(
              "Jika Anda kembali, kursi yang dipilih akan dilepaskan.\n\nLanjutkan?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // batal
                },
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF960000),
                ),
                onPressed: () async {
                  await _unlockKursi();
                  if (!mounted) return;

                  Navigator.of(context).pop(false);

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HalamanUtamaUser(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },

                child: const Text(
                  "Ya, Kembali",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- Bagian UI Kartu dan Komponen ---

  Widget _buildDetailCard() => _buildCard(
    title: "Detail Pemesanan",
    icon: Icons.receipt_long,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow("Rute", "${widget.dari} → ${widget.ke}"),
        _buildRow("Tanggal", formatTanggalIndo(widget.tanggal)),
        _buildRow("Jam", widget.jamKeberangkatan),
        _buildRow("Jumlah Kursi", "${widget.detailPenumpang.length} kursi"),
        const SizedBox(height: 10),
        Text(
          "Detail Penumpang:",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        ...widget.detailPenumpang.map(
          (p) => Text(
            "• Kursi ${p['id_kursi']}: ${p['nama']}",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Total: Rp${widget.totalBayar}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF007BFF),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTransferCard() => _buildCard(
    title: "Transfer Pembayaran",
    icon: Icons.account_balance,
    child: Column(
      children: [
        _buildRow("No. Rekening", "1234-5678-9999"),
        _buildRow("Atas Nama", "PT Travel Sejahtera"),
      ],
    ),
  );

  Widget _buildUploadCard(bool waktuHabis) => _buildCard(
    title: "Upload Bukti Pembayaran",
    icon: Icons.upload_file,
    child: Center(
      child: OutlinedButton.icon(
        onPressed: waktuHabis ? null : _pickFile,
        icon: const Icon(Icons.attach_file),
        label: Text(pickedFile == null ? "Pilih Foto" : pickedFile!.name),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF960000),
          side: const BorderSide(color: Color(0xFF960000)),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );

  Widget _buildTimer(bool waktuHabis) => AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: waktuHabis ? Colors.grey[300] : const Color(0xFFFFE5E5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.timer,
          color: waktuHabis ? Colors.grey[700] : const Color(0xFF960000),
        ),
        const SizedBox(width: 8),
        Text(
          waktuHabis
              ? "❌ Waktu pembayaran habis"
              : "Selesaikan sebelum: ${_formatDuration(_remainingSeconds)}",
          style: GoogleFonts.poppins(
            color: waktuHabis ? Colors.grey[700] : const Color(0xFF960000),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const Divider(height: 16, color: Color(0xFFE0E0E0)),
        child,
      ],
    ),
  );

  Widget _buildRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
