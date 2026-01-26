import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halaman_pilih_kursi_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tiket/core/app_bar_costum2.dart';

class HalamanJadwalUser extends StatefulWidget {
  final int idRute;
  final String dari;
  final String ke;
  final String tanggal; // yyyy-MM-dd
  final int harga;
  final int userId;
  final int jumlahPenumpang;

  const HalamanJadwalUser({
    super.key,
    required this.idRute,
    required this.dari,
    required this.ke,
    required this.tanggal,
    required this.harga,
    required this.userId,
    required this.jumlahPenumpang,
  });

  @override
  State<HalamanJadwalUser> createState() => _HalamanJadwalUserState();
}

class _HalamanJadwalUserState extends State<HalamanJadwalUser> {
  List<Map<String, dynamic>> jadwalList = [];
  bool isLoading = true;

  final Color merahUtama = const Color(0xFF960000);
  late DateTime tanggalDipilih;

  @override
  void initState() {
    super.initState();
    tanggalDipilih = DateTime.parse(widget.tanggal);

    debugPrint("ID RUTE TERIMA: ${widget.idRute}");
    debugPrint("TANGGAL TERIMA: ${widget.tanggal}");

    fetchJadwal();
  }

  // ================= FETCH JADWAL (FIX FINAL) =================
  Future<void> fetchJadwal() async {
    setState(() => isLoading = true);

    try {
      final tanggalApi = DateFormat('yyyy-MM-dd').format(tanggalDipilih);
      final url =
          'https://fifafel.my.id/api/jadwal?rute=${widget.idRute}&tanggal=$tanggalApi';

      debugPrint("GET → $url");

      final response = await http.get(Uri.parse(url));

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          if (json['status'] == true && json['data'] != null) {
            jadwalList = List<Map<String, dynamic>>.from(json['data']);
          } else {
            jadwalList = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          jadwalList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR fetchJadwal: $e");
      setState(() {
        jadwalList = [];
        isLoading = false;
      });
    }
  }

  /// CEK JAM SUDAH LEWAT ATAU BELUM
  bool isJamTidakTersedia(String jam) {
    try {
      final parts = jam.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final jadwalTime = DateTime(
        tanggalDipilih.year,
        tanggalDipilih.month,
        tanggalDipilih.day,
        hour,
        minute,
      );

      if (DateUtils.isSameDay(tanggalDipilih, DateTime.now())) {
        return DateTime.now().isAfter(
          jadwalTime.subtract(const Duration(minutes: 15)),
        );
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom2(
        title: "${widget.dari} → ${widget.ke}",
        subtitle:
            "${DateFormat('dd MMMM yyyy', 'id').format(tanggalDipilih)} • ${widget.jumlahPenumpang} org",
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : jadwalList.isEmpty
            ? Center(
                child: Text(
                  "Jadwal tidak tersedia",
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
              )
            : ListView.builder(
                itemCount: jadwalList.length,
                itemBuilder: (context, index) {
                  final item = jadwalList[index];

                  final jam = item['jamKeberangkatan']?.toString() ?? '-';
                  final supir = item['supir']?.toString() ?? '-';
                  final plat = item['platBus']?.toString() ?? '-';
                  final bangku = item['bangkuTersedia'] ?? 0;

                  final bool tidakTersedia =
                      isJamTidakTersedia(jam) || bangku == 0;

                  return GestureDetector(
                    onTap: tidakTersedia
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HalamanPilihKursiUser(
                                  idRute: widget.idRute,
                                  dari: widget.dari,
                                  ke: widget.ke,
                                  tanggal: widget.tanggal,
                                  harga: widget.harga,
                                  idJadwal: item['id_jadwal'],
                                  jumlahPenumpang: widget.jumlahPenumpang,
                                  jamKeberangkatan: jam,
                                  jadwalData: item,
                                ),
                              ),
                            );
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tidakTersedia
                            ? Colors.grey.shade200
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tidakTersedia
                              ? Colors.grey.shade300
                              : merahUtama.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: tidakTersedia
                                  ? Colors.grey.shade300
                                  : merahUtama.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              jam,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tidakTersedia ? Colors.grey : merahUtama,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supir,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  plat,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            tidakTersedia ? "Tidak tersedia" : "$bangku kursi",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: tidakTersedia ? Colors.grey : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
