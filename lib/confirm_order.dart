import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as googleMap;
import 'package:lottie/lottie.dart';
import 'package:route65/no_internet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/animation_set.dart';
import 'l10n/l10n.dart';
import 'package:http/http.dart' as http;
import 'package:fuzzy/fuzzy.dart';

import 'locations_view.dart';

class ConfirmOrder extends StatefulWidget {
  const ConfirmOrder({super.key});

  @override
  State<ConfirmOrder> createState() => _ConfirmOrderState();
}

class _ConfirmOrderState extends State<ConfirmOrder> with TickerProviderStateMixin {
  Widget infoLine(String a, String b, int aniIndex, {bool green = false}) => Transform.translate(
    offset: Offset(MediaQuery.of(context).size.width * (1.0 - infoAnimations[aniIndex].value), .0),
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(children: [
        Text(a, style: TextStyle(fontSize: 16)),
        SizedBox(width: 20, ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2)),
        SizedBox(width: 20,),
        Text(b, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: green ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary),),
      ],),
    ),
  );

  List<AnimationSet> infoAnimations = [];
  bool loading = true, connectionErr = false;
  Map<String, dynamic> namesAndFees = {};

  Future<void> loadData() async {
    try {
      final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/delivery');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          final isAr = Directionality.of(context) == TextDirection.rtl;
          namesAndFees = jsonDecode(response.body);
          fuzzy = Fuzzy(namesAndFees.keys.map((key) {
            if (isAr) return refinedAr(key);
            return (namesAndFees[key]['ne'] as String);
          }).toList(), options: FuzzyOptions(
            threshold: .5
          ));
          loading = false;
        });
      } else {
        throw Exception();
      }
    }  catch (e) {
      setState(() {
        connectionErr = true;
        loading = false;
      });
    }
  }

  String refinedAr(String input) {
    // Return empty string if input is null
    if (input.isEmpty) return input;

    // Common replacements map
    final replacements = {
      'أل': 'ال', // Hamza forms to standard alif
      'إل': 'ال',
      'آل': 'ال',
      'ة': 'ه', // Ta marbuta to ha
      'ى': 'ي', // Alif maksura to ya
      'ئ': 'ء', // Hamza on ya to standalone hamza
      'ؤ': 'ء', // Hamza on waw to standalone hamza
      'ـ': '',  // Remove tatweel (elongation character)
      'ً': '',  // Remove tanween
      'ٌ': '',
      'ٍ': '',
      'َ': '',  // Remove harakat
      'ُ': '',
      'ِ': '',
      'ّ': '',  // Remove shadda
      'ْ': '',  // Remove sukoon
      'اﻷ': 'الا', // Special cases
      'اﻵ': 'الا',
      'اﻹ': 'الا',
    };

    // Step 1: Normalize characters
    String normalized = input;
    replacements.forEach((from, replace) {
      normalized = normalized.replaceAll(from, replace);
    });

    // Step 2: Remove common prefixes that might affect search
    const prefixes = ['و', 'ف', 'ب', 'ك', 'ل', 'لل'];
    for (final prefix in prefixes) {
      if (normalized.startsWith('$prefix ')) {
        normalized = normalized.substring(prefix.length + 1);
      }
      if (normalized.startsWith(prefix)) {
        normalized = normalized.substring(prefix.length);
      }
    }

    // Step 3: Normalize whitespace and trim
    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();

    // Step 4: Remove common filler words
    const fillers = ['في', 'على', 'من', 'الى', 'عن', 'حتى'];
    final words = normalized.split(' ');
    final filteredWords = words.where((word) => !fillers.contains(word)).toList();
    normalized = filteredWords.join(' ');

    return normalized;
  }

  late Fuzzy fuzzy;
  AnimationSet deliveryAnimation = AnimationSet(), takeAwayAnimation = AnimationSet();

  @override
  void initState() {
    super.initState();
    loadData();

    for(int i=0;i<4;++i) {
      infoAnimations.add(AnimationSet()..init(this, .0, 1.0, Durations.medium1, Curves.easeInBack));
    }

    for(int i=0;i<3;++i) {
      infoAnimations[i].whenDone(infoAnimations[i+1]);
    }

    infoAnimations[0].start();
  }

  Widget orderOptionsView() {
    final padding = EdgeInsets.all(10);
    final margin = EdgeInsets.all(10);
    const height = 100.0;
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Widget itemView(bool newVal) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              isTakeaway = newVal;
            });
          },
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade400),
                color: cs.secondary.withAlpha(newVal == isTakeaway ? 255 : 50)
            ),
            margin: margin,
            padding: padding,
            height: height,
            child: Center(
              child: Center(
                child: Column(spacing: 20, mainAxisSize: MainAxisSize.min, children: [
                  FaIcon(newVal ? Icons.takeout_dining_outlined : Icons.delivery_dining_outlined, size: 30, color: newVal == isTakeaway ? cs.surface : cs.primary,),
                  Text(newVal ? dic.takeaway : dic.delivery, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color : newVal == isTakeaway ? cs.surface : cs.primary),),
                ],),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      itemView(true),
      itemView(false),
    ],);
  }

  int takeawayPlace = 0; // 0: pizza, 1: qal3ah

  final searchController = TextEditingController(), closePlaceController = TextEditingController();
  List<dynamic> fuzzyResults = [];
  bool showSR = false;
  String userLocationSelection = '', serverLocationName = '';
  final searchFocusNode = FocusNode();
  bool sendingOrderData = false, isTakeaway = false;
  double? deliveryFee;

  @override
  Widget build(BuildContext context) {
    final orderInformation = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final dic = L10n.of(context)!;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(dic.confirm_order_title),
      ),

      body: loading ? Center(child: SizedBox(width: 200, child: Lottie.asset('assets/loading.json'))) :
        connectionErr ? NoInternetPage(refreshCallback: () {

        }) : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                infoLine('${dic.name} : ', orderInformation['name'], 0),
                infoLine('${dic.phone} : ', orderInformation['phone'], 1),
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
                      Text('${(orderInformation['price_no_voucher'] as double).toStringAsFixed(2)} JD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough, decorationColor: Colors.red.shade800, color: Colors.red.shade800),),
                      SizedBox(width: 20, ),
                      Text('${(orderInformation['total_price'] as double).toStringAsFixed(2)} JD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.secondary),)
                    ],),
                  ),
                ),


                if (!(orderInformation['used_voucher'] as bool)) infoLine('${dic.total_price} : ', '${orderInformation['total_price']}', 2),

                SizedBox(height: 15,),

                orderOptionsView(),

                SizedBox(height: 15,),


                if (!isTakeaway) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: TextField(
                    onChanged: (value) {
                      final fuzR = fuzzy.search(value);
                      setState(() {
                        showSR = true;
                        fuzzyResults = fuzR;
                      });
                    },
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                      hintText: dic.search,
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search_outlined, color: cs.secondary, size: 20,)
                    ),
                  ),
                ),

                if (showSR && !isTakeaway) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(15)
                    ),
                    height: 220,
                    width: size.width - 20,
                    child: SingleChildScrollView(
                      child: Wrap(spacing: 0, runSpacing: 0, alignment: WrapAlignment.center, children:
                        List.generate(fuzzyResults.length, (index) {
                          final item = fuzzyResults[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                showSR = false;
                                userLocationSelection = item.item;
                                deliveryFee = 0;
                                for(int i=0;i<fuzzy.list.length;++i) {
                                  final item = fuzzy.list[i];
                                  if (item == userLocationSelection) {
                                    serverLocationName = namesAndFees.keys.toList()[i];
                                    break;
                                  }
                                }

                                deliveryFee = 0.0;

                                if (isAr) {
                                  deliveryFee = namesAndFees[userLocationSelection]['p']*1.0;
                                } else {
                                  for(final key in namesAndFees.keys.toList()) {
                                    final _item = namesAndFees[key];
                                    print('${(_item['ne'] as String).toUpperCase()} == ${item.item.toString().toUpperCase()} || ${_item['p']}');
                                    if ((_item['ne'] as String).toUpperCase() == item.item.toString().toUpperCase()) {
                                      deliveryFee = _item['p'] * 1.0;
                                      break;
                                    }
                                  }
                                }

                                // showDialog(context: context, builder: (context) => AlertDialog(content: Text('Fee $deliveryFee'),));

                                searchController.text = item.item;
                                searchFocusNode.unfocus();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.secondary.withAlpha(35),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              height: 42.5,
                              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              child: Text('${item.item}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center,),
                            ),
                          );
                        })
                      ,),
                    ),
                  ),
                ),

                  SizedBox(height: 10,),

                  if (!showSR && userLocationSelection.isNotEmpty && !isTakeaway) Padding(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: Row(spacing: 5, children: [
                      SizedBox(width:30, child: FaIcon(FontAwesomeIcons.locationDot, color: cs.secondary, size: 20,)),
                      SizedBox(width: 5,),
                      Text(dic.search_r_t),
                      Text(userLocationSelection, style: TextStyle(fontWeight: FontWeight.bold),),
                    ],),
                  ),

                  if (!showSR && userLocationSelection.isNotEmpty && !isTakeaway) Padding(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: Row(spacing: 5, children: [
                      SizedBox(width:30, child: FaIcon(FontAwesomeIcons.motorcycle, color: cs.secondary, size: 20,)),
                      SizedBox(width: 5,),
                      Text(dic.delivery_fee),
                      Text('${deliveryFee?.toStringAsFixed(2)} ${dic.jd}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary),),
                    ],),
                  ),

                  if (!showSR && userLocationSelection.isNotEmpty && !isTakeaway) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    child: TextField(
                      controller: closePlaceController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                        hintText: dic.close_place,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.map_outlined, color: cs.secondary, size: 20,)
                      ),
                    ),
                  ),

                  if (!showSR && userLocationSelection.isNotEmpty && !isTakeaway) Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: infoLine(dic.total_with_delivery, ((orderInformation['total_price'] as double) + deliveryFee!).toStringAsFixed(2), 0, green: true),
                  ),

                  if (isTakeaway) Transform.translate(
                    offset: Offset(5, -17.5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(spacing: 10, children: [
                        Icon(FontAwesomeIcons.mapLocationDot, color: cs.secondary, size: 23,),
                        Text(takeawayPlace == 0 ? dic.takeaway_ps : dic.takeaway_qs),
                      ],),
                    ),
                  ),

                  SizedBox(child: isTakeaway ?
                    Container(
                      height: 350,
                      margin: EdgeInsets.only(left: 10, right: 10, bottom: 40),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: googleMap.GoogleMap(
                          compassEnabled: false,
                          buildingsEnabled: false,
                          // liteModeEnabled: true,
                          style: 'hyperspace',
                          initialCameraPosition: googleMap.CameraPosition(target: takeawayPlace == 1 ? LocationsViewPageState.map65OtherBranch : LocationsViewPageState.map65MainBranch, zoom: 14),
                          markers: {
                            googleMap.Marker(position: LocationsViewPageState.map65MainBranch, markerId: googleMap.MarkerId('main_branch'), onTap: () {
                              setState(() {
                                takeawayPlace = 0;
                              });
                            }),
                            googleMap.Marker(position: LocationsViewPageState.map65OtherBranch, markerId: googleMap.MarkerId('2nd_branch'), onTap: () {
                              setState(() {
                                takeawayPlace = 1;
                              });
                            }),
                          },
                        )
                      )
                    ) :
                    Container(),
                  ),
                ],),
              ),
            ),
            GestureDetector(
              onTap: isButtonActive ? () => finishButtonFunc(orderInformation) : null,
              child: Container(
                decoration: BoxDecoration(
                    color:  !isButtonActive ? Colors.grey.shade400 : cs.secondary
                ),
                width: size.width,
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: MediaQuery.of(context).padding.bottom),
                child: Center(child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 15,
                  children: [
                    Text(dic.finish, style: TextStyle(
                      color: !isButtonActive ? Colors.grey.shade600 : cs.surface,
                    ),),
                    FaIcon(FontAwesomeIcons.checkCircle, color: !isButtonActive ? Colors.grey.shade600 : cs.surface, size: 15,)
                  ],
                ))
              ),
            ),
          ],
        )
    );
  }

  bool get isButtonActive {
    if (isTakeaway)
      return true;

    return !(showSR || userLocationSelection.isEmpty || sendingOrderData);
  }

  void finishButtonFunc(dynamic orderInformation) {
    final orderInformationPlaceholder = new Map<String, dynamic>.of(orderInformation);
    print(orderInformationPlaceholder);
    orderInformationPlaceholder.removeWhere((key, value) {
      /*
                  * 'price_no_voucher' : totalBasketPrice,
                    'voucher_perc' : voucherDiscountPerc,
                  * */
      return ['price_no_voucher', 'voucher_perc'].contains(key);
    },);

    if (!isTakeaway) {
      orderInformationPlaceholder.addAll({
        'location' : serverLocationName,
        'close_place' : closePlaceController.text,
        'status' : 'PREP',
        'delivery_fee' : deliveryFee,
        'order_method' : 'Delivery'
      });
    } else {
      final dic = L10n.of(context)!;
      orderInformationPlaceholder.addAll({
        'status' : 'PREP',
        'takeaway_place' : takeawayPlace == 1 ? dic.takeaway_qs : dic.takeaway_ps,
        'order_method' : 'Take away'
      });
    }

    orderInformationPlaceholder['total_price'] = orderInformation['price_no_voucher'] + (isTakeaway ? .0 : deliveryFee);

    setState(() {
      sendingOrderData = true;
    });

    SharedPreferences.getInstance().then((pref) {
      pref.setString('last_location', userLocationSelection);
      pref.setString('close_place', closePlaceController.text);

      final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/post_order');
      print('sending http request ...');
      http.post(url, body: jsonEncode(orderInformationPlaceholder),
          headers: {
            'Content-Type' : 'application/json'
          }).then((response) {
        if (response.statusCode == 200) {
          Navigator.of(context).pop(jsonDecode(response.body)['key']);
        } else {
          showDeliveryErr();
        }

        setState(() {
          sendingOrderData = false;
        });
      }).onError((err, s) {
        showDeliveryErr();
        setState(() {
          sendingOrderData = false;
        });
      });
    });
  }

  void showDeliveryErr() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Text(L10n.of(context)!.error_while_pushing_order, style: TextStyle(color: Colors.red.shade800, fontSize: 16),),
      );
    },);
  }

}
