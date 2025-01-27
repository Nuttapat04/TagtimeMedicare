import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NFCStatus {
  none,
  reading,
  read,
  writing,
  written,
  stopped,
  error,
}

class NfcData {
  final String? id;
  final String? content;
  final String? error;
  final String? statusMapper;

  NFCStatus status = NFCStatus.none;

  NfcData({
    this.id,
    this.content,
    this.error,
    this.statusMapper,
  });

  factory NfcData.fromMap(Map data) {
    NfcData result = NfcData(
      id: data['nfcId'],
      content: data['nfcContent'],
      error: data['nfcError'],
      statusMapper: data['nfcStatus'],
    );
    switch (result.statusMapper) {
      case 'reading':
        result.status = NFCStatus.reading;
        break;
      case 'read':
        result.status = NFCStatus.read;
        break;
      case 'writing':
        result.status = NFCStatus.writing;
        break;
      case 'written':
        result.status = NFCStatus.written;
        break;
      case 'stopped':
        result.status = NFCStatus.stopped;
        break;
      case 'error':
        result.status = NFCStatus.error;
        break;
      default:
        result.status = NFCStatus.none;
    }
    return result;
  }
}

class FlutterNfcReaderWriter {
  static const MethodChannel _channel = MethodChannel('flutter_nfc_reader_writer');
  static const EventChannel _stream = EventChannel('flutter_nfc_reader_writer.stream');

  // Enable NFC Reader Mode
  static Future<NfcData> enableReaderMode() async {
    final Map data = await _channel.invokeMethod('NfcEnableReaderMode');
    return NfcData.fromMap(data);
  }

  // Disable NFC Reader Mode
  static Future<NfcData> disableReaderMode() async {
    final Map data = await _channel.invokeMethod('NfcDisableReaderMode');
    return NfcData.fromMap(data);
  }

  // Write data to NFC tag
  static Future<NfcData> write(String dataToWrite) async {
    final Map data = await _channel.invokeMethod('NfcWrite', <String, dynamic>{
      'data': dataToWrite,
    });
    return NfcData.fromMap(data);
  }

  // Read data from NFC tag
  static Future<NfcData> read() async {
    final Map data = await _channel.invokeMethod('NfcRead');
    return NfcData.fromMap(data);
  }

  // Check NFC Availability
  static Future<bool> checkAvailability() async {
    final bool isAvailable = await _channel.invokeMethod('NfcAvailable');
    return isAvailable;
  }
}
