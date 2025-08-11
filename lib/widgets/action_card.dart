import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String icon;
  final String buttonText;
  final Color buttonColor;
  final Color textColor;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.buttonColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFDF7EF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7E4C27),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 51,
                  height: 51,
                  child: Image.asset(icon),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: buttonColor == const Color(0xFFFDF7EF)
                          ? const BorderSide(
                              color: Color(0xFFDC8542),
                              width: 0.8,
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
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