import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineDetailPage extends StatelessWidget {
  final Map<String, dynamic> medicineData;
  final String rfidUID;

  const MedicineDetailPage({
    Key? key,
    required this.medicineData,
    required this.rfidUID,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        title: const Text(
          'Medicine Details',
          style: TextStyle(
            color: Color(0xFFC76355),
            fontWeight: FontWeight.bold,
            fontSize: 28, // เพิ่มขนาด
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFC76355),
            size: 32, // เพิ่มขนาดไอคอน
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // เพิ่ม padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                title: 'RFID Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Tag ID', rfidUID),
                  ],
                ),
              ),
              const SizedBox(height: 20), // เพิ่มระยะห่าง

              _buildInfoCard(
                title: 'Medicine Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name', medicineData['M_name'] ?? 'N/A'),
                    _buildInfoRow('Properties', medicineData['Properties'] ?? 'N/A'),
                    _buildInfoRow('Frequency', medicineData['Frequency'] ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildInfoCard(
                title: 'Schedule',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRow('Start Date', medicineData['Start_date']),
                    _buildDateRow('End Date', medicineData['End_date']),
                    if (medicineData['Notification_times'] != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notification Times:',
                        style: TextStyle(
                          fontSize: 24, // เพิ่มขนาด
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC76355),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: (medicineData['Notification_times'] as List)
                            .map((time) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFFC76355),
                                      width: 2, // เพิ่มความหนาของเส้น
                                    ),
                                  ),
                                  child: Text(
                                    time.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFC76355),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22, // เพิ่มขนาด
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // เพิ่ม padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26, // เพิ่มขนาด
              fontWeight: FontWeight.bold,
              color: Color(0xFFC76355),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // เพิ่ม padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // เพิ่มความกว้าง
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 22, // เพิ่มขนาด
                fontWeight: FontWeight.w600,
                color: Color(0xFFC76355),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22, // เพิ่มขนาด
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, dynamic date) {
    String formattedDate = 'N/A';
    if (date != null && date is Timestamp) {
      DateTime dateTime = date.toDate();
      formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return _buildInfoRow(label, formattedDate);
  }
}