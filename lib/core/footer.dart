import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color primaryColor;

  const Footer({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom bar
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(icon: Icons.home_rounded, label: 'Beranda', index: 0),
                const SizedBox(width: 60), // ruang tombol tengah
                _item(icon: Icons.person_rounded, label: 'Profil', index: 2),
              ],
            ),
          ),

          // Tombol tengah (Tiket)
          Positioned(
            bottom: 18,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tiket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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

  Widget _item({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? primaryColor : Colors.grey.shade600,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? primaryColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
