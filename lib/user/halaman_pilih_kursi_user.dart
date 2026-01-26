import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'HalamanPembayaranUser.dart';
import 'package:tiket/core/app_bar_costum2.dart';

class HalamanPilihKursiUser extends StatefulWidget {
  final String dari;
  final String ke;
  final int idJadwal;
  final String jamKeberangkatan;
  final String tanggal;
  final int harga;
  final int idRute;
  final Map<String, dynamic> jadwalData;
  final int jumlahPenumpang;

  const HalamanPilihKursiUser({
    super.key,
    required this.dari,
    required this.ke,
    required this.idJadwal,
    required this.jamKeberangkatan,
    required this.tanggal,
    required this.harga,
    required this.idRute,
    required this.jadwalData,
    required this.jumlahPenumpang,
  });

  @override
  State<HalamanPilihKursiUser> createState() => _HalamanPilihKursiUserState();
}

class _HalamanPilihKursiUserState extends State<HalamanPilihKursiUser> {
  final List<int> kursiDipilih = [];
  List<int> kursiTerpesan = [];
  final formatter = NumberFormat.decimalPattern();

  final List<List<dynamic>> seatLayout = [
    [1, 2, null, 'steering'],
    [null, 3, 4, 5],
    [6, null, 7, 8],
    [9, null, 10, 11],
    [12, 13, 14, 15],
  ];

  @override
  void initState() {
    super.initState();
    setKursiTerisiFromApi();
  }

  void setKursiTerisiFromApi() {
    kursiTerpesan = (widget.jadwalData['kursi'] as List)
        .where((k) {
          final status = k['status'] ?? 'kosong';
          return status == 'disable' || status == 'ditolak';
        })
        .map<int>((k) => int.parse(k['no_kursi'].toString()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom2(
        title: "Pilih Kursi",
        subtitle:
            "${widget.jamKeberangkatan} • ${widget.dari} → ${widget.ke} • ${widget.jumlahPenumpang} org",
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== LEGEND (DIPERBAIKI) =====
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendItem(Colors.green, 'Tersedia'),
                  const SizedBox(width: 16),
                  _legendItem(Colors.grey, 'Tidak tersedia'),
                  const SizedBox(width: 16),
                  _legendItem(Colors.blue, 'Dipilih'),
                ],
              ),
            ),

            // jarak diperlebar agar kursi lebih "bernapas"
            const SizedBox(height: 18),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: seatLayout.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((item) {
                          if (item == null) {
                            return const SizedBox(width: 50, height: 50);
                          }

                          if (item == 'steering') {
                            return Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.all(6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                MdiIcons.steering,
                                size: 40,
                                color: Colors.black87,
                              ),
                            );
                          }

                          return buildSeat(item as int);
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== TOTAL HARGA =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${kursiDipilih.length} kursi',
                  style: GoogleFonts.inter(),
                ),
                Text(
                  'Rp. ${formatter.format(kursiDipilih.length * widget.harga)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ===== TOMBOL LANJUT =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: kursiDipilih.length == widget.jumlahPenumpang
                    ? () async {
                        final kursiDipilihUrut = [...kursiDipilih]..sort();

                        final prefs = await SharedPreferences.getInstance();
                        final namaUserLogin =
                            prefs.getString('nama_penumpang') ?? '';
                        final idUserLogin = prefs.getInt('id_penumpang') ?? 0;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HalamanPembayaranUser(
                              dari: widget.dari,
                              ke: widget.ke,
                              tanggal: widget.tanggal,
                              jamKeberangkatan: widget.jamKeberangkatan,
                              kursi: kursiDipilihUrut,
                              harga: widget.harga,
                              namaPenumpang: namaUserLogin,
                              idPenumpang: idUserLogin,
                              idJadwal: widget.idJadwal,
                              idPemesanan: 0,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kursiDipilih.length == widget.jumlahPenumpang
                      ? const Color.fromARGB(255, 150, 0, 0)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Ringkasan Pemesanan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // ===== WIDGET KURSI =====
  Widget buildSeat(int seatNumber) {
    final isUnavailable = kursiTerpesan.contains(seatNumber);
    final isSelected = kursiDipilih.contains(seatNumber);

    Color seatColor;
    if (isUnavailable) {
      seatColor = Colors.grey;
    } else if (isSelected) {
      seatColor = Colors.blue;
    } else {
      seatColor = Colors.green;
    }

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  kursiDipilih.remove(seatNumber);
                } else {
                  if (kursiDipilih.length >= widget.jumlahPenumpang) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jumlah kursi sudah sesuai penumpang'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  kursiDipilih.add(seatNumber);
                }
              });
            },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$seatNumber',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===== LEGEND ITEM =====
  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 13)),
      ],
    );
  }
}
