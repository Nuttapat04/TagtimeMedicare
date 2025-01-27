import 'dart:async';
import 'package:flutter/services.dart';

class FlutterNfcReader {
  static const MethodChannel _channel = MethodChannel('flutter_nfc_reader_writer');

  /// อ่าน Serial Number (UID) ของแท็ก NFC
  static Future<String> readSerialNumber() async {
    try {
      final Map result = await _channel.invokeMethod('NfcRead');
      return result['serialNumber'] ?? 'Unknown UID';  // เปลี่ยนจาก 'nfcId' เป็น 'serialNumber'
    } catch (e) {
      throw Exception('Error reading NFC: $e');
    }
  }
}