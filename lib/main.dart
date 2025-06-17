import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:route65/auth_engine.dart';
import 'package:route65/confirm_order.dart';
import 'package:route65/dining_room_view.dart';
import 'package:route65/firebase_options.dart';
import 'package:route65/home.dart';
import 'package:route65/l10n/animation_set.dart';
import 'package:route65/meal_view.dart';
import 'package:route65/qr_page.dart';
import 'package:route65/tokens_redeem.dart';
import 'l10n/l10n.dart';
import 'dart:math' as math;

Future<void> onBackgroundMessageCallback(RemoteMessage message)  async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AuthEngine.showLocalNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessageCallback);
  runApp(MaterialLauncher());
}

class MaterialLauncher extends StatelessWidget {
  const MaterialLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    // Color(0xFF228B22), // Forest Green
    // Color(0xFF32CD32)
    final cs = ColorScheme.light(
      surface: Colors.white,
      // secondary: Color(0xFF0C8A5E),
      secondary: Color(0xff009252),
      primary: Colors.black
    );

    final theme = ThemeData(
      colorScheme: cs,
      textTheme: GoogleFonts.cairoTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),

        contentPadding: EdgeInsets.all(10),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none
        ),

        filled: true,
        fillColor: Colors.grey.shade200,
      ),

      buttonTheme: ButtonThemeData(
        buttonColor: cs.secondary,
        textTheme: ButtonTextTheme.normal,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(30)),
        )
      )
    );

    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      routes: {
        '/login' : (context) => LoginPage(),
        '/home' : (context) => HomePage(),
        '/meal_view' : (context) => MealView(),
        '/qr_code' : (context) => QrPage(),
        '/dine_room' : (context) => DiningRoomView(),
        '/confirm_order' : (context) => ConfirmOrder(),
        '/tokens_redeem' : (context) => TokensRedeem(),
      },
      initialRoute: '/login',
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final pageController = PageController();
  // --ANI-AREA
  final loginAnimation = AnimationSet(), titleAnimation = AnimationSet(), googleButtonAnimation = AnimationSet(), facebookButtonAnimation = AnimationSet(),
    dividerAnimation = AnimationSet(), p2Pic = AnimationSet(), p2Name = AnimationSet(), p2Input = AnimationSet(), p4t1 = AnimationSet(), p4t2 = AnimationSet(),
    p3t1 = AnimationSet(), p3t2 = AnimationSet(), p3input = AnimationSet(), p5t1 = AnimationSet(), p5t2 = AnimationSet(), p5dropdown = AnimationSet();

  final authEng = AuthEngine();
  final p2NameController = TextEditingController(), p3controller = TextEditingController();
  final p2InputNode = FocusNode();
  String p2NameHolder = '', _verificationId = '';
  String? viewTitle = null;

  List<FocusNode> _controllersNodes = [];
  List<TextEditingController> _phoneControllers = [];
  List<AnimationSet> p3inputs = [];
  List<String> authCode = List.generate(6, (index) => ' ');

  bool authCodeComplete = false, phoneComplete = false;

  @override
  void initState()  {
    super.initState();

    authEng.checkLogin().then((result) {
      if (result.status == CheckResult.FIRST_TIME) {
        print('FIRST_TIME cause is ${result.content}');
        p2NameController.text = authEng.userProfile.name ?? '';
        p2NameHolder = p2NameController.text;
        pageController.nextPage(duration: Durations.short2, curve: Curves.easeIn);
        Future.delayed(Durations.medium2).then((_) => p2Pic.start());
      } else if (result.status == CheckResult.SUCCESS) {
        disposeAnimations();
        Navigator.popAndPushNamed(context, '/home');
      } else {
        print('## Got CheckResult.ERROR ${result.status} -- ${result.content}');
        titleAnimation.start();
      }
    });

    final _duration = Durations.long1;

    loginAnimation.init(this, .0, 1.0, _duration, Curves.easeIn);
    titleAnimation.init(this, .0, 1.0, _duration, Curves.easeIn);
    googleButtonAnimation.init(this, .0, 1.0, _duration, Curves.easeIn);
    facebookButtonAnimation.init(this, .0, 1.0, _duration, Curves.easeIn);
    dividerAnimation.init(this, .0, 1.0, _duration, Curves.easeIn);

    titleAnimation.whenDone(loginAnimation);
    loginAnimation.whenHalf(dividerAnimation);
    dividerAnimation.whenHalf(googleButtonAnimation);
    googleButtonAnimation.whenHalf(facebookButtonAnimation);

    p2Pic.init(this, .0, 1.0, _duration, Curves.easeInBack);
    p2Name.init(this, .0, 1.0, _duration, Curves.easeInBack);
    p2Input.init(this, .0, 1.0, _duration, Curves.easeInBack);

    p2Pic.whenDone(p2Name);
    p2Name.whenHalf(p2Input);

    p3t1.init(this, .0, 1.0, _duration, Curves.easeInBack);
    p3t2.init(this, .0, 1.0, _duration, Curves.easeInBack);
    p3input.init(this, .0, 1.0, _duration, Curves.easeInBack);

    p3t1.whenDone(p3t2);
    p3t2.whenDone(p3input);

    p4t1.init(this, .0, 1.0, _duration, Curves.easeInBack);
    p4t2.init(this, .0, 1.0, _duration, Curves.easeInBack);

    p4t1.whenDone(p4t2);

    // --ANISET-AREA
    p5t1.init(this, .0, 1.0, _duration, Curves.easeIn);
    p5t2.init(this, .0, 1.0, _duration, Curves.easeIn);
    p5dropdown.init(this, .0, 1.0, _duration, Curves.easeIn);

    p5t1.whenDone(p5t2);
    p5t2.whenDone(p5dropdown);

    for(int i=0;i<6;++i) {
      final newController = new TextEditingController();
      newController.addListener(() {
        final regexPattern = RegExp(r'^\d$');
        if (!regexPattern.hasMatch(newController.text)) {
          newController.text = '';
        }

        if(newController.text.trim().isNotEmpty) {
          FocusScope.of(context).nextFocus();
        }

        bool spaceFound = false;

        for(int i=0;i<6;++i) {
          if (_phoneControllers[i].text.isEmpty) {
            spaceFound = true;
          }

          authCode[i] = _phoneControllers[i].text.isEmpty ? ' ' : _phoneControllers[i].text;
        }

        authCodeComplete = !spaceFound;

        if (authCodeComplete) setState(() {});
      });

      _phoneControllers.add(newController);
      _controllersNodes.add(new FocusNode());

      p3controller.addListener(() {
        setState(() {
          phoneComplete = p3controller.text.trim().length == 8;
        });
      });

      if (i == 0) {
        p3inputs.add(new AnimationSet()..init(this, .0, 1.0, Durations.short2, Curves.easeInBack));
      } else {
        p3inputs.add(new AnimationSet()..init(this, .0, 1.0, Durations.short2, Curves.easeInBack));
      }
    }

    for(int i=0;i<5;++i) {
      p3inputs[i].whenHalf(p3inputs[i+1]);
    }

    p4t2.whenDone(p3inputs[0]);

    p2NameController.addListener(() {
      setState(() {
        p2NameHolder = p2NameController.text;
      });
    });
  }

  void disposeAnimations() {
    loginAnimation.dispose();
    titleAnimation.dispose();
    googleButtonAnimation.dispose();
    facebookButtonAnimation.dispose();
    dividerAnimation.dispose();
    p2Pic.dispose();
    p2Name.dispose();
    p2Input.dispose();
    p4t1.dispose();
    p4t2.dispose();
    p3t1.dispose();
    p3t2.dispose();
    p3input.dispose();
    p5t1.dispose();
    p5t2.dispose();
    p5dropdown.dispose();
    // super.dispose();
  }

  void getBottomSheet(List<Widget> children) {
    showModalBottomSheet(context: context, shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero
    ), isScrollControlled: true, builder: (context) {
      return FractionallySizedBox(
        heightFactor: .3,
        widthFactor: 1.0,
        child: Padding(padding: EdgeInsets.all(25), child: Column(
          spacing: 15,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),),
      );
    },);
  }

  void googleLoginCallback() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) {
      return Center(child: SizedBox(width: MediaQuery.of(context).size.width * .5,child: Lottie.asset('assets/loading.json')),);
    },);

    final result = await authEng.loginGoogle();
    Navigator.of(context).pop();
    switch(result.status) {
      case CheckResult.SUCCESS:
        await authEng.userProfile.saveToPref();
        disposeAnimations();
        Navigator.popAndPushNamed(context, '/home');
        break;
      case CheckResult.FIRST_TIME:
        setState(() {
          p2NameController.text = authEng.userProfile.name ?? '';
          p2NameHolder = p2NameController.text;
          pageController.nextPage(duration: Durations.short2, curve: Curves.easeIn);
          viewTitle = L10n.of(context)!.completion;
          Future.delayed(Durations.medium2).then((_) => p2Pic.start());
        });
        break;
      case CheckResult.ERROR:
        final size = MediaQuery.of(context).size;
        print(result.content);
        getBottomSheet([
          Icon(Icons.error_outline, color: Colors.red.shade900, size: 70,),
          Text(L10n.of(context)!.login_error, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: size.width  * .05),)
        ]);
        break;
    }
  }

  void facebookLoginCallback() async {
    final result = await authEng.loginFacebook();
  }

  // --VAR-AREA

  String selectedArea = '';
  bool userSelectedArea = false;
  List<String> areasList = [''];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final dic = L10n.of(context)!;
    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (new_index) {

        },
        children: [
          Stack(
            children: [
              Positioned(
                left: 0, right: 0, top: 0, bottom: size.height * .6,
                child: ClipPath(

                  clipper: TopCustomClipper(),
                  child: Container(
                    height: size.height,
                    color: cs.secondary,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: size.height * .125 - (size.height * .05 * titleAnimation.value),
                child: Center(
                  child: Opacity(
                    opacity: titleAnimation.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/route65_logo_bg.png', width: size.width * .5, colorBlendMode: BlendMode.srcIn, color: cs.surface)
                      ],
                    ),
                  ),
                )
              ),

              Positioned(bottom: size.width * .2, left: size.width * .1, right: size.width * .1, child: Column(
                spacing: 15,
                children: [
                  Opacity(opacity: loginAnimation.value, child: Text(dic.login, style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * .06),)),
                  Opacity(opacity: dividerAnimation.value, child: Divider()),
                  Opacity(
                    opacity: googleButtonAnimation.value,
                    child: GestureDetector(
                      onTap: googleLoginCallback,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.secondary,
                          boxShadow: [BoxShadow(color: Colors.grey.shade200, spreadRadius: 10, blurRadius: 20)],
                          borderRadius: BorderRadius.circular(10)
                        ),

                        padding: EdgeInsets.all(10),
                        child: Row(spacing: 10, children: [
                          ClipOval(child: Container(color: cs.surface, padding: EdgeInsets.all(5), child: Image.asset('assets/google_logo.png', width: 20,))),
                          Text(dic.google_button, style: TextStyle(color: cs.surface, fontWeight: FontWeight.bold),)
                        ],),
                      ),
                    ),
                  ),

                  /*Opacity(
                    opacity: facebookButtonAnimation.value,
                    child: GestureDetector(
                      onTap: facebookLoginCallback,
                      child: Container(

                        decoration: BoxDecoration(
                            color: Color(0xff1877F2),
                            boxShadow: [BoxShadow(color: Colors.grey.shade200, spreadRadius: 10, blurRadius: 20)],
                            borderRadius: BorderRadius.circular(10)
                        ),

                        padding: EdgeInsets.all(15),
                        child: Row(spacing: 10, children: [
                          Image.asset('assets/facebook_logo.png', width: 30,),
                          Text(dic.facebook_button, style: TextStyle(color: Colors.white),)
                        ],),
                      ),
                    ),
                  ),*/
                ],
              )),
            ],
          ),

          // --PAGE-NAME

          Stack(children: [
            Positioned(top: size.height * .075, width: size.width, child: Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 35,
              children: [
                Opacity(
                  opacity: p2Pic.value,
                  child: SizedBox(width: size.width * .7, child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(authEng.userProfile.pic ?? ''),

                    // backgroundImage: NetworkImage(authEng.userProfile.pic ?? ''),
                    maxRadius: size.width * .25,
                  )),
                ),

                // Text('${authEng.userProfile.toJson()}'),

                Opacity(opacity: p2Name.value, child: Text(p2NameHolder, style: TextStyle(fontSize: size.width * .05, fontWeight: FontWeight.bold),))
              ],

            ),),

            Positioned(bottom: size.width * .1, left: size.width * .1, right: size.width * .1, child: Column(
              spacing: 15,
              children: [
                Opacity(
                  opacity: p2Input.value,
                  child: ShadowContainer(
                    child: TextField(
                      focusNode: p2InputNode,
                      cursorColor: cs.secondary,
                      controller: p2NameController,
                    ),
                  ),
                ),

                SizedBox(
                  width: size.width,
                  child: Opacity(
                    opacity: p2Input.value,
                    child: ElevatedButton(
                      onPressed: () {
                        if (p2NameController.text.trim().isEmpty) {
                          FocusScope.of(context).requestFocus(p2InputNode);

                          getBottomSheet([
                            Icon(Icons.error_outline, color: Colors.red.shade900, size: 70,),
                            Text(dic.name_error, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: size.width  * .055),)
                          ]);
                        } else {
                          pageController.nextPage(duration: Durations.short2, curve: Curves.easeIn);
                          Future.delayed(Durations.long1).then((_) => p3t1.start());
                        }
                      },

                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Text(dic.continue_),
                      ),
                    ),
                  ),
                ),
              ],
            ),)
          ],),

          Stack(children: [
            Positioned(top: size.width * .0, left: size.width * .05, right: size.width * .05, child: Column(
              spacing: 45,
              children: [
                /*Wrap(spacing: 15, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Opacity(opacity: p3t1.value, child: Text(dic.enter_phone, style: TextStyle(fontSize: size.width * .055),)),
                  Opacity(opacity: p3t2.value, child: Text('📞', style: TextStyle(fontSize: size.width * .055)))
                ],),*/
                Opacity(
                  opacity: p3t1.value,
                  child: SizedBox(
                    // width: size.width * .5,
                    height: size.height * .3,
                    child: Center(

                      child: Lottie.asset('assets/phone_animation.json',),
                    ),
                  ),
                ),

                Opacity(opacity: p3t2.value, child: Text(dic.enter_phone, style: TextStyle(fontSize: size.width * .055))),


                Opacity(
                  opacity: p3input.value,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15)
                      ),

                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: cs.secondary,),
                          SizedBox(width: 6,),
                          Transform.translate(offset: Offset(0, 2), child: Text('07', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: size.width * .05),)),
                          Expanded(
                            child: TextField(
                              maxLength: 8,
                              controller: p3controller,
                              textAlignVertical: TextAlignVertical.bottom,
                              keyboardType: TextInputType.number,
                              style: TextStyle(letterSpacing: 2, fontSize: size.width * .05),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '...',
                                contentPadding: EdgeInsets.only(top: 5, bottom: 7.5, left: 15, right: 5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ]
            )),

            // --PAGE-PHONE

            Positioned(bottom: size.width * .05, left: size.width * .05, right: size.width * .05, child: Row(
              spacing: 15,
              children: [
                ElevatedButton(
                  onPressed: () {
                    pageController.previousPage(duration: Durations.long1, curve: Curves.easeIn);
                  },

                  child: Icon(Icons.chevron_left),
                ) ,
                // Text('$phoneComplete'),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey.shade300),
                    onPressed: !phoneComplete ? null : () {
                      setState(() {
                        phoneComplete = false;
                      });

                      // showDialog(context: context, builder: (context) {
                      //   return AlertDialog(content:Text('checking, button should be disabled'));
                      // });

                      p3controller.text = p3controller.text.split('').map((char) => PhoneNumberFormatter.mapping.keys.contains(char) ? PhoneNumberFormatter.mapping[char] : char).toList().join('');

                      FirebaseAuth.instance.verifyPhoneNumber(
                        verificationCompleted: (phoneAuthCredential) {

                        }, verificationFailed: (error) {
                          getBottomSheet([
                            Icon(Icons.error_outline, color: Colors.red.shade900, size: 70,),
                            Text(dic.send_code_err, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: size.width  * .055),)
                          ]);
                          setState(() {
                            setState(() {
                              phoneComplete = p3controller.text.length == 8;
                            });
                          });
                        }, codeSent: (verificationId, forceResendingToken) {
                          pageController.nextPage(duration: Durations.short2, curve: Curves.easeInBack).then((_) {
                            p4t1.start();
                          });

                          _verificationId = verificationId;
                        }, codeAutoRetrievalTimeout: (verificationId) {
                          /*getBottomSheet([
                            Icon(Icons.error_outline, color: Colors.red.shade900, size: 70,),
                            Text('${dic.send_code_err} - time out', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: size.width  * .055),)
                          ]);*/
                          setState(() {
                            setState(() {
                              phoneComplete = p3controller.text.length == 8;
                            });
                          });
                        }, phoneNumber: '+9627${p3controller.text}'
                      );
                    },

                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(dic.continue_),
                    ),
                  ),
                ),
              ],
            ),)
          ],),

          // --PAGE-CODE

          Stack(children: [
            Positioned(top: size.width * 0.1, left: 0, right: 0, child: Column(
              spacing: 45,
              children: [
                /*Wrap(spacing: 15, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Opacity(opacity: p4t1.value, child: Text(dic.phone_check, style: TextStyle(fontSize: size.width * .055),)),
                  Opacity(opacity: p4t2.value, child: Text('📩', style: TextStyle(fontSize: size.width * .055)))
                ],),*/

                SizedBox(
                  // width: size.width * .5,
                  height: size.height * .25,
                  child: Center(

                    child: Lottie.asset('assets/code_animation.json'),
                  ),
                ),

                Opacity(opacity: p3t2.value, child: Text(dic.check_phone, style: TextStyle(fontSize: size.width * .055))),

                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, spacing: 10,
                      children: List.generate(_phoneControllers.length, (index) {
                        return Transform.translate(
                          offset: Offset(0, math.sin(p3inputs[index].value * math.pi) * -10),
                          child: Opacity(
                            opacity: p3inputs[index].value,
                            child: Container(
                              width: size.width * (1 /9),
                              height: size.width * (1 /9) + 5,
                              decoration: BoxDecoration(
                                boxShadow: [BoxShadow(spreadRadius: 2, blurRadius: 3, color: Colors.grey.shade300, offset: Offset(0, 5.0))],
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10)
                              ),

                              padding: EdgeInsets.all(3),
                              child: Center(
                                child: TextField(
                                  // keyboardType: TextInputType.number,
                                  decoration: InputDecoration(fillColor: Colors.grey.shade50, contentPadding: EdgeInsets.zero, counterText: ''),
                                  style: TextStyle(color: Colors.black),
                                  textAlign: TextAlign.center,
                                  controller: _phoneControllers[index],
                                  focusNode:  _controllersNodes[index],
                                  maxLength:  1,
                                ),
                              ),
                            ),
                          ),
                        );
                      },),
                    ),
                  ),
                )
              ],
            ),),

            Positioned(bottom: size.width * .05, left: size.width * .05, right: size.width * .05, child: Row(
              spacing: 15,
              children: [
                ElevatedButton(
                  onPressed: () {
                    pageController.previousPage(duration: Durations.long1, curve: Curves.easeIn);
                  },

                  // child: Icon(L10n.of(context).),
                  child: Icon(Icons.chevron_left),
                ) ,
                Expanded(
                  child: ElevatedButton(
                    onPressed: !authCodeComplete ? null : () async {
                      String smsCode = '';
                      for(String char in authCode) {
                        smsCode += char;
                      }

                      try {
                        final authCred  = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: smsCode);
                        await FirebaseAuth.instance.currentUser!.linkWithCredential(authCred);
                        setState(() {
                          areasList = [
                            dic.a3,
                            dic.a4,
                            dic.a5,
                            dic.a6,
                            dic.a7,
                            dic.a8,
                            dic.a9,
                            dic.a10,
                            dic.am,
                            dic.aa,
                            dic.ah,
                            dic.as,
                            dic.ak
                          ];

                          selectedArea = areasList[0];
                        });
                        pageController.nextPage(duration: Durations.short2, curve: Curves.easeInBack);
                        p5t1.start();
                      } catch(err) {

                        getBottomSheet([
                          Icon(Icons.error_outline, color: Colors.red.shade900, size: 70,),
                          Text('$err'),
                          Text(dic.code_auth_err, style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: size.width  * .055),)
                        ],);
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(dic.check_phone),
                    ),
                  ),
                ),
              ],
            ),)
          ],),

          // --PAGE-AREA

          Stack(children: [
            Positioned(left: size.width * .05, right: size.width * .05, top: size.width * .1, child: Column(spacing: 45, children: [
              /*Row(spacing: 15, mainAxisSize: MainAxisSize.min, children: [
                Opacity(opacity: p5t1.value, child: Text(dic.location, style: TextStyle(fontSize: size.width * .055),)),
                Opacity(opacity: p5t2.value, child: Text('📍 🗺️', style: TextStyle(fontSize: size.width * .055)))
              ],),*/

              SizedBox(
                height: size.height * .3,
                child: Lottie.asset('assets/map_animation.json'),
              ),

              Opacity(opacity: p3t2.value, child: Text(dic.location, style: TextStyle(fontSize: size.width * .055))),

              // Text('til tomm ${areasList}'),
              Opacity(
                opacity: p5dropdown.value,
                child: DropdownButtonFormField<String>(items: areasList.map((areaName) => DropdownMenuItem<String>(
                  value: areaName,
                  child: Text(areaName),
                )).toList(), onChanged: (value) {
                  setState(() {
                    selectedArea = value!;
                    userSelectedArea = true;
                  });
                }, value: selectedArea, decoration: InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),),
              ),
              /*ElevatedButton(
                child: Text('change'),
                onPressed: () {
                  setState(() {
                    areasList = ['hello', 'name'];
                    selectedArea = 'hello';
                  });
                },
              )*/
            ],),),

            Positioned(left: size.width * .05, right: size.width * .05, bottom: size.width * .05, child: ElevatedButton(
              child: Text(dic.continue_),
              onPressed: !userSelectedArea ?  null : () async {
                pageController.nextPage(duration: Durations.short2, curve: Curves.easeIn);
              },
            ),)
          ],),

          // --PAGE-DONE
          Stack(children: [
            Positioned(left: size.width * .25, right: size.width * .25, top: size.width * .2, child: Column(
              spacing: 25,
              children: [
                Lottie.asset('assets/green_check.json'),
                Text(dic.account_finished, style: TextStyle(fontSize: size.width * .055),
                )
              ],
            )),
            Positioned(left: size.width * .05, right: size.width * .05, bottom: size.width * .05, child: ElevatedButton(
              child: Text(dic.finish),
              onPressed: () async {
                await authEng.userProfile.update(name: p2NameController.text, location: selectedArea, tokens: 0, completed: true, phone: '07${p3controller.text}', no_orders: 0);
                disposeAnimations();
                Navigator.of(context).popAndPushNamed('/home');
              },
            ),)
          ],)
        ],
      ),
    );
  }
}


class TopCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // TODO: implement getClip
    final path = Path();
    path.lineTo(0, size.height - 50);

    final firstControl = Offset(size.width / 4, size.height);
    final firstEnd = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(firstControl.dx, firstControl.dy, firstEnd.dx, firstEnd.dy);

    final secondControl = Offset(size.width * 3 / 4, size.height - 80);
    final secondEnd = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControl.dx, secondControl.dy, secondEnd.dx, secondEnd.dy);

    path.lineTo(size.width, 0);
    path.close();

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}