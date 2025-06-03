import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  String ioContent = 'TESTER';
  final double qrDw = 5;
  bool sendingQR = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dic = L10n.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Text(ioContent, style: TextStyle(fontSize: 40), textAlign: TextAlign.center,)
        SizedBox(height: 50,),
        Center(
          child: SizedBox(
            width: size.width * .75,
            height: size.width * .75,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 10,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MobileScanner(onDetect: (barcodes) async {
                          if (sendingQR) return;
                          setState(() {
                            sendingQR = true;
                          });

                          final qrCode = barcodes.barcodes[0].displayValue;

                          try {
                            final Uri url = Uri.parse('https://www.route-65-dashboard.com/submit_loyality?phone=${ModalRoute.of(context)!.settings.arguments as String}&serial=$qrCode');
                            final pResponse = await get(url);
                            final pDecoded = jsonDecode(pResponse.body) as Map<String, dynamic>; // {"updated":true,"points":31}
                            final pKeys = pDecoded.keys;
                            if (pKeys.contains('updated')) {
                              final points = double.parse(pDecoded['points'].toString());
                              showDialog(context: context, barrierDismissible: false, builder: (context) {
                                return AlertDialog(content: Column(spacing: 10, mainAxisSize: MainAxisSize.min, children: [
                                  SizedBox(
                                    width: size.width * .3, height: size.width * .3,
                                    child: Stack(
                                      children: [
                                        Positioned(width:size.width * .3, height: size.width * .3, child: Container(
                                          padding: EdgeInsets.all(15),
                                            child: Image.asset('assets/coin.png',))),
                                        Positioned.fill(child: Lottie.asset('assets/congrats.json', width: size.width * .3, height: size.width * .3, )),
                                      ],
                                    ),
                                  ),
                                  Text(dic.congrats.replaceAll('-1', points.toString()).replaceAll('-2', points > 10.0 ? dic.points_1 : dic.points_2)),
                                  ElevatedButton(onPressed: () {
                                    setState(() {
                                      sendingQR = false;
                                    });
                                    Navigator.pop(context);
                                  }, child: Text(dic.get_back)),
                                ],),);
                              },);
                            }
                            else if (pKeys.contains('registered')){
                              print('You should not be seeing this');
                            } else {
                              getBottomSheet([Text(dic.qr_scan_err, style: TextStyle(fontSize: 22, color: Colors.red.shade800),)], (v) {
                                setState(() {
                                  sendingQR = false;
                                });
                              });

                            }
                          } catch (err) {
                            print(err);
                          }
                        },),
                      ),

                      Positioned.fill(child: Visibility(visible: sendingQR, child: BackdropFilter(filter: ImageFilter.blur(sigmaY: 15, sigmaX: 15), child: Container(
                        color: Colors.black.withOpacity(0),
                      ),)),),
                    ],
                  ),
                ),
                Positioned(left: 0, top: 0,child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    border: Border(top: BorderSide(width: qrDw, color: Colors.black), left: BorderSide(width: qrDw, color: Colors.black)),)
                  ),
                ),

                Positioned(right: 0, top: 0,child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      border: Border(top: BorderSide(width: qrDw, color: Colors.black), right: BorderSide(width: qrDw, color: Colors.black)),)
                ),),

                Positioned(right: 0, bottom: 0,child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      border: Border(bottom: BorderSide(width: qrDw, color: Colors.black), right: BorderSide(width: qrDw, color: Colors.black)),)
                ),),

                Positioned(left: 0, bottom: 0,child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      border: Border(left: BorderSide(width: qrDw, color: Colors.black), bottom: BorderSide(width: qrDw, color: Colors.black)),)
                ),),
              ],
            ),
          ),
        )
      ],)),
    );
  }
  
  late io.Socket socket;

  void getBottomSheet(List<Widget> children, Function(dynamic v) onDone) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) {
      return FractionallySizedBox(
        heightFactor: .3,
        widthFactor: 1.0,
        child: Padding(padding: EdgeInsets.all(25), child: Column(
          spacing: 15,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),),
      );
    },).then(onDone);
  }

  @override
  void initState() {
    super.initState();

    /*WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setupSocket();
    },);*/
  }

  void setupSocket() {
    socket = io.io('https://www.route-65-dashboard.com', {
      'transports': ['websocket'],  // Make sure to specify the transport method as websocket
      'path': '/socket.io',         // Path for socket.io
      'secure': true,               // Use secure connection for HTTPS
      'forceNew': true,             // Forces a new connection every time
      'reconnect': true,            // Automatically reconnect on disconnect
      'reconnectAttempts': 5,       // Max attempts to reconnect
      'reconnectDelay': 1000,       // Delay before reconnect attempts
      'reconnectDelayMax': 5000,    // Max delay for reconnection
      'timeout': 5000
    });

    socket.connect();
    socket.onConnect((data) {
      print('connected');
      setState(() {
        ioContent = 'Connected';
        socket.emit('track-order', {'data': '123456789'});
      });
    },);

    socket.on('order-update', (data) {
      print('order-update $data');

      setState(() {
        ioContent = '$data';
      });
    },);

    socket.onConnectError((data) {
      print('connection err $data');
      setState(() {
        ioContent = 'Failed to connect $data';
      });
    },);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
