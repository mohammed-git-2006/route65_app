import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:route65/l10n/l10n.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key, required this.refreshCallback});
  final Function() refreshCallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 15,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * .3, child: Lottie.asset('assets/no_internet_animation.json')),
            Center(child: Text(L10n.of(context)!.no_internet, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800, fontSize: 17))),
            ElevatedButton(
              onPressed: refreshCallback,
              child:Text(L10n.of(context)!.try_again),
            ),
          ],
        ),
      ),
    );
  }
}
