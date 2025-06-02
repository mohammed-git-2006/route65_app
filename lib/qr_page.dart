import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  String ioContent = 'TESTER';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(ioContent, style: TextStyle(fontSize: 40), textAlign: TextAlign.center,)
      ],)),
    );
  }
  
  late io.Socket socket;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setupSocket();
    },);
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
    socket.close();
  }
}
