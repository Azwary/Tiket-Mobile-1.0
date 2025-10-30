import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HalamanPembayaranUser.dart';

class HalamanPilihKursiUser extends StatefulWidget {
  final String dari;
  final String ke;
  final int idJadwal;
  final String jamKeberangkatan;
  final String tanggal;
  final int harga;
  final int idRute;
  final Map<String, dynamic> jadwalData;

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
  });

  @override
  State<HalamanPilihKursiUser> createState() => _HalamanPilihKursiUserState();
}

class _HalamanPilihKursiUserState extends State<HalamanPilihKursiUser> {
  final List<int> kursiDipilih = [];
  List<int> kursiTerpesan = []; // kursi yang terisi dari API
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
        .map<int>((k) => k['no_kursi'] as int)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 150, 0, 0),
        elevation: 1,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Pilih Kursi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rute: ${widget.dari} → ${widget.ke}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text('Jam: ${widget.jamKeberangkatan}', style: GoogleFonts.inter()),
            Text('Tanggal: ${widget.tanggal}', style: GoogleFonts.inter()),
            const SizedBox(height: 20),

            // Legend
            Row(
              children: [
                const Icon(Icons.square, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text('Tersedia', style: GoogleFonts.inter()),
                const SizedBox(width: 16),
                const Icon(Icons.square, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text('Tidak tersedia', style: GoogleFonts.inter()),
                const SizedBox(width: 16),
                const Icon(Icons.square, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('Dipilih', style: GoogleFonts.inter()),
              ],
            ),

            const SizedBox(height: 10),

            // Seat layout
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: seatLayout.map((row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((item) {
                            if (item == null)
                              return const SizedBox(width: 50, height: 50);
                            if (item == 'steering') {
                              return Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.all(6),
                                alignment: Alignment.center,
                                child: const Icon(Icons.drive_eta, size: 30),
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
            ),

            const SizedBox(height: 20),

            // Total harga
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

            // Tombol lanjut
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: kursiDipilih.isNotEmpty
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
                  backgroundColor: kursiDipilih.isNotEmpty
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
}
