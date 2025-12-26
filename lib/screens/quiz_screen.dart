import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId; // ID Dokumen Kuis (misal: 'quiz_matematika')
  final String categoryName; // Judul Kuis (misal: 'Latihan Matematika')

  const QuizScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isSubmitting = false; // Loading saat kirim data ke DB
  int? _selectedAnswerIndex; // Jawaban yang dipilih user
  bool _isAnswered = false; // Status apakah sudah dijawab (untuk kunci tombol)

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  // --- 1. FETCH SOAL DARI FIRESTORE ---
  Future<void> _fetchQuestions() async {
    try {
      final snapshot = await _firestore
          .collection('quizzes')
          .doc(widget.categoryId)
          .collection('questions')
          .get();

      final data = snapshot.docs
          .map((doc) => Question.fromFirestore(doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching questions: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LOGIKA JAWAB SOAL ---
  void _answerQuestion(int index) {
    if (_isAnswered) return; // Mencegah klik ganda

    setState(() {
      _isAnswered = true;
      _selectedAnswerIndex = index;

      // Cek jawaban benar
      if (index == _questions[_currentIndex].correctAnswerIndex) {
        _score += 10; // Asumsi 1 soal = 10 poin (bisa disesuaikan)
      }
    });

    // Delay 1.5 detik untuk melihat feedback warna, lalu lanjut
    Timer(const Duration(milliseconds: 1500), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  // --- 3. SUBMIT DATA LENGKAP KE DATABASE ---
  Future<void> _finishQuiz() async {
    setState(() => _isSubmitting = true);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDocRef = _firestore.collection('users').doc(user.uid);

        // A. Ambil data user terkini (untuk nama & avatar di history)
        final userSnapshot = await userDocRef.get();
        final userData = userSnapshot.data() ?? {};
        final currentTotalScore = userData['totalScore'] ?? 0;

        // B. Data Riwayat (Untuk Halaman Profil)
        final historyData = {
          'quizId': widget.categoryId,
          'title': widget.categoryName,
          'score': _score,
          'totalQuestions': _questions.length,
          'date': DateTime.now().toIso8601String(), // Simpan waktu pengerjaan
          'correctAnswers': _score ~/ 10, // Jika 1 soal 10 poin
        };

        // C. Simpan ke Sub-collection 'quiz_history'
        await userDocRef.collection('quiz_history').add(historyData);

        // D. Update Data Utama User (Untuk Halaman Rank)
        // Kita pakai Update map
        Map<String, dynamic> updateData = {
          // 1. Tambah ke total skor global
          'totalScore': currentTotalScore + _score,

          // 2. Simpan/Update skor spesifik latihan ini
          // Field ini ('score_quizId') yang dipakai RankScreen untuk filter per latihan
          'score_${widget.categoryId}': _score,
        };

        // Cek apakah skor baru lebih tinggi dari skor lama (Optional Logic)
        // Jika ingin selalu update skor terakhir, pakai kode di atas.
        // Jika ingin "Best Score" only, perlu logic tambahan (ambil skor lama dulu).
        // Di sini kita pakai "Update Skor Terakhir" sesuai request.

        await userDocRef.set(updateData, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error submitting result: $e");
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Pindah ke Result Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: _score,
            totalQuestions: _questions.length,
            categoryId: widget.categoryId,
            categoryName: widget.categoryName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text("Kuis Kosong"),
        ),
        body: const Center(child: Text("Belum ada soal untuk kategori ini.")),
      );
    }

    if (_isSubmitting) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Menyimpan hasil latihan...",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    // Hitung progress (0.0 sampai 1.0)
    final double progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF7B1FA2),
                  Color(0xFFB388FF),
                ], // Deep Purple Theme
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. HEADER (Back Button & Progress)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${_currentIndex + 1}/${_questions.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. QUESTION CARD
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teks Kategori
                        Text(
                          widget.categoryName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Teks Soal
                        Text(
                          question.questionText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // List Pilihan Jawaban
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: question.options.length,
                            separatorBuilder: (ctx, i) =>
                                const SizedBox(height: 15),
                            itemBuilder: (ctx, index) {
                              return _buildOptionButton(
                                index,
                                question.options[index],
                                question.correctAnswerIndex,
                              );
                            },
                          ),
                        ),
                      ],
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

  // --- WIDGET TOMBOL PILIHAN ---
  Widget _buildOptionButton(int index, String text, int correctIndex) {
    bool isSelected = _selectedAnswerIndex == index;
    bool isCorrect = index == correctIndex;

    // Warna Default
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    IconData? icon;

    // Logika Warna saat User Menjawab
    if (_isAnswered) {
      if (isCorrect) {
        // Jawaban Benar (Selalu hijau, entah dipilih atau tidak, agar user tahu yg benar)
        borderColor = Colors.green;
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
      } else if (isSelected && !isCorrect) {
        // Jawaban Salah yang dipilih User
        borderColor = Colors.red;
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
      } else {
        // Pilihan lain (non-aktif)
        borderColor = Colors.grey.shade100;
        textColor = Colors.grey.shade400;
      }
    } else {
      // Saat belum dijawab
      if (isSelected) {
        borderColor = Colors.deepPurple;
        bgColor = Colors.deepPurple.shade50;
        textColor = Colors.deepPurple;
      }
    }

    return GestureDetector(
      onTap: () => _answerQuestion(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Label Huruf (A, B, C, D) - Optional
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _isAnswered && isCorrect
                    ? Colors.green
                    : (_isAnswered && isSelected
                          ? Colors.red
                          : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // 65 = A
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isAnswered && (isCorrect || isSelected)
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Teks Jawaban
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected || (_isAnswered && isCorrect)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),

            // Icon Status (Check / Cross)
            if (_isAnswered && (isCorrect || isSelected))
              Icon(icon, color: isCorrect ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }
}
