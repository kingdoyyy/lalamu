import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variabel State
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> quizHistory = [];
  bool isHistoryLoading =
      true; // Hanya loading untuk history, profil langsung tampil

  @override
  void initState() {
    super.initState();

    // 1. INISIALISASI CEPAT (Supaya nama langsung muncul)
    final user = _auth.currentUser;
    userData = {
      'fullName': user?.displayName ?? 'Pengguna',
      'email': user?.email ?? '',
      'avatar': user?.photoURL ?? '',
    };

    // 2. Ambil data detail dari database di background (untuk update jika ada perubahan)
    _loadUserData();
    _loadQuizHistory();
  }

  // --- LOGIC: LOAD DATA ---

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          if (mounted) {
            setState(() {
              // Gabungkan data Auth dengan data Firestore terbaru
              userData = {
                ...?userData, // Data lama
                ...doc.data()!, // Timpa dengan data baru dari DB
              };
            });
          }
        }
      } catch (e) {
        debugPrint("Gagal update data profil dari DB: $e");
        // Tidak perlu alert, karena user masih bisa lihat data dari Auth
      }
    }
  }

  Future<void> _loadQuizHistory() async {
    if (!mounted) return;
    // Set loading history saja
    setState(() => isHistoryLoading = true);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final historySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quiz_history')
            .orderBy('date', descending: true)
            .limit(10)
            .get();

        if (mounted) {
          setState(() {
            quizHistory = historySnap.docs.map((doc) => doc.data()).toList();
            isHistoryLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading history: $e");
        if (mounted) setState(() => isHistoryLoading = false);
      }
    }
  }

  // --- LOGIC: ACTIONS ---

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final user = _auth.currentUser;
    final nameController = TextEditingController(
      text: userData?['fullName'] ?? '',
    );
    final avatarController = TextEditingController(
      text: userData?['avatar'] ?? '',
    );
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Profil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avatarController,
                    decoration: const InputDecoration(
                      labelText: 'URL Avatar',
                      hintText: 'https://...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newFullName = nameController.text.trim();
                          final newAvatar = avatarController.text.trim();
                          if (newFullName.isEmpty) return;

                          setStateDialog(() => isSaving = true);

                          try {
                            if (user != null) {
                              // 1. Update Firestore
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set({
                                    'fullName': newFullName,
                                    'avatar': newAvatar,
                                    'email': userData?['email'], // Keep email
                                  }, SetOptions(merge: true));

                              // 2. Update Auth
                              await user.updateDisplayName(newFullName);
                              if (newAvatar.isNotEmpty) {
                                await user.updatePhotoURL(newAvatar);
                              }

                              // 3. Update UI Local
                              if (mounted) {
                                setState(() {
                                  userData = {
                                    ...?userData,
                                    'fullName': newFullName,
                                    'avatar': newAvatar,
                                  };
                                });
                              }
                              if (mounted) Navigator.of(context).pop();
                            }
                          } catch (e) {
                            debugPrint("Error save: $e");
                          } finally {
                            if (mounted) setStateDialog(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPER DATE ---
  String _formatDate(dynamic dateData) {
    if (dateData == null) return '-';
    DateTime date;
    if (dateData is Timestamp) {
      date = dateData.toDate();
    } else if (dateData is String) {
      try {
        date = DateTime.parse(dateData);
      } catch (_) {
        return dateData;
      }
    } else {
      return '-';
    }
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    // Siapkan data untuk ditampilkan
    final String displayName = userData?['fullName'] ?? 'Pengguna';
    final String displayEmail = userData?['email'] ?? '';
    final String avatarUrl = userData?['avatar'] ?? '';

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // 1. Header Gradient
          Container(
            height: 400,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7B1FA2), Color(0xFFB388FF)],
              ),
            ),
          ),

          // 2. Konten
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // === PROFILE HEADER ===
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Profil Saya',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- AVATAR FIX (Anti Error) ---
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120, // Ukuran lingkaran
                            height: 120,
                            padding: const EdgeInsets.all(4), // Border putih
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              // Logika: Jika URL ada -> Coba load -> Jika gagal -> Icon
                              // Jika URL kosong -> Icon
                              child: (avatarUrl.isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),

                          // Tombol Edit
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Text Nama & Email (Tanpa Loading State)
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        displayEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // === WHITE SHEET ===
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                  child: Column(
                    children: [
                      // Header History
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Riwayat Aktivitas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${quizHistory.length} Selesai',
                              style: TextStyle(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // List History
                      if (isHistoryLoading)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      else if (quizHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_edu,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text('Belum ada riwayat kuis'),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: quizHistory.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 15),
                          itemBuilder: (ctx, index) =>
                              _buildHistoryCard(quizHistory[index]),
                        ),

                      const SizedBox(height: 40),

                      // Tombol Logout
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Keluar Aplikasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.purple),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Kuis',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item['date']),
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item['score'] ?? 0}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
