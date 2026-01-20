import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halaman_pilih_kursi_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tiket/core/app_bar_costum.dart';

class HalamanJadwalUser extends StatefulWidget {
  final int idRute;
  final String dari;
  final String ke;
  final String tanggal;
  final int harga;
  final int userId;
  final int? jumlahPenumpang;

  const HalamanJadwalUser({
    super.key,
    required this.idRute,
    required this.dari,
    required this.ke,
    required this.tanggal,
    required this.harga,
    required this.userId,
    this.jumlahPenumpang,
  });

  @override
  State<HalamanJadwalUser> createState() => _HalamanJadwalUserState();
}

class _HalamanJadwalUserState extends State<HalamanJadwalUser> {
  List<Map<String, dynamic>> jadwalList = [];
  final Color merahUtama = const Color.fromARGB(255, 150, 0, 0);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    setState(() => isLoading = true);
    try {
      final tanggalApi = DateFormat('yyyy-MM-dd')
          .format(DateFormat('dd MMMM yyyy', 'id').parse(widget.tanggal));

      final response = await http.get(
        Uri.parse(
          'https://fifafel.my.id/api/jadwal?rute=${widget.idRute}&tanggal=$tanggalApi',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            jadwalList = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          setState(() => jadwalList = []);
        }
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  bool isJamTidakTersedia(String? jam) {
    if (jam == null) return true;

    try {
      final jamBerangkat = DateFormat("HH:mm").parse(jam);
      final tgl =
          DateFormat('dd MMMM yyyy', 'id').parse(widget.tanggal);

      final jadwalFull = DateTime(
        tgl.year,
        tgl.month,
        tgl.day,
        jamBerangkat.hour,
        jamBerangkat.minute,
      );

      if (DateUtils.isSameDay(tgl, DateTime.now())) {
        return DateTime.now()
            .isAfter(jadwalFull.subtract(const Duration(minutes: 15)));
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(title: 'Pilih Jam'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rute: ${widget.dari} → ${widget.ke}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${widget.harga}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: merahUtama,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Silakan pilih jam keberangkatan:",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// ================= LIST JAM =================
                  Expanded(
                    child: jadwalList.isEmpty
                        ? Center(
                            child: Text(
                              "Jadwal tidak tersedia",
                              style: GoogleFonts.poppins(),
                            ),
                          )
                        : ListView.builder(
                            itemCount: jadwalList.length,
                            itemBuilder: (context, index) {
                              final item = jadwalList[index];
                              final jam = item['jamKeberangkatan'] ?? '-';
                              final supir = item['supir'] ?? '-';
                              final plat = item['platBus'] ?? '-';
                              final bangku = item['bangkuTersedia'] ?? 0;

                              final tidakTersedia =
                                  isJamTidakTersedia(jam) || bangku == 0;

                              return GestureDetector(
                                onTap: tidakTersedia
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HalamanPilihKursiUser(
                                              idRute: widget.idRute,
                                              dari: widget.dari,
                                              ke: widget.ke,
                                              tanggal: widget.tanggal,
                                              harga: widget.harga,

                                                 idJadwal: int.parse(item['id_jadwal'].toString()),

                                              jamKeberangkatan: jam,
                                              jadwalData: item,
                                            ),
                                          ),
                                        );
                                      },
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: tidakTersedia
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: tidakTersedia
                                          ? Colors.grey.shade300
                                          : merahUtama.withOpacity(0.4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      /// JAM
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          color: tidakTersedia
                                              ? Colors.grey.shade300
                                              : merahUtama
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          jam,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: tidakTersedia
                                                ? Colors.grey
                                                : merahUtama,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 14),

                                      /// INFO
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              supir,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: tidakTersedia
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              plat,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: tidakTersedia
                                                    ? Colors.grey
                                                    : Colors
                                                        .grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      /// STATUS
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6),
                                        decoration: BoxDecoration(
                                          color: tidakTersedia
                                              ? Colors.grey.shade300
                                              : Colors.green
                                                  .shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          tidakTersedia
                                              ? "Tidak tersedia"
                                              : "$bangku kursi",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: tidakTersedia
                                                ? Colors.grey
                                                    .shade700
                                                : Colors.green
                                                    .shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
