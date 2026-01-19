import Flutter
import UIKit

public class SwiftOnepayPaygateFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "onepay_paygate_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftOnepayPaygateFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openCustomURL":
        if let url = (call.arguments as? [String])?.first {
            let dataArray = url.split{$0 == "&"}.map(String.init)
            if dataArray.count > 0 {
                self.openCustomURLScheme(customURLScheme: dataArray[0],
                                         appID: dataArray[dataArray.count - 1])
            }
        }
    default:
        result(nil)
    }

    }

    func openCustomURLScheme(customURLScheme: String, appID: String) {
        guard let url = URL(string: customURLScheme) else { return }
        UIApplication.shared.open(url) { [weak self] success in
            if !success {
                self?.handleOpenLinkError(url: url, appID: appID)
            }
        }
    }
    
    func handleOpenLinkError(url: URL, appID: String) {
        // handle unable to open the app, perhaps redirect to the App Store
        if let idx = url.absoluteString.firstIndex(of: ":") {
            let mobileBankApp: String = String(url.absoluteString.prefix(upTo: idx))
            print("App Mobie Banking: \(mobileBankApp)")
            if let url = URL(string: "itms-apps://apple.com/app/" + appID) {
                UIApplication.shared.open(url)
            }else {
//                let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.MOBILE_NOT_APP_BANKING)
//                errorCase.appMobieBanking = String(mobileBankApp)
//                self.delegate?.failConnect(paymentViewController: self,error: errorCase)
            }
        }
        else {
//            let errorCase = OnepayErrorResult(errorCase: OnepayErrorCase.NOT_FOUND_APP_BANKING)
//            errorCase.message = url.absoluteString
//            self.delegate?.failConnect(paymentViewController: self,error: errorCase)
        }
    }
}
