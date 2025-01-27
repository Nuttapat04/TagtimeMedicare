import Flutter
import UIKit
import FirebaseCore
import CoreNFC

@main
@available(iOS 13.0, *)
@objc class AppDelegate: FlutterAppDelegate {
    private var nfcSession: NFCTagReaderSession?
    private var flutterResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // ตั้งค่า MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let nfcChannel = FlutterMethodChannel(name: "flutter_nfc_reader_writer", binaryMessenger: controller.binaryMessenger)

        nfcChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "NfcRead":
                if #available(iOS 13.0, *) {
                    self.startNfcRead(result: result)
                } else {
                    result(FlutterError(code: "NFC_NOT_SUPPORTED", message: "NFC requires iOS 13.0+", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    @available(iOS 13.0, *)
    private func startNfcRead(result: @escaping FlutterResult) {
        guard NFCTagReaderSession.readingAvailable else {
            result(FlutterError(code: "NFC_NOT_SUPPORTED", message: "NFC is not supported on this device", details: nil))
            return
        }

        flutterResult = result
        
        // ใช้ guard let เพื่อ unwrap
        guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil) else {
            result(FlutterError(code: "NFC_SESSION_ERROR", message: "Cannot create NFC Tag Reader Session", details: nil))
            return
        }

        session.alertMessage = "Hold your iPhone near an NFC tag to read its serial number."
        session.begin()

        // เก็บอ้างอิงไว้ เพื่อจะได้หยุด session หรือใช้งานต่อ
        nfcSession = session
    }
}

@available(iOS 13.0, *)
extension AppDelegate: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("NFC Tag Reader Session is now active.")
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError,
           nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            flutterResult?(FlutterError(code: "NFC_SESSION_ERROR",
                                        message: error.localizedDescription,
                                        details: nil))
        }
        flutterResult = nil
        nfcSession = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            flutterResult?(FlutterError(code: "NFC_NO_TAG",
                                        message: "No NFC tag found",
                                        details: nil))
            session.invalidate()
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                return
            }

            switch tag {
            case let .miFare(mifareTag):
                let uidData = mifareTag.identifier
                let uidString = uidData.map { String(format: "%02X", $0) }.joined()
                self.flutterResult?(["serialNumber": uidString])

            case let .iso7816(iso7816Tag):
                let uidData = iso7816Tag.identifier
                let uidString = uidData.map { String(format: "%02X", $0) }.joined()
                self.flutterResult?(["serialNumber": uidString])

            default:
                session.invalidate(errorMessage: "Tag not supported")
                return
            }

            session.invalidate()
            self.nfcSession = nil
        }
    }
}
