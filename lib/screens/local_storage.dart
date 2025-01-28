import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static const String _fileName = 'user_data.json';

  // บันทึกข้อมูล
  static Future<void> saveData(String key, dynamic value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      Map<String, dynamic> data = {};
      
      // ถ้าไฟล์มีอยู่แล้ว อ่านข้อมูลเดิมก่อน
      if (await file.exists()) {
        final String contents = await file.readAsString();
        data = json.decode(contents);
      }
      
      // เพิ่มหรืออัพเดทข้อมูล
      data[key] = value;
      
      // บันทึกลงไฟล์
      await file.writeAsString(json.encode(data));
      print('✅ Saved $key to local storage');
    } catch (e) {
      print('❌ Error saving data: $e');
    }
  }

  // อ่านข้อมูล
  static Future<dynamic> getData(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = json.decode(contents);
        return data[key];
      }
    } catch (e) {
      print('❌ Error reading data: $e');
    }
    return null;
  }

  // ลบข้อมูล
  static Future<void> removeData(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = json.decode(contents);
        data.remove(key);
        await file.writeAsString(json.encode(data));
        print('✅ Removed $key from local storage');
      }
    } catch (e) {
      print('❌ Error removing data: $e');
    }
  }

  // เคลียร์ข้อมูลทั้งหมด
  static Future<void> clearAll() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (await file.exists()) {
        await file.delete();
        print('✅ Cleared all data from local storage');
      }
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}