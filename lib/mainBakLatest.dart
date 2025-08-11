import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF7E4C27),
        body: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double temperature = 0.0;
  int smoke = 0;
  double viscosity = 50.0;
  late DatabaseReference _sensorRef;

  @override
  void initState() {
    super.initState();
    _sensorRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://sipakarena-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('sensor');
    
    _setupFirebaseListener();
  }

  void _setupFirebaseListener() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          temperature = double.tryParse(data['suhu'].toString()) ?? 0.0;
          smoke = int.tryParse(data['gas'].toString()) ?? 0;
        });
      }
    }, onError: (error) {
      print('Error reading data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'SIPAKARENA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Senin, 08 Desember 2025',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Temperature and Viscosity Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: 'assets/suhu.png',
                    title: 'Suhu',
                    value: '${temperature.toStringAsFixed(1)}° C',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: "assets/jam_flask.png",
                    title: 'Kekentalan',
                    value: '${viscosity.toStringAsFixed(0)}%',
                    iconSize: 44,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: 'assets/asap.png',
                    title: 'Asap',
                    value: smoke.toString(),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: "assets/bi_fire.png",
                    title: 'Api',
                    value: '${viscosity.toStringAsFixed(0)}%',
                    iconSize: 51,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SpeedControlCard(),

            const SizedBox(height: 16),

            // Storage and Oil Cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Penyimpanan Kayu',
                    icon: "assets/gate.png",
                    buttonText: "Buka",
                    buttonColor: const Color(0xFFFDF7EF),
                    textColor: const Color(0xFFDC8542),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: 'Oli',
                    icon: "assets/oli.png",
                    buttonText: "Tuang",
                    buttonColor: const Color(0xFFDC8542),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Production Card
            Card(
              color: const Color(0xFFFDF7EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produksi Gula Aren Hari Ini',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            color: Color(0xFF7E4C27),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFDC8542),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String icon,
    required String title,
    required String value,
    double iconSize = 41,
    double fontSize = 24,
  }) {
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

  Widget _buildActionCard({
    required String title,
    required String icon,
    required String buttonText,
    required Color buttonColor,
    required Color textColor,
  }) {
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

class SpeedControlCard extends StatefulWidget {
  @override
  _SpeedControlCardState createState() => _SpeedControlCardState();
}

class _SpeedControlCardState extends State<SpeedControlCard> {
  double _currentSpeed = 100;

  void _incrementSpeed() {
    setState(() {
      if (_currentSpeed < 200) {
        _currentSpeed += 1;
      }
    });
  }

  void _decrementSpeed() {
    setState(() {
      if (_currentSpeed > 0) {
        _currentSpeed -= 1;
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
                max: 200,
                onChanged: (value) {
                  setState(() => _currentSpeed = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerticalLineThumbShape extends SliderComponentShape {
  final double height;
  final double width;

  const VerticalLineThumbShape({this.height = 30, this.width = 4});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    context.canvas.drawLine(
      Offset(center.dx, center.dy - height / 2),
      Offset(center.dx, center.dy + height / 2),
      paint,
    );
  }
}

class SeparatedTrackShape extends SliderTrackShape {
  final double gapWidth;

  const SeparatedTrackShape({this.gapWidth = 4});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4.0;
    final trackLeft = offset.dx + sliderTheme.overlayShape!
            .getPreferredSize(isEnabled, isDiscrete)
            .width /
        2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width -
        sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;

    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    Offset? secondaryOffset,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue;
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final double gap = gapWidth / 1.5;

    // LEFT SIDE (active track)
    final Rect leftRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx - gap,
      trackRect.bottom,
    );

    final RRect leftRounded = RRect.fromRectAndCorners(
      leftRect,
      topLeft: Radius.circular(trackRect.height / 2),
      bottomLeft: Radius.circular(trackRect.height / 2),
    );

    context.canvas.drawRRect(leftRounded, activePaint);

    // RIGHT SIDE (inactive track)
    final Rect rightRect = Rect.fromLTRB(
      thumbCenter.dx + gap,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    final RRect rightRounded = RRect.fromRectAndCorners(
      rightRect,
      topRight: Radius.circular(trackRect.height / 2),
      bottomRight: Radius.circular(trackRect.height / 2),
    );

    context.canvas.drawRRect(rightRounded, inactivePaint);
  }
}