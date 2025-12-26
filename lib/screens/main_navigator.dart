import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'rank_screen.dart';
import 'profile_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = const [
    HomeScreen(),
    RankScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true membuat konten halaman memanjang sampai ke bawah navbar
      // Ini penting agar efek 'floating' terlihat nyata (konten ada di balik navbar)
      extendBody: true,

      body: _pages[_selectedIndex],

      // === Custom Floating Bottom Navigation ===
      bottomNavigationBar: Container(
        // Margin kiri-kanan-bawah agar terlihat melayang
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // Bentuk kapsul
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.15,
              ), // Bayangan sedikit lebih tajam
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(iconPath: 'assets/home.png', label: 'Home', index: 0),
              _navItem(iconPath: 'assets/ranking.png', label: 'Rank', index: 1),
              _navItem(
                iconPath: 'assets/profil.png',
                label: 'Profile',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Item Navigasi dengan Animasi
  Widget _navItem({
    required String iconPath,
    required String label,
    required int index,
  }) {
    final bool isActive = _selectedIndex == index;

    // Warna tema (Sesuaikan dengan ProfileScreen sebelumnya: DeepPurple)
    const activeColor = Color(0xFF7B1FA2); // Deep Purple
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // Kecepatan animasi
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          // Background ungu transparan hanya muncul jika aktif
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ICON
            // Catatan: Properti 'color' di sini akan mengubah seluruh gambar menjadi 1 warna flat.
            // Pastikan aset icon kamu transparan (PNG/SVG).
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: isActive ? activeColor : inactiveColor,
              errorBuilder: (context, error, stackTrace) {
                // Fallback jika gambar asset tidak ditemukan (menghindari crash)
                return Icon(
                  _getFallbackIcon(index),
                  color: isActive ? activeColor : inactiveColor,
                );
              },
            ),

            // TEKS (Hanya muncul saat aktif)
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper untuk icon cadangan jika gambar asset belum ada/rusak
  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.leaderboard_rounded;
      case 2:
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }
}
