import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String size;
  final Color bg;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 'md',
    this.bg = const Color(0xFF2563EB), // blue-600
  });

  @override
  Widget build(BuildContext context) {
    double dim = 40;
    double fontSize = 14;

    if (size == 'sm') {
      dim = 32;
      fontSize = 12;
    } else if (size == 'lg') {
      dim = 56;
      fontSize = 16;
    }

    final parts = name.split(' ');
    String initials = '';
    if (parts.isNotEmpty) {
      initials += parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials += parts[1][0].toUpperCase();
      }
    }

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
