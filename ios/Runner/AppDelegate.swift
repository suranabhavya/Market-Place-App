import Flutter
import UIKit
import FirebaseCore
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Set up notification center delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Set up method channel for notification communication
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    notificationChannel = FlutterMethodChannel(name: "com.surana.homiswap/notifications", 
                                             binaryMessenger: controller.binaryMessenger)
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Handle notification if app was launched from notification
    if let notificationResponse = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      // Convert [AnyHashable: Any] to [String: Any]
      let userInfo: [String: Any] = Dictionary(uniqueKeysWithValues: notificationResponse.compactMap { (key: AnyHashable, value: Any) -> (String, Any)? in
        guard let stringKey = key as? String else { return nil }
        return (stringKey, value)
      })
      
      // Delay the call to ensure Flutter is ready
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.handleNotificationData(userInfo)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle notification data and send to Flutter
  private func handleNotificationData(_ userInfo: [String: Any]) {
    print("iOS: Handling notification data: \(userInfo)")
    
    // Extract notification data
    var notificationData: [String: Any] = [:]
    
    // Check for direct data or nested data structure
    if let data = userInfo["data"] as? [String: Any] {
      notificationData = data
    } else {
      // Sometimes the data is at the root level
      notificationData = userInfo
    }
    
    // Send to Flutter via method channel
    notificationChannel?.invokeMethod("onNotificationTapped", arguments: notificationData)
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notification even when app is in foreground
    // Use alert instead of banner for iOS 13 compatibility
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("iOS: Notification tapped with userInfo: \(userInfo)")
    
    // Convert [AnyHashable: Any] to [String: Any]
    let convertedUserInfo: [String: Any] = Dictionary(uniqueKeysWithValues: userInfo.compactMap { (key: AnyHashable, value: Any) -> (String, Any)? in
      guard let stringKey = key as? String else { return nil }
      return (stringKey, value)
    })
    
    // Handle the notification data
    handleNotificationData(convertedUserInfo)
    
    completionHandler()
  }
}
