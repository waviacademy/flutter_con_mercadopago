import UIKit
import Flutter
import MercadoPagoSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PXLifeCycleProtocol {
    var flutterVC: FlutterViewController!
    var navigationController: UINavigationController?
    var channelMercadoPago: FlutterMethodChannel!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    flutterVC = window?.rootViewController as? FlutterViewController
    navigationController = UINavigationController(rootViewController: flutterVC)
    window?.rootViewController = navigationController
    navigationController?.navigationBar.isHidden = true
    
    channelMercadoPago = FlutterMethodChannel(name: "waviacademy.com/mercadoPago", binaryMessenger: flutterVC.binaryMessenger)
    initMethodChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private func initMethodChannel() {
        channelMercadoPago.setMethodCallHandler { [unowned self] (methodCall, result) in
            if let args = methodCall.arguments as? Dictionary<String, Any>,
            let publicKey = args["publicKey"] as? String,
            let preferenceId = args["preferenceId"] as? String {
                self.mercadoPago(publicKey: publicKey, preferenceId: preferenceId, result: result)
            }
        }
    }
        
    private func adaptarMercadoPago(inicia: Bool) {
        if(inicia) {
            navigationController?.navigationBar.isHidden = false
        } else {
            self.navigationController?.popToRootViewController(animated: true)
            navigationController?.navigationBar.isHidden = true
        }
    }
    
    private func mercadoPago(publicKey: String, preferenceId: String, result: @escaping FlutterResult) {
        self.adaptarMercadoPago(inicia: true)
        let checkout = MercadoPagoCheckout.init(builder: MercadoPagoCheckoutBuilder.init(publicKey: publicKey, preferenceId: preferenceId))
        checkout.start(navigationController: self.navigationController!, lifeCycleProtocol: self)
    }
    
    func finishCheckout() -> ((_ payment: PXResult?) -> Void)? {
        return ({(_ payment: PXResult?) in
            var idPago : String = ""
            var status : String = ""
            var statusDetails : String = ""
            
            if let delegate = (payment) {
                status = delegate.getStatus()
                statusDetails = delegate.getStatusDetail()
                
                if let _idPago = (delegate.getPaymentId()) {
                    idPago = _idPago
                }
            }
            
            let channelRespuestaMercadoPago = FlutterMethodChannel(name: "waviacademy.com/mercadoPagoRespuesta", binaryMessenger: self.flutterVC.binaryMessenger)
            channelRespuestaMercadoPago.invokeMethod("mercadoPagoOK", arguments: [idPago, status, statusDetails])
            self.adaptarMercadoPago(inicia: false)
        })
    }
    
    func cancelCheckout() -> (()->Void)? {
        return {
            let channelRespuestaMercadoPago = FlutterMethodChannel(name: "waviacademy.com/mercadoPagoRespuesta", binaryMessenger: self.flutterVC.binaryMessenger)
                 channelRespuestaMercadoPago.invokeMethod("mercadoPagoError", arguments: ["pagoCancelado"])
             self.adaptarMercadoPago(inicia: false)
        }
    }
}
