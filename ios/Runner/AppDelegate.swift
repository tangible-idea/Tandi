import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Dart 쪽 `ShareIntake` 와 같은 채널 이름.
  private static let shareChannelName = "townloader/share"

  private var shareChannel: FlutterMethodChannel?

  /// Dart 가 준비되기 전에 들어온 공유 링크. `getInitialShare` 호출 때 한 번 넘기고 비운다.
  private var pendingShare: String?
  private var dartReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let messenger = registrar(forPlugin: "TownloaderShare")?.messenger() {
      let channel = FlutterMethodChannel(name: Self.shareChannelName, binaryMessenger: messenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self, call.method == "getInitialShare" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self.dartReady = true
        result(self.pendingShare)
        self.pendingShare = nil
      }
      shareChannel = channel
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 공유 확장이 여는 `townloader://share?url=...` 을 받는다.
  /// 앱이 꺼져 있다 켜진 경우에도 이 메서드가 불리므로 여기 한 곳에서 처리한다.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.scheme == "townloader", url.host == "share" else {
      return super.application(app, open: url, options: options)
    }
    let link = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "url" })?.value
    guard let link, !link.isEmpty else { return false }

    if dartReady {
      shareChannel?.invokeMethod("onShare", arguments: link)
    } else {
      pendingShare = link
    }
    return true
  }
}
