import 'package:flutter/material.dart';

import 'l10n/animation_set.dart';
import 'l10n/l10n.dart';

class ConfirmOrder extends StatefulWidget {
  const ConfirmOrder({super.key});

  @override
  State<ConfirmOrder> createState() => _ConfirmOrderState();
}

class _ConfirmOrderState extends State<ConfirmOrder> with TickerProviderStateMixin {
  Widget infoLine(String a, String b, int aniIndex) => Transform.translate(
    offset: Offset(MediaQuery.of(context).size.width * (1.0 - infoAnimations[aniIndex].value), .0),
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(children: [
        Text(a, style: TextStyle(fontSize: 16)),
        SizedBox(width: 20, ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2)),
        SizedBox(width: 20,),
        Text(b, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
      ],),
    ),
  );

  List<AnimationSet> infoAnimations = [];


  @override
  void initState() {
    super.initState();

    for(int i=0;i<4;++i) {
      infoAnimations.add(AnimationSet()..init(this, .0, 1.0, Durations.medium1, Curves.easeInBack));
    }

    for(int i=0;i<3;++i) {
      infoAnimations[i].whenDone(infoAnimations[i+1]);
    }

    infoAnimations[0].start();
  }

  @override
  Widget build(BuildContext context) {
    final orderInformation = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final dic = L10n.of(context)!;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(dic.confirm_order_title),
      ),

      body: Column(children: [
        infoLine('${dic.name} : ', orderInformation['name'], 0),
        infoLine('${dic.phone} : ', orderInformation['phone'], 1),
        // infoLine('${dic.total_price} : ', (orderInformation['total_price'] as double).toStringAsFixed(2)),
        if (orderInformation['used_voucher'] as bool) infoLine('${dic.voucher} : ', orderInformation['voucher'], 2),
        if (orderInformation['used_voucher'] as bool) Transform.translate(
          offset: Offset(size.width * (1.0 - infoAnimations[3].value), .0),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Row(children: [
              Text('${dic.total_price} : ', style: TextStyle(fontSize: 16)),
              SizedBox(width: 20, ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2)),
              SizedBox(width: 20, ),
              Text((orderInformation['price_no_voucher'] as double).toStringAsFixed(2) + ' JD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, decorationColor: Colors.red.shade800, color: Colors.red.shade800),),
              SizedBox(width: 20, ),
              Text((orderInformation['total_price'] as double).toStringAsFixed(2) + ' JD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.secondary),)
            ],),
          ),
        ),
        if (!(orderInformation['used_voucher'] as bool)) infoLine('${dic.total_price} : ', '${orderInformation['total_price']}', 2),

      ],)
    );
  }
}
