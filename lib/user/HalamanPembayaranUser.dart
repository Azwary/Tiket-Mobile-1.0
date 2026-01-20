import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'halaman_konfirmasi_pembayaran.dart';
import 'package:tiket/core/app_bar_costum.dart';



class HalamanPembayaranUser extends StatefulWidget {
  final String dari;
  final String ke;
  final String tanggal;
  final String jamKeberangkatan;
  final List<int> kursi;
  final int harga;
  final String? namaPenumpang;
  final int idPenumpang;
  final int idJadwal;
  final int idPemesanan;

  const HalamanPembayaranUser({
    super.key,
    required this.dari,
    required this.ke,
    required this.tanggal,
    required this.jamKeberangkatan,
    required this.kursi,
    required this.harga,
    required this.namaPenumpang,
    required this.idPenumpang,
    required this.idJadwal,
    required this.idPemesanan,
  });

  @override
  State<HalamanPembayaranUser> createState() => _HalamanPembayaranUserState();
}

class _HalamanPembayaranUserState extends State<HalamanPembayaranUser> {
  final formatter = NumberFormat.decimalPattern();
  final List<TextEditingController> namaControllers = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id');

    for (int i = 0; i < widget.kursi.length; i++) {
      final c = TextEditingController();
      if (i == 0 && widget.namaPenumpang != null) {
        c.text = widget.namaPenumpang!;
      }
      namaControllers.add(c);
    }
  }

  @override
  void dispose() {
    for (var c in namaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalBayar = widget.kursi.length * widget.harga;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ PENTING
       appBar: const AppBarCustom(title: 'Pembayaran'),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// INFORMASI PEMESANAN
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informasi Pemesanan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow("Rute", "${widget.dari} → ${widget.ke}"),
                    _infoRow("Tanggal", widget.tanggal),
                    _infoRow("Jam", widget.jamKeberangkatan),
                    const Divider(height: 24),
                    Text(
                      "Total Pembayaran: Rp ${formatter.format(totalBayar)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// DETAIL PENUMPANG
            const Text(
              "Detail Penumpang",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.kursi.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Penumpang ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Kursi ${widget.kursi[index]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: namaControllers[index],
                          decoration: InputDecoration(
                            hintText: "Nama Penumpang",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      /// TOMBOL BAWAH
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 150, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // ✅ KUNCI UTAMA
                FocusScope.of(context).unfocus();

                final namaPenumpangList = namaControllers
                    .map((c) => c.text.trim())
                    .toList();

                if (namaPenumpangList.any((e) => e.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Harap isi semua nama penumpang"),
                    ),
                  );
                  return;
                }

                try {
                  await http.post(
                    Uri.parse('https://fifafel.my.id/api/unlock-kursi'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'id_jadwal': widget.idJadwal}),
                  );

                  final res = await http.post(
                    Uri.parse('https://fifafel.my.id/api/lock-kursi'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'id_jadwal': widget.idJadwal,
                      'kursi': widget.kursi,
                    }),
                  );

                  if (res.statusCode != 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal mengunci kursi")),
                    );
                    return;
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Koneksi gagal")),
                  );
                  return;
                }

                final detailPenumpang = List.generate(
                  widget.kursi.length,
                  (i) => {
                    "id_jadwal": widget.idJadwal,
                    "id_kursi": widget.kursi[i],
                    "nama": namaPenumpangList[i],
                  },
                );

                final parsedTanggal = DateFormat(
                  'dd MMMM yyyy',
                  'id',
                ).parse(widget.tanggal);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HalamanKonfirmasiPembayaran(
                      dari: widget.dari,
                      ke: widget.ke,
                      tanggal: DateFormat('yyyy-MM-dd').format(parsedTanggal),
                      jamKeberangkatan: widget.jamKeberangkatan,
                      totalBayar: totalBayar,
                      detailPenumpang: detailPenumpang,
                      idPemesanan: widget.idPemesanan,
                    ),
                  ),
                );
              },
              child: const Text(
                "Lanjut ke Pembayaran",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}