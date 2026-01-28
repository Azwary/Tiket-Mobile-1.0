import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:tiket/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primarySwatch: Colors.red,
      ),
      home: const HalamanPetugas(),
    ),
  );
}

class HalamanPetugas extends StatefulWidget {
  const HalamanPetugas({Key? key}) : super(key: key);

  @override
  State<HalamanPetugas> createState() => _HalamanPetugasState();
}

class _HalamanPetugasState extends State<HalamanPetugas> {
  final String baseUrl = 'https://fifafel.my.id/api/petugas';

  List<int> kursiLocked = [];
  Timer? kursiTimer;

  List<Map<String, dynamic>> ruteList = [];
  List<Map<String, dynamic>> jadwalList = [];
  List<int> kursiTersedia = [];
  Map<int, int> noToIdKursi = {}; // mapping no_kursi -> id_kursi

  String? selectedRute;
  String? selectedJamId;
  DateTime? selectedDate;
  Map<int, String> penumpangPerKursi = {};
  List<int> selectedSeats = [];

  int hargaRute = 0;
  bool showDenah = false;

  final List<List<dynamic>> seatLayout = [
    [1, 2, null, 'setir'],
    [null, 3, 4, 5],
    [6, null, 7, 8],
    [9, null, 10, 11],
    [12, 13, 14, 15],
  ];

  String get formattedDate {
    if (selectedDate == null) return 'Pilih tanggal';
    return DateFormat('d MMMM yyyy', 'id').format(selectedDate!);
  }

  String get formattedDateForApi {
    if (selectedDate == null) return '0000-00-00';
    return DateFormat('yyyy-MM-dd').format(selectedDate!);
  }

  bool get isFormValid =>
      selectedRute != null && selectedDate != null && selectedJamId != null;

  @override
  void dispose() {
    kursiTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    fetchRute();
  }

  Future<void> fetchRute() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rute'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ruteList = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (_) {}
  }

  Future<void> fetchJam(String ruteId) async {
    final response = await http.get(Uri.parse('$baseUrl/rute/$ruteId/jadwal'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        jadwalList = List<Map<String, dynamic>>.from(data['data']);
      });
    }
  }

  Future<void> fetchKursiTersedia(
    String ruteId,
    String tanggal,
    String jamId,
  ) async {
    final url =
        '$baseUrl/kursi/tersedia?rute=$ruteId&tanggal=$tanggal&jam=$jamId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        kursiTersedia = (data['tersedia'] as List<dynamic>)
            .map((e) => int.parse(e.toString()))
            .toList();

        kursiLocked = (data['locked'] as List<dynamic>)
            .map((e) => int.parse(e.toString()))
            .toList();
      });
    }
  }

  Future<void> submitPemesanan() async {
    final url = Uri.parse('$baseUrl/pesan');
    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      'id_rute': selectedRute.toString(),
      'tanggal': formattedDateForApi,
      'id_jadwal': selectedJamId.toString(),
      'penumpang': penumpangPerKursi.entries
          .map((e) => {"kursi": noToIdKursi[e.key], "nama": e.value})
          .toList(),
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Berhasil"),
          content: const Text("Pemesanan berhasil disimpan!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                setState(() {
                  // Reset semua input agar bisa input baru
                  showDenah = false;
                  selectedSeats.clear();
                  penumpangPerKursi.clear();
                  selectedRute = null;
                  selectedJamId = null;
                  selectedDate = null;
                  jadwalList.clear();
                  kursiTersedia.clear();
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("❌ Gagal"),
          content: Text(
            "Terjadi kesalahan simpan. Status code: ${response.statusCode}\n${response.body}",
          ),
        ),
      );
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              // 🔥 hapus session login
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const Login(), // ✅ BENAR
                ),
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void startAutoRefresh() {
    kursiTimer?.cancel();

    kursiTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (!isFormValid || !showDenah) return;

      fetchKursiTersedia(selectedRute!, formattedDateForApi, selectedJamId!);
    });
  }

  void toggleKursi(int nomor) {
    setState(() {
      if (selectedSeats.contains(nomor)) {
        selectedSeats.remove(nomor);
        penumpangPerKursi.remove(nomor);
      } else {
        selectedSeats.add(nomor);
        penumpangPerKursi[nomor] = '';
      }
    });
  }

  Widget kursiBox(dynamic nomor) {
    if (nomor == null) return const SizedBox(width: 42, height: 42);
    if (nomor == 'setir') {
      return const Icon(Icons.directions_bus, size: 32, color: Colors.black45);
    }

    final isSelected = selectedSeats.contains(nomor);
    final isLocked = kursiLocked.contains(nomor);
    final isAvailable = kursiTersedia.contains(nomor);

    Color warnaKursi;

    if (isLocked) {
      warnaKursi = Colors.grey; // ⏳ LOCKED SEMENTARA
    } else if (!isAvailable) {
      warnaKursi = Colors.grey; // ❌ TERISI
    } else if (isSelected) {
      warnaKursi = Colors.blue; // 🔵 DIPILIH
    } else {
      warnaKursi = Colors.green; // ✅ TERSEDIA
    }

    return GestureDetector(
      onTap: (isAvailable && !isLocked) ? () => toggleKursi(nomor) : null,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: warnaKursi,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          nomor.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
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
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget denahKursi() {
    return Column(
      children: [
        const Text(
          "🪑 Denah Kursi Bus",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...seatLayout.map(
          (row) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map<Widget>((n) => kursiBox(n)).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(Colors.blue, "Dipilih"),
            const SizedBox(width: 16),
            _buildLegend(Colors.green, "Tersedia"),
            const SizedBox(width: 16),
            _buildLegend(Colors.grey, "Terisi / Locked"),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: selectedSeats.map((kursi) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Nama penumpang kursi $kursi",
                  filled: true,
                  fillColor: Colors.grey[100],
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    penumpangPerKursi[kursi] = val;
                  });
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (selectedSeats.isNotEmpty)
          Text(
            "Total Harga: Rp ${selectedSeats.length * hargaRute}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        const SizedBox(height: 12),
        if (selectedSeats.isNotEmpty &&
            penumpangPerKursi.values.every((n) => n.trim().isNotEmpty))
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 125, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            onPressed: submitPemesanan,
            child: const Text(
              'Tambah Pemesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecorationBase = InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 125, 0, 0),
        elevation: 4,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Kontrol Pemesanan - Petugas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.route, color: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          "Pilih Rute",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: const Text('Pilih Rute'),
                      value: selectedRute,
                      items: ruteList.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['id_rute'].toString(),
                          child: Text('${r['asal']} - ${r['tujuan']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final rute = ruteList.firstWhere(
                          (r) => r['id_rute'].toString() == val,
                        );

                        setState(() {
                          selectedRute = val;
                          hargaRute =
                              int.tryParse(rute['harga'].toString()) ?? 0;
                          selectedJamId = null;
                          jadwalList.clear();
                          showDenah = false;
                        });

                        fetchJam(val!);
                      },
                      decoration: inputDecorationBase,
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        SizedBox(width: 6),
                        Text(
                          "Pilih Tanggal",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: formattedDate,
                            ),
                            decoration: inputDecorationBase.copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                  selectedJamId = null; // WAJIB
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Hari Ini",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.access_time, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          "Jam Keberangkatan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      hint: const Text('Pilih Jam Keberangkatan'),
                      value: selectedJamId,
                      items: jadwalList.map((j) {
                        final jamText = j['jam_keberangkatan'] ?? '-';
                        DateTime? jamDateTime;

                        if (selectedDate != null) {
                          final parts = jamText.split(':');
                          if (parts.length >= 2) {
                            jamDateTime = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              int.parse(parts[0]),
                              int.parse(parts[1]),
                            );
                          }
                        }

                        final now = DateTime.now();
                        bool isDisabled = false;

                        if (selectedDate != null && jamDateTime != null) {
                          final today = DateTime(now.year, now.month, now.day);
                          final selectedDay = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                          );

                          // ❌ disable HANYA kalau hari ini & jam sudah lewat
                          if (selectedDay.isAtSameMomentAs(today)) {
                            isDisabled = jamDateTime.isBefore(now);
                          }
                        }

                        return DropdownMenuItem<String>(
                          value: j['id_jadwal'].toString(),
                          enabled: !isDisabled,
                          child: Text(
                            jamText,
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedJamId = val;
                        });
                      },
                      decoration: inputDecorationBase,
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 125, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 12,
                          ),
                        ),
                        onPressed: isFormValid
                            ? () {
                                selectedSeats.clear();
                                penumpangPerKursi.clear();

                                fetchKursiTersedia(
                                  selectedRute!,
                                  formattedDateForApi,
                                  selectedJamId!,
                                );

                                setState(() {
                                  showDenah = true;
                                });

                                startAutoRefresh();
                              }
                            : null,
                        child: const Text(
                          "Tampilkan Data",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showDenah)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: denahKursi(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
