// home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../widgets/info_card.dart';
import 'dart:async';
import '../widgets/action_card.dart';
import '../widgets/speed_control_card.dart';
import '../services/system_notification_service.dart';
import 'production_history_screen.dart';
import '../services/storage_service.dart'; // Tambahkan import ini

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
  double viscosity = 0.0;
  int fireStatus = 0;
  late DatabaseReference _sensorRef;

  bool isKayuTerbuka = false;
  bool isOliDituang = false;

  Duration systemRuntime = Duration.zero;
  Timer? systemTimer;
  DateTime? timerStartTime;

  double currentRpm = 0.0;

  final SystemNotificationService _notificationService = SystemNotificationService();
  StreamSubscription? _notificationSubscription;

  // State untuk tombol selesai memasak
  bool _isCookingFinished = false;

  final StorageService _storageService = StorageService(); // Tambahkan ini

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.initialize();
    _setupNotificationListener();
    _setupFirebaseListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService.notificationStream.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    systemTimer?.cancel();
    _notificationSubscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }

  void _setupFirebaseListener() {
    _sensorRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://sipakarena-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('sensor');

    _sensorRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data is Map) {
          setState(() {
            final previousTemperature = temperature;
            
            temperature = double.tryParse(data['suhu']?.toString() ?? '0.0') ?? 0.0;
            smoke = int.tryParse(data['asap']?.toString() ?? '0') ?? 0;
            viscosity = double.tryParse(data['soil']?.toString() ?? '0.0') ?? 0.0;
            fireStatus = int.tryParse(data['api']?.toString() ?? '0') ?? 0;

            if (temperature > 50.0 && previousTemperature <= 50.0) {
              _startTimer();
            } else if (temperature <= 50.0 && previousTemperature > 50.0) {
              _stopTimer();
            }
          });
        }
      },
      onError: (error) {
        print('Error reading data: $error');
      },
    );
  }

  void _startTimer() {
    print('Timer START - Suhu: $temperature°C');
    timerStartTime = DateTime.now();
    systemRuntime = Duration.zero;
    systemTimer?.cancel();
    systemTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        systemRuntime = DateTime.now().difference(timerStartTime!);
      });
    });
    
    _notificationService.startTimerNotification();
    _isCookingFinished = false; // Reset status selesai ketika mulai memasak
  }

  void _stopTimer() {
    print('Timer STOP - Suhu: $temperature°C');
    systemTimer?.cancel();
    systemTimer = null;
    timerStartTime = null;
    
    _notificationService.stopTimerNotification();
    
    setState(() {
      systemRuntime = Duration.zero;
    });
  }

  // Method untuk menyelesaikan memasak dan menyimpan ke histori
  void _finishCooking() async {
    if (systemRuntime > Duration.zero) {
      // Simpan data memasak ke histori
      final todayProduction = _getTodayProductionTotal();
      final cookingRecord = {
        'type': 'cooking_session',
        'date': DateTime.now(),
        'duration': systemRuntime.inSeconds,
        'final_temperature': temperature,
        'final_smoke': smoke,
        'final_viscosity': viscosity,
        'final_fire_status': fireStatus,
        'final_rpm': currentRpm.toInt(),
        'production_amount': 0,
        'total_production': _getTodayProductionTotal(),
      };

      setState(() {
        widget.productionRecords.add(cookingRecord);
        widget.productionRecords.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );
        _isCookingFinished = true;
      });

      // Update parent dan simpan ke storage
      await widget.onProductionRecordsUpdated(List.from(widget.productionRecords));
      
      // Tampilkan dialog konfirmasi
      _showCookingFinishedDialog(cookingRecord);
      
      // Reset timer
      _stopTimer();
      
      print('✅ Selesai Memasak - Data tersimpan permanen');
      print('⏱️ Durasi: ${_formatDuration(systemRuntime)}');
      print('🌡️ Suhu Akhir: ${temperature.toStringAsFixed(1)}°C');
      print('💨 Asap Akhir: $smoke');
      print('🧪 Kekentalan Akhir: ${viscosity.toStringAsFixed(0)}%');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada sesi memasak yang aktif'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showCookingFinishedDialog(Map<String, dynamic> record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Selesai '),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Data sesi memasak telah disimpan', style: TextStyle(fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              _buildRecordDetailItem('⏱️ Durasi', _formatDuration(Duration(seconds: record['duration']))),
              _buildRecordDetailItem('🌡️ Suhu Akhir', '${record['final_temperature'].toStringAsFixed(1)}°C'),
              _buildRecordDetailItem('💨 Asap Akhir', record['final_smoke'] == 0 ? 'Padam' : 'Terdeteksi'),
              _buildRecordDetailItem('🧪 Kekentalan', '${record['final_viscosity'].toStringAsFixed(0)}%'),
              _buildRecordDetailItem('🔥 Status Api', record['final_fire_status'].toString()),
              _buildRecordDetailItem('⚡ RPM Akhir', '${record['final_rpm']} RPM'),
            ],
          ),
          actions: [
           TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Data tetap tersimpan meski hanya tekan Tutup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data sesi memasak telah disimpan'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Tutup'),
          ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7E4C27),
              ),
              onPressed: () {
                Navigator.pop(context);
                _navigateToHistory();
              },
              child: const Text(
                'Lihat Histori',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
          ),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductionHistoryScreen(
          productionRecords: widget.productionRecords,
          onProductionRecordsUpdated: widget.onProductionRecordsUpdated,
        ),
      ),
    );
  }

  int _getTodayProductionTotal() {
    final today = DateTime.now();
    return widget.productionRecords
        .where((record) {
          if (record['type'] == 'cooking_session') return false;
          final recordDate = record['date'] as DateTime;
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        })
        .fold(0, (sum, record) => sum + (record['amount'] as int));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildNotificationStatus() {
    final isTimerActive = temperature > 50.0;
    final isSystemNotificationActive = _notificationService.isNotificationActive;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_isCookingFinished) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Selesai Memasak';
    } else if (isTimerActive && isSystemNotificationActive) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
      statusText = 'Memasak... (${_formatDuration(_notificationService.currentDuration)})';
    } else if (isTimerActive) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
      statusText = 'Memasak... (${_formatDuration(systemRuntime)})';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.timer_off;
      statusText = 'Siap Memasak';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        if (isTimerActive && !_isCookingFinished) ...[
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, color: Colors.blue, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Timer aktif - Tekan "Selesai Memasak" untuk menyimpan data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

Widget _buildFinishCookingButton() {
  final isTimerActive = temperature > 50.0;
  final bool isEnabled = isTimerActive && !_isCookingFinished;
  
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isCookingFinished 
            ? Colors.green 
            : (isEnabled ? const Color(0xFFDC8542) : Colors.grey),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isEnabled ? 8 : 2,
        shadowColor: isEnabled ? const Color(0xFFDC8542).withOpacity(0.3) : Colors.transparent,
      ),
      onPressed: isEnabled ? _finishCooking : () {
        // Jika disabled, tampilkan snackbar informasi
        if (!isTimerActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Belum ada sesi memasak yang aktif'),
              backgroundColor: Colors.orange,
            ),
          );

        } else if (_isCookingFinished) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi memasak sudah selesai'),
              backgroundColor: Colors.green,
            ),
          );

        _isCookingFinished = false;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon status (opsional, bisa dihapus jika tidak mau icon sama sekali)
          if (isTimerActive)
            Icon(
              _isCookingFinished ? Icons.check_circle : Icons.local_fire_department,
              size: 32,
              color: Colors.white.withOpacity(0.8),
            ),
          
          const SizedBox(height: 8),
          
          // Title
          Text(
            'Proses Memasak\n Belum Dimulai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Button text
          // Text(
          //   _isCookingFinished 
          //       ? 'SELESAI' 
          //       : (isTimerActive ? 'SELESAI MEMASAK' : 'Belum Aktif'),
          //   style: TextStyle(
          //     fontSize: 14,
          //     fontWeight: FontWeight.bold,
          //     fontFamily: 'Poppins',
          //     color: Colors.white,
          //     letterSpacing: 1.2,
          //   ),
          // ),
          
          if (isTimerActive && !_isCookingFinished) ...[
            const SizedBox(height: 6),
            Text(
              'Tap untuk menyelesaikan sesi',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  String _getSmokeStatusText() {
    return smoke == 0 ? "Padam" : "Terdeteksi";
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

  void _showAddProductionDialog() async {
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
              onPressed: () async {
                if (amountController.text.isNotEmpty) {
                  final amount = int.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    final newRecord = {
                      'amount': amount, 
                      'date': now,
                      'type': 'production'
                    };

                    setState(() {
                      widget.productionRecords.add(newRecord);
                      widget.productionRecords.sort(
                        (a, b) => (b['date'] as DateTime).compareTo(
                          a['date'] as DateTime,
                        ),
                      );
                    });
                    
                    // Update parent dan simpan ke storage
                    await widget.onProductionRecordsUpdated(
                      List.from(widget.productionRecords),
                    );
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$amount ikat berhasil ditambahkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
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

  void _deleteProductionRecord(int index) async {
    setState(() {
      widget.productionRecords.removeAt(index);
    });
    
    // Update parent dan simpan ke storage
    await widget.onProductionRecordsUpdated(List.from(widget.productionRecords));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data produksi dihapus'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTimerActive = temperature > 50.0;
    
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header dengan tombol history
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Untuk balance
                  Column(
                    children: [
                      Text(
                        isTimerActive ? _formatDuration(systemRuntime) : 'SIPAKARENA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isTimerActive ? const Color.fromRGBO(104, 200, 107, 1) : Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTimerActive
                            ? 'Memasak...'
                            : DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 16,
                          color: isTimerActive ? const Color.fromRGBO(104, 200, 107, 1) : Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: _navigateToHistory,
                    tooltip: 'Lihat Histori',
                  ),
                ],
              ),
              
              // _buildNotificationStatus(),
              
              const SizedBox(height: 20),

              // Sensor Cards
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      icon: 'assets/suhu.png',
                      title: 'Suhu',
                      value: '${temperature.toStringAsFixed(1)}° C',
                      fontSize: 18, // 20
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoCard(
                      icon: "assets/jam_flask.png",
                      title: 'Kekentalan',
                      value: '${viscosity.toStringAsFixed(0)}%',
                      iconSize: 32,
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
                      value: _getSmokeStatusText(),
                      fontSize: 13, // 13
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InfoCard(
                      icon: "assets/bi_fire.png",
                      title: 'Api',
                      value: fireStatus.toString(),
                      iconSize: 51,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Speed Control
              SpeedControlCard(
                onRpmChanged: _updateRpmValue,
                initialRpm: currentRpm,
              ),
              const SizedBox(height: 16),

              // Action Cards - termasuk tombol Selesai Memasak
              Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      title: 'Gerbang\nKayu',
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
              _buildFinishCookingButton(),
              // const SizedBox(height: 16),

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
                                  final record = widget.productionRecords[index];
                                  final date = record['date'] as DateTime;
                                  
                                  // Tampilkan hanya data produksi (bukan cooking session)
                                  if (record['type'] == 'cooking_session') {
                                    return const SizedBox.shrink();
                                  }
                                  
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
