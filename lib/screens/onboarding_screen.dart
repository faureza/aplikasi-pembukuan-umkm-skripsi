import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:umkmjambi/main.dart'; // Impor main.dart untuk akses AuthGate

class OnboardingScreen extends StatefulWidget {
  // [FIX] onFinished tidak lagi diperlukan karena navigasi ditangani di sini.
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Catat Keuangan Harian",
      "subtitle": "Kelola pemasukan & pengeluaran UMKM kamu dengan mudah.",
      "image": "https://cdn-icons-png.flaticon.com/512/4359/4359963.png"
    },
    {
      "title": "Pantau Laporan Otomatis",
      "subtitle": "Dapatkan laporan keuangan secara cepat dan real-time.",
      "image": "https://cdn-icons-png.flaticon.com/512/1183/1183618.png"
    },
    {
      "title": "Data Aman di Cloud",
      "subtitle": "Tersimpan di Firebase, aman dan dapat diakses kapan saja.",
      "image": "https://cdn-icons-png.flaticon.com/512/942/942748.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(p["image"]!, height: 250),
                        const SizedBox(height: 40),
                        Text(
                          p["title"]!,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p["subtitle"]!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _index == index ? 25 : 10,
                  decoration: BoxDecoration(
                    color: _index == index ? Colors.deepOrange : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  // [FIX] Logika navigasi diperbaiki di sini
                  if (_index == pages.length - 1) {
                    // Langsung navigasi ke AuthGate menggunakan context yang valid
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                    );
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _index == pages.length - 1 ? "Mulai" : "Lanjut",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
