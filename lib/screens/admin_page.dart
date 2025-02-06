import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    home: AdminPage(),
  ));
}

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  /// 📌 ดึงข้อมูลผู้ใช้จาก Firestore
  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Users').get();
      setState(() {
        users = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['Name'] ?? 'Unknown',
          'email': doc['Email'] ?? 'No Email',
          'created_at': (doc['Created_at'] as Timestamp?)?.toDate(),
        }).toList();
        filteredUsers = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  /// 🔎 ค้นหาผู้ใช้
  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((user) => user['email'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC76355),
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC76355)),
                filled: true,
                fillColor: const Color(0xFFFFF4E0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: filterUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 18, color: Color(0xFFC76355)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              user['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFC76355),
                              ),
                            ),
                            subtitle: Text(user['email']),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFC76355)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserSummaryPage(
                                    userId: user['id'], 
                                    userName: user['name'], 
                                    createdAt: user['created_at']
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ **หน้าแสดง Summary ของแต่ละ User**
class UserSummaryPage extends StatefulWidget {
  final String userId;
  final String userName;
  final DateTime? createdAt;

  UserSummaryPage({required this.userId, required this.userName, this.createdAt});

  @override
  _UserSummaryPageState createState() => _UserSummaryPageState();
}

class _UserSummaryPageState extends State<UserSummaryPage> {
  Map<String, int> monthlySummary = {};
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> caregivers = [];

  @override
  void initState() {
    super.initState();
    fetchUserSummary();
    fetchMedications();
    fetchCaregivers();
  }

  /// 📊 ดึงข้อมูลสรุปการใช้ยาแบบรายเดือน
  Future<void> fetchUserSummary() async {
    try {
      QuerySnapshot historySnapshot = await FirebaseFirestore.instance
          .collection('Medication_history')
          .where('User_id', isEqualTo: widget.userId)
          .get();

      for (var doc in historySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime date = (data['Intake_time'] as Timestamp).toDate();
        String monthKey = DateFormat('MMM yyyy').format(date);

        if (!monthlySummary.containsKey(monthKey)) {
          monthlySummary[monthKey] = 0;
        }
        monthlySummary[monthKey] = monthlySummary[monthKey]! + 1;
      }

      setState(() {});
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  /// 📌 ดึงข้อมูลยา
  Future<void> fetchMedications() async {
    try {
      QuerySnapshot medSnapshot = await FirebaseFirestore.instance
          .collection('Medications')
          .where('user_id', isEqualTo: widget.userId)
          .get();

      setState(() {
        medications = medSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['M_name'] ?? 'Unknown',
            'created_at': (data['Created_at'] as Timestamp?)?.toDate(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching medications: $e');
    }
  }

  /// 📌 ดึงข้อมูล Caregivers
  Future<void> fetchCaregivers() async {
    try {
      QuerySnapshot caregiverSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('Caregivers')
          .get();

      setState(() {
        caregivers = caregiverSnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['Name'] ?? 'Unknown',
            'relationship': data['Relationship'] ?? 'Unknown',
            'contact': data['Contact'] ?? 'No Contact',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching caregivers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} Summary'),
        backgroundColor: const Color(0xFFC76355),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('User Registered: ${widget.createdAt != null ? DateFormat('dd MMM yyyy').format(widget.createdAt!) : "N/A"}'),
          const SizedBox(height: 16),
          const Text('Monthly Medication Usage:'),
          ...monthlySummary.entries.map((entry) => ListTile(
            title: Text(entry.key),
            trailing: Text('${entry.value} doses'),
          )),
          const SizedBox(height: 16),
          const Text('Caregivers:'),
          ...caregivers.map((caregiver) => ListTile(
            title: Text(caregiver['name']),
            subtitle: Text('${caregiver['relationship']} - ${caregiver['contact']}'),
          )),
        ],
      ),
    );
  }
}
