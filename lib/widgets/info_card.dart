import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final double iconSize;
  final double fontSize;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconSize = 41,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDF7EF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Image.asset(icon),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF7E4C27),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFF7E4C27),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}