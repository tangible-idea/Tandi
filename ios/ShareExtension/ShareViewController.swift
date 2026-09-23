import UIKit
import UniformTypeIdentifiers

/// 다른 앱의 공유 시트에서 Townloader 를 고르면 뜨는 확장.
///
/// 화면은 띄우지 않는다. 공유된 항목에서 링크를 꺼내 `townloader://share?url=...` 로
/// 본 앱을 열고 곧바로 닫힌다. 링크를 URL 에 실어 보내므로 App Group 이 필요 없다.
final class ShareViewController: UIViewController {
  private static let scheme = "townloader"

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { @MainActor in
      if let link = await extractLink(), let url = Self.hostURL(for: link) {
        openHostApp(url)
      }
      extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
  }

  /// 첨부 중 URL 을 먼저 찾고, 없으면 텍스트(캡션에 링크가 섞인 경우)를 쓴다.
  private func extractLink() async -> String? {
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    let providers = items.flatMap { $0.attachments ?? [] }

    for provider in providers
    where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
        return url.absoluteString
      }
    }
    for provider in providers
    where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
        return text
      }
    }
    return items.compactMap { $0.attributedContentText?.string }.first
  }

  private static func hostURL(for link: String) -> URL? {
    var components = URLComponents()
    components.scheme = scheme
    components.host = "share"
    components.queryItems = [URLQueryItem(name: "url", value: link)]
    return components.url
  }

  /// 확장에서는 UIApplication.shared 를 쓸 수 없어 응답자 체인을 거슬러 올라가 연다.
  /// iOS 18 부터 `openURL:` 셀렉터가 동작하지 않아 `open(_:options:completionHandler:)` 을 쓴다.
  /// 확장은 APPLICATION_EXTENSION_API_ONLY 로 빌드되어 이 메서드를 직접 부를 수 없으므로
  /// 런타임에서 구현을 찾아 호출한다.
  private func openHostApp(_ url: URL) {
    var responder: UIResponder? = self
    if #available(iOS 18.0, *) {
      typealias OpenURL = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
      let selector = NSSelectorFromString("openURL:options:completionHandler:")
      while let current = responder {
        if let application = current as? UIApplication, application.responds(to: selector) {
          let open = unsafeBitCast(application.method(for: selector), to: OpenURL.self)
          open(application, selector, url as NSURL, NSDictionary(), nil)
          return
        }
        responder = current.next
      }
    } else {
      let selector = sel_registerName("openURL:")
      while let current = responder {
        if current.responds(to: selector) {
          _ = current.perform(selector, with: url)
          return
        }
        responder = current.next
      }
    }
  }
}
