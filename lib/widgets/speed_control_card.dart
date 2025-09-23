import 'package:flutter/material.dart';
import 'vertical_line_thumb_shape.dart';
import 'separated_track_shape.dart';

class SpeedControlCard extends StatefulWidget {
  final Function(double) onRpmChanged;
  final double initialRpm;

  const SpeedControlCard({
    super.key,
    required this.onRpmChanged,
    required this.initialRpm,
  });

  @override
  _SpeedControlCardState createState() => _SpeedControlCardState();
}

class _SpeedControlCardState extends State<SpeedControlCard> {
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.initialRpm;
  }

  void _incrementSpeed() {
    setState(() {
      if (_currentSpeed < 800) {
        _currentSpeed += 1;
        widget.onRpmChanged(_currentSpeed);
      }
    });
  }

  void _decrementSpeed() {
    setState(() {
      if (_currentSpeed > 0) {
        _currentSpeed -= 1;
        widget.onRpmChanged(_currentSpeed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7E4C27);
    final inactiveColor = const Color.fromARGB(255, 238, 138, 62);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF7EF),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          children: [
            const Text(
              "Sesuaikan Kecepatan Pengaduk",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Color(0xFF7E4C27),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E6D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 20, color: Color(0xFF7E4C27)),
                      padding: const EdgeInsets.all(12),
                      onPressed: _decrementSpeed,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E6D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${_currentSpeed.round()} RPM",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Color(0xFF7E4C27),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E6D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20, color: Color(0xFF7E4C27)),
                      padding: const EdgeInsets.all(12),
                      onPressed: _incrementSpeed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 16,
                trackShape: const SeparatedTrackShape(gapWidth: 10),
                thumbShape: VerticalLineThumbShape(height: 30, width: 4),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: primaryColor,
                inactiveTrackColor: inactiveColor,
                thumbColor: primaryColor,
              ),
              child: Slider(
                value: _currentSpeed,
                min: 0,
                max: 800,
                onChanged: (value) {
                  setState(() {
                    _currentSpeed = value;
                    widget.onRpmChanged(_currentSpeed);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}