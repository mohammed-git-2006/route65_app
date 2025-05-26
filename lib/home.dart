import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:route65/auth_engine.dart';
import 'package:http/http.dart' as http;
import 'package:route65/chatbot.dart';
import 'package:route65/l10n/l10n.dart';
import 'package:route65/no_internet.dart';
import 'dart:math' as math;
import 'dart:developer' as console;

import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/animation_set.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  UserProfile userProfile = UserProfile();
  bool loading = true;
  final nameAnimation = AnimationSet(), tokensAnimation = AnimationSet(), tokenUpAni = AnimationSet();

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
      console.log('got notification --> ${event.notification!.title}');
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
      print('--> response from server --> ${response.body}');
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
      print('### loadTokensFromServer error --> $err}');
      return false;
    }
  }

  bool connectionError = false;

  List<Map<String, dynamic>> bannersAd = [];
  Map<String, dynamic> menuData = {};

  void loadData() async {
    await userProfile.loadFromPref();
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
    } catch (err) {
      console.log('banner data error --> ${err}');
      connectionError = true;
    }

    if (!lr) connectionError = true;

    setState(() {
      loading = false;
      tokenUpAni.start();
    });
  }

  int currentPage = 2;

  @override
  void initState() {
    super.initState();

    setupNotifications();

    nameAnimation.init(this, .0, 1.0, Durations.long1, Curves.easeIn);
    tokensAnimation.init(this, .0, 1.0, Durations.medium2, Curves.easeIn);
    tokenUpAni.init(this, .0, 1.0, Durations.medium2, Curves.easeIn);

    nameAnimation.whenDone(tokensAnimation);

    nameAnimation.start();

    // userProfile.loadFromPref().then((_) => setState(() {
    //   loading = false;
    // }));
    // pageController.nextPage(duration: Durations.medium2, curve: Curves.decelerate);

    loadData();
  }

  PageController pageController = PageController(initialPage: 2);

  Widget carouselViewText(dynamic banner, dynamic size, bool isAr, bool alTop) {
    final style = TextStyle(color: Color(banner['fg']), fontSize: size.width * .055, overflow: TextOverflow.visible);
    if (isAr && alTop)   return Positioned(top: 0, right: 0, child: SizedBox(width: size.width * .6, child: Text('${banner['tar']}', style: style,)));
    if (isAr && !alTop)  return  Positioned(bottom: 0, right: 0,child: SizedBox(width: size.width * .6, child: Text('${banner['tar']}', style: style,)));
    if (!isAr && alTop)  return  Positioned(top: 0, left: 0,child: SizedBox(width: size.width * .6, child: Text('${banner['ten']}', style: style,)));
    else return  Positioned(bottom: 0, left: 0, child: SizedBox(width: size.width * .6, child: Text('${banner['ten']}', style: style,)));
  }


  Widget getMenuItemsView(String category) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      childAspectRatio: .8,
      children: List.generate(menuData[category].length, (index) {
        final menuItem = menuData[category][index];
        AnimationSet localAnimation = AnimationSet();
        localAnimation.init(this, .0, math.pi, Durations.medium2, Curves.decelerate);
        Future.delayed(Duration(milliseconds: 150 * index)).then((_) => localAnimation.start());
        return Transform.translate(
          offset: Offset(0, -25 * localAnimation.value),
          child: Column(
            spacing: 3,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/meal_view', arguments: {
                    'data' : menuItem
                  });
                },
                child: Hero(
                  tag: '${menuItem['ne']}',
                  child: Container(
                    width: size.width * .45,
                    height: size.width * .45,
                    decoration: BoxDecoration(
                        color: HSLColor.fromColor(cs.secondary).withLightness(.2 + (.4 / (index + 1))).toColor(),
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(image: CachedNetworkImageProvider('https://www.route-65-dashboard.com/api/menu/${menuItem['i']}'),
                            fit: BoxFit.cover)
                    ),
                  ),
                ),
              ),

              // SizedBox(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Row(
                    children: [
                      Expanded(child: Center(child: Text('${menuItem[isAr ? 'na' : 'ne']}', style: TextStyle(overflow: TextOverflow.ellipsis),))),
                    ],
                  ),

                  Row(
                    spacing: 5,
                    mainAxisAlignment:MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${menuItem['p']} JD', style: TextStyle(fontWeight: FontWeight.bold, color: cs.secondary),),
                      Row(children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.5),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: !isAr ? BorderRadius.only(
                              topLeft: Radius.circular(45),
                              bottomLeft: Radius.circular(45),
                            ) : BorderRadius.only(
                              topRight: Radius.circular(45),
                              bottomRight: Radius.circular(45),
                            )
                          ),

                          child: Text('-', style: TextStyle(color: cs.surface, fontSize: size.width * .04, fontWeight: FontWeight.bold),),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                              color: cs.secondary.withAlpha(50),
                              // borderRadius: BorderRadius.only(topLeft: Radius.circular(45), bottomLeft: Radius.circular(45),)
                          ),

                          child: Text('0', style: TextStyle(color: cs.secondary, fontSize: size.width * .04, fontWeight: FontWeight.bold),),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.5),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: isAr ? BorderRadius.only(
                              topLeft: Radius.circular(45),
                              bottomLeft: Radius.circular(45),
                            ) : BorderRadius.only(
                              topRight: Radius.circular(45),
                              bottomRight: Radius.circular(45),
                            )
                          ),

                          child: Text('+', style: TextStyle(color: cs.surface, fontSize: size.width * .04, fontWeight: FontWeight.bold),),
                        ),
                      ],)
                    ],
                  ),
                ],),
              )
            ],
          ),
        );
      },),
    );
  }

  String selectedCategory = 'Chicken';


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dic = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      /*floatingActionButton: connectionError ? null : Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        spacing: 15,
        children: [
          SpeedDial(
            backgroundColor: cs.secondary,
            direction: SpeedDialDirection.up,
            icon: (FontAwesomeIcons.add),
            activeIcon: (FontAwesomeIcons.add),
            useRotationAnimation: true,
            animationDuration: Durations.short2,
            animationCurve: Curves.easeIn,
            animationAngle: math.pi / 4,
            spacing: 15,
            children: [
              SpeedDialChild(child: FaIcon(FontAwesomeIcons.cartShopping, color: Colors.white,), backgroundColor: cs.secondary, visible: true, ),
              SpeedDialChild(child: FaIcon(FontAwesomeIcons.robot   , color: Colors.white,), backgroundColor: cs.secondary, visible: true, onTap: () =>
                  Navigator.of(context).pushNamed('/chatbot')),
              SpeedDialChild(child: FaIcon(FontAwesomeIcons.qrcode  , color: Colors.white), backgroundColor: cs.secondary, visible: true, ),
            ],
          ),
          

        ],
      ),*/

      body: loading ? Center(child: CircularProgressIndicator(),) : connectionError ? NoInternetPage(refreshCallback: () {
        setState(() {
          loading = true;
          connectionError = false;
        });

        loadData();
      },) : Column(
        children: [
          Expanded(
            child: PageView(
              onPageChanged: (value) {
                setState(() {
                  currentPage = value;
                });
              },
              controller: pageController,
              children: [
                Column(children: [
                  Text('QR code here')
                ],),

                Column(children: [
                  Text('Your basket here')
                ],),

                SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      // height: size.height * .5,
                      width: size.width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFF0C8A5E), // Forest Green
                          Color(0xFF0B673D),
                        ], begin: Alignment.bottomCenter, end: Alignment.topRight),
                      ),

                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15),
                          child: Column(spacing: 5, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Transform.translate(offset:  Offset((1 - nameAnimation.value) * -size.width, 0), child: Opacity(
                              opacity: nameAnimation.value,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      userProfile.name!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size.width * .065,
                                      overflow: TextOverflow.ellipsis),
                                    ),
                                  ),

                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage: CachedNetworkImageProvider(userProfile.pic!),
                                  )
                                ],
                              ),
                            ),),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${userProfile.location} - ${userProfile.phone}',
                                  style: TextStyle(color: Colors.white),
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
                            // console.log('alTop --> ${alTop} [${banner['al']}]');
                            return SizedBox(
                              width: size.width,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.secondary,
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(image: CachedNetworkImageProvider(banner['img']), fit: BoxFit.cover),
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
                                  [dic.appetizers, 'Appetizers', 'ceaser']
                                ].map((pair) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = pair[1];
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
                                          image: DecorationImage(image: CachedNetworkImageProvider('https://www.route-65-dashboard.com/api/menu/${pair[2]}'),
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

                        TextButton(onPressed: () {}, child: Text(dic.show_more, style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),)),
                    /*

                        Row(
                          mainAxisSize: MainAxisSize.max,
                          spacing: 15,
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade700,)),
                            Text(dic.chicken, style: TextStyle(color: Colors.grey.shade700,),),
                            Expanded(child: Divider(color: Colors.grey.shade700,)),
                          ],
                        ),

                        getMenuItemsView('Chicken'),

                    */

                        SizedBox(
                          height: 0,
                          child: ElevatedButton(child: Text('Reset'), onPressed: () async {
                            await GoogleSignIn().signOut();
                            // await FirebaseAuth.instance.signOut();
                            console.log(' --> ${FirebaseAuth.instance.currentUser == null}');
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

                ChatBotPage()
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
                color: cs.secondary.withAlpha(50),
              boxShadow: [
                // BoxShadow(color: Colors.grey.shade500, blurRadius: 10, spreadRadius: 5)
              ]
            ),
            height: 70,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, textDirection: isAr ? TextDirection.ltr : TextDirection.rtl, children: [
              GestureDetector(onTap: () {
                pageController.animateToPage(3, duration: Durations.medium2, curve: Curves.decelerate);
                setState(() {
                  currentPage = 3;
                });
              }, child: FaIcon(FontAwesomeIcons.robot, color: currentPage == 3 ? cs.secondary : cs.primary,)),

              GestureDetector(
                onTap: () {
                  pageController.animateToPage(2, duration: Durations.medium2, curve: Curves.decelerate);
                  setState(() {
                    currentPage = 2;
                  });
                }, child: FaIcon(FontAwesomeIcons.home, color: currentPage == 2 ? cs.secondary : cs.primary,),
              ),

              GestureDetector(
                onTap: () {
                  pageController.animateToPage(1, duration: Durations.medium2, curve: Curves.decelerate);
                  setState(() {
                    currentPage = 1;
                  });
                },
                child: SizedBox(width:30, height: 30, child: Stack(
                  children: [
                    Positioned.fill(child: FaIcon(FontAwesomeIcons.basketShopping, color: currentPage == 1 ? cs.secondary : cs.primary,size: 25,)),
                    Positioned(top: 0, right: 0, child: Transform.translate(
                      offset: Offset(15, -15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.secondary,
                          borderRadius: BorderRadius.circular(45)
                        ),

                        width: 20,
                        height: 20,

                        child: Center(child: Text('0', style: TextStyle(color: Colors.white),)),
                      ),
                    ),)
                  ],
                )),
              ),

              GestureDetector(onTap: () {
                pageController.animateToPage(0, duration: Durations.medium2, curve: Curves.decelerate);
                setState(() {
                  currentPage = 0;
                });
              },child: FaIcon(FontAwesomeIcons.qrcode, color: currentPage == 0 ? cs.secondary : cs.primary,)),
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
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(0, size.height - 40);

    // Create the "U" with a quadratic bezier
    path.quadraticBezierTo(
      size.width / 2, size.height + 40, // control point (deepest part)
      size.width, size.height - 40,     // end of curve
    );

    // Close the shape at the top-right
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
