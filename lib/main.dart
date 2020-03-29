import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttermercadopago/utils/globals.dart' as globals;
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mercado Pago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage();
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  initState() {
    const channelMercadoPagoRespuesta =
        const MethodChannel("waviacademy.com/mercadoPagoRespuesta");

    channelMercadoPagoRespuesta.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'mercadoPagoOK':
          var idPago = call.arguments[0];
          var status = call.arguments[1];
          var statusDetails = call.arguments[2];
          return mercadoPagoOK(idPago, status, statusDetails);
        case 'mercadoPagoError':
          var error = call.arguments[0];
          return mercadoPagoERROR(error);
      }
    });
    super.initState();
  }

  void mercadoPagoOK(idPago, status, statusDetails) {
    print("idPago $idPago");
    print("status $status");
    print("statusDetails $statusDetails");
  }

  void mercadoPagoERROR(error) {
    print("error $error");
  }

  Future<Map<String, dynamic>> armarPreferencia() async {
    var mp = MP(globals.mpClientID, globals.mpClientSecret);
    var preference = {
      "items": [
        {
          "title": "Test Modified",
          "quantity": 1,
          "currency_id": "USD",
          "unit_price": 20.4
        }
      ],
      "payer": {"name": "Martín", "email": "martin@waviacademy.com"},
      "payment_methods": {
        "excluded_payment_types": [
          {"id": "ticket"},
          {"id": "atm"}
        ]
      }
    };

    var result = await mp.createPreference(preference);
    return result;
  }

  Future<void> ejecutarMercadoPago() async {
    armarPreferencia().then((result) {
      if (result != null) {
        var preferenceId = result['response']['id'];
        try {
          const channelMercadoPago =
              const MethodChannel("waviacademy.com/mercadoPago");
          final response = channelMercadoPago.invokeMethod(
              'mercadoPago', <String, dynamic>{
            "publicKey": globals.mpTESTPublicKey,
            "preferenceId": preferenceId
          });
          print(response);
        } on PlatformException catch (e) {
          print(e.message);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Mercado Pago"),
        ),
        body: Center(
          child: MaterialButton(
            color: Colors.blue,
            onPressed: ejecutarMercadoPago,
            child: Text(
              "Comprar con Mercado Pago",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ));
  }
}
