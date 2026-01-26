import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiket/core/app_bar_costum.dart';

class DetailTikePage extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailTikePage({super.key, required this.data});

  String displayStatus(String status) {
    if (status.toLowerCase() == 'berhasil') return 'Aktif';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final asal = data['asal'] ?? '-';
    final tujuan = data['tujuan'] ?? '-';
    final tanggal = data['tanggal_keberangkatan'] ?? '-';
    final jam = data['jam'] ?? '-';
    final penumpang = List<Map<String, dynamic>>.from(data['penumpang'] ?? []);
    final totalBayar = double.tryParse(data['total_bayar'].toString()) ?? 0;
    final nomorTiket = data['nomor_tiket'] ?? '-';

    return Scaffold(
      appBar: const AppBarCustom(title: 'ETIKET'),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: Color(0xFF960000),
                    size: 45,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "FIFAFEL TRANS",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF960000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusChip(status),
                  const SizedBox(height: 20),

                  // ==== Rute & Jadwal ====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              asal,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tujuan,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _iconText(Icons.calendar_today, tanggal),
                            _iconText(Icons.access_time, jam),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Harap datang 15 menit sebelum keberangkatan!",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==== Info Tiket ====
                  _infoRow(
                    "Nomor Tiket",
                    nomorTiket,
                    valueColor: const Color(0xFF960000),
                  ),
                  _infoRow(
                    "Total Pembayaran",
                    _formatRupiah(totalBayar),
                    valueColor: const Color(0xFF960000),
                  ),

                  const SizedBox(height: 20),

                  // ==== Detail Penumpang ====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail Penumpang",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        penumpang.isEmpty
                            ? Center(
                                child: Text(
                                  "Tidak ada data penumpang",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Column(
                                children: penumpang.map((p) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFF1F1),
                                          Color(0xFFFFFFFF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p['nama'] ?? '-',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.event_seat,
                                              size: 16,
                                              color: Colors.black54,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "Kursi ${p['kursi'] ?? '-'}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==== Footer di dalam card ====
                  Column(
                    children: [
                      Text(
                        "“Melayani dengan Kenyamanan dan Kecepatan”",
                        style: GoogleFonts.montserrat(
                          color: Colors.black54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PT Fifafel Trans",
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== CHIP STATUS ====
  Widget _statusChip(String status) {
    final display = displayStatus(status);
    Color bgColor;
    Color textColor;

    switch (display.toLowerCase()) {
      case 'aktif':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'menunggu':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 15),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(dynamic value) {
    final n = (value is num)
        ? value.toInt()
        : int.tryParse(value.toString()) ?? 0;
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }
}
