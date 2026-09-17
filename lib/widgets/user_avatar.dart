import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF008080),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'U',
      style: TextStyle(
        fontSize: radius * 0.9,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}