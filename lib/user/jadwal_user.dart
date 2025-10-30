import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'halaman_pilih_kursi_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Map<String, dynamic>? selectedJadwal;
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
      final tanggalApi = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd MMMM yyyy', 'id').parse(widget.tanggal));
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
          setState(() {
            jadwalList = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Data jadwal kosong')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ambil jadwal: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fungsi untuk cek apakah jam sudah lewat atau kurang dari 15 menit sebelum keberangkatan
  bool isJamTidakTersedia(String? jam) {
    if (jam == null) return true;

    try {
      // Parse jam keberangkatan
      final formatJam = DateFormat("HH:mm");
      final jamBerangkat = formatJam.parse(jam);

      // Parse tanggal perjalanan dari input (format 'dd MMMM yyyy')
      final tglPerjalanan = DateFormat(
        'dd MMMM yyyy',
        'id',
      ).parse(widget.tanggal);

      final jadwalFull = DateTime(
        tglPerjalanan.year,
        tglPerjalanan.month,
        tglPerjalanan.day,
        jamBerangkat.hour,
        jamBerangkat.minute,
      );

      final now = DateTime.now();

      // Cek apakah jadwal hari ini
      final isHariIni =
          tglPerjalanan.year == now.year &&
          tglPerjalanan.month == now.month &&
          tglPerjalanan.day == now.day;

      if (isHariIni) {
        // Jika hari ini, disable jika kurang dari 15 menit sebelum keberangkatan
        final batas15Menit = jadwalFull.subtract(const Duration(minutes: 15));
        return now.isAfter(batas15Menit);
      } else {
        // Jika bukan hari ini, jadwal tetap bisa dipilih (selama kursi tersedia)
        return false;
      }
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Jam',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: merahUtama,
        foregroundColor: Colors.white,
      ),
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
                  const SizedBox(height: 12),
                  if (widget.jumlahPenumpang != null)
                    Text(
                      "Jumlah Penumpang: ${widget.jumlahPenumpang}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
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
                              final isSelected = selectedJadwal == item;
                              final tidakTersedia =
                                  isJamTidakTersedia(jam) || bangku == 0;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected
                                        ? merahUtama
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.white,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.directions_bus,
                                    color: merahUtama,
                                  ),
                                  title: Text(
                                    jam,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: tidakTersedia
                                          ? Colors.grey
                                          : (isSelected
                                                ? merahUtama
                                                : Colors.black),
                                    ),
                                  ),
                                  subtitle: Text(
                                    tidakTersedia
                                        ? "Tidak tersedia"
                                        : (bangku == 0
                                              ? "Kursi Penuh"
                                              : "$bangku kursi tersedia"),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: tidakTersedia
                                          ? Colors.grey
                                          : (bangku == 0
                                                ? Colors.red
                                                : Colors.green),
                                    ),
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        supir,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: tidakTersedia
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        plat,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: tidakTersedia
                                              ? Colors.grey
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: (tidakTersedia || bangku == 0)
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedJadwal = item;
                                          });
                                        },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: Text('Kembali', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (selectedJadwal != null)
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HalamanPilihKursiUser(
                                        idRute: widget.idRute,
                                        dari: widget.dari,
                                        ke: widget.ke,
                                        tanggal: widget.tanggal,
                                        harga: widget.harga,
                                        idJadwal:
                                            selectedJadwal!['id_jadwal'] ?? 0,
                                        jamKeberangkatan:
                                            selectedJadwal!['jamKeberangkatan'] ??
                                            '-',
                                        jadwalData: selectedJadwal!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(
                            'Lanjutkan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: merahUtama,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
