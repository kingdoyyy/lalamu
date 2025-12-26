import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  // Default selection: Global
  String selectedQuizId = 'global';
  String selectedQuizTitle = 'Global Rank';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // 1. HEADER GRADIENT
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7B1FA2), Color(0xFFB388FF)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // JUDUL HALAMAN
                const Center(
                  child: Text(
                    "Papan Peringkat",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 2. LIST KATEGORI / LATIHAN (HORIZONTAL)
                // Mengambil daftar kuis dari collection 'quizzes' agar tab-nya dinamis
                SizedBox(
                  height: 50,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Item pertama selalu Global Rank
                      List<Map<String, String>> categories = [
                        {'id': 'global', 'title': 'Global Rank'},
                      ];

                      // Jika ada data latihan, tambahkan ke list
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          categories.add({
                            'id': doc.id, // ID Dokumen (misal: quiz_1)
                            'title': data['name'] ?? 'Latihan',
                          });
                        }
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final item = categories[index];
                          final bool isSelected = selectedQuizId == item['id'];

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedQuizId = item['id']!;
                                  selectedQuizTitle = item['title']!;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.amber
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    item['title']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // LABEL JUDUL LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedQuizTitle, // Judul berubah sesuai tab
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.sort, color: Colors.white70),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 3. LIST USER (VERTIKAL)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // Padding bawah agar tidak tertutup navbar
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: _buildUserList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    // --- LOGIKA UTAMA PERUBAHAN ---
    // Tentukan field mana yang mau di-sort di collection 'users'
    // Jika Global -> ambil field 'totalScore'
    // Jika Latihan -> ambil field 'score_' + id_kuis (Contoh: score_quiz_1)

    String orderByField = (selectedQuizId == 'global')
        ? 'totalScore'
        : 'score_$selectedQuizId';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(orderByField, descending: true) // Urutkan score tertinggi
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Jika data kosong (atau tidak ada user yang punya field score tersebut)
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                Text(
                  "Belum ada peringkat\nuntuk kategori ini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rank = index + 1;

            // Ambil skor sesuai field yang sedang aktif
            // Jika field tidak ada (null), anggap 0
            final score = data[orderByField] ?? 0;

            return _buildRankCard(rank, data, score);
          },
        );
      },
    );
  }

  Widget _buildRankCard(int rank, Map<String, dynamic> data, dynamic score) {
    // Styling Badge Juara 1, 2, 3
    Color badgeColor;
    Color numColor;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Emas
      numColor = Colors.white;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Perak
      numColor = Colors.white;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Perunggu
      numColor = Colors.white;
    } else {
      badgeColor = Colors.grey.shade100; // Biasa
      numColor = Colors.grey.shade600;
    }

    final avatarUrl = data['avatar'];
    final name = data['fullName'] ?? 'Pengguna';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // NOMOR URUT
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              "$rank",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: numColor,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // FOTO & NAMA
        title: Row(
          children: [
            // Avatar Kecil (Safe Load)
            ClipOval(
              child: Container(
                width: 40,
                height: 40,
                color: Colors.grey.shade200,
                child: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            // Nama User
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // SKOR
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$score pts",
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
