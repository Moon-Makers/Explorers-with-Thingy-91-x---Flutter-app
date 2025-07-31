import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // For now, we'll use a placeholder. In production, you'd add your actual Google Maps API key here
    GMSServices.provideAPIKey("AIzaSyCR6g8EjqrIte6ZnX6Uzo_dG00pRNh9iQc")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
