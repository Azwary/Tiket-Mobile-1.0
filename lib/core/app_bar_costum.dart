import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  const AppBarCustom({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    const Color merahUtama = Color.fromARGB(255, 150, 0, 0);

    return AppBar(
      backgroundColor: merahUtama,
      foregroundColor: Colors.white,
      elevation: 1,
      toolbarHeight: 52,
      titleSpacing: 0,
      leadingWidth: 40,

      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,

      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
