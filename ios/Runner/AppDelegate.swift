import UIKit
import Flutter
import FirebaseCore
import CoreNFC
import UserNotifications

@main
@available(iOS 13.0, *)
@objc class AppDelegate: FlutterAppDelegate{
    private var nfcSession: NFCTagReaderSession?
    private var flutterResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // ✅ Initialize Firebase
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        // ✅ Configure Notification
        configureNotification(application)

        // ✅ Setup NFC Method Channel
        setupNFCMethodChannel()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ✅ Configure Notification Permissions
    private func configureNotification(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self // ตั้งค่า Delegate เพื่อให้แสดง Noti แม้อยู่ในแอป

        // ขออนุญาตการแจ้งเตือน
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ Notification Permission Denied")
            }
        }
    }

    // ✅ Setup NFC Method Channel
    private func setupNFCMethodChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else { return }
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
    }

    // ✅ Display Notification While App is in Foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Notification received in foreground: \(notification.request.content.body)")
        completionHandler([.alert, .badge, .sound])
    }

    // ✅ Handle Notification Taps
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "flutter_notification_tap",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("notificationTapped", arguments: userInfo)
        }
        completionHandler()
    }

    // ✅ NFC Functions
    @available(iOS 13.0, *)
    private func startNfcRead(result: @escaping FlutterResult) {
        guard NFCTagReaderSession.readingAvailable else {
            result(FlutterError(code: "NFC_NOT_SUPPORTED", message: "NFC is not supported on this device", details: nil))
            return
        }

        flutterResult = result
        
        guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil) else {
            result(FlutterError(code: "NFC_SESSION_ERROR", message: "Cannot create NFC Tag Reader Session", details: nil))
            return
        }

        session.alertMessage = "Hold your iPhone near an NFC tag to read its serial number."
        session.begin()
        nfcSession = session
    }
}

@available(iOS 13.0, *)
extension AppDelegate: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("✅ NFC Tag Reader Session is now active.")
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
