import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:route65/auth_engine.dart';

import 'l10n/l10n.dart';

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

class _TokensRedeemState extends State<TokensRedeem> {
  bool modalRouteValuesSet = false;
  UserProfile? userProfile;


  @override
  Widget build(BuildContext context) {
    if (!modalRouteValuesSet) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      userProfile = args['userProfile'] as UserProfile;
      modalRouteValuesSet = true;
    }

    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;
    final dic = L10n.of(context)!;
    final _decoration = BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(7),
      boxShadow: [
        BoxShadow(color: cs.secondary.withAlpha(15), spreadRadius: 3, blurRadius: 3)
      ]
    );
    
    final tokens = userProfile?.tokens ?? 0;
    final nextSpot = tokens + (100.0 - (tokens % 100));

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Container(decoration: BoxDecoration(color: cs.secondary.withAlpha(20)),),
        ),
        Positioned.fill(
          top: 0,
          bottom: size.height * .875,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: cs.secondary
            ),
          ),
        ),

        Positioned(top: MediaQuery.of(context).padding.top + 10, left: 10, right: 10, child: Text(
          dic.rt_header,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),),

        /// Tokens view
        Positioned(
          top: size.height * .1,
          right: size.width* .05,
          left: size.width*  .05,
          child: Column(
            spacing: 15,
            children: [
              Container(
                decoration: _decoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      spacing: 10,
                      children: [
                        Row(spacing: 20, children: [
                          Image.asset('assets/coin.png', height: 35,),
                          Text('${dic.tokens} ${userProfile?.tokens?.toStringAsFixed(2)}', style: TextStyle(fontSize: 22),)
                        ],),

                        GradientProgressIndicator(value: 1, width: size.width * .9 - 60, cs: cs, animValue: 1.0)
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                decoration: _decoration,
                child: userProfile?.selfVouchers.length == 0 ? Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(dic.no_vouchers_for_redeem),
                ) : Column(children: userProfile!.selfVouchers.map((voucherName) {
                  return Text('$voucherName');
                }).toList(),),
              )
            ],
          ),
        ),

      ],),
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
      width: width,
      height: height,
      child: Stack(
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
            width: value *  width,
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
      ),
    );
  }
}
