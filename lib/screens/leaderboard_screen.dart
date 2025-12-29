import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  final String categoryId; // ID Latihan (misal: quiz_1)
  final String categoryName; // Nama Latihan (opsional, untuk judul)

  const LeaderboardScreen({
    super.key,
    required this.categoryId,
    this.categoryName = 'Peringkat Latihan',
  });

  @override
  Widget build(BuildContext context) {
    // Nama field di database yang akan kita sort
    // Contoh: score_quiz_1
    final String scoreField = 'score_$categoryId';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // 1. HEADER GRADIENT
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7B1FA2), Color(0xFFB388FF)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. APP BAR CUSTOM
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                      ), // Spacer penyeimbang tombol back
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Top Peserta",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 30),

                // 3. LIST RANKING SPESIFIK
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy(
                            scoreField,
                            descending: true,
                          ) // Sort berdasarkan Latihan ini
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        // Handle jika tidak ada data atau error (misal field belum ada di index)
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 30),
                          itemCount: docs.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            // Validasi: Hanya tampilkan jika user punya skor di latihan ini
                            // (Meskipun orderBy biasanya otomatis filter field yg null)
                            if (!data.containsKey(scoreField)) {
                              return const SizedBox.shrink();
                            }

                            return _buildRankItem(index + 1, data, scoreField);
                          },
                        );
                      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("Belum ada data peringkat untuk latihan ini."),
          ],
        ),
      ),
    );
  }

  Widget _buildRankItem(
    int rank,
    Map<String, dynamic> data,
    String scoreField,
  ) {
    final avatar = data['avatar'];
    final name = data['fullName'] ?? 'User';
    final score = data[scoreField] ?? 0;

    // Warna Badge Nomor
    Color badgeColor;
    Color textColor;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Emas
      textColor = Colors.white;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0); // Perak
      textColor = Colors.white;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32); // Perunggu
      textColor = Colors.white;
    } else {
      badgeColor = Colors.grey.shade200;
      textColor = Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // NOMOR URUT
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Center(
            child: Text(
              "$rank",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
        // AVATAR & NAMA
        title: Row(
          children: [
            ClipOval(
              child: Container(
                width: 35,
                height: 35,
                color: Colors.grey.shade100,
                child: (avatar != null && avatar.toString().isNotEmpty)
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // SKOR
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$score",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
