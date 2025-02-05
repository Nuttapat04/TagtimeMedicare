import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'dart:io' show Platform, File;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

class SummaryPage extends StatefulWidget {
  final String userId;

  SummaryPage({required this.userId});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int touchedIndex = -1;
  String selectedMedicine = "";
  String selectedMedicineId = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> generateMonthlyReport(DateTime? month) async {
    try {
      setState(() {
        isGeneratingReport = true;
      });

      final reportMonth = month ?? DateTime.now();
      final startOfMonth = DateTime(reportMonth.year, reportMonth.month, 1);
      final endOfMonth = DateTime(reportMonth.year, reportMonth.month + 1, 0);

      // Debug log
      print(
          'Starting to generate report for ${DateFormat('MMMM yyyy').format(reportMonth)}...');

      final medicationSnapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('user_id', isEqualTo: widget.userId)
          .get();

      final historySnapshot = await FirebaseFirestore.instance
          .collection('Medication_history')
          .where('User_id', isEqualTo: widget.userId)
          .where('Intake_time', isGreaterThanOrEqualTo: startOfMonth)
          .where('Intake_time', isLessThanOrEqualTo: endOfMonth)
          .where('mark', isEqualTo: true)
          .get();

      if (medicationSnapshot.docs.isEmpty || historySnapshot.docs.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFFEF4E0),
            title: const Text(
              'No Data',
              style: TextStyle(color: Color(0xFFC76355)),
            ),
            content: const Text(
              'No medication data found for the selected month.',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFC76355)),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Process data
      Map<String, Map<String, dynamic>> medicationStats = {};

      for (var doc in medicationSnapshot.docs) {
        final data = doc.data();
        medicationStats[doc.id] = {
          'name': data['M_name'],
          'frequency': data['Frequency'],
          'total': 0,
          'onTime': 0,
          'late': 0,
          'adherenceRate': 0.0,
          'notificationTimes': data['Notification_times'],
          'startDate': data['Start_date'],
          'endDate': data['End_date'],
        };
      }

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final medId = data['Medication_id'] as String;

        if (medicationStats.containsKey(medId)) {
          medicationStats[medId]!['total'] =
              medicationStats[medId]!['total']! + 1;

          if (data['Status'] == 'On Time') {
            medicationStats[medId]!['onTime'] =
                medicationStats[medId]!['onTime']! + 1;
          } else if (data['Status'] == 'Late') {
            medicationStats[medId]!['late'] =
                medicationStats[medId]!['late']! + 1;
          }
        }
      }

      medicationStats.forEach((key, stats) {
        if (stats['total'] > 0) {
          stats['adherenceRate'] =
              (stats['onTime'] / stats['total'] * 100).round();
        }
      });

      final pdf = pw.Document();

      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Medication Report',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 24,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMMM yyyy').format(reportMonth),
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            ...medicationStats.entries.map((entry) {
              final stats = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      stats['name'],
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Frequency',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Total Doses',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('On Time',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Late',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Adherence Rate',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(stats['frequency'].toString(),
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(stats['total'].toString(),
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(stats['onTime'].toString(),
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(stats['late'].toString(),
                                style: pw.TextStyle(font: regularFont)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${stats['adherenceRate']}%',
                                style: pw.TextStyle(font: regularFont)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Notification Times: ${(stats['notificationTimes'] as List).join(', ')}',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      );

      // Save and open PDF
      final output = await getTemporaryDirectory();
      final filename =
          'medication_report_${DateFormat('yyyy_MM').format(reportMonth)}.pdf';
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      print('Error generating report: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Error',
            style: TextStyle(color: Color(0xFFC76355)),
          ),
          content: Text(
            'Failed to generate report: ${e.toString()}',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFC76355)),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF4E0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFEF4E0),
        title: const Text(
          "Summary",
          style: TextStyle(color: Color(0xFFC76355)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFC76355)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC76355),
          labelColor: const Color(0xFFC76355),
          unselectedLabelColor: Colors.grey,
          labelStyle:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ยาของฉัน'),
            Tab(text: 'ผลสรุป'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListPage(),
          _buildSummaryPage(),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          _buildTitle("การรับประทานยา (7 วันที่ผ่านมา)"),
          const SizedBox(height: 10),
          SizedBox(height: 200, child: _buildIntakeBarChart()),
          const SizedBox(height: 20),
          _buildExportSection(),
          const SizedBox(height: 20),
          _buildTitle("การกระจายของยา"),
          const SizedBox(height: 10),
          Expanded(child: _buildTypePieChart()),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_month, color: Color(0xFFC76355)),
            label: Text(
              selectedMonth == null
                  ? 'เลือกเดือน'
                  : DateFormat('MMMM yyyy').format(selectedMonth!),
              style: const TextStyle(color: Color(0xFFC76355)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC76355)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isGeneratingReport
                ? null
                : () => generateMonthlyReport(selectedMonth),
            icon: isGeneratingReport
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            label: Text(
              isGeneratingReport ? 'Generating...' : 'ดูรายงานของการกินยา',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC76355),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

// เพิ่มตัวแปรสำหรับเก็บเดือนที่เลือก
  DateTime? selectedMonth;
  bool isGeneratingReport = false;

// เพิ่มฟังก์ชันเลือกเดือน
  void _selectMonth() async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('en', 'US'),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  /// ✅ **Current Medicines - ดึงจาก Firestore**
  Widget _buildListPage() {
    return RefreshIndicator(
      onRefresh: _refreshData, // ฟังก์ชันที่ใช้รีเฟรชข้อมูล
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Medications')
            .where('user_id', isEqualTo: widget.userId)
            .orderBy('Updated_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final medications = snapshot.data!.docs;

          if (medications.isEmpty) {
            return const Center(
              child: Text(
                'No medications found',
                style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
              ),
            );
          }

          List<DocumentSnapshot> filteredMedications = medications.where((med) {
            final data = med.data() as Map<String, dynamic>;

            if (!data.containsKey('Notification_times') ||
                !data.containsKey('End_date')) {
              return false;
            }

            final timeStrings =
                data['Notification_times'] as List<dynamic>? ?? [];
            final endDate = data['End_date'] is Timestamp
                ? (data['End_date'] as Timestamp).toDate()
                : DateTime.now();

            if (timeStrings.isNotEmpty) {
              final lastTimeString = timeStrings.last.toString();
              final timeParts = lastTimeString.split(':');
              if (timeParts.length != 2) return false;

              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;

              final lastNotificationTime = DateTime(
                  endDate.year, endDate.month, endDate.day, hour, minute);

              return lastNotificationTime.isAfter(DateTime.now());
            }
            return false;
          }).toList();

          if (filteredMedications.isEmpty) {
            return const Center(
              child: Text(
                'No active medications',
                style: TextStyle(fontSize: 24, color: Color(0xFFC76355)),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredMedications.length,
            itemBuilder: (context, index) {
              final med =
                  filteredMedications[index].data() as Map<String, dynamic>;
              final name = med['M_name'] ?? 'No name';
              final time = med['Notification_times'] ?? [];
              final startDate = med['Start_date'] is Timestamp
                  ? (med['Start_date'] as Timestamp).toDate()
                  : DateTime.now();
              final endDate = med['End_date'] is Timestamp
                  ? (med['End_date'] as Timestamp).toDate()
                  : DateTime.now();
              final assignedBy = med['Assigned_by'] ?? 'Unknown';

              // เวลาปัจจุบัน
              final now = DateTime.now();

              Color statusColor = Colors.grey;
              String statusText = '';

              if (now.isBefore(startDate)) {
                // ยังไม่ถึง startDate
                final totalDays = endDate.difference(startDate).inDays;
                statusText = 'Total duration: $totalDays days';
                statusColor = Colors.orange;
              } else if (now.isAfter(endDate)) {
                // เกิน endDate
                statusText = 'Today';
                statusColor = Colors.red;
              } else {
                // อยู่ในช่วง startDate ถึง endDate
                final remainingDays = endDate.difference(now).inDays;
                final remainingHours = endDate.difference(now).inHours % 24;
                statusText = 'เหลือเวลา $remainingDays วัน $remainingHours ชั่วโมง';
                statusColor = Colors.green;
              }

              final formattedStartDate =
                  DateFormat('dd/MM/yyyy').format(startDate);
              final formattedEndDate = DateFormat('dd/MM/yyyy').format(endDate);

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC76355),
                                    ),
                                  ),
                                ),
                                if (statusText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'จำนวณการกิน: ${med['Frequency']}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFFC76355),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'เวลา: ${time.join(', ')}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'วัน: $formattedStartDate to $formattedEndDate',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'จ่ายยาโดย: ${assignedBy}${med['Caregiver_name'] != null && assignedBy == 'Caregiver' ? ' (${med['Caregiver_name']})' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      assignedBy != 'Pharmacist'
                          ? Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 30, color: Color(0xFFC76355)),
                                  onPressed: () => _showEditDialog(context,
                                      filteredMedications[index].id, med),
                                ),
                                const SizedBox(height: 50),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 30, color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(context,
                                          filteredMedications[index].id),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 30, color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(context,
                                          filteredMedications[index].id),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFC76355),
      ),
    );
  }

  Widget _buildTypePieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Medications')
          .where('user_id', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFC76355),
            ),
          );
        }

        final medications = snapshot.data!.docs;
        Map<String, int> medicineCount = {};
        Map<String, String> medicineIds = {};

        for (var doc in medications) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['M_name'] ?? 'Unknown';
          medicineCount[name] = (medicineCount[name] ?? 0) + 1;
          medicineIds[name] = doc.id;
        }

        List<String> medNames = medicineCount.keys.toList();
        // Remove auto-selection of first medicine
        if (selectedMedicine.isEmpty) {
          selectedMedicineId = '';
        }

        final List<Color> pieColors = [
          Colors.blueAccent,
          Colors.redAccent,
          Colors.greenAccent,
          Colors.orangeAccent,
          Colors.purpleAccent,
          Colors.yellowAccent,
          Colors.pinkAccent,
          Colors.tealAccent
        ];

        List<Color> assignedColors = List.generate(medicineCount.length,
            (index) => pieColors[index % pieColors.length].withOpacity(0.8));

        List<PieChartSectionData> sections = medicineCount.entries.map((entry) {
          int index = medicineCount.keys.toList().indexOf(entry.key);
          bool isSelected = selectedMedicine == entry.key;
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: entry.key,
            radius: isSelected ? 85 : 75,
            color: assignedColors[index],
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          );
        }).toList();

        return PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 5,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (event is FlTapUpEvent || event is FlLongPressEnd) {
                  if (pieTouchResponse?.touchedSection != null &&
                      pieTouchResponse!.touchedSection!.touchedSectionIndex >=
                          0 &&
                      pieTouchResponse.touchedSection!.touchedSectionIndex <
                          medNames.length) {
                    setState(() {
                      String newSelectedMed = medNames[
                          pieTouchResponse.touchedSection!.touchedSectionIndex];
                      selectedMedicine = newSelectedMed;
                      selectedMedicineId = medicineIds[newSelectedMed] ?? '';
                    });
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntakeBarChart() {
    final ValueNotifier<int> touchedIndex = ValueNotifier<int>(-1);

    return StreamBuilder<QuerySnapshot>(
      stream: selectedMedicineId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('Medication_history')
              .where('User_id', isEqualTo: widget.userId)
              //.where('mark', isEqualTo: true)
              .where('Medication_id', isEqualTo: selectedMedicineId)
              .orderBy('Intake_time', descending: true)
              .limit(100)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('Medication_history')
              .where('User_id', isEqualTo: widget.userId)
              //.where('mark', isEqualTo: true)
              .orderBy('Intake_time', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC76355)),
          );
        }

        final history = snapshot.data!.docs;
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: Color(0xFFC76355),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedMedicine.isNotEmpty
                      ? 'No data available for $selectedMedicine'
                      : 'No data available',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFC76355),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        Map<String, Map<String, int>> intakeData = {
          "Mon": {"onTime": 0, "late": 0, "skip": 0},
          "Tue": {"onTime": 0, "late": 0, "skip": 0},
          "Wed": {"onTime": 0, "late": 0, "skip": 0},
          "Thu": {"onTime": 0, "late": 0, "skip": 0},
          "Fri": {"onTime": 0, "late": 0, "skip": 0},
          "Sat": {"onTime": 0, "late": 0, "skip": 0},
          "Sun": {"onTime": 0, "late": 0, "skip": 0}
        };

        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        for (var doc in history) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['Intake_time'] as Timestamp).toDate();

          if (timestamp.isAfter(sevenDaysAgo)) {
            final day = DateFormat('EEE').format(timestamp);
            final status = data['Status'] as String;

            if (status == 'On Time') {
              intakeData[day]!['onTime'] =
                  (intakeData[day]!['onTime'] ?? 0) + 1;
            } else if (status == 'Late') {
              intakeData[day]!['late'] = (intakeData[day]!['late'] ?? 0) + 1;
            } else if (status == 'Skip') {
              intakeData[day]!['skip'] = (intakeData[day]!['skip'] ?? 0) + 1;
            }
          }
        }

        double maxY = intakeData.values
            .map((dayData) =>
                (dayData['onTime'] ?? 0) +
                (dayData['late'] ?? 0) +
                (dayData['skip'] ?? 0))
            .reduce(max)
            .toDouble();
        maxY = maxY == 0 ? 10 : (maxY * 1.2).ceilToDouble();

        List<BarChartGroupData> barGroups = intakeData.entries.map((entry) {
          final index = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
              .indexOf(entry.key);
          final onTimeValue = entry.value['onTime']?.toDouble() ?? 0;
          final lateValue = entry.value['late']?.toDouble() ?? 0;
          final skipValue =
              entry.value['skip']?.toDouble() ?? 0; // เพิ่มบรรทัดนี้

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: onTimeValue + lateValue + skipValue,
                color: Colors.transparent,
                width: touchedIndex.value == index ? 22 : 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    onTimeValue,
                    Colors.green.withOpacity(0.8),
                  ),
                  BarChartRodStackItem(
                    onTimeValue,
                    onTimeValue + lateValue,
                    Colors.red.withOpacity(0.8),
                  ),
                  BarChartRodStackItem(
                    onTimeValue + lateValue,
                    onTimeValue + lateValue + skipValue,
                    Colors.orange.withOpacity(0.8), // สีส้มสำหรับ Skip
                  ),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFE8E8E8),
                ),
              ),
            ],
            showingTooltipIndicators: touchedIndex.value == index ? [0] : [],
          );
        }).toList();

        return Stack(
          children: [
            Column(
              children: [
                if (!selectedMedicine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: Colors.green.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        const Text('ตรงเวลา'),
                        const SizedBox(width: 16),
                        Container(
                          width: 16,
                          height: 16,
                          color: Colors.red.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        const Text('ล่าช้า'),
                        const SizedBox(width: 16),
                        Container(
                          width: 16,
                          height: 16,
                          color: Colors.orange.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        const Text('ลืมกิน'),
                      ],
                    ),
                  ),
                // Show selected medicine name
                if (selectedMedicine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'เเสดงข้อมูลของยา: $selectedMedicine',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC76355),
                      ),
                    ),
                  ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: touchedIndex,
                    builder: (context, touchedIndexValue, _) {
                      return Stack(
                        children: [
                          BarChart(
                            BarChartData(
                              barGroups: barGroups,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY / 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: const Color(0xFFE8E8E8),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
  axisNameWidget: Column(
    children: [
      const Text(
        'จำนวนครั้ง', 
        style: TextStyle(
          color: Color(0xFFC76355),
          fontSize: 14, 
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12), 
    ],
  ),
  sideTitles: SideTitles(
    reservedSize: 45,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      return Padding(
        padding: const EdgeInsets.only(left: 8), 
        child: Text(
          value.toInt().toString(),
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
          ),
        ),
      );
    },
  ),
),

                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final days = [
                                        "Mon",
                                        "Tue",
                                        "Wed",
                                        "Thu",
                                        "Fri",
                                        "Sat",
                                        "Sun"
                                      ];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[value.toInt()],
                                          style: TextStyle(
                                            color: touchedIndexValue ==
                                                    value.toInt()
                                                ? const Color(0xFFC76355)
                                                : const Color(0xFF666666),
                                            fontSize: 12,
                                            fontWeight: touchedIndexValue ==
                                                    value.toInt()
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                handleBuiltInTouches: false,
                                touchCallback:
                                    (FlTouchEvent event, barTouchResponse) {
                                  if (!event.isInterestedForInteractions ||
                                      barTouchResponse == null ||
                                      barTouchResponse.spot == null) {
                                    touchedIndex.value = -1;
                                    return;
                                  }
                                  touchedIndex.value = barTouchResponse
                                      .spot!.touchedBarGroupIndex;
                                },
                              ),
                            ),
                          ),
                          if (touchedIndexValue != -1)
                            Positioned(
                              // ปรับตำแหน่งซ้าย-ขวา ตามขนาดจอ
                              left: touchedIndexValue ==
                                      6 // ถ้าเป็นวัน Sun (index = 6)
                                  ? MediaQuery.of(context).size.width -
                                      165 // ชิดขอบขวา
                                  : (touchedIndexValue *
                                          (MediaQuery.of(context).size.width -
                                              60) /
                                          7) +
                                      45,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC76355),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'On Time: ${intakeData[[
                                            "Mon",
                                            "Tue",
                                            "Wed",
                                            "Thu",
                                            "Fri",
                                            "Sat",
                                            "Sun"
                                          ][touchedIndexValue]]!["onTime"] ?? 0}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Late: ${intakeData[[
                                            "Mon",
                                            "Tue",
                                            "Wed",
                                            "Thu",
                                            "Fri",
                                            "Sat",
                                            "Sun"
                                          ][touchedIndexValue]]!["late"] ?? 0}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Skip: ${intakeData[[
                                            "Mon",
                                            "Tue",
                                            "Wed",
                                            "Thu",
                                            "Fri",
                                            "Sat",
                                            "Sun"
                                          ][touchedIndexValue]]!["skip"] ?? 0}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, String docId, Map<String, dynamic> medData) {
    final nameController = TextEditingController(text: medData['M_name']);
    final propertiesController =
        TextEditingController(text: medData['Properties']);
    DateTime? startDate = medData['Start_date'] is Timestamp
        ? (medData['Start_date'] as Timestamp).toDate()
        : DateTime.now();
    DateTime? endDate = medData['End_date'] is Timestamp
        ? (medData['End_date'] as Timestamp).toDate()
        : DateTime.now();
    int frequency =
        int.tryParse(medData['Frequency']?.split(' ')[0] ?? '1') ?? 1;
    List<TimeOfDay> notificationTimes =
        (medData['Notification_times'] as List).map((timeString) {
      final timeParts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFEF4E0),
              title: const Text(
                'เเก้ไข การกินยา',
                style: TextStyle(color: Color(0xFFC76355)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'ชื่อยา'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: propertiesController,
                      decoration:
                          const InputDecoration(labelText: 'คุณสมบัติ'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: DateTimeRange(
                            start: startDate!,
                            end: endDate!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC76355),
                      ),
                      child: Text(
                        startDate != null && endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                            : 'Select Date Range',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'จำนวณครั้ง:',
                          style: TextStyle(color: Color(0xFFC76355)),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: frequency,
                          items: List.generate(4, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text('${index + 1} times/day'),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              frequency = value!;
                              // Update notification times based on frequency
                              if (frequency == 1) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0)
                                ];
                              } else if (frequency == 2) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 19, minute: 0)
                                ];
                              } else if (frequency == 3) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 13, minute: 0),
                                  TimeOfDay(hour: 19, minute: 0)
                                ];
                              } else if (frequency == 4) {
                                notificationTimes = [
                                  TimeOfDay(hour: 8, minute: 0),
                                  TimeOfDay(hour: 12, minute: 0),
                                  TimeOfDay(hour: 16, minute: 0),
                                  TimeOfDay(hour: 20, minute: 0)
                                ];
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เวลาเเจ้งเตือนการกินยา:',
                          style: TextStyle(color: Color(0xFFC76355)),
                        ),
                        const SizedBox(height: 10),
                        ...notificationTimes.asMap().entries.map((entry) {
                          int index = entry.key;
                          TimeOfDay time = entry.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${index + 1}: ${time.format(context)}',
                                style: const TextStyle(color: Colors.black),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Color(0xFFC76355)),
                                onPressed: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: time,
                                  );
                                  if (pickedTime != null) {
                                    setDialogState(() {
                                      notificationTimes[index] = pickedTime;
                                    });
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Save updated medication to Firestore
                    try {
                      await FirebaseFirestore.instance
                          .collection('Medications')
                          .doc(docId)
                          .update({
                        'M_name': nameController.text.trim(),
                        'Properties': propertiesController.text.trim(),
                        'Start_date': startDate,
                        'End_date': endDate,
                        'Frequency': '$frequency times/day',
                        'Notification_times': notificationTimes
                            .map((time) =>
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}')
                            .toList(),
                        'Updated_at': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication updated successfully!'),
                        ),
                      );
                    } catch (e) {
                      print('Error updating medication: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update medication!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC76355),
                  ),
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF4E0),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(color: Color(0xFFC76355)),
          ),
          content: const Text(
            'Are you sure you want to delete this medication?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('Medications')
                      .doc(docId)
                      .delete();

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication deleted successfully!'),
                    ),
                  );
                } catch (e) {
                  print('Error deleting medication: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete medication!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
