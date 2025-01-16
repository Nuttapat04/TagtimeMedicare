import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtime_medicare/screens/all_user_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> selectedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ดึงข้อมูลผู้ใช้จาก Firestore
  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Users').get();
      setState(() {
        users = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['Name'] ?? 'Unknown',
                  'email': doc['Email'] ?? 'No Email',
                })
            .toList();
        filteredUsers = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // ฟังก์ชันค้นหาผู้ใช้ตามอีเมล
  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((user) =>
                user['email'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // เพิ่มผู้ใช้ในรายการเลือก
  void selectUser(Map<String, dynamic> user) {
    setState(() {
      if (!selectedUsers.contains(user)) {
        selectedUsers.add(user);
      }
    });
  }

  // ลบผู้ใช้ออกจากรายการเลือก
  void deselectUser(Map<String, dynamic> user) {
    setState(() {
      selectedUsers.remove(user);
    });
  }

  void logout() {
    Navigator.of(context).pop(); // กลับไปหน้าล็อกอิน
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: const Color(0xFFC76355),
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Notification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC76355),
                ),
              ),
              const SizedBox(height: 16),
              // ช่องค้นหา
              TextFormField(
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
              // รายการผู้ใช้
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(
                              fontSize: 18, color: Color(0xFFC76355)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 2,
                            child: CheckboxListTile(
                              title: Text(
                                user['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFFC76355),
                                ),
                              ),
                              subtitle: Text(
                                user['email'],
                                style: const TextStyle(color: Colors.black54),
                              ),
                              value: selectedUsers.contains(user),
                              onChanged: (bool? selected) {
                                if (selected == true) {
                                  selectUser(user);
                                } else {
                                  deselectUser(user);
                                }
                              },
                              activeColor: const Color(0xFFC76355),
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              // แสดงรายชื่อผู้ใช้ที่เลือก
              if (selectedUsers.isNotEmpty) ...[
                const Text(
                  'Selected Users:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC76355),
                  ),
                ),
                Wrap(
                  spacing: 8.0,
                  children: selectedUsers.map((user) {
                    return Chip(
                      label: Text(user['email']),
                      backgroundColor: const Color(0xFFFFF4E0),
                      labelStyle: const TextStyle(color: Color(0xFFC76355)),
                      deleteIconColor: Colors.red,
                      onDeleted: () {
                        deselectUser(user);
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              // ช่องข้อความ
              TextFormField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Enter your message',
                  filled: true,
                  fillColor: const Color(0xFFFFF4E0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Message cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (selectedUsers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please select at least one user'),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                isLoading = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification sent successfully!'),
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                          child: const Text(
                            'Send Notification',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC76355),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AllUsersPage()),
                            );
                          },
                          child: const Text(
                            'View All Users',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC76355),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
