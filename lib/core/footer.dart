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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          _buildItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Beranda',
          ),
          _buildItem(
            index: 1,
            icon: Icons.confirmation_number_rounded,
            label: 'Tiket Saya',
          ),
          _buildItem(
            index: 2,
            icon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isActive ? primaryColor : Colors.grey.shade600,
        ),
      ),
    );
  }
}
