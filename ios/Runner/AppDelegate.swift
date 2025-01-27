import Flutter
import UIKit
import FirebaseCore
import CoreNFC

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var nfcSession: NFCNDEFReaderSession?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        NSLog("App is starting...")
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // ตั้งค่า MethodChannel สำหรับ NFC
        let controller = window?.rootViewController as! FlutterViewController
        let nfcChannel = FlutterMethodChannel(name: "flutter_nfc_reader_writer", binaryMessenger: controller.binaryMessenger)

        nfcChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "NfcRead":
                self.startNfcRead(result: result)
            case "NfcWrite":
                if let arguments = call.arguments as? [String: String],
                   let dataToWrite = arguments["data"] {
                    self.startNfcWrite(data: dataToWrite, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing data to write", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ฟังก์ชันสำหรับอ่าน NFC
    private func startNfcRead(result: @escaping FlutterResult) {
        guard NFCNDEFReaderSession.readingAvailable else {
            result(FlutterError(code: "NFC_NOT_SUPPORTED", message: "NFC is not supported on this device", details: nil))
            return
        }

        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.begin()
        result("NFC Read session started")
    }

    // ฟังก์ชันสำหรับเขียน NFC
    private func startNfcWrite(data: String, result: @escaping FlutterResult) {
        // การเขียน NFC ต้องการเพิ่มเติมการตั้งค่า NFCNDEFWriterSession
        result(FlutterError(code: "NFC_WRITE_NOT_IMPLEMENTED", message: "Writing NFC not implemented yet", details: nil))
    }
}

// Extension สำหรับจัดการ NFCNDEFReaderSessionDelegate
extension AppDelegate: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError, nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            NSLog("NFC Session Error: \(error.localizedDescription)")
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let payload = String(data: record.payload, encoding: .utf8) {
                    NSLog("NFC Record: \(payload)")
                }
            }
        }
    }
}
