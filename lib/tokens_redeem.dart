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

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Container(decoration: BoxDecoration(color: cs.secondary.withAlpha(20)),),
        ),
        Positioned.fill(
          top: 0,
          bottom: size.height * .85,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: cs.secondary
            ),
          ),
        ),

        Positioned(top: MediaQuery.of(context).padding.top + 10, left: 10, right: 10, child: Text(
          'Buy from the restaurant using the app, and get points and vouchers!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),),

        /// Tokens view
        Positioned(
          top: size.height * .1175,
          right: size.width* .05,
          left: size.width*  .05,
          child: Column(
            spacing: 15,
            children: [
              Container(
                height: size.height * .1,
                decoration: _decoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(spacing: 20, children: [
                    Image.asset('assets/coin.png', height: size.height * .05,),
                    Text('${dic.tokens} ${userProfile?.tokens?.toStringAsFixed(2)}', style: TextStyle(fontSize: 22),)
                  ],),
                ),
              ),

              Container(
                decoration: _decoration,
                child: userProfile?.selfVouchers.length == 0 ? Padding(
                  padding: EdgeInsets.all(15),
                  child: Text('No vouchers available for redeem'),
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
