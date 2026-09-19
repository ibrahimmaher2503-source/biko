import 'package:flutter/material.dart';

class DriverAvatar extends StatelessWidget {
  const DriverAvatar({required this.name, required this.url, super.key});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 26,
    foregroundImage: url == null ? null : NetworkImage(url!),
    child: Text(name.isEmpty ? 'س' : name.characters.first),
  );
}
