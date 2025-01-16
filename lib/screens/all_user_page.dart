import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUsersPage extends StatefulWidget {
  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  String sortCriteria = 'name';
  bool isAscending = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      setState(() {
        users = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;

          return {
            'id': doc.id,
            'name': data?['Name'] ?? 'Unknown',
            'surname': data?['Surname'] ?? 'Unknown',
            'email': data?['Email'] ?? 'No Email',
            'phone': data?['Phone'] ?? 'No Phone',
            'role': data?['Role'] ?? 'No Role',
            'image': data?['photoURL'] ?? '',
          };
        }).toList();

        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((user) =>
                user['name'].toLowerCase().contains(query.toLowerCase()) ||
                user['email'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void sortUsers(String criteria) {
    setState(() {
      sortCriteria = criteria;
      filteredUsers.sort((a, b) {
        final valueA = a[criteria]?.toString().toLowerCase() ?? '';
        final valueB = b[criteria]?.toString().toLowerCase() ?? '';
        return isAscending
            ? valueA.compareTo(valueB)
            : valueB.compareTo(valueA);
      });
      isAscending = !isAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC76355),
        iconTheme: const IconThemeData(
          color: Colors.white, // เปลี่ยนสีลูกศรเป็นสีขาว
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ช่องค้นหา
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by name or email',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFFC76355)),
                      filled: true,
                      fillColor: const Color(0xFFFFF4E0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: filterUsers,
                  ),
                ),
                // ปุ่มเรียงลำดับ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => sortUsers('name'),
                        icon: Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 18,
                          color: Colors.white, // เปลี่ยนสีลูกศรเป็นสีขาว
                        ),
                        label: const Text('Sort by Name'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC76355),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => sortUsers('email'),
                        icon: Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 18,
                          color: Colors.white, // เปลี่ยนสีลูกศรเป็นสีขาว
                        ),
                        label: const Text('Sort by Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC76355),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFC76355),
                                  backgroundImage: user['image'].isNotEmpty
                                      ? NetworkImage(
                                          user['image']) // แสดงรูปจาก URL
                                      : null, // ถ้าไม่มีรูปจะใช้พื้นหลังสีและตัวอักษรแทน
                                  child: user['image'].isEmpty
                                      ? Text(
                                          user['name'][0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )
                                      : null, // ไม่แสดงตัวอักษรหากมีรูป
                                ),
                                title: Text(
                                  user['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFC76355),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Name: ${user['name']} ${user['surname']}',
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                    Text('Email: ${user['email']}',
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                    Text('Phone: ${user['phone']}',
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                    Text('Role: ${user['role']}',
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
