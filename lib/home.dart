import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart' as lottieLib;
import 'package:path_provider/path_provider.dart';
import 'package:route65/auth_engine.dart';
import 'package:http/http.dart' as http;
import 'package:route65/chatbot.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:route65/meal_view.dart';
import 'package:route65/no_internet.dart';
import 'dart:math' as math;
import 'dart:developer' as console;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/animation_set.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  UserProfile userProfile = UserProfile();
  bool loading = true;
  // --ANI-SET
  final nameAnimation = AnimationSet(), tokensAnimation = AnimationSet(), tokenUpAni = AnimationSet(), qrCodeAnimation = AnimationSet();
  final mapAnimation = AnimationSet(), basketAnimation = AnimationSet();
  void setupNotifications() async {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    await notificationsPlugin.initialize(initSettings);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcm = await FirebaseMessaging.instance.getToken();
    await userProfile.updateFCM(fcm);

    FirebaseMessaging.onMessage.listen((event) {
      AuthEngine.showLocalNotification(event);
    },);
  }

  Future<bool> loadTokensFromServer() async {
    try {
      final Uri url = Uri.parse('https://www.route-65-dashboard.com/points?phone=${userProfile.phone}');
      final Uri registerUrl = Uri(scheme: 'https', host: 'www.route-65-dashboard.com', path: 'register', queryParameters: {
        'phone' : userProfile.phone,
        'username' : userProfile.name
      });
      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data.containsKey(('registered'))) {
        final registerResponse = await http.get(registerUrl);
        if ((jsonDecode(registerResponse.body) as Map<String, dynamic>).containsKey('server_error')) throw '[Register] Server error';
        userProfile.tokens = 0;

        return true;
      }

      userProfile.update(tokens: data['points'] * 1.0);
      return true;
    } catch (err) {
      return false;
    }
  }

  bool connectionError = false, checkingVoucher = false, usingVoucher = false;
  List<Map<String, dynamic>> bannersAd = [];
  Map<String, dynamic> menuData = {};
  List<String> menuCats = [];
  Map<String, FileImage> menuSavedImages = {};
  List<Map<String, dynamic>> myBasket = [];
  List<dynamic> fromServerBasket = [];
  List<dynamic> catsDetails = [];
  TextEditingController voucherController = TextEditingController();
  double voucherDiscountPerc = .0;
  late double fromServerTotalPrice;
  late bool fromServerIsTakeaway;
  late String fromServerLocation, fromServerClosePlace, fromServerTakeawayLocation;

  Future<void> loadData() async {
    await userProfile.loadFromPref();
    setupNotifications();
    final lr = await loadTokensFromServer();

    try {
      print('[#]    COC --> ${userProfile.coc}');

      if (userProfile.waiting_order) {
        final Uri fsbUri = Uri.parse('https://www.route-65-dashboard.com/api/order_items/${userProfile.coc}');
        final fsbResponse = await http.get(fsbUri);
        fromServerBasket = jsonDecode(fsbResponse.body)['items'] as List<dynamic>;
        // fromServerTotalPrice = jsonDecode(fsbResponse.body)['total_price'] as double;
        final _data = jsonDecode(fsbResponse.body) as Map<String, dynamic>;
        fromServerTotalPrice = _data['total_price']*1.0;
        fromServerIsTakeaway = (_data['order_method'] as String) == 'Take away';
        if (!fromServerIsTakeaway) {
          fromServerLocation = _data['location'] as String;
          fromServerClosePlace = _data['close_place'] as String;
        } else {
          fromServerTakeawayLocation = _data['takeaway_place'] as String;
        }

        runBackgroundOrderCheck();
      }

      final Uri url = Uri(host: 'www.route-65-dashboard.com', scheme: 'https', path: '/api/banner');
      final bannersResponse = await http.get(url);
      final jsonData = jsonDecode(bannersResponse.body) as Map<String, dynamic>;
      final bannersData = jsonData['result'] as List<dynamic>;
      bannersAd.clear();
      for(final bannerDataItem in bannersData) {
        bannersAd.add(bannerDataItem as Map<String, dynamic>);
      }

      final Uri menuUrl = Uri(scheme: 'https', host: 'www.route-65-dashboard.com', path: '/api/menu');
      final menuResponse = await http.get(menuUrl);
      menuData = jsonDecode(menuResponse.body) as Map<String, dynamic>;
      final Uri catsUrl = Uri(scheme: 'https', host: 'www.route-65-dashboard.com', path: '/api/cats');
      final catsResponse = await http.get(catsUrl);
      final catsDecoded = jsonDecode(catsResponse.body);
      List.generate(catsDecoded.length, (i) => menuCats.add(catsDecoded[i]));
      final Uri catsInfoUrl = Uri.parse('https://www.route-65-dashboard.com/api/cats_info');
      final catsInfoResponse = await http.get(catsInfoUrl);
      final catsInfoDecoded = jsonDecode(catsInfoResponse.body);
      catsDetails = List.generate(catsDecoded.length, (i) => [...catsInfoDecoded[i], new AnimationSet()..init(this, .0, 1.0, Durations.medium1, Curves.easeIn)]);
      loadAllAnimationsForMenuItems();
    } catch (err, trace) {
      console.log('[Connection check][1] $err $trace');
      connectionError = true;
    }

    if (!lr) connectionError = true;

    try {
      final path = await getApplicationDocumentsDirectory();
      for(String cat in menuCats) {
        final catData = menuData[cat];

        for(final item in catData) {
          final File saveFile = File('${path.path}/${item['i']}.jgp');
          if(!(await saveFile.exists())) {
            final Uri imageUrl = Uri(scheme:'https', host: 'www.route-65-dashboard.com', path: '/api/menu/${item['i']}');
            final imageResponse = await http.get(imageUrl);
            await saveFile.writeAsBytes(imageResponse.bodyBytes);
          }

          menuSavedImages.addAll({'${item['i']}' : FileImage(saveFile)});
        }
      }

      for(final bannerData in bannersAd) {
        File bannerImageFile = File('${path.path}/${bannerData['id']}.jpg');
        if (!(await bannerImageFile.exists())) {
          final Uri bannerImageUrl = Uri.parse(bannerData['img'] as String);
          final bannerImageResponse = await http.get(bannerImageUrl);
          bannerImageFile.writeAsBytes(bannerImageResponse.bodyBytes);
        }

        menuSavedImages.addAll({'${bannerData['id']}' : FileImage(bannerImageFile)});
      }

      File languageFile = File('${path.path}/language.config');
      await languageFile.writeAsString(Localizations.localeOf(context).languageCode);
    } on Exception catch (e, trace) {
      console.log('error $e $trace');
      setState(() {
        loading = false;
        connectionError = true;
      });

      return;
    }

    setState(() {
      loading = false;
      tokenUpAni.start();
      catsDetails[0][4].start();
    });
  }

  int currentPage = 1;

  @override
  void initState() {
    super.initState();

    nameAnimation.init(this, .0, 1.0, Durations.long1, Curves.easeIn);
    tokensAnimation.init(this, .0, 1.0, Durations.medium2, Curves.easeIn);
    tokenUpAni.init(this, .0, 1.0, Durations.medium2, Curves.easeIn);
    qrCodeAnimation.init(this, 1.0, 0.3, Durations.medium2, Curves.easeIn);

    nameAnimation.whenDone(tokensAnimation);
    nameAnimation.start();

    mapAnimation.init(this, .0, 1.0, Durations.long1, Curves.decelerate);
    basketAnimation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);

    loadData();
  }

  PageController pageController = PageController(initialPage: 1);

  Widget carouselViewText(dynamic banner, dynamic size, bool isAr, bool alTop) {
    final style = TextStyle(color: Color(banner['fg']), fontSize: size.width * .055, overflow: TextOverflow.visible);
    if (isAr && alTop)   return  Positioned(top: 0    , right: 0, child: SizedBox(width: size.width * .6, child: Text('${banner['tar']}', style: style,)));
    if (isAr && !alTop)  return  Positioned(bottom: 0 , right: 0, child: SizedBox(width: size.width * .6, child: Text('${banner['tar']}', style: style,)));
    if (!isAr && alTop)  return  Positioned(top: 0    , left: 0 , child: SizedBox(width: size.width * .6, child: Text('${banner['ten']}', style: style,)));
    else return                  Positioned(bottom: 0 , left: 0 , child: SizedBox(width: size.width * .6, child: Text('${banner['ten']}', style: style,)));
  }

  Map<String, List<AnimationSet>> listItemsAnimations = {};

  void loadVoucherInfoFromServer() async {

  }

  void loadAllAnimationsForMenuItems() {
    for(String cat in menuCats) {
      List<AnimationSet> animationsForCat = [];

      for(int i=0;i<menuData[cat].length;++i) {
        final animation = new AnimationSet();
        animation.init(this, .0, 1.0, Durations.long1, Curves.decelerate);
        animationsForCat.add(animation);
      }

      listItemsAnimations.addAll({cat: animationsForCat});
    }
  }

  void startAnimationsTrailFor(String cat) {
    int i = 0;
    for(final animation in listItemsAnimations[cat]!) {
      animation.reset();
      Future.delayed(Duration(milliseconds: 100 * i)).then((_) => animation.start());
      i += 1;
    }
  }

  String breadName(L10n dic, BreadType type) {
    switch(type) {
      case BreadType.NORMAL:
        return dic.b_65;
        case BreadType.POTATO:
        return dic.b_potbun;
      case BreadType.FIT:
        return dic.b_fit;
    }
  }

  String pattyName(L10n dic, PattyType type) {
    switch(type) {
      case PattyType.NORMAL:
        return dic.pa_normal;
      case PattyType.SPECIAL:
        return dic.pa_special;
      case PattyType.SMASHED:
        return dic.pa_smashed;
    }
  }

  String friesName(L10n dic, FriesTypes type) {
    switch(type) {
      case FriesTypes.CURLY:
        return dic.pcurly;
      case FriesTypes.NORMAL:
        return dic.pnormal;
      case FriesTypes.WEDGES:
        return dic.pwidges;
      case FriesTypes.NONE:
        return '';
    }
  }

  Widget getMenuItemsView(String category) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final List<dynamic> modifiedList = [];
    List<int> modificationMap = [];

    for(int i=0;i<menuData[category].length;++i) {
      final originalItem = menuData[category][i];
      if (userProfile.liked.contains(originalItem['id'] as int)) {
        modifiedList.add(originalItem);
      } else {
        modificationMap.add(i);
      }
    }

    for (int unAddedIndex in modificationMap) {
      modifiedList.add(menuData[category][unAddedIndex]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: .625,
        children: List.generate(menuData[category].length, (index) {
          final menuItem = modifiedList[index];
          final isLiked = userProfile.liked.contains(menuItem['id'] as int);

          return Transform.translate(
            offset: Offset(.0, -25 * math.sin(listItemsAnimations[category]![index].value * math.pi)),
            child: Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: cs.secondary.withAlpha(25), blurRadius: 10, spreadRadius: 5)
                ]
              ),
              child: Column(
                spacing: 5,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Hero(
                            tag: '${menuItem['ne']}',
                            child: Container(
                              width: size.width * .45,
                              height: size.width * .45,
                              decoration: BoxDecoration(
                                  color: HSLColor.fromColor(cs.secondary).withLightness(.2 + (.4 / (index + 1))).toColor(),
                                  borderRadius:  BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                                  image: DecorationImage(image: menuSavedImages['${menuItem['i']}'] as ImageProvider, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () async{
                              await userProfile.changeLiked(menuItem['id']);
                              setState(() {

                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(45),
                              ),

                              padding: EdgeInsets.all(7),
                              child: isLiked ?  Image.asset('assets/heart_filled.png',    width: 15, color: Colors.red.shade800, colorBlendMode: BlendMode.srcIn) :
                                                Image.asset('assets/heart_unfilled.png',  width: 15),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  // SizedBox(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                      Row(
                        children: [
                          Expanded(child: Center(child: Text('${menuItem[isAr ? 'na' : 'ne']}', style: TextStyle(overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),))),
                        ],
                      ),

                      Text('${category != 'Appetizers' ? menuItem['c'].map((c) {
                        return (c == 'GC' || c == 'FB') ? '' : menuData['cs'][c][0];
                      }) : (menuItem['q'] == 1? '' : '${menuItem['q']} ${L10n.of(context)!.piece}')}', style: TextStyle(overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w300, fontSize: size.width * .025),),

                      Row(
                        spacing: 5,
                        mainAxisAlignment:MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${menuItem['p']} ${L10n.of(context)!.jd}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary),),
                          Row(children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: IconButton(
                                style: IconButton.styleFrom(backgroundColor: cs.secondary),
                                color: cs.surface,
                                icon: FaIcon(FontAwesomeIcons.add, size: 15,),
                                onPressed: () async {
                                  final pushResult = await Navigator.pushNamed(context, '/meal_view', arguments: {
                                    'data' : menuItem,
                                    'image_provider' : menuSavedImages[menuItem['i']],
                                    'category' : category,
                                    'cs' : menuData['cs'],
                                    'waiting_order' : userProfile.waiting_order,
                                  }) as Map<String, dynamic>;

                                  if (pushResult.containsKey('ordered')) {
                                    return;
                                  }

                                  pushResult.addAll({
                                    'id' : menuItem['id'],
                                    'na' : menuItem['na'],
                                    'ne' : menuItem['ne'],
                                    'cat' : category
                                  });

                                  myBasket.add(pushResult);
                                  setState(() {});

                                  Future.delayed(Durations.medium3).then((_) {
                                    basketAnimation.reset();
                                    basketAnimation.start();
                                  });
                                },
                              ),
                            )
                          ],)
                        ],
                      ),
                    ],),
                  )
                ],
              ),
            ),
          );
        },),
      ),
    );
  }

  String selectedCategory = 'Chicken';
  bool scanningCode = true;

  double get totalBasketPrice {
    double price = 0;
    for(final item in myBasket) {
      price += item['ppi'] * item['q'];
    }

    return price;
  }

  late Timer? timer;

  void checkingOrderStatusErrCallback(String msg) {
    /*showDialog(context: context, builder: (context) {
      return AlertDialog(content: Text('CHECKING_ORDER_ERR_CB --> $msg'));
    });

    timer?.cancel();*/
  }

  String currentOrderStatus = '';

  void runBackgroundOrderCheck() {
    final Uri checkingUrl = Uri.parse('https://www.route-65-dashboard.com/api/order_status');

    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updating'), duration: Duration(seconds: 1),));
      if (userProfile.waiting_order) {
        final key = userProfile.coc;
        final body = {
          'key' : key
        };

        http.post(checkingUrl, body: body).then((response) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;

            if (data['server_err'] as bool) {
              checkingOrderStatusErrCallback('L1');
            } else {
              setState(() {
                currentOrderStatus = data['status'] as String;
              });
            }
          } else {
            checkingOrderStatusErrCallback('L2 --> ${response.body}');
          }
        }).onError((err, s) {
          checkingOrderStatusErrCallback('$err');
        });
      }
    },);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: loading ? Center(child: SizedBox(width: size.width * .5, child: lottieLib.Lottie.asset('assets/loading.json')),) : connectionError ? NoInternetPage(refreshCallback: () {
        setState(() {
          loading = true;
          connectionError = false;
        });

        loadData();
      },) : Column(
        children: [
          if (userProfile.waiting_order) Container(
            decoration: BoxDecoration(
              color: cs.secondary.withAlpha(50),
              border: Border.all(color: Colors.grey.shade400),
              // borderRadius: BorderRadius.circular(5)
            ),
            width: size.width,
            padding: EdgeInsets.only(left:10, right:10, top:MediaQuery.of(context).padding.top, bottom:15),
            // margin: EdgeInsets.only(left: 10, right: 10, bottom: 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, spacing: 5, children: [
              Text(currentOrderStatus == 'PREP' ? dic.order_status_preparing : dic.order_status_on_road),
              SizedBox(width:10),
              Transform.scale(
                scale: currentOrderStatus == 'PREP' ? 1.75 : 2,
                child: lottieLib.Lottie.asset(
                  currentOrderStatus == 'PREP' ? 'assets/preparing.json' : 'assets/delivering.json', height: 35
                )
              ),
            ],),
          ),
          Expanded(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (value) {
                setState(() {
                  currentPage = value;
                });
              },
              controller: pageController,
              children: [
                /// --PAGE-PROFILE
                SingleChildScrollView(
                  child: Column(spacing: 0, children: [
                    Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 35), child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(userProfile.pic!),
                      radius: size.width * .25,
                    )),

                    SizedBox(height: 25,),
                    Text(userProfile.name!, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size.width * .065),),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.5, children: [
                        [userProfile.location!, 'assets/map_pin.png', false],
                        [userProfile.phone!, 'assets/telephone.png', false],
                        ['${dic.no_orders} ${userProfile.no_orders.toString()}', 'assets/burger.png', true, false],
                        ['${userProfile.tokens} ${(userProfile.tokens! > 10 ? dic.points_1 : dic.points_2)}', 'assets/coin.png', true, true]
                      ].map((item) {
                        return Container(
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: cs.secondary.withAlpha(15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300, width: 2)
                          ),

                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 10,
                              children: [
                                Image.asset(item[1] as String, width: 25,),
                                if (item[2] as bool) Row(mainAxisSize: MainAxisSize.min, spacing: 5, children: [
                                  Text((item[0] as String).split(' ')[0], style: TextStyle(fontWeight: (item[3] as bool) ? FontWeight.bold : FontWeight.normal, fontSize: size.width * .04)),
                                  Text((item[0] as String).split(' ')[1], style: TextStyle(fontWeight: (item[3] as bool) ? FontWeight.normal : FontWeight.bold, fontSize: size.width * .04),),
                                ],),

                                if (!(item[2] as bool)) Text(item[0] as String, style: TextStyle(fontSize: size.width * .035),)
                              ],
                            ),
                          ),
                        );
                      }).toList(),),
                    ),

                    ElevatedButton(
                      child: Text('Reset App'),
                      onPressed: () {
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.clear();
                          FirebaseAuth.instance.signOut();
                          FirebaseFirestore.instance.collection('app-users').doc(userProfile.uid).delete();
                          GoogleSignIn().signOut();
                          Navigator.of(context).popAndPushNamed('/login');
                        });
                      },
                    )
                  ])
                ),

                // --PAGE-HOME
                SingleChildScrollView(
                  child: Column(children: [

                    // --APP-BAR
                    Container(
                      width: size.width,
                      padding: EdgeInsets.only(top: !userProfile.waiting_order ? MediaQuery.of(context).padding.top : 10, left: 5, right: 5, bottom: 10),
                      decoration: BoxDecoration(
                        color: cs.secondary
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              dic.current_location,
                              style: TextStyle(color: cs.surface, fontSize: size.width * .045),
                            ),

                            Text(
                              userProfile.location ?? ' -- ',
                              style: TextStyle(color: cs.surface, fontSize: size.width * .045, decoration: TextDecoration.underline, decorationColor: cs.surface,
                                decorationThickness: 1.25),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                      ),

                      width: size.width,
                      child: Column(spacing: 15, children: [
                        SizedBox(height: 10,),
                        CarouselSlider.builder(
                          itemCount: bannersAd.length,
                          itemBuilder: (context, index, realIndex) {
                            final banner = bannersAd[index];
                            final alTop = banner['al'] == 'top';
                            return SizedBox(
                              width: size.width,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.secondary,
                                      borderRadius: BorderRadius.circular(0),
                                      image: DecorationImage(image: menuSavedImages['${banner['id']}'] as ImageProvider, fit: BoxFit.cover),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: !alTop ? [Colors.transparent, Colors.grey.shade900] : [
                                            Colors.grey.shade900, Colors.transparent
                                          ], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [.1, .8])
                                      ),
                                      child: Padding(padding: EdgeInsets.all(15), child: Stack(children: [
                                        carouselViewText(banner, size, isAr, alTop)
                                      ],),),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300,
                            autoPlay: true,
                          )
                        ),

                        SizedBox(height: 10,),
                        // --CATS-VIEW
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: EdgeInsets.only(top: 20),
                            child: Row(
                              spacing: 10,
                              children: [
                                SizedBox(width: 5,),
                                ...List.generate(catsDetails.length, (i) {
                                  final pair = catsDetails[i];
                                return Transform.translate/*Padding*/(
                                  offset: Offset(0, math.sin((pair[4] as AnimationSet).value * math.pi / 2.0) * -15),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Material(
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedCategory = pair[2];
                                            startAnimationsTrailFor(pair[2]);

                                            for(int x=0;x<catsDetails.length;++x) {
                                              if (x != i) {
                                                catsDetails[x][4].reset();
                                              } else {
                                                catsDetails[x][4].start();
                                              }
                                            }
                                          });
                                        },
                                        child: Container(
                                          width: size.width * .25,
                                          height: size.width * .25,
                                          decoration: BoxDecoration(
                                            color: (selectedCategory == pair[2] ? cs.secondary : cs.secondary.withAlpha(50)),
                                            borderRadius: BorderRadius.circular(15)
                                          ),

                                          child: Column(spacing: 10, mainAxisAlignment: MainAxisAlignment.center, children: [
                                            Container(
                                              padding: EdgeInsets.all(10),
                                              width: size.width * .12,
                                              height: size.width * .12,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(45),
                                                image: DecorationImage(image: menuSavedImages[pair[3]] as ImageProvider,
                                                  fit: BoxFit.cover)
                                              ),
                                            ),
                                            Text(pair[isAr ? 1 : 0], style: TextStyle(fontWeight: FontWeight.bold, color: selectedCategory == pair[2] ? Colors.white : cs.primary),),
                                          ],),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                                SizedBox(width: 5,),
                              ]
                            ),
                          ),
                        ),

                        Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Row(
                          spacing: 10,
                          children: [
                            Expanded(
                              child:Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: cs.secondary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey.shade300, width: 1)
                                ),
                                // --BUTTON-ASSETS
                                child: Row(spacing: 20, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  Image.asset('assets/coin.png', width: 28,),
                                  Transform.translate(offset: Offset(0, 3), child: Text('${userProfile.tokens} ${userProfile.tokens! > 10.0 ? dic.points_1 : dic.points_2}', style: TextStyle(color: cs.primary, fontSize: size.width * .045),)),
                                ],),
                              ),
                            ),

                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    // BUTTON-VOUCHERS
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/dine_room');
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                          color: cs.secondary.withAlpha(15),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: Row(spacing: 20, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                        Image.asset('assets/dining-room.png', width: 35,),
                                        Transform.translate(offset: Offset(0, 2), child: Text(dic.tables, style: TextStyle(color: cs.primary, fontSize: size.width * .045),))
                                      ],),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),),

                        getMenuItemsView(selectedCategory),

                        SizedBox(
                          height: 0,
                          child: ElevatedButton(child: Text('Reset'), onPressed: () async {
                            await GoogleSignIn().signOut();
                            // await FirebaseAuth.instance.signOut();
                            final pref = await SharedPreferences.getInstance();
                            pref.clear();
                            nameAnimation.dispose();
                            tokensAnimation.dispose();
                            FirebaseAuth.instance.currentUser!.delete();
                            await FirebaseFirestore.instance.collection('app-users').doc(userProfile.uid).delete();
                            Navigator.of(context).popAndPushNamed('/login');
                          },),
                        ),
                      ]),
                    ),
                  ],),
                ),


                // --PAGE-BASKET
                Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: userProfile.waiting_order ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text('${fromServerTotalPrice.toStringAsFixed(2)} ${dic.jd}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.secondary),),
                              SizedBox(width: 20),
                              FaIcon(FontAwesomeIcons.clock, color: cs.secondary)
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(fromServerIsTakeaway ? dic.takeaway : dic.delivery, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary),),
                              Transform.translate(
                                offset: Offset(.0, 3),
                                  child: FaIcon(fromServerIsTakeaway ? Icons.takeout_dining_outlined : Icons.delivery_dining_outlined, color: cs.primary, size:22)),
                              Transform.translate(
                                offset: Offset(.0, 2.5),
                                child: Text(fromServerIsTakeaway ? fromServerTakeawayLocation : '$fromServerLocation ($fromServerClosePlace)'))
                            ],
                          )
                        ),

                        ElevatedButton(
                          child: Text('Reset'),
                          onPressed : () {
                            userProfile.update(waiting_order: false, coc: null);
                            setState(() {

                            });
                          }
                        ),

                        Divider(color: Colors.grey.shade400, thickness: 2,),
                        SizedBox(height: 10,),

                        ...fromServerBasket.map((basketItem) {

                          return Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                borderRadius: BorderRadius.circular(15),
                                color: cs.surface
                            ),

                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                              Padding(padding: EdgeInsets.all(5), child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      spacing: 5,
                                      children: [
                                        Text('${basketItem[isAr ? 'name' : 'name_english']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, overflow: TextOverflow.ellipsis),),
                                        Text('x${basketItem['quantity']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, color:cs.secondary),
                                          textDirection: Directionality.of(context) == TextDirection.rtl ? TextDirection.ltr : TextDirection.rtl,),
                                      ],
                                    ),

                                    Text((basketItem['notes'] as String).trim().isEmpty ? dic.no_additional_notes : basketItem['notes'], style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontStyle: FontStyle.italic),)
                                  ],
                                ),
                              ),),


                              // SizedBox(height: 10,),

                              // if (basketItem['bt'] != null) basketViewLineWidget(dic.bv_bt, breadName(dic, basketItem['bt']), '🍞'),
                              // if (basketItem['pt'] != null) basketViewLineWidget(dic.bv_pt, pattyName(dic, basketItem['pt']), '🍔'),
                              // if (basketItem['ft'] != null) basketViewLineWidget(dic.bv_ft, friesName(dic, basketItem['ft']), '🍟'),
                              // if (basketItem['g']  != null) Text('${basketItem['g']} ${dic.gram} '),
                              // if (basketItem['cat'] == 'Appetizers' && basketItem['q'] != 1) Text('${basketItem['apq']} x ${basketItem['q']} = ${basketItem['apq'] * basketItem['q']} ${basketItem['apq'] * basketItem['q'] < 10 ? dic.piece : isAr ? 'قطعة' : dic.piece}', textDirection: TextDirection.ltr,)
                            ],),
                          );
                        })
                      ],
                    ),
                  ) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 8,),
                    Padding(
                      padding: const EdgeInsets.all(15.0).copyWith(top: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${dic.your_basket}', style: TextStyle(fontSize: size.width * .055)),
                          if (!usingVoucher) Text('${totalBasketPrice.toStringAsFixed(2)} JD', style: TextStyle(fontSize: size.width * .055, fontWeight: FontWeight.bold, color: cs.secondary),),
                          if (usingVoucher) Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 15,
                            children: [
                              Text('${totalBasketPrice.toStringAsFixed(2)} JD', style: TextStyle(fontSize: size.width * .055, fontWeight: FontWeight.bold, color: cs.primary, decoration: TextDecoration.lineThrough, decorationThickness: 3, decorationStyle: TextDecorationStyle.wavy, decorationColor: cs.primary)),
                              Text('${(totalBasketPrice * (1.0 - (voucherDiscountPerc / 100.0))).toStringAsFixed(2)} JD', style: TextStyle(fontSize: size.width * .055, fontWeight: FontWeight.bold, color: cs.secondary))
                            ],
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 15,),

                    myBasket.isEmpty ? Expanded(child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          SizedBox(width: size.width * .5, child: lottieLib.Lottie.asset('assets/empty_basket.json', repeat: false)),
                          Text(dic.basket_empty),
                          GestureDetector(
                            onTap: () {
                              pageController.jumpToPage(1);
                              setState(() {
                                currentPage = 1;
                              });
                            },

                            child: Text(dic.continue_shopping, style: TextStyle(color: cs.secondary, fontStyle: FontStyle.normal, decoration: TextDecoration.underline),),
                          )
                        ],
                      )
                    ),) :  Expanded(child: SingleChildScrollView(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20,
                      children: [
                        ...(List.generate(myBasket.length, (i) {
                          final basketItem = myBasket[myBasket.length - i - 1];
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(15),
                              color: cs.surface
                            ),

                            padding: EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                              Padding(padding: EdgeInsets.all(5), child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      spacing: 5,
                                      children: [
                                        Text('${basketItem[isAr ? 'na' : 'ne']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, overflow: TextOverflow.ellipsis),),
                                        Text('x${basketItem['q']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, color:cs.secondary),
                                            textDirection: Directionality.of(context) == TextDirection.rtl ? TextDirection.ltr : TextDirection.rtl,),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(child: Icon(Icons.close, size: 20,), onTap: () {
                                    setState(() {
                                      myBasket.remove(basketItem);
                                    });
                                  },)
                                ],
                              ),),

                              Divider(color: Colors.grey.shade400,),
                              Row(
                                children: [
                                  Text('${basketItem['ppi']} x ${basketItem['q']} = ${(basketItem['ppi'] * basketItem['q']).toStringAsFixed(2)} JD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .04, color: cs.secondary),
                                    textDirection: TextDirection.ltr,),
                                ],
                              ),

                              SizedBox(height: 10,),

                              if (basketItem['bt'] != null) basketViewLineWidget(dic.bv_bt, breadName(dic, basketItem['bt']), '🍞'),
                              if (basketItem['pt'] != null) basketViewLineWidget(dic.bv_pt, pattyName(dic, basketItem['pt']), '🍔'),
                              if (basketItem['ft'] != null) basketViewLineWidget(dic.bv_ft, friesName(dic, basketItem['ft']), '🍟'),
                              if (basketItem['g']  != null) Text('${basketItem['g']} ${dic.gram} '),
                              if (basketItem['cat'] == 'Appetizers' && basketItem['q'] != 1) Text('${basketItem['apq']} x ${basketItem['q']} = ${basketItem['apq'] * basketItem['q']} ${basketItem['apq'] * basketItem['q'] < 10 ? dic.piece : isAr ? 'قطعة' : dic.piece}', textDirection: TextDirection.ltr,)
                            ],),
                          );
                        }).toList()),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(dic.use_voucher,style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .0525),
                            textAlign: TextAlign.start),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(15),
                              color: cs.surface
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Image.asset('assets/voucher.png', height: 20,),
                                  Expanded(
                                    child: TextField(
                                      textAlignVertical: TextAlignVertical.center,
                                      controller: voucherController,
                                      decoration: InputDecoration(
                                        filled: false,
                                        hintText: '00XX21YY',
                                        hintStyle: TextStyle(color: Colors.grey.shade400,)
                                      ),
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: checkingVoucher ? null : () {
                                      setState(() {
                                        checkingVoucher = true;
                                        usingVoucher = false;
                                        /*Future.delayed(Duration(seconds: 1)).then((_) {
                                          setState(() {
                                            voucherDiscountPerc = 10;
                                            usingVoucher = true;
                                            checkingVoucher = false;
                                          });
                                        });*/
                                      });

                                      final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/voucher');
                                      http.post(url, body: {
                                        'code' : voucherController.text
                                      }).then((response) {
                                        print(response.body);
                                        try {
                                          final body = jsonDecode(response.body);
                                          print(body);
                                          if (body['err']) {
                                            setState(() {
                                              voucherDiscountPerc = 0;
                                              usingVoucher = false;
                                              checkingVoucher = false;
                                            });

                                            showDialog(context: context, builder: (context) => AlertDialog(content: Text(dic.voucher_dne, style: TextStyle(color: Colors.red.shade800),),));
                                          } else {
                                            if (body['exists']) {
                                              setState(() {
                                                usingVoucher = true;
                                                checkingVoucher = false;
                                                voucherDiscountPerc = body['perc'] * 100.0;
                                              });
                                            } else {
                                              setState(() {
                                                voucherDiscountPerc = 0;
                                                usingVoucher = false;
                                                checkingVoucher = false;
                                              });

                                              showDialog(context: context, builder: (context) => AlertDialog(content: Text(dic.voucher_dne, style: TextStyle(color: Colors.red.shade800)),));
                                            }
                                          }
                                        } catch (err) {
                                          setState(() {
                                            voucherDiscountPerc = 0;
                                            usingVoucher = false;
                                            checkingVoucher = false;
                                          });

                                          showDialog(context: context, builder: (context) => AlertDialog(content: Text(dic.voucher_dne, style: TextStyle(color: Colors.red.shade800)),));
                                        }
                                      }).onError((error, stackTrace) {
                                        setState(() {
                                          voucherDiscountPerc = 0;
                                          usingVoucher = false;
                                          checkingVoucher = false;
                                        });

                                        showDialog(context: context, builder: (context) => AlertDialog(content: Text(dic.voucher_dne, style: TextStyle(color: Colors.red.shade800)),));
                                      },);
                                    },
                                    child: Transform.translate(offset: Offset(0, 2), child:
                                      Text(
                                        dic.check_voucher,
                                        style: TextStyle(
                                          color: checkingVoucher ? Colors.grey.shade600 : cs.secondary,
                                          fontWeight: FontWeight.bold
                                        ),
                                      )
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (usingVoucher) Container(
                          decoration: BoxDecoration(
                            color: cs.secondary.withAlpha(50),
                            borderRadius: BorderRadius.circular(7)
                          ),
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          padding: EdgeInsets.all(10),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 15,
                                  children: [
                                    Text(voucherController.text, style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),),
                                    Text('$voucherDiscountPerc %', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary),),
                                    FaIcon(FontAwesomeIcons.receipt, color: cs.secondary, size:20)
                                  ],
                                ),
                              ),

                              Positioned(right: 5, top: 0, bottom: 0,
                                width:20, child: GestureDetector(child: Icon(Icons.close, color: cs.secondary, fill: .5,), onTap: () {
                                  setState(() {
                                    usingVoucher = false;
                                    voucherController.clear();
                                    voucherDiscountPerc = 0;
                                  });
                                },),),
                            ],
                          ),
                        ),

                        SizedBox(height: 0,),

                        Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Column(
                          spacing: 5,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dic.total_price,style: TextStyle(fontWeight: FontWeight.normal, fontSize: size.width * .0425),
                                    textAlign: TextAlign.start),

                                Text('$totalBasketPrice JD', style: TextStyle(fontWeight: FontWeight.normal, fontSize: size.width * .0425, color: cs.secondary))

                              ],
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dic.voucher_value,style: TextStyle(fontWeight: FontWeight.normal, fontSize: size.width * .0425),
                                    textAlign: TextAlign.start),

                                Text('$voucherDiscountPerc %', style: TextStyle(fontWeight: FontWeight.normal, fontSize: size.width * .0425, color: checkingVoucher ? Colors.grey.shade400 : cs.secondary))

                              ],
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dic.price_after_discount,style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .0425),
                                    textAlign: TextAlign.start),
                                Text('${(totalBasketPrice * (1.0 - (voucherDiscountPerc / 100.0))).toStringAsFixed(2)} JD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .0425, color: checkingVoucher ? Colors.grey.shade400 : cs.secondary))

                              ],
                            ),
                          ],
                        ),),

                        SizedBox(height: 50,),
                      ],
                    ),)),

                    Material(
                      child: InkWell(
                        onTap: () async {
                          try {
                            List<Map<String, dynamic>> refinedBasket = [];
                            for(final basketItem in myBasket) {
                              // throw basketItem['pt'].toString().split('.')[1];
                              final isMeal = basketItem['im'] as bool;
                              refinedBasket.add({
                                'name' : basketItem['na'],
                                'name_english' : basketItem['ne'],
                                'price' : basketItem['ppi'],
                                'quantity' : basketItem['q'],
                                'bt' : basketItem['bt']?.toString().split('.')[1],
                                'ft' : basketItem['ft']?.toString().split('.')[1],
                                'pt' : basketItem['pt']?.toString().split('.')[1],
                                'notes' : basketItem['an'],
                                'puq' : basketItem['apq'],
                                'grams' : basketItem['g'],
                                'cat' : basketItem['cat']
                              });
                            }

                            final body = {
                              'name' : userProfile.name,
                              'phone' : userProfile.phone,
                              'basket_items' : jsonEncode(refinedBasket),
                              'used_voucher' : usingVoucher,
                              'voucher' : usingVoucher ? voucherController.text : null,
                              'price_no_voucher' : totalBasketPrice,
                              'voucher_perc' : voucherDiscountPerc,
                              'total_price' : totalBasketPrice * (usingVoucher ? (1.0 - (voucherDiscountPerc / 100.0)) : 1.0),
                            };

                            Navigator.of(context).pushNamed('/confirm_order', arguments: body).then((r) {
                              if (r != null) {
                                setState(() {
                                  userProfile.update(waiting_order: true, coc: r as String);
                                  setState(() {
                                    loading = true;
                                  });
                                  loadData().then((_) {
                                    currentPage = 3;
                                  });
                                });
                              }
                            });
                          } catch (Err) {
                            showDialog(context: context, builder: (context) => AlertDialog(content: Text('Err --> $Err')));
                          }
                        },
                        child: Container(
                          height: myBasket.isEmpty ? 0 : 50,
                          width: size.width,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: cs.secondary
                          ),

                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              spacing: 15,
                              children: [
                                Text(dic.continue_, style: TextStyle(fontWeight: FontWeight.bold,
                                    color: cs.surface, fontSize: 15),),

                                FaIcon(Directionality.of(context) == TextDirection.rtl ? FontAwesomeIcons.arrowLeft : FontAwesomeIcons.arrowRight, color: cs.surface, size: 15,)
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],),
                ),

                // --PAGE-BOT
                ChatBotPage()
              ],
            ),
          ),

          Container(
            color: cs.secondary.withAlpha(50),
            height: 70,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, textDirection: isAr ? TextDirection.ltr : TextDirection.rtl, children: [
              // --NAV-BAR
              GestureDetector(onTap: () {
                pageController.jumpToPage(3);
                setState(() {
                  currentPage = 3;
                });
              }, child: FaIcon(
                currentPage == 3 ? Icons.smart_toy : Icons.smart_toy_outlined, size:30, color: currentPage == 3 ? cs.secondary : cs.primary,)),

              GestureDetector(
                onTap: () {
                  pageController.jumpToPage(2);
                  setState(() {
                    currentPage = 2;
                  });
                },
                child: SizedBox(width:30, height: 30, child: Stack(
                  children: [
                    Positioned.fill(child: FaIcon(
                      currentPage == 2 ? Icons.shopping_basket :Icons.shopping_basket_outlined, size: 30, color: currentPage == 2 ? cs.secondary : cs.primary,)),
                    Positioned(top: 0, right: 0, child: Transform.translate(
                      offset: Offset(15, -15 + (math.sin(basketAnimation.value * math.pi) * -10)),
                      child: Container(
                        decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(45)
                        ),
                        width: 20,
                        height: 20,
                        child: Transform.translate(offset: Offset(.0, .0), child: Center(child: Text('${userProfile.waiting_order ? fromServerBasket.length : myBasket.length}', style: TextStyle(color: Colors.white),))),
                      ),
                    ),)
                  ],
                )),
              ),

              GestureDetector(
                onTap: () {
                  pageController.jumpToPage(1);//, duration: Durations.medium2, curve: Curves.decelerate);
                  setState(() {
                    currentPage = 1;
                  });
                }, child: FaIcon(currentPage == 1 ? Icons.home : Icons.home_outlined, size: 32.5, color: currentPage == 1 ? cs.secondary : cs.primary,),
              ),

              GestureDetector(onTap: () {
                Navigator.pushNamed(context, '/qr_code', arguments: userProfile.phone).then((value) {
                  loadTokensFromServer().then((_) => setState(() {}));
                });


              }, child: FaIcon(Icons.qr_code_rounded, size:30, color: cs.primary),),


              GestureDetector(onTap: () {
                pageController.jumpToPage(0);
                setState(() {
                  currentPage = 0;
                });
              },child: FaIcon(currentPage == 0 ? Icons.person : Icons.person_outlined, size: 30, color: currentPage == 0 ? cs.secondary : cs.primary,)),
            ],),
          )
        ],
      ),
    );
  }

  Widget basketViewLineWidget(String name, String content, String icon) {
    return Row(children: [
      Text(name),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withAlpha(50),
          borderRadius: BorderRadius.circular(45),
        ),

        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(spacing: 5, children: [
          Text(icon),
          Text(content, style: TextStyle(color: Theme.of(context).colorScheme.primary),)
        ],),
      )
    ],);
  }

  @override
  void dispose() {
    ChatBotPage.endSession(userProfile);
    timer?.cancel();
    super.dispose();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}