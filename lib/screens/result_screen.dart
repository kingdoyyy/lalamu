// File: lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'main_navigator.dart'; // Pastikan path ini sesuai
import 'leaderboard_screen.dart'; // Pastikan path ini sesuai

class ResultScreen extends StatelessWidget {
  final int score; // Total Nilai (Misal: 80)
  final int totalQuestions; // Jumlah Soal (Misal: 10)
  final String categoryId; // ID Latihan (Untuk parameter ke Leaderboard)
  final String categoryName; // Nama Latihan

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // --- 1. LOGIKA STATISTIK ---
    // Asumsi: 1 soal benar = 10 poin.
    // Jadi jika skor 80, berarti benar 8 soal.
    final int correctAnswers = score ~/ 10;
    final int wrongAnswers = totalQuestions - correctAnswers;
    final double percentage = correctAnswers / totalQuestions;

    // --- 2. TENTUKAN PESAN & IKON ---
    String message;
    String subMessage;
    IconData iconStatus;
    Color themeColor;

    if (percentage >= 0.8) {
      message = "Luar Biasa!";
      subMessage = "Kamu menguasai materi ini!";
      iconStatus = Icons.emoji_events_rounded;
      themeColor = Colors.amber;
    } else if (percentage >= 0.5) {
      message = "Kerja Bagus!";
      subMessage = "Tingkatkan lagi sedikit lagi!";
      iconStatus = Icons.thumb_up_alt_rounded;
      themeColor = Colors.blue;
    } else {
      message = "Jangan Menyerah!";
      subMessage = "Teruslah berlatih!";
      iconStatus = Icons.psychology_alt_rounded;
      themeColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Stack(
        children: [
          // A. BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7B1FA2), Color(0xFFB388FF)],
              ),
            ),
          ),

          // B. KONTEN UTAMA
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- KARTU HASIL ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. Icon Status (Lingkaran)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconStatus,
                              size: 60,
                              color: themeColor,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. Teks Pesan
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 3. Skor Besar
                          Text(
                            "$score",
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepPurple,
                              height: 1,
                            ),
                          ),
                          const Text(
                            "Total Poin",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 4. Grid Statistik (Benar & Salah)
                          Row(
                            children: [
                              _buildStatCard(
                                label: "Benar",
                                value: "$correctAnswers",
                                color: Colors.green,
                                icon: Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 15),
                              _buildStatCard(
                                label: "Salah",
                                value: "$wrongAnswers",
                                color: Colors.red,
                                icon: Icons.cancel_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- TOMBOL NAVIGASI ---

                    // Tombol 1: Lihat Ranking Latihan Ini (Primary)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigasi ke LeaderboardScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaderboardScreen(
                                categoryId: categoryId, // Kirim ID Latihan
                                categoryName:
                                    categoryName, // Kirim Nama Latihan
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.leaderboard_rounded),
                        label: const Text(
                          "Lihat Ranking Latihan Ini",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Tombol 2: Kembali ke Beranda (Secondary/Outline)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset ke Main Navigator (Tab Home)
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigator(),
                            ),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white70,
                            width: 1.5,
                          ),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Kembali ke Beranda",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Kotak Statistik Kecil ---
  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
