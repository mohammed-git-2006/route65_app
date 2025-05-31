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

  bool connectionError = false;
  List<Map<String, dynamic>> bannersAd = [];
  Map<String, dynamic> menuData = {};
  List<String> menuCats = [];
  Map<String, FileImage> menuSavedImages = {};
  List<Map<String, dynamic>> myBasket = [];

  void loadData() async {
    await userProfile.loadFromPref();
    setupNotifications();
    final lr = await loadTokensFromServer();

    try {
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
      loadAllAnimationsForMenuItems();
    } catch (err) {
      console.log('[Connection check][1] $err');
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
    } on Exception catch (e) {
      console.log('error $e');
      setState(() {
        loading = false;
        connectionError = true;
      });

      return;
    }

    setState(() {
      loading = false;
      tokenUpAni.start();
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

  void loadAllAnimationsForMenuItems() {
    for(String cat in menuCats) {
      List<AnimationSet> animationsForCat = [];

      for(int i=0;i<menuData[cat].length;++i) {
        final animation = new AnimationSet();
        animation.init(this, .0, 1.0, Durations.medium1, Curves.decelerate);
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
    List<int> modificationMap = [];//List.generate((menuData[category] as List<dynamic>).length, (i) => i);

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
        mainAxisSpacing: 15,
        crossAxisSpacing: 0,
        childAspectRatio: .625,
        children: List.generate(menuData[category].length, (index) {
          final menuItem = modifiedList[index];
          final isLiked = userProfile.liked.contains(menuItem['id'] as int);

          return Transform.translate(
            offset: Offset(.0, -20 * math.sin(listItemsAnimations[category]![index].value * math.pi)),
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
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(image: menuSavedImages['${menuItem['i']}'] as ImageProvider,
                                      fit: BoxFit.cover)
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
                          Text('${menuItem['p']} JD', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary),),
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
                                    'cs' : menuData['cs']
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

  final map65MainBranch = LatLng(29.5218664,34.999778), map65OtherBranch = LatLng(29.5322255,35.0038199);

  double get totalBasketPrice {
    double price = 0;
    for(final item in myBasket) {
      price += item['ppi'] * item['q'];
    }

    return price;
  }

  get map65MidPoint {
    return LatLng(
      (map65MainBranch.latitude  + map65OtherBranch.latitude ) / 2.0,
      (map65MainBranch.longitude + map65OtherBranch.longitude) / 2.0,
    );
  }

  void openLocation(LatLng location) async {
    Uri uri = Uri.parse('https://maps.app.goo.gl/5TXstuZonzbguVVA7');
    if (location == map65MainBranch) {
      uri = Uri.parse('https://maps.app.goo.gl/NMEJK6Q8GjzZHSex7');
    }

    if (await canLaunchUrl(uri)) launchUrl(uri);
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
                SafeArea(
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(dic.map_t1, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: size.width * .065),),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.secondary.withAlpha(50), width: 4),
                          borderRadius: BorderRadius.circular(30)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: GoogleMap(
                            style: 'hyperspace',
                            initialCameraPosition: CameraPosition(target: map65MidPoint, zoom: 15),
                            markers: {
                              Marker(position: map65MainBranch, markerId: MarkerId('main_branch'), onTap: () => openLocation(map65MainBranch)),
                              Marker(position: map65OtherBranch, markerId: MarkerId('2nd_branch'), onTap: () => openLocation(map65OtherBranch)),
                            },
                          )
                        )
                      ),
                    )
                  ],),
                ),

                SingleChildScrollView(
                  child: Column(children: [
                    ClipPath(
                      // clipper: UShapeClipper(),
                      child: Container(
                        // height: size.height * .5,
                        width: size.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            cs.secondary, // Forest Green
                            cs.secondary,
                          ], begin: Alignment.bottomCenter, end: Alignment.topRight),
                        ),

                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15),
                            child: Column(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    spacing: 10,
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: CachedNetworkImageProvider(userProfile.pic!),
                                      ),

                                      Text(
                                        userProfile.name!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size.width * .035,
                                          overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Transform.translate(offset: Offset(.0, -10 * math.sin(tokenUpAni.value * math.pi)), child: Text('${userProfile.tokens}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)),
                                      SizedBox(width: 5,),
                                      Image.asset('assets/token.png', color: Colors.white, colorBlendMode: BlendMode.srcIn, width: 20,),
                                      IconButton(icon: FaIcon(FontAwesomeIcons.refresh, color: cs.surface, size: 20,), onPressed: () {
                                        tokenUpAni.reset();

                                        loadData();
                                      },),
                                    ],
                                  )
                                ],
                              ),
                            ],),
                          ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 10,
                              children: [
                                SizedBox(width: 5,),
                                ...[
                                  [dic.chicken, 'Chicken', 'mixcheese_chicken'],
                                  [dic.beef, 'Beef', '65_beef'],
                                  [dic.hotdogs, 'Hotdog', 'hotdog'],
                                  [dic.appetizers, 'Appetizers', 'ceaser'],
                                ].map((pair) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = pair[1];
                                      startAnimationsTrailFor(pair[1]);
                                    });
                                  },
                                  child: Container(
                                    width: size.width * .25,
                                    height: size.width * .25,
                                    decoration: BoxDecoration(
                                      color: selectedCategory == pair[1] ? cs.secondary : cs.secondary.withAlpha(50),
                                      borderRadius: BorderRadius.circular(15)
                                    ),

                                    child: Column(spacing: 10, mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        width: size.width * .12,
                                        height: size.width * .12,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(45),
                                          image: DecorationImage(image: menuSavedImages[pair[2]] as ImageProvider,
                                            fit: BoxFit.cover)
                                        ),
                                      ),
                                      Text(pair[0], style: TextStyle(fontWeight: FontWeight.bold, color: selectedCategory == pair[1] ? Colors.white : cs.primary),),
                                    ],),
                                  ),
                                );
                              }).toList(),
                                SizedBox(width: 5,),
                              ]
                            ),
                          ),
                        ),

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


                // PAGE-BASKET
                Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 8,),
                    Padding(
                      padding: const EdgeInsets.all(15.0).copyWith(top: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${dic.your_basket}', style: TextStyle(fontSize: size.width * .055)),
                          Text('${totalBasketPrice.toStringAsFixed(2)} JD', style: TextStyle(fontSize: size.width * .055, fontWeight: FontWeight.bold, color: cs.secondary),)
                        ],
                      ),
                    ),
                    SizedBox(height: 15,),

                    myBasket.isEmpty ? Expanded(child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          SizedBox(width: size.width * .5, child: lottieLib.Lottie.asset('assets/empty_basket.json')),
                          Text(dic.basket_empty),
                        ],
                      )
                    ),) : Expanded(child: SingleChildScrollView(child: Column(
                      spacing: 20,
                      children: [
                        ...(myBasket.map((basketItem) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(15),
                              color: cs.surface
                            ),

                            padding: EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

                              if (basketItem['bt'] != null) Text('${dic.bv_bt}\t${breadName(dic, basketItem['bt'])}'),
                              if (basketItem['pt'] != null) Text('${dic.bv_pt}\t${pattyName(dic, basketItem['pt'])}'),
                              if (basketItem['ft'] != null) Text('${dic.bv_ft}\t${friesName(dic, basketItem['ft'])}'),
                              if (basketItem['g']  != null) Text('${basketItem['g']} ${dic.gram} '),
                              if (basketItem['cat'] == 'Appetizers' && basketItem['q'] != 1) Text('${basketItem['apq']} x ${basketItem['q']} = ${basketItem['apq'] * basketItem['q']} ${basketItem['apq'] * basketItem['q'] < 10 ? dic.piece : isAr ? 'قطعة' : dic.piece}',
                                    textDirection: TextDirection.ltr,)

                            ],),
                          );
                        }).toList()),

                      ],
                    ),)),
                  ],),
                ),

                ChatBotPage()
              ],
            ),
          ),

          Container(
            color: cs.secondary.withAlpha(50),
            height: 70,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, textDirection: isAr ? TextDirection.ltr : TextDirection.rtl, children: [
              GestureDetector(onTap: () {
                pageController.jumpToPage(3);
                setState(() {
                  currentPage = 3;
                });
              }, child: FaIcon(FontAwesomeIcons.robot, color: currentPage == 3 ? cs.secondary : cs.primary,)),

              GestureDetector(
                onTap: () {
                  pageController.jumpToPage(2);
                  setState(() {
                    currentPage = 2;
                  });
                },
                child: SizedBox(width:30, height: 30, child: Stack(
                  children: [
                    Positioned.fill(child: FaIcon(FontAwesomeIcons.basketShopping, color: currentPage == 2 ? cs.secondary : cs.primary,size: 25,)),
                    Positioned(top: 0, right: 0, child: Transform.translate(
                      offset: Offset(15, -15 + (math.sin(basketAnimation.value * math.pi) * -10)),
                      child: Container(
                        decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(45)
                        ),
                        width: 20,
                        height: 20,
                        child: Center(child: Text('${myBasket.length}', style: TextStyle(color: Colors.white),)),
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
                }, child: FaIcon(FontAwesomeIcons.home, color: currentPage == 1 ? cs.secondary : cs.primary,),
              ),

              GestureDetector(onTap: () {
                pageController.jumpToPage(0);//, duration: Durations.medium2, curve: Curves.decelerate);
                setState(() {
                  currentPage = 0;
                });

              }, child: FaIcon(FontAwesomeIcons.mapLocationDot, color: currentPage == 0 ? cs.secondary : cs.primary,),),


              GestureDetector(onTap: () {

              },child: FaIcon(FontAwesomeIcons.qrcode, /*color: currentPage == 0 ? cs.secondary : cs.primary,*/)),
            ],),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    ChatBotPage.endSession(userProfile);
    super.dispose();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class UShapeClipper extends CustomClipper<Path> {
  final zigZagHeight = 10.0;
  final zigZagWidth = 50.0;
  final minHeight = 15.0;
  final maxHeight = 20.0;
  @override
  Path getClip(Size size) {
    /*
    final path = Path();
    path.moveTo(0, 0);

    // Top edge
    path.lineTo(0, size.height - zigZagHeight);

    // ZigZag along the bottom
    bool isZig = true;
    for (double x = 0; x < size.width; x += zigZagWidth) {
      if (isZig) {
        path.lineTo(x + zigZagWidth / 2, size.height);
      } else {
        path.lineTo(x + zigZagWidth / 2, size.height - zigZagHeight);
      }
      isZig = !isZig;
    }

    // Right side
    path.lineTo(size.width, 0);
    path.close();

    return path;
*/
    final path = Path();
    final random = Random();

    path.moveTo(0, 0); // Top-left corner
    path.lineTo(0, size.height - maxHeight); // Left side

    double x = 0;
    bool down = true;

    while (x < size.width) {
      double height = minHeight + random.nextDouble() * (maxHeight - minHeight);
      double nextX = x + zigZagWidth;

      if (nextX > size.width) nextX = size.width;

      double y = down ? size.height : size.height - height;
      path.lineTo(x + zigZagWidth / 2, y);

      down = !down;
      x = nextX;
    }

    path.lineTo(size.width, 0); // Right side
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
