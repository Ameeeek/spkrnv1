import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../widgets/info_card.dart';
import 'dart:async';
import '../widgets/action_card.dart';
import '../widgets/speed_control_card.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productionRecords;
  final Function(List<Map<String, dynamic>>) onProductionRecordsUpdated;

  const HomeScreen({
    super.key,
    required this.productionRecords,
    required this.onProductionRecordsUpdated,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double temperature = 0.0;
  int smoke = 0;
  double viscosity = 0.0; // soil dari firebase
  bool fire = false;
  late DatabaseReference _sensorRef;
  // List<Map<String, dynamic>> productionRecords = [];

  // State untuk tombol kayu dan oli
  bool isKayuTerbuka = false;
  bool isOliDituang = false;

  // Timer state
  Duration systemRuntime = Duration.zero;
  Timer? systemTimer;
  DateTime? timerStartTime;

  // State untuk RPM
  double currentRpm = 0.0;

  @override
  void initState() {
    super.initState();
    _sensorRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://sipakarena-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('sensor');

    _setupFirebaseListener();
  }

  @override
  void dispose() {
    systemTimer?.cancel();
    super.dispose();
  }

  void _setupFirebaseListener() {
    _sensorRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data is Map) {
          setState(() {
            // suhu
            temperature =
                double.tryParse(data['suhu']?.toString() ?? '0.0') ?? 0.0;

            // asap
            smoke = int.tryParse(data['asap']?.toString() ?? '0') ?? 0;

            // soil (kekentalan)
            viscosity =
                double.tryParse(data['soil']?.toString() ?? '0.0') ?? 0.0;

            // api
            final apiValue = data['api'];
            bool newFireStatus = false;
            if (apiValue is bool) {
              newFireStatus = apiValue;
            } else if (apiValue is int) {
              newFireStatus = apiValue == 1;
            } else if (apiValue is String) {
              newFireStatus =
                  apiValue.toLowerCase() == 'true' || apiValue == '1';
            }

            // Timer logika
            if (newFireStatus && !fire) {
              timerStartTime = DateTime.now();
              systemRuntime = Duration.zero;
              systemTimer?.cancel();
              systemTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setState(() {
                  systemRuntime = DateTime.now().difference(timerStartTime!);
                });
              });
            } else if (!newFireStatus && fire) {
              systemTimer?.cancel();
              systemTimer = null;
              timerStartTime = null;
              systemRuntime = Duration.zero;
            }

            fire = newFireStatus;
          });
        }
      },
      onError: (error) {
        print('Error reading data: $error');
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _updateFirebaseValue(String path, dynamic value) {
    FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
              'https://sipakarena-default-rtdb.asia-southeast1.firebasedatabase.app',
        )
        .ref()
        .child(path)
        .set(value)
        .then((_) {
          print('Successfully updated $path to $value');
        })
        .catchError((error) {
          print('Error updating $path: $error');
        });
  }

  void _updateRpmValue(double rpmValue) {
    setState(() {
      currentRpm = rpmValue;
    });
    _updateFirebaseValue('aktuator/rpm', rpmValue.round());
  }

  void _toggleKayu() {
    setState(() {
      isKayuTerbuka = !isKayuTerbuka;
      _updateFirebaseValue('aktuator/penyimpanan_kayu', isKayuTerbuka ? 1 : 0);
    });
  }

  void _toggleOli() {
    setState(() {
      isOliDituang = !isOliDituang;
      _updateFirebaseValue('aktuator/oli', isOliDituang ? 1 : 0);
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
          // TOMBAL BATAL - harusnya hanya menutup dialog
          TextButton(
            onPressed: () => Navigator.pop(context), // Hanya tutup dialog
            child: const Text('Batal'),
          ),
          // TOMBOL SIMPAN - harusnya menyimpan data
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7E4C27),
            ),
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  final newRecord = {'amount': amount, 'date': now};

                  setState(() {
                    widget.productionRecords.add(newRecord);
                    widget.productionRecords.sort(
                      (a, b) => (b['date'] as DateTime).compareTo(
                        a['date'] as DateTime,
                      ),
                    );
                    widget.onProductionRecordsUpdated(
                      List.from(widget.productionRecords),
                    );
                  });
                  Navigator.pop(context); // Tutup dialog setelah simpan
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Masukkan jumlah yang valid (lebih dari 0)',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

  void _deleteProductionRecord(int index) {
    setState(() {
      widget.productionRecords.removeAt(index);
      widget.onProductionRecordsUpdated(List.from(widget.productionRecords));
    });
  }

  int get _todayTotalProduction {
    final today = DateTime.now();
    return widget.productionRecords
        .where((record) {
          final recordDate = record['date'] as DateTime;
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        })
        .fold(0, (sum, record) => sum + (record['amount'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                fire ? _formatDuration(systemRuntime) : 'SIPAKARENA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: fire ? Colors.green : Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fire
                    ? 'Timer Aktif'
                    : DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 16,
                  color: fire ? Colors.green : Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),

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
                      value: fire ? "Menyala" : "Padam",
                      iconSize: 51,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SpeedControlCard(
                onRpmChanged: _updateRpmValue,
                initialRpm: currentRpm,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      title: 'Penyimpanan\nKayu',
                      icon: "assets/gate.png",
                      buttonText: isKayuTerbuka ? "Tutup" : "Buka",
                      buttonColor: isKayuTerbuka
                          ? const Color(0xFFDC8542)
                          : const Color(0xFFFDF7EF),
                      textColor: isKayuTerbuka
                          ? Colors.white
                          : const Color(0xFFDC8542),
                      onPressed: _toggleKayu,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionCard(
                      title: 'Oli',
                      icon: "assets/oli.png",
                      buttonText: isOliDituang ? "Naik" : "Tuang",
                      buttonColor: isOliDituang
                          ? const Color(0xFFFDF7EF)
                          : const Color(0xFFDC8542),
                      textColor: isOliDituang
                          ? const Color(0xFFDC8542)
                          : Colors.white,
                      onPressed: _toggleOli,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                        child: widget.productionRecords.isEmpty
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
                                itemCount: widget.productionRecords.length,
                                itemBuilder: (context, index) {
                                  final record =
                                      widget.productionRecords[index];
                                  final date = record['date'] as DateTime;
                                  return Dismissible(
                                    key: Key('$index-${record['date']}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      color: Colors.red,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
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
      ),
    );
  }
}
