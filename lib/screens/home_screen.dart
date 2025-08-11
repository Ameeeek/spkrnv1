import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../widgets/info_card.dart';
import '../widgets/action_card.dart';
import '../widgets/speed_control_card.dart';

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
  List<Map<String, dynamic>> productionRecords = [];

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

  void _showAddProductionDialog() {
    final TextEditingController amountController = TextEditingController();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Produksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tanggal: $formattedDate'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (ikat)',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan jumlah ikat',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E4C27),
              ),
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final amount = int.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    setState(() {
                      productionRecords.add({
                        'amount': amount,
                        'date': now,
                      });
                      // Sort by date (newest first)
                      productionRecords.sort((a, b) => 
                          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan jumlah yang valid (lebih dari 0)'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteProductionRecord(int index) {
    setState(() {
      productionRecords.removeAt(index);
    });
  }

  int get _todayTotalProduction {
    final today = DateTime.now();
    return productionRecords.where((record) {
      final recordDate = record['date'] as DateTime;
      return recordDate.year == today.year &&
             recordDate.month == today.month &&
             recordDate.day == today.day;
    }).fold(0, (sum, record) => sum + (record['amount'] as int));
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
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
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
                  child: InfoCard(
                    icon: 'assets/suhu.png',
                    title: 'Suhu',
                    value: '${temperature.toStringAsFixed(1)}° C',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
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
                  child: InfoCard(
                    icon: 'assets/asap.png',
                    title: 'Asap',
                    value: smoke.toString(),
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
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

            const SpeedControlCard(),

            const SizedBox(height: 16),

            // Storage and Oil Cards
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    title: 'Penyimpanan Kayu',
                    icon: "assets/gate.png",
                    buttonText: "Buka",
                    buttonColor: const Color(0xFFFDF7EF),
                    textColor: const Color(0xFFDC8542),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ActionCard(
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
                          'Produksi Gula Aren',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            color: Color(0xFF7E4C27),
                          ),
                        ),
                        Row(
                          children: [ 
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: TextButton(
                                onPressed: _showAddProductionDialog,
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 100,
                        maxHeight: 120,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: productionRecords.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada data produksi',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: productionRecords.length,
                              itemBuilder: (context, index) {
                                final record = productionRecords[index];
                                final date = record['date'] as DateTime;
                                return Dismissible(
                                  key: Key('$index-${record['date']}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (direction) {
                                    _deleteProductionRecord(index);
                                  },
                                  child: ListTile(
                                    title: Text(
                                      '${record['amount']} ikat',
                                      style: const TextStyle(
                                        color: Color(0xFF7E4C27),
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat('HH:mm').format(date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    trailing: Text(
                                      DateFormat('dd/MM').format(date),
                                      style: const TextStyle(
                                        color: Color(0xFF7E4C27),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                );
                              },
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
}