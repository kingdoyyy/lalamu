// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  String _email = '';
  String _password = '';
  String _fullName = '';

  void _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } else {
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(email: _email, password: _password);

        // Simpan data awal user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'fullName': _fullName,
              'email': _email,
              'totalScore': 0, // Skor Akumulasi Global
              'avatar': 'assets/profil.png',
            });
      }
    } on FirebaseAuthException catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.message ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skema warna agar konsisten
    const primaryColor = Colors.deepPurple;
    const accentColor = Colors.deepPurpleAccent;

    return Scaffold(
      // Menggunakan Container dengan decoration untuk gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.shade900,
              primaryColor.shade500,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO AREA ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded, // Ikon representasi kuis
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'InterQuiz',
                  style: TextStyle(
                    fontSize: 36, // Ukuran sedikit diperkecil agar proporsional
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLogin ? 'Selamat Datang Kembali!' : 'Ayo Mulai Belajar!',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // --- CARD FORM ---
                Card(
                  elevation: 12,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            _isLogin ? 'LOGIN' : 'DAFTAR AKUN',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Input Nama (Hanya jika Register)
                          if (!_isLogin) ...[
                            TextFormField(
                              key: const ValueKey('fullName'),
                              validator: (value) =>
                                  value!.isEmpty ? 'Nama wajib diisi' : null,
                              onSaved: (value) => _fullName = value!,
                              decoration: _inputDecoration(
                                label: 'Nama Lengkap',
                                icon: Icons.person_outline,
                                primaryColor: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Input Email
                          TextFormField(
                            key: const ValueKey('email'),
                            validator: (value) => !(value!.contains('@'))
                                ? 'Email tidak valid'
                                : null,
                            onSaved: (value) => _email = value!,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              label: 'Alamat Email',
                              icon: Icons.email_outlined,
                              primaryColor: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Input Password
                          TextFormField(
                            key: const ValueKey('password'),
                            validator: (value) => value!.length < 6
                                ? 'Password minimal 6 karakter'
                                : null,
                            onSaved: (value) => _password = value!,
                            obscureText: true,
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              primaryColor: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Tombol Submit Utama
                          ElevatedButton(
                            onPressed: _submitAuthForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'MASUK' : 'BUAT AKUN',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Tombol Toggle Login/Register
                          TextButton(
                            onPressed: () =>
                                setState(() => _isLogin = !_isLogin),
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.grey[600]),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? 'Belum punya akun? '
                                        : 'Sudah punya akun? ',
                                  ),
                                  TextSpan(
                                    text: _isLogin ? 'Daftar' : 'Masuk',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }

  // Fungsi helper untuk dekorasi input agar kode lebih rapi
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            BorderSide.none, // Hilangkan border default agar terlihat clean
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
