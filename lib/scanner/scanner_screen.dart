// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'package:zmall/constants.dart';
// import 'package:zmall/models/metadata.dart';
// import 'package:zmall/scanner/components/scanned_store.dart';
// import 'package:zmall/size_config.dart';
//
// class ScannerScreen extends StatefulWidget {
//   static String routeName = '/scan';
//
//   @override
//   State<StatefulWidget> createState() => _ScannerScreenState();
// }
//
// class _ScannerScreenState extends State<ScannerScreen> {
//   late Barcode result;
//   late QRViewController controller;
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Platform.isAndroid) {
//       controller.pauseCamera();
//     }
//     controller.resumeCamera();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   elevation: 0.0,
//       //   leading: BackButton(
//       //     color: kSecondaryColor,
//       //   ),
//       // ),
//       body: SafeArea(
//         child: Stack(
//           // mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             _buildQrView(context),
//             Align(
//               alignment: Alignment.topLeft,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: getProportionateScreenWidth(kDefaultPadding),
//                     vertical:
//                         getProportionateScreenWidth(kDefaultPadding * 1.5)),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: kPrimaryColor,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(10.0),
//                     child: GestureDetector(
//                       onTap: () {
//                         Navigator.pop(context);
//                       },
//                       child: Icon(
//                         Icons.arrow_back_rounded,
//                         color: kBlackColor,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.topRight,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: getProportionateScreenWidth(kDefaultPadding),
//                     vertical:
//                         getProportionateScreenWidth(kDefaultPadding * 1.5)),
//                 child: GestureDetector(
//                   onTap: () async {
//                     print("pressed");
//                     await controller?.toggleFlash();
//                     setState(() {});
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: kPrimaryColor,
//                     ),
//                     padding: const EdgeInsets.all(10.0),
//                     child: FutureBuilder(
//                       future: controller?.getFlashStatus(),
//                       builder: (context, snapshot) {
//                         return snapshot.data != null
//                             ? snapshot.data != null
//                                 ? Icon(Icons.flash_off)
//                                 : Icon(Icons.lightbulb_outline_rounded)
//                             : Icon(Icons.flash_off);
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQrView(BuildContext context) {
//     // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
//     var scanArea = (MediaQuery.of(context).size.width < 400 ||
//             MediaQuery.of(context).size.height < 400)
//         ? getProportionateScreenWidth(kDefaultPadding * 7.5)
//         : getProportionateScreenWidth(kDefaultPadding * 15);
//     return QRView(
//       key: qrKey,
//       onQRViewCreated: _onQRViewCreated,
//       overlay: QrScannerOverlayShape(
//           borderColor: kSecondaryColor,
//           borderRadius: 10,
//           borderLength: 30,
//           borderWidth: 10,
//           cutOutSize: scanArea),
//     );
//   }
//
//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });
//     controller.scannedDataStream.listen((scanData) {
//       setState(() {
//         this.controller.stopCamera();
//         result = scanData;
//         print(result.code);
//       });
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ScannedStore(
//             storeId: result.code.toString().split("=")[1].split("_")[0],
//             tableNumber: result.code.toString().split("=")[1].split("_")[1],
//           ),
//         ),
//       );
//     });
//   }
//
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
