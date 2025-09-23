import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productionRecords;

  const ProductionHistoryScreen({
    super.key,
    required this.productionRecords,
  });

  @override
  State<ProductionHistoryScreen> createState() => _ProductionHistoryScreenState();
}

class _ProductionHistoryScreenState extends State<ProductionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Group records by date
    Map<String, List<Map<String, dynamic>>> groupedRecords = {};
    
    for (var record in widget.productionRecords) {
      final date = DateFormat('yyyy-MM-dd').format(record['date'] as DateTime);
      if (!groupedRecords.containsKey(date)) {
        groupedRecords[date] = [];
      }
      groupedRecords[date]!.add(record);
    }

    // Sort dates descending
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Histori Produksi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${widget.productionRecords.length} data',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: widget.productionRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(sortedDates, groupedRecords),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data produksi',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan data produksi di halaman beranda',
            style: TextStyle(
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<String> sortedDates, Map<String, List<Map<String, dynamic>>> groupedRecords) {
    return Column(
      children: [
        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7E4C27).withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Hari Ini', _getTodayTotal()),
              _buildSummaryItem('Total', _getTotalProduction()),
              _buildSummaryItem('Record', widget.productionRecords.length.toString()),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final records = groupedRecords[date]!;
              final total = records.fold(0, (sum, record) => sum + (record['amount'] as int));
              final dateTime = DateTime.parse(date);
              
              return _buildDateGroup(dateTime, records, total);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7E4C27),
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDateGroup(DateTime date, List<Map<String, dynamic>> records, int total) {
    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF7E4C27).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.date_range,
          color: const Color(0xFF7E4C27),
          size: 20,
        ),
      ),
      title: Text(
        DateFormat('dd MMMM yyyy').format(date),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Color(0xFF7E4C27),
        ),
      ),
      subtitle: Text(
        'Total: $total ikat • ${records.length} transaksi',
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
        ),
      ),
      children: records.map((record) => _buildRecordItem(record)).toList(),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final date = record['date'] as DateTime;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFDC8542).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.inventory_2,
          color: Color(0xFFDC8542),
          size: 18,
        ),
      ),
      title: Text(
        '${record['amount']} ikat',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: Color(0xFF7E4C27),
        ),
      ),
      subtitle: Text(
        DateFormat('HH:mm').format(date),
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
        ),
      ),
      trailing: Text(
        DateFormat('dd/MM').format(date),
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
        ),
      ),
    );
  }

  String _getTodayTotal() {
    final today = DateTime.now();
    final todayTotal = widget.productionRecords
        .where((record) {
          final recordDate = record['date'] as DateTime;
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        })
        .fold(0, (sum, record) => sum + (record['amount'] as int));
    return todayTotal.toString();
  }

  String _getTotalProduction() {
    final total = widget.productionRecords
        .fold(0, (sum, record) => sum + (record['amount'] as int));
    return total.toString();
  }
}