import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'detail_tiket.dart';
import 'halaman_utama_user.dart';

class TiketSayaPage extends StatefulWidget {
  final Map<String, dynamic>? tiketBaru;
  final int idPenumpang;

  const TiketSayaPage({super.key, this.tiketBaru, required this.idPenumpang});

  @override
  State<TiketSayaPage> createState() => _TiketSayaPageState();
}

class _TiketSayaPageState extends State<TiketSayaPage> {
  List<Map<String, dynamic>> daftarTiket = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTiket();
  }

  Future<void> fetchTiket() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse('https://fifafel.my.id/api/tiket/${widget.idPenumpang}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          List<Map<String, dynamic>> tiketDariApi =
              List<Map<String, dynamic>>.from(data['data']);

          if (widget.tiketBaru != null) {
            tiketDariApi.insert(0, widget.tiketBaru!);
          }

          final now = DateTime.now();

          tiketDariApi = tiketDariApi.where((t) {
            String status = t['status'].toString().toLowerCase();

            // hanya izinkan status tertentu
            if (status != 'menunggu' &&
                status != 'berhasil' &&
                status != 'ditolak' &&
                status != 'ditempat') {
              return false;
            }

            try {
              final tanggal = t['tanggal_keberangkatan'].toString();
              final jam = t['jam'].toString().padLeft(5, '0');
              final keberangkatanStr = '${tanggal}T$jam:00';
              final keberangkatan = DateTime.parse(keberangkatanStr).toLocal();

              print(
                '🕓 Sekarang: $now | Keberangkatan: $keberangkatan | Status: $status',
              );

              // tampilkan hanya jika waktu keberangkatan > waktu sekarang
              return keberangkatan.isAfter(now);
            } catch (e) {
              print('⚠️ Gagal parse tanggal tiket: $e');
              return false;
            }
          }).toList();

          // Urutkan tiket berdasarkan nomor tiket terbaru
          int extractTicketNumber(String tiket) {
            final match = RegExp(r'(\d+)$').firstMatch(tiket);
            return match != null ? int.parse(match.group(1)!) : 0;
          }

          tiketDariApi.sort((a, b) {
            final noA = extractTicketNumber(a['nomor_tiket'].toString());
            final noB = extractTicketNumber(b['nomor_tiket'].toString());
            return noB.compareTo(noA);
          });

          if (!mounted) return;
          setState(() {
            daftarTiket = tiketDariApi;
          });
        } else {
          setState(() => daftarTiket = []);
        }
      } else {
        setState(() => daftarTiket = []);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => daftarTiket = []);
      print('❌ Error fetch tiket: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String displayStatus(String status) {
    if (status.toLowerCase() == 'berhasil') return 'Aktif';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Tiket Saya',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF960000),
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : daftarTiket.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ICON
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF960000).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TITLE
                    Text(
                      'Belum Ada Tiket',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // SUBTITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 42),
                      child: Text(
                        'Tiket yang sudah dipesan akan muncul di halaman ini',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // BUTTON PESAN TIKET
                    SizedBox(
                      width: 180,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HalamanUtamaUser (),
                            ),
                            (route) => false,
                          );
                        },

                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          'Pesan Tiket',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF960000),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daftarTiket.length,
                itemBuilder: (context, i) {
                  final ticket = daftarTiket[i];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailTikePage(data: ticket),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header tanggal pemesanan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE7F8EF),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dipesan: ${ticket['tanggal_pemesanan']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Isi tiket
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon bus
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECEC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    size: 24,
                                    color: Color(0xFF960000),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Info utama tiket
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ticket['asal']} → ${ticket['tujuan']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${ticket['tanggal_keberangkatan']} • ${ticket['jam']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nomor Tiket: ${ticket['nomor_tiket']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.people_alt_rounded,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${(ticket['penumpang'] as List).length} Penumpang • Kursi: ${ticket['penumpang'].map((p) => p['kursi']).join(', ')}',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Status dan harga
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          ticket['status'].toString(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        displayStatus(ticket['status']),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatRupiah(ticket['total_bayar']),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF222222),
                                      ),
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
                },
              ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'berhasil' || s == 'aktif') return Colors.green;
    if (s == 'ditolak') return Colors.red;
    if (s == 'ditempat') return Colors.blueGrey;
    return Colors.orange;
  }

  String _formatRupiah(dynamic value) {
    final n = (value is num)
        ? value.toInt()
        : int.tryParse(value.toString().split('.').first) ?? 0;
    final s = n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }
}
