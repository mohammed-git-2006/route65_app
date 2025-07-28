import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:route65/auth_engine.dart';
import 'package:route65/l10n/animation_set.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:route65/no_internet.dart';
import 'l10n/l10n.dart';
import 'package:gif/gif.dart';

/*
* The Tokens redeem page is simply converting the tokens of user (using userProfile.phone and name) to a one-time voucher
* from here i will change the tokens system on the Express server, since we have 30% discount vouchers for staff and they are reusable
* We will add the options in each document voucher which is times: (int), if -1 : infinity, else one-time, 10-times, ...
* here we will use the API url, we will use it when the user wants to redeem the tokens (each 100)
*
* The Data Arch will be like this --> user-made vouchers will be saved in both (mongo DB) as usable, and in FireStore to read them for user
* since here i will add the vouchers string[] in UserProfile class
* */

/*
* The UI will be like this --> Column --> Header with tokens number --> ListView with all pre-existing vouchers
* */

class TokensRedeem extends StatefulWidget {
  const TokensRedeem({super.key});

  @override
  State<TokensRedeem> createState() => _TokensRedeemState();
}

class _TokensRedeemState extends State<TokensRedeem>  with TickerProviderStateMixin {
  bool modalRouteValuesSet = false;
  UserProfile? userProfile;
  AnimationsCollection collection = new AnimationsCollection();
  bool loading = true, connectionErr = false;
  late double voucherThreshold, discount;
  int uiAnimationsOffset = 3;
  late int _offset;
  GifController? _gifController;
  late double tokensPlaceholder;

  void calculateOffset(){
    _offset = (tokensPlaceholder / voucherThreshold).floor();
  }

  Future<void> loadInfo() async {
    try {
      setState(() {
        loading = true;
        connectionErr = false;
      });

      final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/voucher_info');
      final response = await http.get(url);

      if (response.statusCode != 200) throw Exception('Status not 200');
      final rMap = jsonDecode(response.body) as Map<String, dynamic>;

      voucherThreshold = rMap['threshold'] * 1.0;
      discount = rMap['perc'] as double;

      calculateOffset();

      await userProfile?.loadVouchers();

      setState(() {
        loading = false;
        connectionErr = false;

        collection.start();
      });
    } on Exception catch (e) {
      setState(() {
        loading = false;
        connectionErr = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    collection.create(0, this, 0, 1.0, Durations.medium1, Curves.easeIn);
    collection.create(1, this, 0, 1.0, Durations.extralong3, Curves.decelerate);
    collection.create(2, this, 0, 1.0, Durations.medium1, Curves.easeInBack);

    collection.makeTrailDone(0, 1);
    collection.whenDone(1, 2);

    collection.create(3, this, 0, 1.0, Durations.medium1, Curves.easeInBack);
    collection.whenDone(2, 3);

    _congratsAnimation.init(this, 0, 1.0, Duration(seconds: 4), Curves.linear);
    _gifController = GifController(vsync: this);

    loadInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (!modalRouteValuesSet) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      userProfile = args['userProfile'] as UserProfile;
      modalRouteValuesSet = true;
      tokensPlaceholder = userProfile!.tokens!;
    }

    final q = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final dic = L10n.of(context)!;

    return Scaffold(
      body: loading ? Center(child: SizedBox(width: 250, child: Lottie.asset('assets/loading.json')),) :
      connectionErr ? NoInternetPage(refreshCallback: loadInfo) : Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(left: 10, right: 10, top: q.padding.top + 10, bottom: 15),
          decoration: BoxDecoration(
            color: cs.secondary
          ),

          child: Text(dic.rt_header, style: TextStyle(color: cs.surface, fontSize: 20),),
        ),

        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    customContainer(child: Container(
                      child: ListTile(
                        leading: Image.asset('assets/coin.png', height: 50, width: 50,),
                        title: Row(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(dic.tokens, style: TextStyle(fontSize: 18),),
                            Transform.scale(
                              scale: 1 + (math.sin(collection.value(2) * math.pi) * .5),
                              child: Text((tokensPlaceholder * collection.value(1)).toStringAsFixed(2), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),)
                            )
                          ],
                        ),

                        subtitle: Text(
                          dic.forevery.replaceAll('#', voucherThreshold.toStringAsFixed(0)).replaceAll('*', (discount * 100.0).toStringAsFixed(0))
                        ),
                      )
                    ), aniIndex: 0),

                    if (userProfile!.selfVouchers.isNotEmpty) Expanded(
                      child: customContainer(aniIndex: 3, padding: EdgeInsets.symmetric(horizontal: 10), child: Container(
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(userProfile!.selfVouchers.length, (i) {
                              final voucherString = userProfile!.selfVouchers[i];

                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                                leading: Transform.translate(offset: Offset(L10n.of(context)!.localeName == 'en' ? 5 : -5, 0), child: Image.asset('assets/voucher.png', height: 30,)),
                                title: Container(
                                  margin: EdgeInsets.only(left: 15),
                                  child: Text(
                                    voucherString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: cs.secondary),),
                                ),
                                trailing: OutlinedButton(
                                  style: OutlinedButton.styleFrom(side: BorderSide(color: cs.secondary, width: 2)),
                                  onPressed: () {
                                    Navigator.pop(context, {
                                      'voucher' : voucherString,
                                      'perc' : discount*100.0
                                    });
                                  },

                                  child: Text(dic.use, style: TextStyle(fontWeight: FontWeight.bold, color:cs.secondary),),
                                ),
                              );
                            }),
                          ),
                        ),
                      )),
                    ),

                    if (_offset == 0) Expanded(
                      child: customContainer(
                        aniIndex: 0,
                        child: Center(
                          child: Text(dic.no_tokens_enough),
                        )
                      ),
                    ),

                    // Text('$redeemingTokens'),

                    if (_offset > 0)Expanded(
                      child: customContainer(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        aniIndex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(_offset, (i) {
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                                leading: Gif(image: AssetImage('assets/gift.gif'), controller: _gifController, height: 40, autostart: Autostart.loop,),
                                title: Text(' ${dic.voucher_value} %${(discount * 100.0).toStringAsFixed(0)}'),
                                trailing: OutlinedButton(
                                  style: OutlinedButton.styleFrom(side: BorderSide(color: cs.secondary, width: 2), disabledBackgroundColor: Colors.grey,
                                    disabledForegroundColor: Colors.red),
                                  onPressed: redeemingTokens ? null : () {
                                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Redeeming ...'),));
                                    redeemTokens();
                                  },
                                  child: Text(dic.redeem, style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold),),
                                ),
                              );
                            }),
                          ),
                        )
                      ),
                    ),

                    SizedBox(height: q.padding.bottom,)
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(child: Lottie.asset('assets/congrats.json', controller: _congratsAnimation.controller))
              )
            ],
          ),
        )
      ],),
    );
  }

  final AnimationSet _congratsAnimation = new AnimationSet();

  @override
  void dispose() {
    super.dispose();
    collection.dispose();
  }

  bool redeemingTokens = false;
  bool redeemingResult = false;

  void redeemTokens() {
    setState(() {
      redeemingTokens = true;
      redeemingResult = false;
    });

    showDialog(
      context: context,
      builder: (ctx) {
        final Uri url = Uri.parse('https://www.route-65-dashboard.com/api/redeem/${userProfile?.phone?.trim()}');
        http.get(url).then((serverResponse) {
          redeemingResult = serverResponse.statusCode == 200;

          if (redeemingResult) {
            final redeemInfo = jsonDecode(serverResponse.body) as Map<String, dynamic>;

            tokensPlaceholder = redeemInfo['final_tokens'] * 1.0;
            calculateOffset();
            userProfile?.update(tokens: tokensPlaceholder);
            userProfile?.loadVouchers().then((_) {
              setState(() {});
            });
          }

          Navigator.of(ctx).pop();
        });

        return AlertDialog(
          content: SizedBox(
            height: 150,
            width: 150,
            child: Lottie.asset('assets/loading.json'),
          ),
        );
      },

      barrierDismissible: false
    ).then((value) {
      setState(() {
        redeemingTokens = false;
        _congratsAnimation.reset();
        _congratsAnimation.start();
      });
      // showDialog(context: context, builder: (context) {
      //   return AlertDialog(content: Text(redeemingResult ? 'Redeemed Succesfully' : "Not reedeemed"),);
      // },);
    },);
  }

  Widget customContainer({
    required int aniIndex,
    required Widget child,
    EdgeInsets? padding
  }) {
    final cs = Theme.of(context).colorScheme;
    return customAnimator(child: Container(
      margin: EdgeInsets.all(15),
      padding: padding ?? EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, spreadRadius: 5, blurRadius: 5)
        ]
      ),

      child: child,
    ), index: aniIndex);
  }

  Widget customAnimator({required Widget child, required int index}) {
    return Transform.translate(
      offset: Offset(MediaQuery.of(context).size.width * (1 - collection.value(index)), 0),
      child: child,
    );
  }
}















class GradientProgressIndicator extends StatelessWidget {
  late double value, width;
  double height = 10.0;
  late ColorScheme cs;
  late double animValue;
  GradientProgressIndicator({super.key, required this.value, required this.width, required this.cs, required this.animValue});

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2.0),
                      color: cs.secondary.withAlpha(50)
                  ),
                ),
              ),

              Positioned(
                left: 0,
                top: 0,
                // right: ((1.0 - value) * width) * animValue,
                height: height,
                width: value *  constraints.maxWidth,
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height / 2.0),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF228B22), // Forest Green
                            Color(0xFF32CD32)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                    )
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
