// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = "Pelajar";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Mengambil nama user dari Firestore
  void _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _displayName = doc.data()?['fullName'] ?? "Pelajar";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // 1. BACKGROUND FIXED (Gradient Ungu)
          Container(
            height: 400,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9C27B0), // Ungu tua
                  Color(0xFFB388FF), // Ungu muda
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. KONTEN SCROLLABLE
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAGIAN HEADER ---
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris Salam & Logout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, $_displayName!',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  'InterQuiz',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Spin Wheel Banner
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A80),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A80).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/spinner.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (c, o, s) => const Icon(
                                    Icons.casino,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lucky Spin!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Putar dan dapatkan poin',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Judul Mapel
                        const Text(
                          'Dasar Desain\nKomunikasi Visual',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- BAGIAN WHITE SHEET (ISI) ---
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latihan Soal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // === GRID DARI DATABASE (DYNAMIC) ===
                      StreamBuilder<QuerySnapshot>(
                        // Mengambil data dari koleksi 'quizzes' di Firestore
                        stream: FirebaseFirestore.instance
                            .collection('quizzes')
                            .snapshots(),
                        builder: (context, snapshot) {
                          // 1. State Loading
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // 2. State Error
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Terjadi kesalahan memuat data."),
                            );
                          }

                          // 3. State Data Kosong
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_off,
                                    size: 50,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Belum ada latihan tersedia.",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            );
                          }

                          // 4. State Ada Data
                          final docs = snapshot.data!.docs;

                          // (Opsional) Sorting manual berdasarkan ID (bab1, bab2, dst)
                          // Agar urutannya rapi
                          docs.sort((a, b) => a.id.compareTo(b.id));

                          return GridView.builder(
                            physics:
                                const NeverScrollableScrollPhysics(), // Scroll ikut parent
                            shrinkWrap: true,
                            itemCount: docs.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              // Ambil ID dokumen sebagai categoryId (misal: 'bab1')
                              final String id = doc.id;

                              // Ambil field 'name' jika ada, kalau tidak gunakan ID yang dirapikan
                              String name = data.containsKey('name')
                                  ? data['name']
                                  : id.toUpperCase();

                              // Jika dokumennya 'pretest' atau 'posttest', kita bisa ubah warnanya atau ikonnya (Opsional)
                              return _buildChapterCard(
                                context,
                                id,
                                name,
                                'assets/book.png', // Default icon
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 80), // Space untuk BottomNav
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildChapterCard(
    BuildContext context,
    String id,
    String name,
    String iconPath,
  ) {
    return InkWell(
      onTap: () {
        // Navigasi ke QuizScreen dengan membawa ID dan Nama
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizScreen(categoryId: id, categoryName: name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => const Icon(
                    Icons.book,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
