import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:socket_io_client/socket_io_client.dart';

class DiningRoomView extends StatefulWidget {
  const DiningRoomView({super.key});

  @override
  State<DiningRoomView> createState() => _DiningRoomViewState();
}

class _DiningRoomViewState extends State<DiningRoomView> {
  late Socket socket;
  bool loading = true, connectionErr = false;
  List<bool> tablesMap = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSocket();
    });
  }

  void initSocket() {
    socket = io('https://www.route-65-dashboard.com', <String, dynamic>{
      'transports': ['websocket'],
      'secure': true,
      'autoConnect': true,
      'path': '/socket.io',
      'extraHeaders': {
        'origin': 'https://www.route-65-dashboard.com',
      },
    });

    socket.on('room-listener', (data) {
      try {
        if (!mounted) return;
        setState(() {
          final dataHolder = data as Map<String, dynamic>;
          // print(dataHolder.keys.toList().map((key) => tablesMap.add(dataHolder[key]!)).join(' - '));
          // print(dataHolder['table_0']);
          tablesMap.clear();
          List.generate(dataHolder.length, (i) => tablesMap.add(dataHolder['table_$i']));
          loading = false;
          connectionErr = false;
        });
      } on Exception catch (e) {
        print('err -> $e');
        showDialog(context: context, builder: (context) {
          return AlertDialog(content: Text('$e'),);
        },);
      }
    });
  }

  @override
  void dispose() {
    socket.offAny();
    socket.disconnect();
    socket.close();
    super.dispose();
  }

  Widget renderBoxWidget(int i) {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final boxHeight = 100.0, boxWidth = size.width * .25;
    final dic = L10n.of(context)!;

    if (i == 11) {
      return Container(height: (boxHeight + 20) * (i >= 8 ? 8/7 : 1.0),);
    } else {
      return Container(
        height: boxHeight  * (i >= 8 ? 8/7 : 1.0),
        width: boxWidth,
        margin: EdgeInsets.symmetric(horizontal: size.width * .1, vertical: 10 * (i >= 8 ? 8/7 : 1.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: tablesMap[(i > 11 ? i-1 : i)] ? cs.secondary: cs.secondary.withAlpha(50)
        ),

        child: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${i+1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .065, color: tablesMap[(i > 11 ? i-1 : i)] ?cs.surface:cs.primary),),
              Text(tablesMap[(i > 11 ? i-1 : i)] ? dic.occupied : dic.free, style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, color: tablesMap[(i > 11 ? i-1 : i)] ?cs.surface:cs.primary)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = L10n.of(context)!;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final boxHeight = 100.0, boxWidth = size.width * .25;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic.tables),
        centerTitle: true,
      ),

      body: loading ? Center(child: SizedBox(width: 200, child: Lottie.asset('assets/loading.json'))) :
        connectionErr ? Center(child: Text('Connection err'),) : SingleChildScrollView(
          child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(children: [
                ...(List.generate(7, (i) {
                  return renderBoxWidget(i+8);
                }))
              ],)
            ),

            Expanded(
              child: Column(children: [
                ...(List.generate(8, (i) {
                  return renderBoxWidget(i);
                }))
              ],)
            ),
          ],),
        ),
    );
  }
}
